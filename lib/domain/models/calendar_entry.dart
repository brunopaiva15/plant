import '../../core/utils/dates.dart';

/// Catégorie d'événement propre au jardin : « Marché aux plantes », « Taille »…
class EventCategory {
  const EventCategory({
    required this.id,
    required this.gardenId,
    required this.label,
    required this.emoji,
    required this.position,
    required this.createdAt,
    required this.updatedAt,
    this.colorKey,
  });

  final String id;
  final String gardenId;
  final String label;
  final String emoji;
  final String? colorKey;
  final int position;
  final DateTime createdAt;
  final DateTime updatedAt;

  EventCategory copyWith({String? label, String? emoji, String? Function()? colorKey, int? position}) => EventCategory(
        id: id,
        gardenId: gardenId,
        label: label ?? this.label,
        emoji: emoji ?? this.emoji,
        colorKey: colorKey == null ? this.colorKey : colorKey(),
        position: position ?? this.position,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );
}

/// Événement saisi à la main, à côté des échéances de soin projetées.
class CalendarEntry {
  const CalendarEntry({
    required this.id,
    required this.gardenId,
    required this.title,
    required this.startAt,
    required this.allDay,
    required this.createdAt,
    required this.updatedAt,
    this.plantId,
    this.categoryId,
    this.notes,
    this.endAt,
    this.reminderMinutes,
  });

  final String id;
  final String gardenId;
  final String? plantId;
  final String? categoryId;
  final String title;
  final String? notes;
  final DateTime startAt;
  final DateTime? endAt;
  final bool allDay;
  final int? reminderMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Dernier jour couvert : la fin quand elle existe, sinon le jour de début.
  DateTime get lastDay => (endAt ?? startAt).dateOnly;

  DateTime get firstDay => startAt.dateOnly;

  bool get isMultiDay => lastDay.isAfter(firstDay);

  /// Tous les jours couverts, bornés à [maxDays] pour ne jamais boucler sur
  /// une saisie absurde (« du 1er janvier à l'an 3000 »).
  List<DateTime> daysCovered({int maxDays = 366}) {
    final days = <DateTime>[];
    var day = firstDay;
    final end = lastDay;
    while (!day.isAfter(end) && days.length < maxDays) {
      days.add(day);
      day = day.addDays(1);
    }
    return days;
  }

  /// Instant du rappel, ou `null` si l'événement n'en a pas.
  DateTime? get remindAt => reminderMinutes == null ? null : startAt.subtract(Duration(minutes: reminderMinutes!));

  CalendarEntry copyWith({
    String? title,
    String? Function()? notes,
    String? Function()? plantId,
    String? Function()? categoryId,
    DateTime? startAt,
    DateTime? Function()? endAt,
    bool? allDay,
    int? Function()? reminderMinutes,
  }) =>
      CalendarEntry(
        id: id,
        gardenId: gardenId,
        plantId: plantId == null ? this.plantId : plantId(),
        categoryId: categoryId == null ? this.categoryId : categoryId(),
        title: title ?? this.title,
        notes: notes == null ? this.notes : notes(),
        startAt: startAt ?? this.startAt,
        endAt: endAt == null ? this.endAt : endAt(),
        allDay: allDay ?? this.allDay,
        reminderMinutes: reminderMinutes == null ? this.reminderMinutes : reminderMinutes(),
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );
}
