import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../domain/home/home_climate.dart';
import '../../../domain/home/home_climate_advisor.dart';
import '../../../domain/repositories/repositories.dart';
import '../../plants/application/plant_providers.dart';
import '../../weather/application/weather_providers.dart';

/// La mesure des capteurs retenus ; `null` sans capteur, ou s'ils ne
/// répondent pas. Relue toutes les quinze minutes : l'air d'une pièce ne
/// change pas plus vite, et HomeKit n'aime pas qu'on le harcèle.
///
/// La température vient du capteur de température ; l'humidité du capteur
/// d'humidité s'il y en a un, sinon du même capteur, s'il la mesure.
final homeReadingProvider = FutureProvider<HomeReading?>((ref) async {
  final sensor = ref.watch(preferencesProvider.select((p) => p.homeSensor));
  final humiditySensor = ref.watch(preferencesProvider.select((p) => p.homeHumiditySensor));
  if (sensor == null) return null;
  final timer = Timer(const Duration(minutes: 15), ref.invalidateSelf);
  ref.onDispose(timer.cancel);
  final service = ref.watch(homeClimateServiceProvider);
  try {
    final main = await service.read(sensor.id);
    final other = humiditySensor == null || humiditySensor.id == sensor.id ? null : await service.read(humiditySensor.id);
    final humidity = other != null ? other.humidity : (humiditySensor == null ? main?.humidity : null);
    // La raison d'une valeur manquante, celle du capteur qui devait la donner.
    final humidityError = other?.error ?? (humiditySensor == null ? main?.error : null);
    final error = {
      if (main?.temperatureC == null) ?main?.error,
      if (humidity == null) ?humidityError,
    }.join('; ');
    if (main?.temperatureC == null && humidity == null && error.isEmpty) return null;
    return HomeReading(
      at: main?.at ?? other?.at ?? DateTime.now(),
      temperatureC: main?.temperatureC,
      humidity: humidity,
      sensor: sensor,
      humiditySensor: humiditySensor,
      error: error.isEmpty ? null : error,
    );
  } catch (_) {
    // Un capteur muet n'est pas une panne de l'application : la ligne
    // disparaît, tout le reste continue.
    return null;
  }
});

/// Les plantes d'intérieur concernées par le capteur, avec leur fiche.
///
/// Celles qui ne sont pas dehors ; et si un emplacement porte le nom de la
/// pièce du capteur (« Salon »), seulement celles-là — un thermomètre de
/// salon ne dit rien de la chambre.
final indoorPlantsProvider = Provider<List<IndoorPlant>>((ref) {
  final sensor = ref.watch(preferencesProvider.select((p) => p.homeSensor));
  final plants = ref.watch(plantSummariesProvider(const PlantFilter())).value ?? const [];
  final outdoor = ref.watch(outdoorLocationIdsProvider);
  final indoor = HomeClimateAdvisor.indoorPlants(plants, outdoorLocationIds: outdoor, roomName: sensor?.roomName);
  final guide = ref.watch(careGuideProvider);
  final family = speciesFamilyLookupIn(ref);
  return [
    for (final p in indoor)
      if (p.plant.speciesName case final species? when species.isNotEmpty)
        IndoorPlant(name: p.plant.name, profile: guide.resolve(species, family: family(species)).profile),
  ];
});

/// Les conseils du jour tirés de la mesure, vides s'il n'y a rien à dire.
final homeClimateTipsProvider = Provider<List<HomeClimateTip>>((ref) {
  final reading = ref.watch(homeReadingProvider).value;
  if (reading == null || reading.isEmpty) return const [];
  return HomeClimateAdvisor.advise(reading: reading, plants: ref.watch(indoorPlantsProvider));
});

/// Conseils masqués pour la journée (après fermeture).
class DismissedHomeTipsController extends Notifier<DateTime?> {
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

final dismissedHomeTipsProvider = NotifierProvider<DismissedHomeTipsController, DateTime?>(DismissedHomeTipsController.new);
