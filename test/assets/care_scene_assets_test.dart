import 'dart:io';

import 'package:flora/domain/care/care_profile.dart';
import 'package:flora/domain/species/species_info.dart';
import 'package:flora/features/species/application/care_environment_slots.dart';
import 'package:flora/features/species/application/care_environment_spec.dart';
import 'package:flutter_test/flutter_test.dart';

/// Les assets de la scène d'environnement idéal. On vérifie les fichiers
/// réellement embarqués : une image renommée, oubliée dans le pubspec ou
/// jamais rendue ne se verrait qu'à l'exécution, sur l'appareil — et une
/// valeur d'enum ajoutée sans son image casserait ici.
void main() {
  void expectWebp(File file, {int plancher = 2048}) {
    expect(file.existsSync(), isTrue, reason: file.path);
    expect(
      file.lengthSync(),
      greaterThan(plancher),
      reason: '${file.path} est vide ou presque',
    );
    // En-tête RIFF/WEBP : le fichier est bien ce qu'il prétend être.
    final head = file.openSync().readSync(12);
    expect(String.fromCharCodes(head.sublist(0, 4)), 'RIFF', reason: file.path);
    expect(
      String.fromCharCodes(head.sublist(8, 12)),
      'WEBP',
      reason: file.path,
    );
  }

  test(
    'chaque besoin de lumière a sa variante de décor, dedans comme dehors',
    () {
      const noms = {
        LightNeed.shade: 'shade',
        LightNeed.lowLight: 'low_light',
        LightNeed.indirect: 'indirect',
        LightNeed.brightIndirect: 'bright_indirect',
        LightNeed.someSun: 'some_sun',
        LightNeed.fullSun: 'full_sun',
      };
      expect(noms, hasLength(LightNeed.values.length));
      for (final entree in noms.entries) {
        expectWebp(
          File('assets/care_scene/indoor/light/${entree.value}.webp'),
          plancher: 4096,
        );
        expectWebp(
          File('assets/care_scene/outdoor/light/${entree.value}.webp'),
          plancher: 4096,
        );
      }
    },
  );

  test('chaque silhouette a son image', () {
    for (final v in PlantVisualKind.values) {
      final spec = CareEnvironmentVisualSpec(
        environment: CareEnvironmentKind.indoorRoom,
        light: LightNeed.indirect,
        slot: CarePlantSlot.middle,
        plant: v,
        humidity: HumidityNeed.average,
        humidityRange: (40, 60),
      );
      expectWebp(File(spec.plantAsset));
    }
  });

  test('les chemins rendus par la projection existent', () {
    for (final light in LightNeed.values) {
      for (final category in [SpeciesCategory.indoor, SpeciesCategory.tree]) {
        final spec = careEnvironmentSpec(
          profile: CareProfile(
            wateringSummerDays: 7,
            wateringWinterDays: 14,
            light: light,
            humidity: HumidityNeed.average,
            difficulty: CareDifficulty.easy,
            soil: SoilKind.standard,
          ),
          speciesName: 'Monstera deliciosa',
          category: category,
        );
        expect(
          File(spec.backdropAsset).existsSync(),
          isTrue,
          reason: '${light.name} / ${category.name}',
        );
        expect(File(spec.plantAsset).existsSync(), isTrue);
      }
    }
  });

  test(
    'la table des emplacements couvre exactement les valeurs de l\'enum',
    () {
      expect(
        CareEnvironmentSlots.slots.keys.toSet(),
        CarePlantSlot.values.map((s) => s.name).toSet(),
      );
      expect(
        CareEnvironmentSlots.humidifier.keys.toSet(),
        CarePlantSlot.values.map((s) => s.name).toSet(),
      );
      expect(
        CareEnvironmentSlots.humidifierTop.keys.toSet(),
        CarePlantSlot.values.map((s) => s.name).toSet(),
      );
    },
  );

  test('les props du climat ont leur image', () {
    for (final nom in ['humidifier']) {
      expectWebp(File('assets/care_scene/props/$nom.webp'));
    }
  });

  test('le poids total reste sous le budget de la fonctionnalité', () {
    final dossier = Directory('assets/care_scene');
    final total = dossier
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.webp'))
        .fold<int>(0, (somme, f) => somme + f.lengthSync());
    // Le budget (docs/13, tool/build_care_scene_assets.py) : 8 Mo pour toute
    // la fonctionnalité ; la vague 1 en est loin.
    expect(total, lessThan(8 * 1024 * 1024), reason: '${total / 1e6} Mo');
  });

  test('les dossiers sont déclarés dans le pubspec', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('- assets/care_scene/indoor/light/'));
    expect(pubspec, contains('- assets/care_scene/outdoor/light/'));
    expect(pubspec, contains('- assets/care_scene/plants/'));
    expect(pubspec, contains('- assets/care_scene/props/'));
  });
}
