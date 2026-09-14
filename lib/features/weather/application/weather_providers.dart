import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/l10n/l10n.dart';
import '../../../domain/repositories/repositories.dart';
import '../../../domain/weather/outdoor_alert.dart';
import '../../../domain/weather/region_climate.dart';
import '../../../domain/weather/weather.dart';
import '../../../domain/weather/weather_advisor.dart';
import '../../account/application/membership_providers.dart';
import '../../actions/application/care_actions.dart';
import '../../plants/application/plant_providers.dart';

/// Météo du jour pour le lieu configuré ; `null` sans lieu, et hors ligne.
///
/// Tirée de la fenêtre commune : la ligne datée d'aujourd'hui, à défaut la
/// première à venir — un fuseau qui bascule ne doit pas vider l'écran.
final todayWeatherProvider = Provider<DailyWeather?>((ref) {
  final window = ref.watch(weatherWindowProvider).value ?? const [];
  if (window.isEmpty) return null;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  for (final day in window) {
    if (!DateTime(day.date.year, day.date.month, day.date.day).isBefore(today)) return day;
  }
  return null;
});

/// Prévisions à partir d'aujourd'hui : la même fenêtre, sans les jours
/// passés, qui n'ont plus rien à prévoir. Garde l'attente et l'erreur de la
/// fenêtre — l'écran des prévisions montre l'une et l'autre.
final forecastProvider = Provider<AsyncValue<List<DailyWeather>>>((ref) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return ref.watch(weatherWindowProvider).whenData((window) => [
        for (final day in window)
          if (!DateTime(day.date.year, day.date.month, day.date.day).isBefore(today)) day,
      ]);
});

/// Les jours à venir, sans l'état de chargement : ce que lisent les
/// avertissements, qui n'ont rien à afficher tant qu'il n'y a rien.
final forecastDaysProvider = Provider<List<DailyWeather>>((ref) => ref.watch(forecastProvider).value ?? const []);

/// La pluie déjà tombée sur les trois derniers jours, aujourd'hui compris.
final rainFallenProvider = Provider<double>(
    (ref) => WeatherAdvisor.rainFallen(ref.watch(weatherWindowProvider).value ?? const [], DateTime.now()));

/// Emplacements marqués « extérieur » (id).
final outdoorLocationIdsProvider = Provider<Set<String>>((ref) {
  final locations = ref.watch(locationsProvider).value ?? const [];
  return {for (final l in locations) if (l.isOutdoor) l.id};
});

/// Les plantes qui vivent dehors, avec la fiche de leur espèce : ce sont
/// elles que le gel et la canicule concernent.
final outdoorPlantsProvider = Provider<List<OutdoorPlant>>((ref) {
  final outdoor = ref.watch(outdoorLocationIdsProvider);
  if (outdoor.isEmpty) return const [];
  final plants = ref.watch(plantSummariesProvider(const PlantFilter())).value ?? const [];
  final guide = ref.watch(careGuideProvider);
  final family = speciesFamilyLookupIn(ref);
  return [
    for (final p in plants)
      if (outdoor.contains(p.plant.locationId))
        if (p.plant.speciesName case final species? when species.isNotEmpty)
          OutdoorPlant(name: p.plant.name, profile: guide.resolve(species, family: family(species)).profile),
  ];
});

/// Gel et chaleur des trois prochains jours, pour les plantes du dehors.
final outdoorAlertsProvider = Provider<List<OutdoorAlert>>((ref) => OutdoorAlertAdvisor.alerts(
      forecast: ref.watch(forecastDaysProvider),
      plants: ref.watch(outdoorPlantsProvider),
      now: DateTime.now(),
    ));

/// Conseil du jour (la pluie tombée vaut un arrosage, la pluie annoncée le
/// reporte), `null` si rien à dire.
final weatherAdviceProvider = Provider<WeatherAdvice?>((ref) {
  final weather = ref.watch(todayWeatherProvider);
  if (weather == null) return null;
  final outdoor = ref.watch(outdoorLocationIdsProvider);
  if (outdoor.isEmpty) return null;
  final now = DateTime.now();
  final tasks = (ref.watch(careTasksProvider).value ?? const []).where((t) => !t.dueAt!.isAfter(DateTime(now.year, now.month, now.day, 23, 59, 59))).toList();
  final advice = WeatherAdvisor.advise(
    weather: weather,
    dueTasks: tasks,
    outdoorLocationIds: outdoor,
    // Le réglage ne décide que de l'automatisme : coupé, la carte du matin
    // propose encore de noter l'arrosage d'un tap.
    rainFallenMm: ref.watch(rainFallenProvider),
  );
  return advice.isEmpty ? null : advice;
});

