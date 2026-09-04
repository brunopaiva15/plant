enum CalendarEventKind {
  /// Action déjà enregistrée dans l'historique.
  past,

  /// Échéance connue d'une routine (prochaine occurrence).
  due,

  /// Occurrence projetée à partir de l'intervalle de la routine.
  projected,
}

class CalendarEvent {
  const CalendarEvent({
    required this.date,
    required this.plantId,
    required this.plantName,
    required this.typeKey,
    required this.kind,
    this.thumbPath,
    this.scheduleId,
    this.actionId,
  });

  final DateTime date;
  final String plantId;
  final String plantName;
  final String? thumbPath;
  final String typeKey;
  final CalendarEventKind kind;
  final String? scheduleId;
  final String? actionId;
}
