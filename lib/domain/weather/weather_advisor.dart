import '../models/models.dart';
import 'weather.dart';

/// Conseil météo du jour : uniquement pour les arrosages de plantes situées dehors.
class WeatherAdvice {
  const WeatherAdvice({required this.skipWateringTasks, required this.locationNames});

  /// Tâches d'arrosage extérieures que la pluie rend inutiles aujourd'hui.
  final List<CareTask> skipWateringTasks;
  final List<String> locationNames;

  bool get isEmpty => skipWateringTasks.isEmpty;
}

abstract final class WeatherAdvisor {
  static WeatherAdvice advise({required DailyWeather weather, required List<CareTask> dueTasks, required Set<String> outdoorLocationIds}) {
    if (!weather.rainExpected) return const WeatherAdvice(skipWateringTasks: [], locationNames: []);
    final tasks = dueTasks.where((t) => t.typeKey == CareKind.watering.key && outdoorLocationIds.contains(t.summary.plant.locationId)).toList();
    final names = <String>[];
    for (final t in tasks) {
      final n = t.summary.locationName;
      if (n != null && !names.contains(n)) names.add(n);
    }
    return WeatherAdvice(skipWateringTasks: tasks, locationNames: names);
  }
}
