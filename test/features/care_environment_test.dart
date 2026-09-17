import 'package:flora/domain/care/care_profile.dart';
import 'package:flora/domain/species/species_info.dart';
import 'package:flora/features/species/application/care_environment_slots.dart';
import 'package:flora/features/species/application/care_environment_spec.dart';
import 'package:flutter_test/flutter_test.dart';

/// La projection de la fiche vers la scène d'environnement idéal : pure et
/// déterministe, elle se teste sans widget. Rien n'y est inventé — une
/// information absente de la fiche n'apparaît pas dans la scène.
void main() {
  const base = CareProfile(
    wateringSummerDays: 7,
    wateringWinterDays: 14,
    light: LightNeed.brightIndirect,
    humidity: HumidityNeed.high,
    difficulty: CareDifficulty.easy,
    soil: SoilKind.standard,
  );

  CareProfile avec({
    LightNeed light = LightNeed.brightIndirect,
    HumidityNeed humidity = HumidityNeed.high,
    AirflowPreference? airflow,
    int? idealTempMinC,
    int? idealTempMaxC,
    int? damageBelowC,
    int? survivalMinC,
  }) => CareProfile(
    wateringSummerDays: 7,
    wateringWinterDays: 14,
    light: light,
    humidity: humidity,
    difficulty: CareDifficulty.easy,
    soil: SoilKind.standard,
    airflow: airflow,
    idealTempMinC: idealTempMinC,
    idealTempMaxC: idealTempMaxC,
    damageBelowC: damageBelowC,
    survivalMinC: survivalMinC,
  );

  group('la lumière décide de l\'emplacement et du décor', () {
    const attendus = {
      LightNeed.shade: (CarePlantSlot.backCorner, 'shade'),
      LightNeed.lowLight: (CarePlantSlot.back, 'low_light'),
      LightNeed.indirect: (CarePlantSlot.middle, 'indirect'),
      LightNeed.brightIndirect: (CarePlantSlot.besideBeam, 'bright_indirect'),
      LightNeed.someSun: (CarePlantSlot.beamEdge, 'some_sun'),
      LightNeed.fullSun: (CarePlantSlot.sunZone, 'full_sun'),
    };

    for (final entree in attendus.entries) {
      test('${entree.key.name} → ${entree.value.$1.name}', () {
        final spec = careEnvironmentSpec(profile: avec(light: entree.key));
        expect(spec.slot, entree.value.$1);
        expect(
          spec.backdropAsset,
          'assets/care_scene/indoor/light/${entree.value.$2}.webp',
        );
      });
    }

    test('les six situations sont six emplacements distincts', () {
      final slots = LightNeed.values.map((l) => slotFor(l)).toSet();
      expect(slots, hasLength(LightNeed.values.length));
    });
  });

  group('l\'humidité suit la fiche', () {
    test('la plage est celle du besoin, ou celle de l\'espèce', () {
      expect(careEnvironmentSpec(profile: base).humidityRange, (60, 80));
      expect(
        careEnvironmentSpec(profile: avec(humidity: HumidityNeed.low))
            .humidityRange,
        (30, 50),
      );
    });
  });

  group('la température ne se montre que si elle existe', () {
    test('la plage idéale devient une puce', () {
      final spec = careEnvironmentSpec(
        profile: avec(idealTempMinC: 18, idealTempMaxC: 27),
      );
      expect(spec.tempRange, (18, 27));
      expect(spec.tempFloorC, isNull, reason: 'la plage prime sur le seuil');
    });

    test('le seuil de dégâts seul devient un plancher', () {
      final spec = careEnvironmentSpec(profile: avec(damageBelowC: 12));
      expect(spec.tempRange, isNull);
      expect(spec.tempFloorC, 12);
    });

    test('rien de connu, rien d\'affiché', () {
      final spec = careEnvironmentSpec(profile: base);
      expect(spec.tempRange, isNull);
      expect(spec.tempFloorC, isNull);
    });
  });

  group('l\'air qui bouge n\'est jamais inventé', () {
    test('non renseigné : la scène se tait', () {
      expect(careEnvironmentSpec(profile: base).airflow, isNull);
    });

    test('renseigné, il passe tel quel', () {
      expect(
        careEnvironmentSpec(profile: avec(airflow: AirflowPreference.sheltered))
            .airflow,
        AirflowPreference.sheltered,
      );
      expect(
        careEnvironmentSpec(
          profile: avec(airflow: AirflowPreference.ventilated),
        ).airflow,
        AirflowPreference.ventilated,
      );
      expect(
        careEnvironmentSpec(profile: avec(airflow: AirflowPreference.normal))
            .airflow,
        AirflowPreference.normal,
      );
    });

    test('l\'effet de flux ne se dessine que s\'il dit quelque chose', () {
      expect(
        careEnvironmentSpec(profile: avec(airflow: AirflowPreference.sheltered))
            .hasAirflowEffect,
        isTrue,
      );
      expect(
        careEnvironmentSpec(
          profile: avec(airflow: AirflowPreference.ventilated),
        ).hasAirflowEffect,
        isTrue,
      );
      expect(
        careEnvironmentSpec(profile: avec(airflow: AirflowPreference.normal))
            .hasAirflowEffect,
        isFalse,
        reason: 'l\'air ordinaire n\'a pas d\'emphase',
      );
      expect(careEnvironmentSpec(profile: base).hasAirflowEffect, isFalse);
    });

    test('l\'air à abriter entre par l\'ouverture, pas par une machine', () {
      final dedans = careEnvironmentSpec(
        profile: avec(airflow: AirflowPreference.sheltered),
      );
      expect(dedans.airflowOriginFraction, CareEnvironmentSlots.airflow['indoor']);
      final dehors = careEnvironmentSpec(
        profile: avec(airflow: AirflowPreference.sheltered),
        category: SpeciesCategory.tree,
      );
      expect(dehors.airflowOriginFraction, CareEnvironmentSlots.airflow['outdoor']);
    });
  });

  group('les props du climat', () {
    test('l\'humidificateur ne paraît que si l\'air humide est un besoin', () {
      expect(careEnvironmentSpec(profile: base).hasHumidifier, isTrue);
      expect(
        careEnvironmentSpec(profile: avec(humidity: HumidityNeed.average))
            .hasHumidifier,
        isFalse,
      );
      expect(
        careEnvironmentSpec(profile: avec(humidity: HumidityNeed.low))
            .hasHumidifier,
        isFalse,
      );
    });

    test('les positions des props sont dans le cadre, la vapeur au-dessus', () {
      for (final slot in CarePlantSlot.values) {
        final h = CareEnvironmentSlots.humidifier[slot.name]!;
        final s = CareEnvironmentSlots.humidifierTop[slot.name]!;
        expect(h.$1, inInclusiveRange(0.0, 1.0), reason: slot.name);
        expect(h.$2, inInclusiveRange(0.0, 1.0), reason: slot.name);
        expect(s.$1, inInclusiveRange(0.0, 1.0), reason: slot.name);
        expect(s.$2, inInclusiveRange(0.0, 1.0), reason: slot.name);
        expect(
          s.$2,
          lessThan(h.$2),
          reason: 'la vapeur part du haut (${slot.name})',
        );
      }
      expect(CareEnvironmentSlots.airflow['indoor']!.$1, inInclusiveRange(0.0, 1.0));
      expect(CareEnvironmentSlots.airflow['indoor']!.$2, inInclusiveRange(0.0, 1.0));
      expect(CareEnvironmentSlots.airflow['outdoor']!.$1, inInclusiveRange(0.0, 1.0));
      expect(CareEnvironmentSlots.airflow['outdoor']!.$2, inInclusiveRange(0.0, 1.0));
    });
  });

  group('pièce ou dehors', () {
    test('les arbres, fruitiers et légumes vont dehors', () {
      for (final cat in [
        SpeciesCategory.tree,
        SpeciesCategory.fruit,
        SpeciesCategory.vegetable,
      ]) {
        expect(
          environmentFor(base, cat),
          CareEnvironmentKind.outdoorPatch,
          reason: cat.name,
        );
      }
    });

    test('les plantes d\'intérieur et succulentes restent dedans', () {
      for (final cat in [SpeciesCategory.indoor, SpeciesCategory.succulent]) {
        expect(
          environmentFor(base, cat),
          CareEnvironmentKind.indoorRoom,
          reason: cat.name,
        );
      }
    });

    test('aromatiques et fleurs : la rusticité départage', () {
      expect(
        environmentFor(avec(damageBelowC: -5), SpeciesCategory.herb),
        CareEnvironmentKind.outdoorPatch,
        reason: 'une aromatique qui tient le gel vit dehors',
      );
      expect(
        environmentFor(base, SpeciesCategory.herb),
        CareEnvironmentKind.indoorRoom,
      );
      expect(
        environmentFor(avec(survivalMinC: -8), SpeciesCategory.flower),
        CareEnvironmentKind.outdoorPatch,
      );
      expect(
        environmentFor(base, SpeciesCategory.flower),
        CareEnvironmentKind.indoorRoom,
      );
    });

    test('sans catégorie, la pièce est le repli', () {
      expect(environmentFor(base, null), CareEnvironmentKind.indoorRoom);
    });

    test('dehors a son propre décor lumineux', () {
      final spec = careEnvironmentSpec(
        profile: base,
        category: SpeciesCategory.tree,
      );
      expect(spec.environment, CareEnvironmentKind.outdoorPatch);
      expect(
        spec.backdropAsset,
        'assets/care_scene/outdoor/light/bright_indirect.webp',
      );
    });
  });

  group('la silhouette', () {
    test('une Monstera est une monstera', () {
      expect(
        resolvePlantVisual(speciesName: 'Monstera deliciosa'),
        PlantVisualKind.monstera,
      );
      expect(
        resolvePlantVisual(speciesName: 'monstera adansonii'),
        PlantVisualKind.monstera,
        reason: 'la casse ne compte pas',
      );
    });

    test('le genre suffit quand l\'espèce n\'est pas nommée', () {
      expect(
        resolvePlantVisual(speciesName: 'Monstera dubia'),
        PlantVisualKind.monstera,
      );
    });

    test('un sansevieria est des lames droites, synonyme compris', () {
      expect(
        resolvePlantVisual(speciesName: 'Dracaena trifasciata'),
        PlantVisualKind.uprightLeaf,
      );
      expect(
        resolvePlantVisual(speciesName: 'Sansevieria trifasciata'),
        PlantVisualKind.uprightLeaf,
        reason: 'l\'ancien nom vaut le nouveau',
      );
      expect(
        resolvePlantVisual(speciesName: 'Dracaena marginata'),
        PlantVisualKind.uprightLeaf,
      );
    });

    test('un cactus est un cactus, même sans nom d\'espèce', () {
      expect(
        resolvePlantVisual(
          speciesName: 'Opuntia ficus-indica',
          family: 'Cactaceae',
        ),
        PlantVisualKind.cactus,
      );
      expect(resolvePlantVisual(family: 'Cactaceae'), PlantVisualKind.cactus);
    });

    test('un pin est un conifère', () {
      expect(
        resolvePlantVisual(speciesName: 'Picea abies', family: 'Pinaceae'),
        PlantVisualKind.conifer,
      );
    });

    test('les fougères d\'appartement sont des fougères', () {
      expect(
        resolvePlantVisual(speciesName: 'Nephrolepis exaltata'),
        PlantVisualKind.fern,
      );
      expect(
        resolvePlantVisual(speciesName: 'Adiantum raddianum'),
        PlantVisualKind.fern,
      );
    });

    test('une orchidée d\'appartement a sa hampe fleurie', () {
      for (final nom in [
        'Phalaenopsis amabilis',
        'Dendrobium nobile',
        'Cymbidium hybridum',
      ]) {
        expect(resolvePlantVisual(speciesName: nom), PlantVisualKind.orchid, reason: nom);
      }
      // Une orchidée terrestre du catalogue étendu garde la feuille large :
      // la silhouette en pot ne lui va pas.
      expect(
        resolvePlantVisual(speciesName: 'Ophrys sphegodes', family: 'Orchidaceae'),
        PlantVisualKind.broadLeaf,
      );
    });

    test('les plantes qui retombent sont des lianes', () {
      for (final nom in [
        'Epipremnum aureum',
        'Scindapsus pictus',
        'Tradescantia zebrina',
        'Hedera helix',
        'Cissus rhombifolia',
        'Ceropegia woodii',
      ]) {
        expect(resolvePlantVisual(speciesName: nom), PlantVisualKind.vine, reason: nom);
      }
    });

    test('le philodendron grimpant est une liane, le selloum non', () {
      // Genre mixte : la règle reste à l'espèce.
      expect(resolvePlantVisual(speciesName: 'Philodendron hederaceum'), PlantVisualKind.vine);
      expect(resolvePlantVisual(speciesName: 'Philodendron bipinnatifidum'), PlantVisualKind.broadLeaf);
    });

    test('une succulente sans autre indice tient de la rosette', () {
      expect(
        resolvePlantVisual(
          speciesName: 'Echeveria elegans',
          category: SpeciesCategory.succulent,
        ),
        PlantVisualKind.rosette,
      );
      expect(
        resolvePlantVisual(
          speciesName: 'Opuntia ficus-indica',
          family: 'Cactaceae',
          category: SpeciesCategory.succulent,
        ),
        PlantVisualKind.cactus,
        reason: 'la famille tranche avant la catégorie',
      );
    });

    test('l\'inconnu tombe sur la feuille large', () {
      expect(
        resolvePlantVisual(speciesName: 'Ficus elastica'),
        PlantVisualKind.broadLeaf,
      );
      expect(resolvePlantVisual(speciesName: null), PlantVisualKind.broadLeaf);
      expect(resolvePlantVisual(speciesName: '  '), PlantVisualKind.broadLeaf);
    });

    test('chaque silhouette nomme son asset du pipeline', () {
      for (final v in PlantVisualKind.values) {
        final spec = CareEnvironmentVisualSpec(
          environment: CareEnvironmentKind.indoorRoom,
          light: LightNeed.indirect,
          slot: CarePlantSlot.middle,
          plant: v,
          humidity: HumidityNeed.average,
          humidityRange: (40, 60),
        );
        expect(spec.plantAsset, startsWith('assets/care_scene/plants/'));
        expect(spec.plantAsset, endsWith('.webp'));
      }
    });
  });

  group('la table des emplacements', () {
    test('chaque valeur de CarePlantSlot a sa position projetée', () {
      for (final slot in CarePlantSlot.values) {
        expect(
          CareEnvironmentSlots.slots,
          contains(slot.name),
          reason: slot.name,
        );
      }
      expect(
        CareEnvironmentSlots.slots,
        hasLength(CarePlantSlot.values.length),
      );
    });

    test('les positions sont dans le cadre et distinctes', () {
      final vues = <(double, double)>{};
      for (final p in CareEnvironmentSlots.slots.values) {
        expect(p.$1, inInclusiveRange(0.0, 1.0), reason: 'x de $p');
        expect(p.$2, inInclusiveRange(0.0, 1.0), reason: 'y de $p');
        vues.add(p);
      }
      expect(
        vues,
        hasLength(CareEnvironmentSlots.slots.length),
        reason: 'deux emplacements ne se confondent pas',
      );
      expect(CareEnvironmentSlots.anchor.$1, inInclusiveRange(0.0, 1.0));
      expect(CareEnvironmentSlots.anchor.$2, inInclusiveRange(0.0, 1.0));
    });

    test('la distance à la fenêtre ordonne les emplacements', () {
      // La fenêtre est à gauche de l'image : plus un besoin est sombre, plus
      // l'emplacement est à droite, loin d'elle. L'ordre est strict — un
      // besoin plus lumineux ne recule jamais.
      double x(CarePlantSlot s) => CareEnvironmentSlots.slots[s.name]!.$1;
      final ordre = LightNeed.values.map(slotFor).toList();
      for (var i = 1; i < ordre.length; i++) {
        expect(
          x(ordre[i]),
          lessThan(x(ordre[i - 1])),
          reason:
              '${ordre[i].name} devrait être plus près de la fenêtre que '
              '${ordre[i - 1].name}',
        );
      }
    });

    test('les six emplacements sont sur une droite, à pas constant', () {
      // C'est ce qui fait lire la scène d'une fiche à l'autre : la plante
      // avance d'un cran vers la lumière, elle ne se pose pas au hasard
      // dans la pièce.
      final points = LightNeed.values
          .map((l) => CareEnvironmentSlots.slots[slotFor(l).name]!)
          .toList();
      final dx = points[0].$1 - points[1].$1;
      final dy = points[0].$2 - points[1].$2;
      for (var i = 1; i < points.length; i++) {
        expect(
          points[i - 1].$1 - points[i].$1,
          closeTo(dx, 0.001),
          reason: 'le pas en x change au cran $i',
        );
        expect(
          points[i - 1].$2 - points[i].$2,
          closeTo(dy, 0.001),
          reason: 'le pas en y change au cran $i',
        );
      }
    });
  });
}
