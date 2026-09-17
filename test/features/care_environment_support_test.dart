import 'package:flora/domain/care/care_profile.dart';
import 'package:flora/domain/species/species_info.dart';
import 'package:flora/features/species/application/care_environment_slots.dart';
import 'package:flora/features/species/application/care_environment_spec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const profile = CareProfile(
    wateringSummerDays: 7,
    wateringWinterDays: 14,
    light: LightNeed.brightIndirect,
    humidity: HumidityNeed.average,
    difficulty: CareDifficulty.easy,
    soil: SoilKind.standard,
  );

  group('support de la plante dans la scène', () {
    test('une plante compacte est posée sur le guéridon', () {
      final spec = careEnvironmentSpec(
        profile: profile,
        speciesName: 'Goeppertia sanderiana',
        family: 'Marantaceae',
        category: SpeciesCategory.indoor,
      );

      expect(spec.support, CarePlantSupport.pedestal);
      expect(spec.hasPedestal, isTrue);
      expect(spec.hidesBackdropPedestal, isFalse);
      expect(spec.plantFraction, CareEnvironmentSlots.pedestalTop);
    });

    test('Monstera deliciosa reste au sol et masque le guéridon', () {
      final spec = careEnvironmentSpec(
        profile: profile,
        speciesName: 'Monstera deliciosa',
        family: 'Araceae',
        category: SpeciesCategory.indoor,
      );

      expect(spec.support, CarePlantSupport.floor);
      expect(spec.hasPedestal, isFalse);
      expect(spec.hidesBackdropPedestal, isTrue);
      expect(spec.plantFraction, spec.slotFraction);
    });

    test('un palmier reste au sol', () {
      final spec = careEnvironmentSpec(
        profile: profile,
        speciesName: 'Howea forsteriana',
        family: 'Arecaceae',
        category: SpeciesCategory.indoor,
      );

      expect(spec.support, CarePlantSupport.floor);
      expect(spec.hidesBackdropPedestal, isTrue);
    });

    test('dehors il n\'y a jamais de guéridon', () {
      final spec = careEnvironmentSpec(
        profile: profile,
        speciesName: 'Malus domestica',
        family: 'Rosaceae',
        category: SpeciesCategory.tree,
      );

      expect(spec.environment, CareEnvironmentKind.outdoorPatch);
      expect(spec.support, CarePlantSupport.floor);
      expect(spec.hasPedestal, isFalse);
      expect(spec.hidesBackdropPedestal, isFalse);
    });

    test('l\'humidificateur suit le guéridon', () {
      final humid = CareProfile(
        wateringSummerDays: profile.wateringSummerDays,
        wateringWinterDays: profile.wateringWinterDays,
        light: profile.light,
        humidity: HumidityNeed.high,
        difficulty: profile.difficulty,
        soil: profile.soil,
      );
      final spec = careEnvironmentSpec(
        profile: humid,
        speciesName: 'Phalaenopsis amabilis',
        family: 'Orchidaceae',
        category: SpeciesCategory.indoor,
      );

      expect(spec.hasPedestal, isTrue);
      expect(
        spec.humidifierFraction,
        CareEnvironmentSlots.pedestalHumidifier,
      );
      expect(
        spec.steamOriginFraction,
        CareEnvironmentSlots.pedestalHumidifierTop,
      );
    });
  });
}
