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
      // Le pot se pose sur le plateau du guéridon, dont la base est au slot
      // lumineux : à l'aplomb du slot, à hauteur du plateau.
      expect(
        spec.plantFraction.$1,
        closeTo(
          spec.slotFraction.$1 +
              CareEnvironmentSlots.pedestalPot.$1 -
              CareEnvironmentSlots.anchor.$1,
          1e-9,
        ),
      );
      expect(
        spec.plantFraction.$2,
        closeTo(
          spec.slotFraction.$2 +
              CareEnvironmentSlots.pedestalPot.$2 -
              CareEnvironmentSlots.anchor.$2,
          1e-9,
        ),
      );
      // Le plateau est au-dessus de la base dans l'image du prop.
      expect(
        CareEnvironmentSlots.pedestalPot.$2,
        lessThan(CareEnvironmentSlots.anchor.$2),
      );
    });

    test('Monstera deliciosa reste au sol', () {
      final spec = careEnvironmentSpec(
        profile: profile,
        speciesName: 'Monstera deliciosa',
        family: 'Araceae',
        category: SpeciesCategory.indoor,
      );

      expect(spec.support, CarePlantSupport.floor);
      expect(spec.hasPedestal, isFalse);
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
      expect(spec.hasPedestal, isFalse);
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
    });

    test('l\'humidificateur suit le support', () {
      final humid = CareProfile(
        wateringSummerDays: profile.wateringSummerDays,
        wateringWinterDays: profile.wateringWinterDays,
        light: profile.light,
        humidity: HumidityNeed.high,
        humidityMethods: {HumidityMethod.humidifier},
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
      // L'humidificateur se pose à côté du support, à la place prévue pour
      // le slot.
      expect(
        spec.humidifierFraction,
        CareEnvironmentSlots.humidifier[spec.slot.name],
      );
      expect(
        spec.steamOriginFraction,
        CareEnvironmentSlots.humidifierTop[spec.slot.name],
      );
    });
  });
}
