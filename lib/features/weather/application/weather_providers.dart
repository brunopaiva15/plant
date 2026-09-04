import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../domain/weather/weather.dart';
import '../../../domain/weather/weather_advisor.dart';
import '../../plants/application/plant_providers.dart';

/// Météo du jour pour le lieu configuré ; `null` sans lieu. Rafraîchie toutes les heures.
final todayWeatherProvider = FutureProvider<DailyWeather?>((ref) async {
  final place = ref.watch(preferencesProvider.select((p) => p.weatherPlace));
  if (place == null) return null;
  final timer = Future<void>.delayed(const Duration(hours: 1), () => ref.invalidateSelf());
  ref.onDispose(() => timer.ignore());
  try {
    return await ref.watch(weatherServiceProvider).today(place);
  } catch (_) {
    // Hors ligne : pas de météo, l'app reste entièrement utilisable.
    return null;
  }
});

/// Prévisions sur cinq jours, rafraîchies toutes les heures comme le jour même.
final forecastProvider = FutureProvider.autoDispose<List<DailyWeather>>((ref) async {
  final place = ref.watch(preferencesProvider.select((p) => p.weatherPlace));
  if (place == null) return const [];
  return ref.watch(weatherServiceProvider).forecast(place);
});

/// Emplacements marqués « extérieur » (id).
final outdoorLocationIdsProvider = Provider<Set<String>>((ref) {
  final locations = ref.watch(locationsProvider).value ?? const [];
  return {for (final l in locations) if (l.isOutdoor) l.id};
});

/// Conseil du jour (pluie → pas d'arrosage dehors), `null` si rien à dire.
final weatherAdviceProvider = Provider<WeatherAdvice?>((ref) {
  final weather = ref.watch(todayWeatherProvider).value;
  if (weather == null) return null;
  final outdoor = ref.watch(outdoorLocationIdsProvider);
  if (outdoor.isEmpty) return null;
  final now = DateTime.now();
  final tasks = (ref.watch(careTasksProvider).value ?? const []).where((t) => !t.dueAt!.isAfter(DateTime(now.year, now.month, now.day, 23, 59, 59))).toList();
  final advice = WeatherAdvisor.advise(weather: weather, dueTasks: tasks, outdoorLocationIds: outdoor);
  return advice.isEmpty ? null : advice;
});

/// Conseil masqué pour la journée (après « Reporter » ou fermeture).
class DismissedAdviceController extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;
  void dismissToday() => state = DateTime.now();
  bool get isDismissedToday => state != null && state!.day == DateTime.now().day && state!.month == DateTime.now().month;
}

final dismissedAdviceProvider = NotifierProvider<DismissedAdviceController, DateTime?>(DismissedAdviceController.new);
