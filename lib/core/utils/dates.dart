/// Helpers de dates purs (sans dépendance Flutter) pour rester testables.
extension DateOnly on DateTime {
  /// Minuit local du même jour.
  DateTime get dateOnly => DateTime(year, month, day);

  /// Nombre de jours civils entre `this` et [other] (positif si [other] est après).
  int daysUntil(DateTime other) => other.dateOnly.difference(dateOnly).inDays;

  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  DateTime addDays(int days) => DateTime(year, month, day + days, hour, minute);
}
