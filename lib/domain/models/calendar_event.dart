enum CalendarEventKind {
  /// Action déjà enregistrée dans l'historique.
  past,

  /// Échéance connue d'une routine (prochaine occurrence).
  due,

  /// Occurrence projetée à partir de l'intervalle de la routine.
  projected,

  /// Événement saisi à la main dans le calendrier.
  custom,
}

class CalendarEvent {
  const CalendarEvent({
    required this.date,
    required this.typeKey,
    required this.kind,
    this.plantId,
    this.plantName,
    this.thumbPath,
    this.title,
    this.scheduleId,
    this.actionId,
    this.entryId,
    this.categoryId,
    this.allDay = true,
  });

  final DateTime date;

  /// Plante concernée : toujours renseignée pour un soin, facultative pour
  /// un événement saisi à la main.
  final String? plantId;
  final String? plantName;
  final String? thumbPath;

  /// Titre d'un événement saisi à la main.
  final String? title;
  final String typeKey;
  final CalendarEventKind kind;
  final String? scheduleId;
  final String? actionId;
  final String? entryId;
  final String? categoryId;
  final bool allDay;
}
