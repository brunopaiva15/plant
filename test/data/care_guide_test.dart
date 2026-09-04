import 'package:flora/data/species/care_profiles.dart';
import 'package:flora/data/species/catalog_care_guide.dart';
import 'package:flora/data/species/species_catalog.dart';
import 'package:flora/domain/care/care_guide.dart';
import 'package:flora/domain/care/care_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const guide = CatalogCareGuide();

  group('résolution', () {
    test('espèce exacte', () {
      final r = guide.resolve('Monstera deliciosa');
      expect(r.match, CareMatch.species);
      expect(r.profile.toxicity, Toxicity.toxic);
    });

    test('genre quand l\'espèce est inconnue', () {
      final r = guide.resolve('Ficus benghalensis');
      expect(r.match, CareMatch.genus);
      expect(r.matchedOn, 'Ficus');
    });

    test('famille quand le genre est inconnu', () {
      final r = guide.resolve('Xanthosoma sagittifolium', family: 'Araceae');
      expect(r.match, CareMatch.family);
      expect(r.matchedOn, 'Araceae');
    });

    test('famille déduite du catalogue intégré sans indication', () {
      // Aechmea est au catalogue (Bromeliaceae) mais pas dans les profils.
      final r = guide.resolve('Aechmea fasciata');
      expect(r.match, CareMatch.family);
      expect(r.matchedOn, 'Bromeliaceae');
    });

    test('profil générique en dernier recours', () {
      expect(guide.resolve('Quelquechose inconnu').match, CareMatch.generic);
      expect(guide.resolve(null).match, CareMatch.generic);
      expect(guide.resolve('   ').match, CareMatch.generic);
    });

    test('la casse et les hybrides ne cassent pas la résolution', () {
      expect(guide.resolve('ficus lyrata').match, CareMatch.species);
      expect(guide.resolve('FICUS LYRATA').match, CareMatch.species);
      expect(guide.resolve('Citrus × limon').match, CareMatch.species);
      expect(CatalogCareGuide.genusOf('Citrus × limon'), 'Citrus');
    });

    test('un genre seul est résolu comme genre', () {
      final r = guide.resolve('Calathea');
      expect(r.match, CareMatch.genus);
      expect(r.matchedOn, 'Calathea');
    });

    test('la catégorie sert de repli avant le générique', () {
      final r = guide.resolve(null, categoryKey: 'succulent');
      expect(r.match, CareMatch.category);
      expect(r.profile.soil, SoilKind.cactus);
    });

    test('les espèces proches ne partagent pas la même fiche', () {
      // Sansevieria (rare) et dracaena arbustif : même genre, besoins opposés.
      final snake = guide.resolve('Dracaena trifasciata');
      final marginata = guide.resolve('Dracaena marginata');
      expect(snake.match, CareMatch.species);
      expect(marginata.match, CareMatch.genus);
      expect(snake.profile.wateringSummerDays, greaterThan(marginata.profile.wateringSummerDays));
    });
  });

  group('saisonnalité de l\'arrosage', () {
    final monstera = CareProfiles.bySpecies['Monstera deliciosa']!;

    test('plus fréquent en été qu\'en hiver', () {
      expect(monstera.wateringDaysFor(7), lessThan(monstera.wateringDaysFor(1)));
      expect(monstera.wateringDaysFor(7), monstera.wateringSummerDays);
      expect(monstera.wateringDaysFor(1), monstera.wateringWinterDays);
    });

    test('la mi-saison est entre les deux', () {
      final spring = monstera.wateringDaysFor(4);
      expect(spring, greaterThan(monstera.wateringSummerDays));
      expect(spring, lessThan(monstera.wateringWinterDays));
    });

    test('l\'hémisphère sud inverse les saisons', () {
      expect(monstera.wateringDaysFor(1, south: true), monstera.wateringSummerDays);
      expect(monstera.wateringDaysFor(7, south: true), monstera.wateringWinterDays);
    });

    test('une place ensoleillée assèche plus vite', () {
      final sunny = monstera.wateringDaysFor(7, actualLight: LightNeed.fullSun);
      final dim = monstera.wateringDaysFor(7, actualLight: LightNeed.lowLight);
      expect(sunny, lessThan(dim));
    });

    test('jamais moins d\'un jour', () {
      const thirsty = CareProfile(
        wateringSummerDays: 1,
        wateringWinterDays: 1,
        light: LightNeed.fullSun,
        humidity: HumidityNeed.average,
        difficulty: CareDifficulty.easy,
        soil: SoilKind.rich,
      );
      expect(thirsty.wateringDaysFor(7, actualLight: LightNeed.fullSun), 1);
    });
  });

  group('fenêtre d\'engrais', () {
    test('la saison standard couvre le printemps et l\'été', () {
      final p = CareProfiles.bySpecies['Monstera deliciosa']!;
      expect(p.fertilizesIn(5), isTrue);
      expect(p.fertilizesIn(12), isFalse);
    });

    test('une fenêtre à cheval sur l\'hiver reste continue', () {
      const w = MonthWindow(10, 3);
      expect(w.contains(11), isTrue);
      expect(w.contains(1), isTrue);
      expect(w.contains(3), isTrue);
      expect(w.contains(6), isFalse);
    });

    test('sans engrais, aucun mois n\'est concerné', () {
      final lavender = CareProfiles.bySpecies['Lavandula angustifolia']!;
      expect(lavender.fertilizingDays, isNull);
      expect(lavender.fertilizesIn(5), isFalse);
    });
  });

  group('cohérence de la base', () {
    test('toute espèce du catalogue obtient une fiche non générique', () {
      final orphans = <String>[];
      for (final e in SpeciesCatalog.entries) {
        final r = guide.resolve(e.scientificName);
        if (r.match == CareMatch.generic) orphans.add(e.scientificName);
      }
      expect(orphans, isEmpty, reason: 'espèces sans fiche : $orphans');
    });

    test('les intervalles d\'hiver ne sont jamais plus courts que ceux d\'été', () {
      final bad = <String>[];
      for (final entry in {...CareProfiles.bySpecies, ...CareProfiles.byGenus, ...CareProfiles.byFamily, ...CareProfiles.byCategory}.entries) {
        final p = entry.value;
        // Le cyclamen et l'aeonium se reposent en été : exception assumée.
        if (!p.dormantInWinter) continue;
        if (p.wateringWinterDays < p.wateringSummerDays) bad.add(entry.key);
      }
      expect(bad, isEmpty, reason: 'profils incohérents : $bad');
    });

    test('toutes les clés de conseils sont traduisibles', () {
      // La couche i18n mappe les clés ; une clé absente afficherait du vide.
      const known = {
        'fingerTest', 'drySoilFirst', 'neverDryOut', 'evenWatering', 'waterAtBase', 'noWaterOnLeaves', 'bottomWatering',
        'filteredWater', 'rainwaterOnly', 'thirstyPlant', 'droopSignal', 'winterDry', 'winterRest', 'summerDormant',
        'noWaterWhileSplitting', 'orchidSoak', 'soakMount', 'dryUpsideDown', 'waterInTheCup', 'noSoil', 'greenRoots',
        'humidityTray', 'noDirectSun', 'toleratesLowLight', 'toleratesNeglect', 'brightForColor', 'rotatePot',
        'hatesMoving', 'wipeLeaves', 'trimToBushOut', 'monsteraSupport', 'shallowPot', 'likesBeingPotbound',
        'trunkStoresWater', 'pupsToShare', 'keepFlowerSpike', 'darkForRebloom', 'notADesertCactus', 'deadheadFlowers',
        'pinchFlowers', 'harvestTop', 'harvestOutside', 'stakeAndPrune', 'prunesInSpring', 'prunesAfterFlowering',
        'winterPruning', 'pruneAfterHarvest', 'cutSpentCanes', 'trimTwiceAYear', 'containItsRoots', 'mulchIt',
        'acidSoil', 'blueNeedsAcid', 'citrusFertilizer', 'noFertilizer', 'noNitrogen', 'letFoliageDieBack',
        'diesBackInWinter', 'summerOutdoors', 'winterIndoors', 'winterShelter', 'winterCool', 'coolerIsBetter',
        'hardyOutdoors', 'shelterFromWind', 'airFlow', 'spiderMiteWatch', 'slugWatch', 'boxMothWatch', 'sapIrritant',
        'veryToxic', 'sharpSpines', 'splitsAreNormal', 'dryToBloom',
      };
      final unknown = <String>{};
      for (final p in {...CareProfiles.bySpecies, ...CareProfiles.byGenus, ...CareProfiles.byFamily, ...CareProfiles.byCategory}.values) {
        unknown.addAll(p.tipKeys.where((k) => !known.contains(k)));
      }
      expect(unknown, isEmpty, reason: 'clés de conseils non traduites : $unknown');
    });
  });
}
