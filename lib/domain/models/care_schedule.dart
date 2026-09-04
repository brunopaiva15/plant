/// Stratégie de planification d'une routine.
enum CareStrategy {
  /// Intervalle fixe en jours.
  fixed,

  /// Intervalle ajusté par saison (plus long en hiver, plus court en été).
  seasonal,

  /// Pas d'échéance automatique : l'utilisateur agit quand il veut.
  manual,
}

/// Une routine d'entretien. Strictement séparée des actions historiques.
class CareSchedule {
  const CareSchedule({
    required this.id,
    required this.plantId,
    required this.typeKey,
    required this.strategy,
    required this.intervalDays,
    required this.enabled,
    required this.createdAt,
    required this.updatedAt,
    this.nextDueAt,
    this.lastCompletedAt,
    this.seasonalRules,
  });

  final String id;
  final String plantId;
  final String typeKey;
  final CareStrategy strategy;
  final int intervalDays;

  /// Multiplicateurs par saison (`winter`, `spring`, `summer`, `autumn`).
  final Map<String, double>? seasonalRules;
  final DateTime? nextDueAt;
  final DateTime? lastCompletedAt;
  final bool enabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  CareSchedule copyWith({
    CareStrategy? strategy,
    int? intervalDays,
    Map<String, double>? Function()? seasonalRules,
    DateTime? Function()? nextDueAt,
    DateTime? Function()? lastCompletedAt,
    bool? enabled,
    DateTime? updatedAt,
  }) =>
      CareSchedule(
        id: id,
        plantId: plantId,
        typeKey: typeKey,
        strategy: strategy ?? this.strategy,
        intervalDays: intervalDays ?? this.intervalDays,
        seasonalRules: seasonalRules != null ? seasonalRules() : this.seasonalRules,
        nextDueAt: nextDueAt != null ? nextDueAt() : this.nextDueAt,
        lastCompletedAt: lastCompletedAt != null ? lastCompletedAt() : this.lastCompletedAt,
        enabled: enabled ?? this.enabled,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
