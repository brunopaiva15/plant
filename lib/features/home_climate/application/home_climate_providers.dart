import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../domain/home/home_climate.dart';
import '../../../domain/home/home_climate_advisor.dart';
import '../../../domain/repositories/repositories.dart';
import '../../plants/application/plant_providers.dart';
import '../../weather/application/weather_providers.dart';

/// La mesure du capteur retenu ; `null` sans capteur, ou s'il ne répond pas.
/// Relue toutes les quinze minutes : l'air d'une pièce ne change pas plus
/// vite, et HomeKit n'aime pas qu'on le harcèle.
final homeReadingProvider = FutureProvider<HomeReading?>((ref) async {
  final sensor = ref.watch(preferencesProvider.select((p) => p.homeSensor));
  if (sensor == null) return null;
  final timer = Timer(const Duration(minutes: 15), ref.invalidateSelf);
  ref.onDispose(timer.cancel);
  try {
    final reading = await ref.watch(homeClimateServiceProvider).read(sensor.id);
    if (reading == null) return null;
    return HomeReading(at: reading.at, temperatureC: reading.temperatureC, humidity: reading.humidity, sensor: sensor);
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
