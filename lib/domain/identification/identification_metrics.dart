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
    this.remoteDay = '',
    this.remoteToday = 0,
  });

  /// Identifications demandées (hors cache).
  final int total;

  /// Passages par le modèle local.
  final int local;

  /// Réponses locales acceptées sans repli.
  final int localAccepted;

  /// Appels au service distant, toutes raisons confondues.
  final int remote;

  /// Appels distants déclenchés *après* une réponse locale incertaine.
  final int fallbacks;
  final int cacheHits;
  final int errors;

  /// Appels distants refusés parce que le quota du jour était atteint.
  final int quotaRefusals;

  /// Somme des meilleurs scores rendus, pour la moyenne.
  final double confidenceSum;

  /// Jour (AAAA-MM-JJ) du compteur [remoteToday].
  final String remoteDay;
  final int remoteToday;

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
    String? remoteDay,
    int? remoteToday,
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
        remoteDay: remoteDay ?? this.remoteDay,
        remoteToday: remoteToday ?? this.remoteToday,
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
        'remoteDay': remoteDay,
        'remoteToday': remoteToday,
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
      remoteDay: (json['remoteDay'] as String?) ?? '',
      remoteToday: i('remoteToday'),
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
