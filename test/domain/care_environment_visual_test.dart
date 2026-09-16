import 'package:flora/domain/care/care_profile.dart';
import 'package:flora/features/species/application/care_environment_visual.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  CareProfile profile({
    LightNeed light = LightNeed.brightIndirect,
    HumidityNeed humidity = HumidityNeed.average,
    SoilKind soil = SoilKind.standard,
    bool outdoorFriendly = false,
    int? damageBelowC = 10,
    int? min = 18,
    int? max = 24,
    PlantSupport? support,
  }) => CareProfile(
        wateringSummerDays: 7,
        wateringWinterDays: 14,
        light: light,
        humidity: humidity,
        difficulty: CareDifficulty.easy,
        soil: soil,
        outdoorFriendly: outdoorFriendly,
        damageBelowC: damageBelowC,
        idealTempMinC: min,
        idealTempMaxC: max,
        support: support,
      );

  group('lumière', () {
    for (final light in LightNeed.values) {
      test('${light.name} garde une variante propre', () {
        final spec = CareEnvironmentVisualResolver.resolve(profile(light: light));
        expect(spec.light, light);
        expect(spec.lightAssetKey, isNotEmpty);
      });
    }

    test('vive indirecte utilise la variante dédiée', () {
      final spec = CareEnvironmentVisualResolver.resolve(profile(light: LightNeed.brightIndirect));
      expect(spec.lightAssetKey, 'bright_indirect');
    });
  });

  test('Monstera deliciosa garde sa silhouette', () {
    final spec = CareEnvironmentVisualResolver.resolve(profile(humidity: HumidityNeed.high), speciesName: 'Monstera deliciosa');
    expect(spec.plant, CarePlantVisualKind.monstera);
    expect(spec.environment, CareEnvironmentKind.indoor);
  });

  test('Dracaena trifasciata est verticale', () {
    final spec = CareEnvironmentVisualResolver.resolve(profile(), speciesName: 'Dracaena trifasciata');
    expect(spec.plant, CarePlantVisualKind.uprightLeaf);
  });

  test('un cactus reconnu utilise la silhouette cactus', () {
    final spec = CareEnvironmentVisualResolver.resolve(profile(soil: SoilKind.cactus), speciesName: 'Mammillaria elongata');
    expect(spec.plant, CarePlantVisualKind.cactus);
  });

  test('un conifère rustique passe dehors', () {
    final spec = CareEnvironmentVisualResolver.resolve(
      profile(light: LightNeed.fullSun, outdoorFriendly: true, damageBelowC: -20),
      speciesName: 'Abies alba',
    );
    expect(spec.environment, CareEnvironmentKind.outdoor);
    expect(spec.plant, CarePlantVisualKind.conifer);
  });

  test('une plante seulement estivale reste représentée dedans', () {
    final spec = CareEnvironmentVisualResolver.resolve(
      profile(outdoorFriendly: true, damageBelowC: 10),
      speciesName: 'Ficus elastica',
    );
    expect(spec.environment, CareEnvironmentKind.indoor);
  });

  test('l'humidité et la température ne sont pas inventées', () {
    final spec = CareEnvironmentVisualResolver.resolve(
      profile(humidity: HumidityNeed.high, min: null, max: null),
      speciesName: 'Adiantum raddianum',
    );
    expect(spec.humidityMin, 60);
    expect(spec.humidityMax, 80);
    expect(spec.temperatureMin, isNull);
    expect(spec.temperatureMax, isNull);
  });

  test('un inconnu retombe sur une feuille large', () {
    final spec = CareEnvironmentVisualResolver.resolve(profile(), speciesName: 'Planta incognita');
    expect(spec.plant, CarePlantVisualKind.broadLeaf);
  });
}
