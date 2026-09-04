import '../models/care_task.dart';
import 'care_engine.dart';

/// Résumé structuré des soins d'un jour, destiné à une notification groupée.
///
/// Le texte final est construit côté présentation (localisé). Ici on ne
/// manipule que des noms de plantes et des clés de type.
class ReminderDigest {
  const ReminderDigest({required this.byType, required this.totalPlants});

  /// `typeKey` → noms de plantes (dédoublonnés, dans l'ordre d'échéance).
  final Map<String, List<String>> byType;
  final int totalPlants;

  bool get isEmpty => byType.isEmpty;
}

abstract final class ReminderPlanner {
  /// Construit le résumé des soins dus (aujourd'hui ou en retard) à [now].
  static ReminderDigest digest(Iterable<CareTask> tasks, DateTime now) {
    final byType = <String, List<String>>{};
    final plants = <String>{};
    final sorted = tasks.toList()
      ..sort((a, b) => (a.dueAt ?? now).compareTo(b.dueAt ?? now));
    for (final t in sorted) {
      final s = t.status(now);
      if (s != DueStatus.today && s != DueStatus.overdue) continue;
      final names = byType.putIfAbsent(t.typeKey, () => []);
      if (!names.contains(t.summary.plant.name)) names.add(t.summary.plant.name);
      plants.add(t.plantId);
    }
    return ReminderDigest(byType: byType, totalPlants: plants.length);
  }

  /// Prochaine occurrence de [hour]:[minute] après [now], en évitant [quietWeekdays]
  /// (1 = lundi … 7 = dimanche).
  static DateTime nextFireTime(DateTime now, {required int hour, required int minute, Set<int> quietWeekdays = const {}}) {
    var candidate = DateTime(now.year, now.month, now.day, hour, minute);
    if (!candidate.isAfter(now)) candidate = candidate.add(const Duration(days: 1));
    var guard = 0;
    while (quietWeekdays.contains(candidate.weekday) && guard++ < 7) {
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate;
  }
}
