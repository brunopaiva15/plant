import '../care/care_profile.dart';
import '../models/models.dart';
import 'home_climate.dart';

/// Ce qu'une mesure de la maison dit aux plantes d'intérieur.
enum HomeClimateTipKind {
  /// Air sec pour des plantes qui en veulent beaucoup.
  dryAir,

  /// Air très humide : l'eau du pot s'évapore lentement, les champignons aiment.
  humidAir,

  /// En dessous du minimum d'une espèce.
  cold,

  /// Au-dessus de la plage idéale : la terre sèche plus vite.
  hot,
}

/// Un conseil, avec la valeur qui le motive et les plantes concernées.
class HomeClimateTip {
  const HomeClimateTip({required this.kind, required this.value, required this.plantNames});

  final HomeClimateTipKind kind;

  /// La température (°C) ou l'humidité (%) mesurée, selon le conseil.
  final num value;

  /// Les plantes concernées, dans l'ordre du jardin, quatre au plus.
  final List<String> plantNames;
}

/// Une plante d'intérieur et ce que sa fiche attend.
class IndoorPlant {
  const IndoorPlant({required this.name, required this.profile});

  final String name;
  final CareProfile profile;
}

/// Seuils, en clair. Au-delà de 70 %, une pièce est humide pour tout le monde.
///
/// Pour l'air sec, le seuil se lit sur la plage de la fiche, [tolerance] points
/// en dessous de son minimum : une plante n'est pas en peine dès le premier
/// point manquant, mais un salon chauffé à 30 % met en peine ce qui demande
/// 60 %. Une espèce qui précise « 50 à 70 % » est donc avertie plus tard
/// qu'une autre qui en demande 65.
abstract final class HomeClimateAdvisor {
  static const int tolerance = 15;
  static const int humid = 70;
  static const int hot = 30;
  static const int maxNames = 4;

  static List<HomeClimateTip> advise({required HomeReading reading, required List<IndoorPlant> plants}) {
    if (plants.isEmpty) return const [];
    final tips = <HomeClimateTip>[];
    final humidity = reading.humidity;
    final temp = reading.temperatureC;

    if (humidity != null) {
      final dry = [
        for (final p in plants)
          if (humidity < p.profile.humidityRange.$1 - tolerance) p.name,
      ];
      if (dry.isNotEmpty) tips.add(HomeClimateTip(kind: HomeClimateTipKind.dryAir, value: humidity, plantNames: _cap(dry)));
      if (humidity > humid) {
        final wet = [
          for (final p in plants)
            if (humidity > p.profile.humidityRange.$2 + tolerance) p.name,
        ];
        tips.add(HomeClimateTip(kind: HomeClimateTipKind.humidAir, value: humidity, plantNames: _cap(wet)));
      }
    }

    if (temp != null) {
      final cold = [
        for (final p in plants)
          if (_floor(p.profile) case final floor? when temp < floor) p.name,
      ];
      if (cold.isNotEmpty) tips.add(HomeClimateTip(kind: HomeClimateTipKind.cold, value: temp, plantNames: _cap(cold)));
      final warm = [
        for (final p in plants)
          if (temp > (p.profile.idealTempMaxC ?? hot)) p.name,
      ];
      if (warm.isNotEmpty) tips.add(HomeClimateTip(kind: HomeClimateTipKind.hot, value: temp, plantNames: _cap(warm)));
    }
    return tips;
  }

  /// Le seuil en dessous duquel l'espèce souffre : son minimum supporté, à
  /// défaut le bas de sa plage idéale.
  static int? _floor(CareProfile p) => p.minTempC ?? p.idealTempMinC;

  static List<String> _cap(List<String> names) {
    final unique = <String>[];
    for (final n in names) {
      if (!unique.contains(n)) unique.add(n);
    }
    return unique.take(maxNames).toList();
  }

  /// Les plantes d'intérieur d'un jardin : celles qui ne sont pas dehors,
  /// et, si un emplacement porte le nom de la pièce du capteur, seulement
  /// celles de cette pièce.
  static List<PlantSummary> indoorPlants(List<PlantSummary> plants, {required Set<String> outdoorLocationIds, String? roomName}) {
    final indoor = [
      for (final p in plants)
        if (p.plant.locationId == null || !outdoorLocationIds.contains(p.plant.locationId)) p,
    ];
    final room = roomName?.trim().toLowerCase() ?? '';
    if (room.isEmpty) return indoor;
    final inRoom = [
      for (final p in indoor)
        if (p.locationName?.trim().toLowerCase() == room) p,
    ];
    return inRoom.isEmpty ? indoor : inRoom;
  }
}
