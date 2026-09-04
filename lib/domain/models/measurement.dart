enum MeasurementKind {
  height('height'),
  width('width'),
  leaves('leaves'),
  pot('pot');

  const MeasurementKind(this.key);

  final String key;

  /// Les feuilles se comptent ; le reste se mesure en longueur.
  bool get isCount => this == MeasurementKind.leaves;

  static MeasurementKind fromKey(String key) => values.firstWhere((k) => k.key == key, orElse: () => MeasurementKind.height);
}

class Measurement {
  const Measurement({
    required this.id,
    required this.plantId,
    required this.kind,
    required this.value,
    required this.unit,
    required this.measuredAt,
    this.actionId,
  });

  final String id;
  final String plantId;
  final String? actionId;
  final MeasurementKind kind;
  final double value;
  final String unit;
  final DateTime measuredAt;
}

/// Résumé d'une série de mesures : dernière valeur et variation depuis la première.
class MeasurementSeries {
  const MeasurementSeries({required this.kind, required this.points});

  final MeasurementKind kind;

  /// Chronologique (plus ancienne en premier).
  final List<Measurement> points;

  Measurement get latest => points.last;
  Measurement get first => points.first;
  double get delta => latest.value - first.value;
  bool get hasTrend => points.length > 1;
}
