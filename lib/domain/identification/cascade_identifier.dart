import 'dart:async';
import 'dart:io';

import '../../core/utils/scientific_name.dart';
import 'identification_metrics.dart';
import 'identification_policy.dart';
import 'local_plant_model.dart';
import 'plant_identifier.dart';

/// Relie un nom d'espèce venu d'un modèle ou d'un service à l'identifiant
/// interne du catalogue de l'app, ou `null` si la plante n'y est pas.
typedef CatalogMapper = String? Function(String scientificName);

/// Modèle local d'abord, service distant ensuite si le local hésite.
///
/// Le déroulé, pour une photo :
/// 1. cache : la même photo déjà identifiée rend le même résultat ;
/// 2. modèle local, s'il est chargé, avec un délai maximal ;
/// 3. [FallbackPolicy] : réponse acceptée → on s'arrête là, sans réseau ;
/// 4. sinon service distant, s'il est configuré, autorisé, et sous le
///    quota du jour ;
/// 5. sans service distant utilisable, on rend la réponse locale, même
///    incertaine — mieux vaut une liste douteuse qu'un écran vide, et
///    l'interface montre toujours plusieurs candidats.
class CascadeIdentifier implements PlantIdentifier {
  CascadeIdentifier({
    required this.local,
    required this.fallback,
    this.policy = const FallbackPolicy(),
    IdentificationMetricsStore? metrics,
    this.fallbackEnabled = true,
    this.dailyRemoteLimit = 200,
    this.localTimeout = const Duration(seconds: 4),
    CatalogMapper? mapper,
    DateTime Function()? now,
    this.cacheSize = 24,
  })  : metricsStore = metrics ?? InMemoryMetricsStore(),
        _mapper = mapper ?? ((_) => null),
        _now = now ?? DateTime.now;

  final LocalPlantModel local;
  final PlantIdentifier fallback;
  final FallbackPolicy policy;
  final IdentificationMetricsStore metricsStore;

  /// L'utilisateur peut couper le repli distant (réglages) : tout reste
  /// alors sur l'appareil.
  final bool fallbackEnabled;

  /// Plafond d'appels distants par jour civil, en dessous du quota gratuit
  /// de Pl@ntNet (500 / jour) pour garder une marge aux autres usages.
  final int dailyRemoteLimit;
  final Duration localTimeout;
  final int cacheSize;
  final CatalogMapper _mapper;
  final DateTime Function() _now;
  final _cache = <String, List<IdentificationCandidate>>{};

  IdentificationMetrics get metrics => metricsStore.read();

  /// Charge le modèle local à l'avance, sans rien identifier.
  Future<void> warmUp() => local.warmUp().then((_) {}, onError: (_) {});

  @override
  bool get isConfigured => local.isAvailable || (fallbackEnabled && fallback.isConfigured);

  /// Reste-t-il du quota distant aujourd'hui ?
  bool get remoteAllowedToday {
    final m = metricsStore.read();
    return m.remoteDay != _today() || m.remoteToday < dailyRemoteLimit;
  }

  @override
  Future<List<IdentificationCandidate>> identify(List<File> images, {String? language}) async {
    if (images.isEmpty) return const [];
    final key = await _cacheKey(images);
    final cached = _cache[key];
    if (cached != null) {
      await _update((m) => m.copyWith(cacheHits: m.cacheHits + 1));
      return cached;
    }

    var m = metricsStore.read().copyWith(total: metricsStore.read().total + 1);
    List<IdentificationCandidate> localResult = const [];
    var verdict = IdentificationVerdict.noCandidate;
    if (local.isAvailable) {
      m = m.copyWith(local: m.local + 1);
      try {
        localResult = _mark(await _classifyAll(images), IdentificationSource.local);
        verdict = policy.decide(localResult);
      } on Object {
        // Un modèle qui plante ou dépasse le délai ne doit pas bloquer
        // l'identification : on passe au repli.
        m = m.copyWith(errors: m.errors + 1);
      }
    }

    if (verdict == IdentificationVerdict.accepted) {
      m = m.copyWith(localAccepted: m.localAccepted + 1, confidenceSum: m.confidenceSum + localResult.first.score);
      await metricsStore.write(m);
      return _remember(key, localResult);
    }

    final canFallback = fallbackEnabled && fallback.isConfigured;
    if (canFallback) {
      final today = _today();
      final todayCount = m.remoteDay == today ? m.remoteToday : 0;
      if (todayCount >= dailyRemoteLimit) {
        m = m.copyWith(quotaRefusals: m.quotaRefusals + 1);
      } else {
        m = m.copyWith(
          remote: m.remote + 1,
          fallbacks: m.fallbacks + (local.isAvailable ? 1 : 0),
          remoteDay: today,
          remoteToday: todayCount + 1,
        );
        try {
          final remote = _mark(await fallback.identify(images, language: language), IdentificationSource.remote);
          if (remote.isNotEmpty) m = m.copyWith(confidenceSum: m.confidenceSum + remote.first.score);
          await metricsStore.write(m);
          return _remember(key, remote);
        } on Object {
          m = m.copyWith(errors: m.errors + 1);
          if (localResult.isEmpty) {
            await metricsStore.write(m);
            rethrow;
          }
        }
      }
    }

    // Pas de repli possible : la réponse locale, telle quelle.
    if (localResult.isNotEmpty) m = m.copyWith(confidenceSum: m.confidenceSum + localResult.first.score);
    await metricsStore.write(m);
    return _remember(key, localResult);
  }

  Future<List<IdentificationCandidate>> _classifyAll(List<File> images) async {
    // Plusieurs photos de la même plante : les scores s'additionnent par
    // espèce puis se normalisent, ce qui favorise l'espèce vue partout.
    final sums = <String, double>{};
    final commons = <String, String?>{};
    for (final image in images) {
      final result = await local.classify(image).timeout(localTimeout);
      for (final c in result) {
        sums[c.scientificName] = (sums[c.scientificName] ?? 0) + c.score;
        commons.putIfAbsent(c.scientificName, () => c.commonName);
      }
    }
    final merged = [
      for (final e in sums.entries) IdentificationCandidate(scientificName: e.key, commonName: commons[e.key], score: e.value / images.length),
    ]..sort((a, b) => b.score.compareTo(a.score));
    return merged;
  }

  List<IdentificationCandidate> _mark(List<IdentificationCandidate> candidates, IdentificationSource source) => [
        for (final c in candidates)
          c.copyWith(
            scientificName: normalizeScientificName(c.scientificName).isEmpty ? c.scientificName : normalizeScientificName(c.scientificName),
            source: source,
            internalId: () => _mapper(c.scientificName),
          ),
      ];

  List<IdentificationCandidate> _remember(String key, List<IdentificationCandidate> result) {
    if (_cache.length >= cacheSize) _cache.remove(_cache.keys.first);
    _cache[key] = result;
    return result;
  }

  Future<void> _update(IdentificationMetrics Function(IdentificationMetrics) change) => metricsStore.write(change(metricsStore.read()));

  Future<String> _cacheKey(List<File> images) async {
    final parts = <String>[];
    for (final f in images) {
      final stat = await f.stat();
      parts.add('${f.path}|${stat.size}|${stat.modified.millisecondsSinceEpoch}');
    }
    return parts.join(';');
  }

  String _today() {
    final d = _now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}
