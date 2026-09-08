import '../../core/utils/dates.dart';
import '../models/care_schedule.dart';
import 'season.dart';

/// État d'une échéance par rapport à « maintenant ».
enum DueStatus { none, overdue, today, upcoming }

/// Moteur de calcul des échéances. Pur, sans dépendance, testé unitairement.
abstract final class CareEngine {
  /// Multiplicateurs saisonniers par défaut (arrosage plus espacé en hiver).
  static const Map<String, double> defaultSeasonalRules = {
    'winter': 1.5,
    'autumn': 1.2,
    'spring': 1.0,
    'summer': 0.8,
  };

  /// Intervalle effectif (en jours) de [schedule] à la date [at].
  ///
  /// [south] dit que le jardin est dans l'hémisphère sud, où décembre est un
  /// mois de croissance et juillet un mois de repos. Sans lui, une plante de
  /// Melbourne serait arrosée au rythme de l'hiver en plein été.
  static int effectiveInterval(CareSchedule schedule, DateTime at, {bool south = false}) {
    switch (schedule.strategy) {
      case CareStrategy.fixed:
      case CareStrategy.manual:
        return schedule.intervalDays;
      case CareStrategy.seasonal:
        final rules = schedule.seasonalRules ?? defaultSeasonalRules;
        final factor = rules[Season.of(at, southernHemisphere: south).name] ?? 1.0;
        return (schedule.intervalDays * factor).round().clamp(1, 3650);
    }
  }

  /// Prochaine échéance après une complétion à [completedAt].
  /// `null` pour la stratégie manuelle (jamais de rappel).
  static DateTime? nextDueAfter(CareSchedule schedule, DateTime completedAt, {bool south = false}) {
    if (schedule.strategy == CareStrategy.manual || !schedule.enabled) return null;
    final interval = effectiveInterval(schedule, completedAt, south: south);
    return completedAt.dateOnly.addDays(interval);
  }

  /// Échéance initiale d'une routine nouvellement créée (sans historique).
  static DateTime? initialDue(CareSchedule schedule, DateTime now, {bool south = false}) =>
      nextDueAfter(schedule, now, south: south);

  /// Applique une complétion et retourne la routine mise à jour.
  static CareSchedule complete(CareSchedule schedule, DateTime completedAt, {bool south = false}) =>
      schedule.copyWith(
        lastCompletedAt: () => completedAt,
        nextDueAt: () => nextDueAfter(schedule, completedAt, south: south),
        updatedAt: completedAt,
      );

  /// Reporte l'échéance de [days] jours à partir d'aujourd'hui (« Plus tard »).
  static CareSchedule snooze(CareSchedule schedule, DateTime now, {int days = 1}) =>
      schedule.copyWith(nextDueAt: () => now.dateOnly.addDays(days), updatedAt: now);

  static DueStatus status(DateTime? dueAt, DateTime now) {
    if (dueAt == null) return DueStatus.none;
    final days = now.daysUntil(dueAt);
    if (days < 0) return DueStatus.overdue;
    if (days == 0) return DueStatus.today;
    return DueStatus.upcoming;
  }

  /// Jours restants (négatif si en retard), `null` si aucune échéance.
  static int? daysUntil(DateTime? dueAt, DateTime now) =>
      dueAt == null ? null : now.daysUntil(dueAt);
}