/// Le climat du lieu, mis de côté dans les préférences : un appel d'archives
/// sur trois ans est lent, et un climat ne bouge pas d'une saison.
///
/// Relu quand le lieu change — les préférences effacent alors le cache — et
/// au bout de [climateMaxAge], pour que l'année qui vient de s'écouler
/// finisse par compter.
const climateMaxAge = Duration(days: 180);

final regionClimateProvider = FutureProvider<RegionClimate?>((ref) async {
  final place = ref.watch(preferencesProvider.select((p) => p.weatherPlace));
  if (place == null) return null;
  final prefs = ref.watch(preferencesServiceProvider);
  final cached = prefs.regionClimate;
  if (cached != null && DateTime.now().difference(cached.at) < climateMaxAge) {
    return RegionClimate(winterLowC: cached.winterLow, summerHighC: cached.summerHigh, years: cached.years);
  }
  try {
    final climate = await ref.watch(weatherServiceProvider).climate(place);
    if (climate == null) return null;
    await prefs.setRegionClimate(
      lat: place.latitude,
      lon: place.longitude,
      winterLow: climate.winterLowC,
      summerHigh: climate.summerHighC,
      years: climate.years,
      at: DateTime.now(),
    );
    return climate;
  } catch (_) {
    // Hors ligne : le climat gardé fait l'affaire, même périmé. La région
    // d'il y a six mois est encore la bonne.
    if (cached == null) return null;
    return RegionClimate(winterLowC: cached.winterLow, summerHighC: cached.summerHigh, years: cached.years);
  }
});

/// Conseil masqué pour la journée (après « Reporter » ou fermeture).
class DismissedAdviceController extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;
  void dismissToday() => state = DateTime.now();
  bool get isDismissedToday {
    final s = state;
    if (s == null) return false;
    final now = DateTime.now();
    return s.year == now.year && s.month == now.month && s.day == now.day;
  }
}

final dismissedAdviceProvider = NotifierProvider<DismissedAdviceController, DateTime?>(DismissedAdviceController.new);

/// Avertissements masqués pour la journée.
class DismissedAlertsController extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;
  void dismissToday() => state = DateTime.now();
  bool get isDismissedToday {
    final s = state;
    if (s == null) return false;
    final now = DateTime.now();
    return s.year == now.year && s.month == now.month && s.day == now.day;
  }
}

final dismissedAlertsProvider = NotifierProvider<DismissedAlertsController, DateTime?>(DismissedAlertsController.new);

/// Ce que la pluie a arrosé aujourd'hui, une fois noté.
class RainWatered {
  const RainWatered({required this.count, required this.locationNames, required this.rainMm, required this.at});

  final int count;
  final List<String> locationNames;
  final double rainMm;
  final DateTime at;
}

/// Note comme faits les arrosages extérieurs que la pluie a déjà donnés.
///
/// Une fois par jour, au premier écran du matin, et seulement si le réglage
/// est actif et qu'on a le droit d'écrire — un invité en lecture seule ne
/// doit pas voir passer un refus qu'il n'a pas demandé.
///
/// L'état garde ce qui a été noté : sans lui la carte disparaîtrait au moment
/// même où elle a quelque chose à dire, les tâches n'étant plus dues.
class RainWateringController extends Notifier<RainWatered?> {
  @override
  RainWatered? build() => null;

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  /// Ce qui a été noté aujourd'hui, `null` sinon : la carte d'hier ne
  /// traîne pas jusqu'à demain.
  RainWatered? get today {
    final s = state;
    return s != null && _isToday(s.at) ? s : null;
  }

  Future<void> applyIfNeeded(AppLocalizations l10n) async {
    if (today != null) return;
    final advice = ref.read(weatherAdviceProvider);
    if (advice == null || advice.kind != RainAdviceKind.fallen) return;
    if (!ref.read(preferencesProvider).rainCountsAsWatering) return;
    if (!ref.read(canEditProvider)) return;
    await apply(l10n, advice);
  }

  /// Le même geste, demandé d'un tap quand l'automatisme est coupé.
  Future<void> apply(AppLocalizations l10n, WeatherAdvice advice) async {
    // Posé avant l'écriture : elle passe par plusieurs `await`, et la carte
    // se reconstruit entre-temps. Sans cette marque, elle relancerait tout.
    state = RainWatered(count: advice.tasks.length, locationNames: advice.locationNames, rainMm: advice.rainMm, at: DateTime.now());
    final count = await ref.read(careActionsProvider).logRainWatering(l10n, tasks: advice.tasks, rainMm: advice.rainMm);
    if (count == 0) {
      // Lecture seule, ou plus rien à noter : la carte reprend sa place.
      state = null;
      return;
    }
    state = RainWatered(count: count, locationNames: advice.locationNames, rainMm: advice.rainMm, at: DateTime.now());
  }
}

final rainWateringProvider = NotifierProvider<RainWateringController, RainWatered?>(RainWateringController.new);
