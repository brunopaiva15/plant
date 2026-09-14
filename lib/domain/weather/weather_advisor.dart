import '../models/models.dart';
import 'weather.dart';

/// Ce que la pluie fait aux arrosages du jour.
enum RainAdviceKind {
  /// Elle est tombée : ce qui est dehors a reçu son eau.
  fallen,

  /// Elle est annoncée : l'arrosage peut attendre demain.
  expected,
}

/// Conseil météo du jour : uniquement pour les arrosages de plantes situées
/// dehors.
class WeatherAdvice {
  const WeatherAdvice({required this.kind, required this.tasks, required this.locationNames, required this.rainMm});

  static const empty = WeatherAdvice(kind: RainAdviceKind.expected, tasks: [], locationNames: [], rainMm: 0);

  final RainAdviceKind kind;

  /// Les arrosages extérieurs que la pluie rend inutiles aujourd'hui.
  final List<CareTask> tasks;
  final List<String> locationNames;

  /// Les millimètres qui motivent le conseil : tombés, ou attendus.
  final double rainMm;

  bool get isEmpty => tasks.isEmpty;
}

abstract final class WeatherAdvisor {
  /// Ce qu'il faut de pluie pour valoir un arrosage. Trois millimètres
  /// mouillent la surface et s'évaporent ; cinq traversent, et c'est le
  /// seuil qu'on retient. Un pot serré sous un feuillage en reçoit moins —
  /// le réglage se coupe dans Profil › Météo pour qui arrose à la main.
  static const double wateredMm = 5;

  static WeatherAdvice advise({
    required DailyWeather weather,
    required List<CareTask> dueTasks,
    required Set<String> outdoorLocationIds,
    double rainFallenMm = 0,
  }) {
    final fallen = rainFallenMm >= wateredMm;
    if (!fallen && !weather.rainExpected) return WeatherAdvice.empty;
    final tasks = dueTasks.where((t) => t.typeKey == CareKind.watering.key && outdoorLocationIds.contains(t.summary.plant.locationId)).toList();
    final names = <String>[];
    for (final t in tasks) {
      final n = t.summary.locationName;
      if (n != null && !names.contains(n)) names.add(n);
    }
    return WeatherAdvice(
      // La pluie tombée l'emporte sur celle qu'on annonce : reporter un
      // arrosage que la pluie a déjà fait n'aurait plus de sens.
      kind: fallen ? RainAdviceKind.fallen : RainAdviceKind.expected,
      tasks: tasks,
      locationNames: names,
      rainMm: fallen ? rainFallenMm : weather.precipitationMm,
    );
  }

  /// La pluie déjà tombée sur la fenêtre passée, aujourd'hui compris : c'est
  /// elle qui vaut un arrosage, pas celle qu'on annonce.
  static double rainFallen(Iterable<DailyWeather> window, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return window
        .where((d) => !DateTime(d.date.year, d.date.month, d.date.day).isAfter(today))
        .fold(0.0, (sum, d) => sum + d.precipitationMm);
  }
}
