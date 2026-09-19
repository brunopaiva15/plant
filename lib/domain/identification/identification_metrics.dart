import 'dart:convert';

/// Compteurs de la cascade d'identification, tenus sur l'appareil.
///
/// Aucune image, aucun nom d'espèce, aucun horodatage individuel : des
/// totaux, qui servent à régler le seuil de repli et à mesurer ce que le
/// modèle local économise en appels distants.
class IdentificationMetrics {
  const IdentificationMetrics({
    this.total = 0,
    this.local = 0,
    this.localAccepted = 0,
    this.remote = 0,
    this.fallbacks = 0,
    this.cacheHits = 0,
    this.errors = 0,
    this.quotaRefusals = 0,
    this.confidenceSum = 0,
    this.remotePeriod = '',
    this.remoteInPeriod = 0,
    this.jevConsulted = 0,
    this.jevIncidents = 0,
    this.jevShowResult = 0,
    this.jevAskAnotherPhoto = 0,
    this.jevKeepUncertain = 0,
    this.jevShowResultThenSearched = 0,
    this.jevKeepUncertainThenPicked = 0,
    this.jevLatencyMsSum = 0,
  });

  /// Identifications demandées (hors cache).
  final int total;

  /// Passages par le modèle local.
  final int local;

  /// Réponses locales acceptées sans repli.
  final int localAccepted;

  /// Appels au service distant, toutes raisons confondues.
  final int remote;

  /// Appels distants déclenchés après une tentative locale sans candidat exploitable.
  final int fallbacks;
  final int cacheHits;
  final int errors;

  /// Appels distants refusés parce que le quota du jour était atteint.
  final int quotaRefusals;

  /// Somme des meilleurs scores rendus, pour la moyenne.
  final double confidenceSum;

  /// Mois civil (AAAA-MM) du compteur [remoteInPeriod].
  final String remotePeriod;
  final int remoteInPeriod;

  /// Arbitrages Jev réellement partis sur le réseau. Un scan qu'Iris juge
  /// net, un appareil hors ligne ou une clé absente n'en produisent aucun.
  final int jevConsulted;

  /// Appels partis sans rien rendre : erreur, délai dépassé, réponse
  /// illisible. Auxine est alors retombée sur la politique Iris locale.
  final int jevIncidents;

  /// Les trois décisions rendues, dans leur proportion.
  final int jevShowResult;
  final int jevAskAnotherPhoto;
  final int jevKeepUncertain;

  /// Jev a dit « montre le résultat », et la personne est quand même allée
  /// chercher en ligne. C'est le signe d'un résultat présenté comme
  /// exploitable sans l'être.
  final int jevShowResultThenSearched;

  /// Jev a refusé de conclure, et la personne a quand même retenu une
  /// candidate. C'est le signe d'une prudence qui lui a coûté un geste.
  final int jevKeepUncertainThenPicked;

  /// Somme des durées d'appel, en millisecondes, pour la moyenne.
  final int jevLatencyMsSum;

  /// Arbitrages effectivement rendus, incidents exclus.
  int get jevAnswered => jevShowResult + jevAskAnotherPhoto + jevKeepUncertain;

  double get jevAverageLatencyMs => jevConsulted == 0 ? 0 : jevLatencyMsSum / jevConsulted;

  /// Part des résultats montrés que la personne n'a pas jugés suffisants.
  double get jevShowResultDoubtRate =>
      jevShowResult == 0 ? 0 : jevShowResultThenSearched / jevShowResult;

  /// Part des incertitudes que la personne a tranchées elle-même.
  double get jevKeepUncertainOverrideRate =>
      jevKeepUncertain == 0 ? 0 : jevKeepUncertainThenPicked / jevKeepUncertain;

  double get localSuccessRate => local == 0 ? 0 : localAccepted / local;
  double get fallbackRate => local == 0 ? 0 : fallbacks / local;
  double get averageConfidence => total == 0 ? 0 : confidenceSum / total;

  /// Appels distants évités grâce au modèle local et au cache.
  int get remoteCallsSaved => localAccepted + cacheHits;

