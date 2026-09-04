import '../../core/utils/dates.dart';

/// Unité de récurrence d'une tâche libre.
enum RecurrenceUnit {
  hours('hours'),
  days('days'),
  weeks('weeks'),
  months('months'),
  years('years');

  const RecurrenceUnit(this.key);

  final String key;

  static RecurrenceUnit? fromKey(String? key) => key == null ? null : values.where((u) => u.key == key).firstOrNull;
}

/// « Toutes les 2 semaines ».
class TaskRecurrence {
  const TaskRecurrence({required this.value, required this.unit});

  final int value;
  final RecurrenceUnit unit;

  /// Occurrence suivante à partir de [from] (mois et années conservent le
  /// jour du mois, bornés au dernier jour du mois cible).
  DateTime next(DateTime from) => switch (unit) {
        RecurrenceUnit.hours => from.add(Duration(hours: value)),
        RecurrenceUnit.days => from.add(Duration(days: value)),
        RecurrenceUnit.weeks => from.add(Duration(days: 7 * value)),
        RecurrenceUnit.months => _addMonths(from, value),
        RecurrenceUnit.years => _addMonths(from, 12 * value),
      };

  /// Première occurrence strictement postérieure à [now], en partant de [from].
  DateTime nextAfter(DateTime from, DateTime now) {
    var candidate = next(from);
    var guard = 0;
    while (!candidate.isAfter(now) && guard++ < 10000) {
      candidate = next(candidate);
    }
    return candidate;
  }

  static DateTime _addMonths(DateTime d, int months) {
    final totalMonths = d.year * 12 + (d.month - 1) + months;
    final year = totalMonths ~/ 12;
    final month = totalMonths % 12 + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, d.day > lastDay ? lastDay : d.day, d.hour, d.minute);
  }

  @override
  bool operator ==(Object other) => other is TaskRecurrence && other.value == value && other.unit == unit;

  @override
  int get hashCode => Object.hash(value, unit);
}

/// État d'une tâche par rapport à maintenant.
enum FreeTaskStatus { overdue, today, upcoming, noDate, done }

/// Tâche libre (« Nettoyer la serre », « Commander du terreau »), avec ou
/// sans plante liée, échéance facultative, récurrence facultative.
class FreeTask {
  const FreeTask({
    required this.id,
    required this.gardenId,
    required this.title,
    required this.allDay,
    required this.done,
    required this.createdAt,
    required this.updatedAt,
    this.plantId,
    this.description,
    this.dueAt,
    this.recurrence,
    this.doneAt,
  });

  final String id;
  final String gardenId;
  final String? plantId;
  final String title;
  final String? description;
  final DateTime? dueAt;

  /// Échéance à la journée (sans heure) : `true` par défaut.
  final bool allDay;
  final TaskRecurrence? recurrence;
  final bool done;

  /// Dernière complétion (tâche récurrente : la dernière occurrence faite).
  final DateTime? doneAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isRecurring => recurrence != null;

  FreeTaskStatus status(DateTime now) {
    if (done) return FreeTaskStatus.done;
    final due = dueAt;
    if (due == null) return FreeTaskStatus.noDate;
    if (allDay) {
      if (due.isSameDay(now)) return FreeTaskStatus.today;
      return due.isBefore(now) ? FreeTaskStatus.overdue : FreeTaskStatus.upcoming;
    }
    if (due.isBefore(now)) return FreeTaskStatus.overdue;
    return due.isSameDay(now) ? FreeTaskStatus.today : FreeTaskStatus.upcoming;
  }

  bool isOverdue(DateTime now) => status(now) == FreeTaskStatus.overdue;

  FreeTask copyWith({
    String? Function()? plantId,
    String? title,
    String? Function()? description,
    DateTime? Function()? dueAt,
    bool? allDay,
    TaskRecurrence? Function()? recurrence,
    bool? done,
    DateTime? Function()? doneAt,
    DateTime? updatedAt,
  }) =>
      FreeTask(
        id: id,
        gardenId: gardenId,
        plantId: plantId != null ? plantId() : this.plantId,
        title: title ?? this.title,
        description: description != null ? description() : this.description,
        dueAt: dueAt != null ? dueAt() : this.dueAt,
        allDay: allDay ?? this.allDay,
        recurrence: recurrence != null ? recurrence() : this.recurrence,
        done: done ?? this.done,
        doneAt: doneAt != null ? doneAt() : this.doneAt,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
