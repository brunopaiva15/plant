import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

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
    this.monthlyRemoteLimit = 30,
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
  /// Appels distants par appareil et par mois civil. Trente, parce qu'un
  /// appel Pl@ntNet se paie et que le modèle embarqué doit suffire au
  /// quotidien ; la recherche en ligne est le recours, pas la règle.
  final int monthlyRemoteLimit;
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

  /// Appels distants déjà faits ce mois-ci.
  int get remoteUsedThisMonth {
    final m = metricsStore.read();
    return m.remotePeriod == _month() ? m.remoteInPeriod : 0;
  }

  /// Reste-t-il du quota distant ce mois-ci ?
  bool get remoteAllowedThisMonth => remoteUsedThisMonth < monthlyRemoteLimit;

  /// Interroge le service distant sans repasser par le modèle local.
  /// Appelée quand l'utilisateur demande explicitement une recherche en
  /// ligne, parce qu'aucune proposition locale ne lui convient.
  Future<List<IdentificationCandidate>> identifyRemotely(List<File> images, {String? language}) async {
    if (images.isEmpty) return const [];
    if (!fallbackEnabled || !fallback.isConfigured) return const [];
    var m = metricsStore.read();
    final month = _month();
    final used = m.remotePeriod == month ? m.remoteInPeriod : 0;
    if (used >= monthlyRemoteLimit) {
      await metricsStore.write(m.copyWith(quotaRefusals: m.quotaRefusals + 1));
      return const [];
    }
    m = m.copyWith(remote: m.remote + 1, remotePeriod: month, remoteInPeriod: used + 1);
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
      final month = _month();
      final used = m.remotePeriod == month ? m.remoteInPeriod : 0;
      if (used >= monthlyRemoteLimit) {
        m = m.copyWith(quotaRefusals: m.quotaRefusals + 1);
      } else {
        m = m.copyWith(
          remote: m.remote + 1,
          fallbacks: m.fallbacks + (localRan ? 1 : 0),
          remotePeriod: month,
          remoteInPeriod: used + 1,
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

  /// Sous ce score, le modèle ne rend pas un candidat (`TflitePlantModel`).
  /// Une espèce absente d'une liste vaut donc *au plus* cela.
  static const _absentScore = 0.01;

  /// Au-delà, les plus anciennes photos sortent du mémo. Trois pour la série
  /// en cours, et de quoi ne pas tout perdre quand l'utilisateur recommence.
  static const _maxShots = 8;

  /// Ce que le modèle a déjà dit de chaque photo, prise une par une.
  ///
  /// Une photo de plus refait toute la **fusion** — la moyenne géométrique se
  /// calcule sur la liste entière —, mais elle n'a aucune raison de refaire
  /// toute l'**inférence**. Elle la refaisait : à 320 px chaque image coûte
  /// près d'une seconde (§ 6.7), et monter à trois photos en demandait six au
  /// lieu de trois. La bande des photos rend le geste répétable ; il devait
  /// cesser d'être quadratique.
  ///
  /// Ce mémo est en amont du cache de [identify], qui garde des réponses
  /// finies par jeu de photos : ici ce sont les scores bruts d'une image,
  /// avant fusion, avant seuil, avant rattachement au catalogue.
  final _shots = <String, List<IdentificationCandidate>>{};

  /// Les scores du modèle pour une photo, calculés une seule fois.
  Future<List<IdentificationCandidate>> _classifyOnce(File image) async {
    final key = await _fileKey(image);
    final known = _shots[key];
    if (known != null) return known;
    final result = await local.classify(image).timeout(localTimeout);
    _shots[key] = result;
    if (_shots.length > _maxShots) _shots.remove(_shots.keys.first);
    return result;
  }

  Future<List<IdentificationCandidate>> _classifyAll(List<File> images) async {
    if (images.length == 1) {
      return _classifyOnce(images.first);
    }
    // Plusieurs photos de la même plante : on fusionne par **moyenne
    // géométrique** des scores, c'est-à-dire moyenne des logarithmes.
    //
    // La moyenne arithmétique pardonne à une photo ratée : une espèce vue à
    // 0,9 sur l'une et 0,1 sur l'autre ressort à 0,5. La géométrique exige
    // que les photos soient d'accord et la ramène à 0,3. Mesuré sur 2 000
    // observations de trois photos du jeu de test (tools/plant_model/
    // multi_photo.py), l'écart entre les deux est de cinq points de top-1 ;
    // le passage d'une photo à trois en vaut dix-neuf.
    //
    // Une espèce absente de la liste d'une photo ne vaut pas zéro — cela
    // annulerait le produit — mais la borne que l'on connaît : le modèle
    // ayant tronqué sa liste, elle est sous le plus petit score rendu, et
    // sous le seuil de troncature. C'est une pénalité, pas un veto.
    final scores = <Map<String, double>>[];
    final floors = <double>[];
    final commons = <String, String?>{};
    var coveredMass = 0.0;
    for (final image in images) {
      final result = await _classifyOnce(image);
      final byName = {for (final c in result) c.scientificName: c.score};
      var floor = _absentScore;
      for (final s in byName.values) {
        if (s < floor) floor = s;
        coveredMass += s;
      }
      scores.add(byName);
      floors.add(floor);
      for (final c in result) {
        commons.putIfAbsent(c.scientificName, () => c.commonName);
      }
    }
    coveredMass /= images.length;

    final names = {for (final s in scores) ...s.keys};
    if (names.isEmpty) return const [];
    final merged = <String, double>{};
    var total = 0.0;
    for (final name in names) {
      var sumOfLogs = 0.0;
      for (var i = 0; i < scores.length; i++) {
        sumOfLogs += math.log(math.max(scores[i][name] ?? floors[i], 1e-9));
      }
      final score = math.exp(sumOfLogs / scores.length);
      merged[name] = score;
      total += score;
    }

    // Remise à l'échelle. Moyenner aplatit la distribution : le premier
    // candidat perd de la confiance alors même que le classement s'améliore,
    // et il passe sous le seuil de [FallbackPolicy] — l'app irait consulter
    // Pl@ntNet pour une réponse devenue *meilleure*.
    //
    // La cible est la masse que les listes d'entrée couvraient en moyenne,
    // et non 1. Ramener à 1 fabriquerait de la confiance : deux photos qui
    // ne rendent qu'un seul candidat, à 0,30 puis 0,90, en sortiraient à
    // 1,00 — une certitude que personne n'a exprimée. Avec la masse
    // moyenne, elles en sortent à 0,60. La fusion redresse l'échelle, elle
    // n'invente rien. Multiplier par une constante ne change aucun ordre.
    final scale = total > 0 ? coveredMass / total : 1.0;
    return [
      for (final e in merged.entries)
        IdentificationCandidate(
          scientificName: e.key,
          commonName: commons[e.key],
          score: (e.value * scale).clamp(0.0, 1.0),
        ),
    ]..sort((a, b) => b.score.compareTo(a.score));
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
      parts.add(await _fileKey(f));
    }
    return parts.join(';');
  }

  /// Ce qui distingue une photo d'une autre : son chemin, sa taille et sa
  /// date. Un fichier réécrit au même endroit change donc de clé.
  Future<String> _fileKey(File f) async {
    final stat = await f.stat();
    return '${f.path}|${stat.size}|${stat.modified.millisecondsSinceEpoch}';
  }

  /// Le mois civil de l'appareil, clé du compteur distant.
  String _month() {
    final d = _now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}';
  }
}
