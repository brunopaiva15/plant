import '../../core/utils/dates.dart';
import '../models/models.dart';
import 'care_engine.dart';

/// Projette les routines et l'historique sur une plage de dates.
///
/// - Les actions passées deviennent des événements `past`.
/// - La prochaine échéance de chaque routine est `due`.
/// - Les occurrences suivantes sont `projected` en répétant l'intervalle
///   effectif (saisonnier inclus) jusqu'à la fin de la plage.
abstract final class CalendarProjector {
  static List<CalendarEvent> project({
    required List<CareSchedule> schedules,
    required List<PlantAction> actions,
    required Map<String, PlantSummary> plants,
    required DateTime from,
    required DateTime to,
    List<CalendarEntry> entries = const [],
    int maxPerSchedule = 60,
  }) {
    final events = <CalendarEvent>[];
    final start = from.dateOnly;
    final end = to.dateOnly;

    for (final a in actions) {
      final p = plants[a.plantId];
      if (p == null) continue;
      final d = a.occurredAt.dateOnly;
      if (d.isBefore(start) || d.isAfter(end)) continue;
      events.add(CalendarEvent(date: a.occurredAt, plantId: a.plantId, plantName: p.plant.name, thumbPath: p.thumbPath, typeKey: a.typeKey, kind: CalendarEventKind.past, actionId: a.id));
    }

    for (final s in schedules) {
      final p = plants[s.plantId];
      if (p == null || !s.enabled || s.nextDueAt == null || s.strategy == CareStrategy.manual) continue;
      var occurrence = s.nextDueAt!.dateOnly;
      var kind = CalendarEventKind.due;
      var guard = 0;
      while (!occurrence.isAfter(end) && guard++ < maxPerSchedule) {
        if (!occurrence.isBefore(start)) {
          events.add(CalendarEvent(date: occurrence, plantId: s.plantId, plantName: p.plant.name, thumbPath: p.thumbPath, typeKey: s.typeKey, kind: kind, scheduleId: s.id));
        }
        final interval = CareEngine.effectiveInterval(s, occurrence);
        occurrence = occurrence.addDays(interval);
        kind = CalendarEventKind.projected;
      }
    }

    for (final e in entries) {
      // Un événement de plusieurs jours apparaît chaque jour qu'il couvre,
      // dans la plage seulement.
      for (final day in e.daysCovered()) {
        if (day.isBefore(start) || day.isAfter(end)) continue;
        final p = e.plantId == null ? null : plants[e.plantId];
        events.add(CalendarEvent(
          // Le premier jour garde l'heure saisie ; les suivants commencent
          // au matin, pour rester en tête de journée.
          date: e.allDay || day.isAfter(e.firstDay) ? day : e.startAt,
          plantId: p?.plant.id,
          plantName: p?.plant.name,
          thumbPath: p?.thumbPath,
          title: e.title,
          typeKey: 'event',
          kind: CalendarEventKind.custom,
          entryId: e.id,
          categoryId: e.categoryId,
          allDay: e.allDay,
        ));
      }
    }

    events.sort((a, b) => a.date.compareTo(b.date));
    return events;
  }

  /// Regroupe par jour (minuit local), dans l'ordre chronologique.
  static Map<DateTime, List<CalendarEvent>> byDay(List<CalendarEvent> events) {
    final map = <DateTime, List<CalendarEvent>>{};
    for (final e in events) {
      map.putIfAbsent(e.date.dateOnly, () => []).add(e);
    }
    return map;
  }
}