  IdentificationMetrics copyWith({
    int? total,
    int? local,
    int? localAccepted,
    int? remote,
    int? fallbacks,
    int? cacheHits,
    int? errors,
    int? quotaRefusals,
    double? confidenceSum,
    String? remotePeriod,
    int? remoteInPeriod,
    int? jevConsulted,
    int? jevIncidents,
    int? jevShowResult,
    int? jevAskAnotherPhoto,
    int? jevKeepUncertain,
    int? jevShowResultThenSearched,
    int? jevKeepUncertainThenPicked,
    int? jevLatencyMsSum,
  }) =>
      IdentificationMetrics(
        total: total ?? this.total,
        local: local ?? this.local,
        localAccepted: localAccepted ?? this.localAccepted,
        remote: remote ?? this.remote,
        fallbacks: fallbacks ?? this.fallbacks,
        cacheHits: cacheHits ?? this.cacheHits,
        errors: errors ?? this.errors,
        quotaRefusals: quotaRefusals ?? this.quotaRefusals,
        confidenceSum: confidenceSum ?? this.confidenceSum,
        remotePeriod: remotePeriod ?? this.remotePeriod,
        remoteInPeriod: remoteInPeriod ?? this.remoteInPeriod,
        jevConsulted: jevConsulted ?? this.jevConsulted,
        jevIncidents: jevIncidents ?? this.jevIncidents,
        jevShowResult: jevShowResult ?? this.jevShowResult,
        jevAskAnotherPhoto: jevAskAnotherPhoto ?? this.jevAskAnotherPhoto,
        jevKeepUncertain: jevKeepUncertain ?? this.jevKeepUncertain,
        jevShowResultThenSearched:
            jevShowResultThenSearched ?? this.jevShowResultThenSearched,
        jevKeepUncertainThenPicked:
            jevKeepUncertainThenPicked ?? this.jevKeepUncertainThenPicked,
        jevLatencyMsSum: jevLatencyMsSum ?? this.jevLatencyMsSum,
      );

  Map<String, Object> toJson() => {
        'total': total,
        'local': local,
        'localAccepted': localAccepted,
        'remote': remote,
        'fallbacks': fallbacks,
        'cacheHits': cacheHits,
        'errors': errors,
        'quotaRefusals': quotaRefusals,
        'confidenceSum': confidenceSum,
        'remotePeriod': remotePeriod,
        'remoteInPeriod': remoteInPeriod,
        'jevConsulted': jevConsulted,
        'jevIncidents': jevIncidents,
        'jevShowResult': jevShowResult,
        'jevAskAnotherPhoto': jevAskAnotherPhoto,
        'jevKeepUncertain': jevKeepUncertain,
        'jevShowResultThenSearched': jevShowResultThenSearched,
        'jevKeepUncertainThenPicked': jevKeepUncertainThenPicked,
        'jevLatencyMsSum': jevLatencyMsSum,
      };

  static IdentificationMetrics fromJson(Map<String, dynamic> json) {
    int i(String k) => (json[k] as num?)?.toInt() ?? 0;
    return IdentificationMetrics(
      total: i('total'),
      local: i('local'),
      localAccepted: i('localAccepted'),
      remote: i('remote'),
      fallbacks: i('fallbacks'),
      cacheHits: i('cacheHits'),
      errors: i('errors'),
      quotaRefusals: i('quotaRefusals'),
      confidenceSum: (json['confidenceSum'] as num?)?.toDouble() ?? 0,
      remotePeriod: (json['remotePeriod'] as String?) ?? '',
      remoteInPeriod: i('remoteInPeriod'),
      jevConsulted: i('jevConsulted'),
      jevIncidents: i('jevIncidents'),
      jevShowResult: i('jevShowResult'),
      jevAskAnotherPhoto: i('jevAskAnotherPhoto'),
      jevKeepUncertain: i('jevKeepUncertain'),
      jevShowResultThenSearched: i('jevShowResultThenSearched'),
      jevKeepUncertainThenPicked: i('jevKeepUncertainThenPicked'),
      jevLatencyMsSum: i('jevLatencyMsSum'),
    );
  }

  String encode() => jsonEncode(toJson());

  static IdentificationMetrics decode(String? raw) {
    if (raw == null || raw.isEmpty) return const IdentificationMetrics();
    try {
      return fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      return const IdentificationMetrics();
    }
  }
}

/// Où les compteurs vivent. En mémoire pour les tests, dans les réglages
/// sur l'appareil.
abstract class IdentificationMetricsStore {
  IdentificationMetrics read();
  Future<void> write(IdentificationMetrics metrics);
}

class InMemoryMetricsStore implements IdentificationMetricsStore {
  InMemoryMetricsStore([this._value = const IdentificationMetrics()]);

  IdentificationMetrics _value;

  @override
  IdentificationMetrics read() => _value;

  @override
  Future<void> write(IdentificationMetrics metrics) async => _value = metrics;
}
