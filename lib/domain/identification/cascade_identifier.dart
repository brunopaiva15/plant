import 'dart:async';
import 'dart:io';

import '../../core/utils/scientific_name.dart';
import 'identification_metrics.dart';
import 'identification_policy.dart';
import 'local_plant_model.dart';
import 'plant_identifier.dart';

/// Ce que le catalogue de l'app sait d'une espèce nommée par un modèle ou un
/// service : son identifiant interne, et son nom courant dans la langue de
/// l'utilisateur. Un nom scientifique seul ne dit rien à la plupart des gens ;
/// « Spathiphyllum wallisii » ne devient une plante qu'en lisant « Fleur de
/// lune » en dessous.
class CatalogMatch {
  const CatalogMatch({required this.internalId, this.commonName});

  final String internalId;
  final String? commonName;
}

/// Relie un nom d'espèce au catalogue, dans une langue donnée, ou rend
/// `null` si la plante n'y est pas.
typedef CatalogLookup = CatalogMatch? Function(String scientificName, String languageCode);

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
    CatalogLookup? lookup,
    DateTime Function()? now,
    this.cacheSize = 24,
  })  : metricsStore = metrics ?? InMemoryMetricsStore(),
        _lookup = lookup ?? ((_, _) => null),
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
  final CatalogLookup _lookup;
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

  /// Interroge le service distant sans repasser par le modèle local.
  /// Appelée quand l'utilisateur demande explicitement une recherche en
  /// ligne, parce qu'aucune proposition locale ne lui convient.
  Future<List<IdentificationCandidate>> identifyRemotely(List<File> images, {String? language}) async {
    if (images.isEmpty) return const [];
    if (!fallbackEnabled || !fallback.isConfigured) return const [];
    var m = metricsStore.read();
    final today = _today();
    final todayCount = m.remoteDay == today ? m.remoteToday : 0;
    if (todayCount >= dailyRemoteLimit) {
      await metricsStore.write(m.copyWith(quotaRefusals: m.quotaRefusals + 1));
      return const [];
    }
    m = m.copyWith(remote: m.remote + 1, remoteDay: today, remoteToday: todayCount + 1);
    try {
      final remote = _mark(await fallback.identify(images, language: language), IdentificationSource.remote, language);
      await metricsStore.write(m);
      _cache[await _cacheKey(images)] = remote;
      return remote;
    } on Object {
      await metricsStore.write(m.copyWith(errors: m.errors + 1));
      rethrow;
    }
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
    // Le modèle se charge à la première demande. Décider sur `isAvailable`
    // seul revenait à l'ignorer tant que rien d'autre ne l'avait chargé — en
    // pratique, tant que l'utilisateur n'avait pas ouvert les réglages — et
    // à payer un appel distant pour une photo que le modèle n'avait jamais
    // vue. On le charge donc ici, dans le même délai que la classification.
    final localRan = local.isAvailable && await _warmUp();
    if (localRan) {
      m = m.copyWith(local: m.local + 1);
      try {
        localResult = _mark(await _classifyAll(images), IdentificationSource.local, language);
        verdict = policy.decide(localResult);
      } on Object {
        // Un modèle qui plante ou dépasse le délai ne doit pas bloquer
        // l'identification : on passe au repli.
        m = m.copyWith(errors: m.errors + 1);
      }
    }

    // Réponse sûre, ou seulement plausible : dans les deux cas on s'arrête
    // là. Une liste plausible est utile telle quelle — l'écran en montre
    // cinq et l'utilisateur choisit — et il peut demander une recherche en
    // ligne si rien ne lui convient. Payer l'appel d'avance reviendrait à
    // le faire pour toutes les photos, y compris celles où le modèle avait
    // déjà proposé la bonne espèce.
    if (verdict == IdentificationVerdict.accepted || verdict == IdentificationVerdict.plausible) {
      m = m.copyWith(
        localAccepted: m.localAccepted + 1,
        confidenceSum: m.confidenceSum + localResult.first.score,
      );
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
          fallbacks: m.fallbacks + (localRan ? 1 : 0),
          remoteDay: today,
          remoteToday: todayCount + 1,
        );
        try {
          final remote = _mark(await fallback.identify(images, language: language), IdentificationSource.remote, language);
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

  /// Charge le modèle si ce n'est pas déjà fait. Faux si le chargement
  /// échoue ou traîne : la cascade continue alors sans lui.
  Future<bool> _warmUp() async {
    try {
      return await local.warmUp().timeout(localTimeout);
    } on Object {
      return false;
    }
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

  /// Normalise les noms, note la provenance, rattache au catalogue. Le nom
  /// courant vient du catalogue quand la source n'en donne pas : le modèle
  /// local ne connaît que les noms scientifiques, Pl@ntNet fournit le sien
  /// et on le garde.
  List<IdentificationCandidate> _mark(List<IdentificationCandidate> candidates, IdentificationSource source, String? language) => [
        for (final c in candidates)
          () {
            final canonical = normalizeScientificName(c.scientificName);
            final match = _lookup(c.scientificName, language ?? 'en');
            return c.copyWith(
              scientificName: canonical.isEmpty ? c.scientificName : canonical,
              commonName: (c.commonName?.isNotEmpty ?? false) ? c.commonName : match?.commonName,
              source: source,
              internalId: () => match?.internalId,
            );
          }(),
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
