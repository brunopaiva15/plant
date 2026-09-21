import 'package:flora/data/species/care_profiles.dart';
import 'package:flora/data/species/catalog_care_guide.dart';
import 'package:flora/data/species/species_catalog.dart';
import 'package:flora/domain/care/care_guide.dart';
import 'package:flora/domain/care/care_profile.dart';
import 'package:flora/domain/care/toxicity.dart';
import 'package:flora/domain/care/water_quality.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const guide = CatalogCareGuide();

  group('résolution', () {
    test('espèce exacte', () {
      final r = guide.resolve('Monstera deliciosa');
      expect(r.match, CareMatch.species);
      expect(r.toxicity.status, Toxicity.toxic);
    });

    test('genre quand l\'espèce est inconnue', () {
      final r = guide.resolve('Ficus sycomorus');
      expect(r.match, CareMatch.genus);
      expect(r.matchedOn, 'Ficus');
    });

    test('famille quand le genre est inconnu', () {
      final r = guide.resolve('Xanthosoma sagittifolium', family: 'Araceae');
      expect(r.match, CareMatch.family);
      expect(r.matchedOn, 'Araceae');
    });

    test('famille déduite du catalogue intégré sans indication', () {
      // Le cymbidium est au catalogue (Orchidaceae) mais pas dans les profils.
      final r = guide.resolve('Cymbidium hybridum');
      expect(r.match, CareMatch.family);
      expect(r.matchedOn, 'Orchidaceae');
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
      // Les deux ont leur fiche depuis le masque Indoor ; ce qui compte est
      // qu'elles ne disent pas la même chose de la soif.
      final snake = guide.resolve('Dracaena trifasciata');
      final marginata = guide.resolve('Dracaena marginata');
      expect(snake.match, CareMatch.species);
      expect(marginata.match, CareMatch.species);
      expect(snake.profile.wateringSummerDays, greaterThan(marginata.profile.wateringSummerDays));
      // Un genre répond toujours pour une espèce qui n'a pas sa fiche.
      expect(guide.resolve('Philodendron scandens').match, CareMatch.genus);
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

    test('au sud, la fenêtre affichée bascule de six mois', () {
      const w = MonthWindow(3, 9);
      expect(w.forHemisphere().from, 3, reason: 'au nord, elle ne bouge pas');
      expect(w.forHemisphere(south: true).from, 9);
      expect(w.forHemisphere(south: true).to, 3);
      // Une fenêtre à cheval sur l'hiver reste à cheval sur l'autre.
      expect(const MonthWindow(10, 3).forHemisphere(south: true).from, 4);
      expect(const MonthWindow(10, 3).forHemisphere(south: true).to, 9);
      expect(const MonthWindow(12, 2).forHemisphere(south: true).from, 6);
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
        'thirstyPlant', 'droopSignal', 'winterDry', 'winterRest', 'summerDormant',
        'noWaterWhileSplitting', 'orchidSoak', 'soakMount', 'dryUpsideDown', 'waterInTheCup', 'noSoil', 'greenRoots',
        'humidityTray', 'noDirectSun', 'toleratesLowLight', 'toleratesNeglect', 'brightForColor', 'rotatePot',
        'hatesMoving', 'wipeLeaves', 'trimToBushOut', 'monsteraSupport', 'shallowPot', 'likesBeingPotbound',
        'trunkStoresWater', 'pupsToShare', 'keepFlowerSpike', 'darkForRebloom', 'notADesertCactus', 'deadheadFlowers',
        'pinchFlowers', 'harvestTop', 'harvestOutside', 'stakeAndPrune', 'prunesInSpring', 'prunesAfterFlowering',
        'winterPruning', 'pruneAfterHarvest', 'cutSpentCanes', 'trimTwiceAYear', 'containItsRoots', 'mulchIt',
        'acidSoil', 'feedsOnInsects', 'blueNeedsAcid', 'citrusFertilizer', 'noFertilizer', 'noNitrogen', 'letFoliageDieBack',
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

    test('une floraison dit sa saison et ce qui la décide', () {
      // Sans condition, la carte n'apprend rien de plus que le calendrier ;
      // au-delà de trois, elle ne se lit plus. Une fenêtre lue à la RHS
      // n'invente pas de déclencheur : le calendrier suffit.
      final bad = <String>[];
      for (final entry in _allProfiles.entries) {
        final bloom = entry.value.bloom;
        if (bloom == null) continue;
        final sourced = entry.value.sourcing[CareField.bloom] == CareSource.rhs;
        if (bloom.triggers.isEmpty && !sourced) bad.add(entry.key);
        if (bloom.triggers.length > 3) bad.add(entry.key);
        if (bloom.triggers.toSet().length != bloom.triggers.length) bad.add(entry.key);
      }
      expect(bad, isEmpty, reason: 'floraisons sans condition, en double, ou trop bavardes : $bad');
    });

    test('les plages en pourcentage vont du plus sec au plus humide', () {
      final bad = <String>[];
      for (final entry in _allProfiles.entries) {
        final (min, max) = entry.value.humidityRange;
        if (min >= max || min < 10 || max > 95) bad.add(entry.key);
      }
      expect(bad, isEmpty, reason: 'plages d\'hygrométrie incohérentes : $bad');
    });

    test('une plage resserrée reste dans l\'esprit de son besoin', () {
      // Une fiche peut préciser « 50 à 70 % » là où « aime l'air humide »
      // dit 60 à 80 ; elle ne peut pas dire le contraire de son besoin.
      final bad = <String>[];
      for (final entry in _allProfiles.entries) {
        final p = entry.value;
        final (min, max) = p.humidityRange;
        final (low, high) = humidityPercentRange(p.humidity);
        if (max <= low - 10 || min >= high + 10) bad.add(entry.key);
      }
      expect(bad, isEmpty, reason: 'pourcentage en désaccord avec le besoin : $bad');
    });

    test('un repos a une plage de rangement qui tient debout', () {
      final bad = <String>[];
      for (final entry in _allProfiles.entries) {
        final rest = entry.value.dormancy;
        if (rest == null) continue;
        final min = rest.storeMinC;
        final max = rest.storeMaxC;
        if (min != null && max != null && min >= max) bad.add(entry.key);
        if (min != null && (min < -5 || min > 25)) bad.add(entry.key);
      }
      expect(bad, isEmpty, reason: 'rangements incohérents : $bad');
    });

    test('les plantes à réserves que le catalogue cite ont leur repos', () {
      // Le crocus et le caladium sont les deux cas que la fiche doit savoir
      // expliquer : le premier veut le froid, le second pourrit en dessous
      // de 15 °C. Une même carte, deux consignes opposées.
      final crocus = guide.resolve('Crocus vernus');
      final caladium = guide.resolve('Caladium bicolor');
      expect(crocus.match, CareMatch.genus);
      expect(caladium.match, CareMatch.genus);
      expect(crocus.profile.dormancy!.storeMinC, lessThan(caladium.profile.dormancy!.storeMinC!));
      expect(caladium.profile.damageBelowC, greaterThanOrEqualTo(15));
      // Le froid du crocus n'est pas dans son rangement d'été : c'est ce qui
      // déclenche sa floraison, et la fiche le dit là.
      expect(crocus.profile.bloom!.triggers, contains(BloomTrigger.chillBulb));
      expect(caladium.profile.bloom, isNull);
    });

    test('le rapport au pot ne contredit pas le rempotage', () {
      // Une annuelle ne se rempote pas : lui prêter un avis sur son pot
      // n'aurait rien à dire.
      final bad = [
        for (final e in _allProfiles.entries)
          if (e.value.repotEveryMonths == null && e.value.pot != PotPreference.steady) e.key,
      ];
      expect(bad, isEmpty, reason: 'avis sur le pot sans rempotage : $bad');
    });
  });

  group('l\'eau qui convient', () {
    test('une plante ordinaire boit l\'eau du robinet', () {
      expect(guide.resolve('Monstera deliciosa').profile.water, WaterTolerance.tolerant);
      expect(CareProfiles.fallback.water, WaterTolerance.tolerant);
    });

    test('les pointes qui brunissent : marantacées, dracaenas, palmiers, fougères', () {
      // Une fille de l'air se nourrit par ses feuilles : le calcaire la marque,
      // mais une eau sans minéraux ne lui apporte rien non plus.
      const sensibles = ['Calathea orbifolia', 'Dracaena marginata', 'Chamaedorea elegans', 'Nephrolepis exaltata', 'Spathiphyllum wallisii', 'Citrus × limon', 'Tillandsia ionantha'];
      for (final name in sensibles) {
        expect(guide.resolve(name).profile.water, WaterTolerance.sensitive, reason: name);
      }
    });

    test('la terre acide et les épiphytes ne supportent pas le calcaire', () {
      const stricts = ['Rhododendron simsii', 'Camellia japonica', 'Vaccinium corymbosum', 'Hydrangea macrophylla', 'Gardenia jasminoides'];
      for (final name in stricts) {
        expect(guide.resolve(name).profile.water, WaterTolerance.strict, reason: name);
      }
    });

    test('une carnivore ne boit pas le robinet, à quelque niveau qu’on la lise', () {
      // Le piège à mouches a sa fiche depuis le masque Indoor ; ce qu'elle
      // tient de Droseraceae — l'eau stricte, pas d'engrais — la suit. Une
      // fiche générique aurait conseillé l'eau du robinet.
      final dionaea = guide.resolve('Dionaea muscipula', family: 'Droseraceae');
      expect(dionaea.match, CareMatch.species);
      expect(dionaea.profile.water, WaterTolerance.strict);
      expect(waterVerdictFor(WaterKind.tap, dionaea.profile.water), WaterVerdict.avoid);
      // Elles se nourrissent de ce qu'elles attrapent : pas d'engrais.
      expect(dionaea.profile.fertilizingDays, isNull);
      expect(guide.resolve('Sarracenia purpurea', family: 'Sarraceniaceae').profile.water, WaterTolerance.strict);
      // Le népenthès, lui, n'a encore que sa famille : elle dit la même chose.
      final nepenthes = guide.resolve('Nepenthes alata', family: 'Nepenthaceae');
      expect(nepenthes.match, CareMatch.family);
      expect(nepenthes.profile.water, WaterTolerance.strict);
    });

    test('le sansevieria échappe à la sensibilité de son genre', () {
      expect(guide.resolve('Dracaena trifasciata').profile.water, WaterTolerance.tolerant);
      expect(guide.resolve('Dracaena marginata').profile.water, WaterTolerance.sensitive);
    });

    test('aucun conseil ne redit ce que la carte « Eau » porte', () {
      final profils = {...CareProfiles.bySpecies, ...CareProfiles.byGenus, ...CareProfiles.byFamily, ...CareProfiles.byCategory};
      for (final entry in profils.entries) {
        expect(entry.value.tipKeys, isNot(contains('filteredWater')), reason: entry.key);
        expect(entry.value.tipKeys, isNot(contains('rainwaterOnly')), reason: entry.key);
      }
    });

    test('le calcium est une question de nutrition, pas d\'eau', () {
      // Deux axes séparés : la ligne « Calcium » dit ce que l'engrais apporte,
      // la carte « Eau » ce que la plante supporte du calcaire versé. Rien ne
      // les lie, et le fluor a son propre axe encore.
      final sansevieria = CareProfiles.bySpecies['Dracaena trifasciata']!;
      expect(sansevieria.water, WaterTolerance.tolerant, reason: 'elle boit l\'eau du robinet');
      expect(sansevieria.fluorideSensitive, isTrue, reason: 'et brunit pourtant au fluor');
      // Une plante de terre acide évite le calcium pour son sol, pas pour son eau.
      final camellia = CareProfiles.byGenus['Camellia']!;
      expect(camellia.calciumNeed, CalciumNeed.avoid);
    });
  });
}

Map<String, CareProfile> get _allProfiles =>
    {...CareProfiles.bySpecies, ...CareProfiles.byGenus, ...CareProfiles.byFamily, ...CareProfiles.byCategory};
