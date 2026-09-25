/// Combien de temps une analyse a duré, et combien il lui en reste.
///
/// Sans repère, une attente d'une minute ressemble à une panne : la personne
/// ne sait pas si l'écran travaille ou s'il est figé, et elle le ferme. Le
/// repère vient des diagnostics déjà aboutis sur cet appareil, parce que la
/// durée dépend du modèle choisi par le relais — une douzaine de secondes
/// pour l'un, plus d'une minute pour l'autre.
abstract final class AnalysisEta {
  /// L'attente annoncée avant tout diagnostic abouti.
  static const initial = Duration(seconds: 45);

  /// Ce qu'on attend de la prochaine analyse.
  static Duration expected(int? storedSeconds) =>
      storedSeconds == null || storedSeconds <= 0 ? initial : Duration(seconds: storedSeconds);

  /// La durée gardée après une analyse aboutie : la moyenne de l'habitude
  /// et de la nouvelle mesure. Un essai isolé ne fait pas basculer
  /// l'annonce, et un changement de modèle s'y lit en trois analyses — de
  /// 80 s à 21 s quand le relais passe à un modèle qui répond en 12 s.
  static int blend(int? storedSeconds, Duration took) {
    final measured = took.inMilliseconds / 1000;
    if (storedSeconds == null || storedSeconds <= 0) return measured.round().clamp(1, 600);
    return ((storedSeconds + measured) / 2).round().clamp(1, 600);
  }

  /// Le temps restant tel qu'il s'annonce, `null` une fois l'attente
  /// dépassée. Arrondi aux cinq secondes supérieures au-delà de dix : un
  /// décompte à la seconde promettrait une précision que personne n'a.
  static Duration? remaining(Duration expected, Duration elapsed) {
    final left = expected - elapsed;
    if (left <= Duration.zero) return null;
    final seconds = left.inMilliseconds / 1000;
    if (seconds <= 10) return Duration(seconds: seconds.ceil());
    return Duration(seconds: (seconds / 5).ceil() * 5);
  }

  /// « 40 s », « 1 min », « 1 min 25 s » : les mêmes unités dans les quatre
  /// langues de l'application.
  static String format(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (minutes == 0) return '$seconds s';
    if (seconds == 0) return '$minutes min';
    return '$minutes min $seconds s';
  }
}
