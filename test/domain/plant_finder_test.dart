import 'package:flora/data/species/catalog_care_guide.dart';
import 'package:flora/data/species/species_catalog.dart';
import 'package:flora/domain/care/care_profile.dart';
import 'package:flora/domain/care/toxicity.dart';
import 'package:flora/domain/species/plant_finder.dart';
import 'package:flora/domain/species/species_info.dart';
import 'package:flora/domain/weather/region_climate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const guide = CatalogCareGuide();
  const finder = PlantFinder(entries: SpeciesCatalog.entries, guide: guide);

  CareProfile profileOf(FinderMatch m) => m.care.profile;

  group('les propositions', () {
    test('respectent la catégorie demandée', () {
      final results = finder.search(const FinderCriteria(categories: {SpeciesCategory.herb}));
      expect(results, isNotEmpty);
      expect(results.every((m) => m.entry.category == SpeciesCategory.herb), isTrue);
    });

    test('sont classées de la meilleure à la moins bonne', () {
      final results = finder.search(const FinderCriteria(spot: FinderSpot.brightRoom, effort: FinderEffort.normal));
      expect(results, isNotEmpty);
      for (var i = 1; i < results.length; i++) {
        expect(results[i - 1].score, greaterThanOrEqualTo(results[i].score));
      }
    });

    test('ne dépassent pas la limite demandée', () {
      expect(finder.search(const FinderCriteria(), limit: 3), hasLength(3));
    });

    test('évitent de répéter le même genre', () {
      final results = finder.search(const FinderCriteria(spot: FinderSpot.mediumRoom, effort: FinderEffort.forgiving));
      final genera = results.map((m) => m.entry.scientificName.split(' ').first).toList();
      expect(genera.toSet(), hasLength(genera.length));
    });

    test('portent la raison de leur présence', () {
      final results = finder.search(const FinderCriteria(spot: FinderSpot.darkRoom));
      expect(results, isNotEmpty);
      expect(results.every((m) => m.reasons.isNotEmpty), isTrue);
      expect(results.first.reasons, contains(FinderReason.lowLight));
    });
  });

  group('les critères éliminatoires', () {
    test('animaux ou enfants : uniquement des espèces non toxiques', () {
      final results = finder.search(const FinderCriteria(safeOnly: true), limit: 20);
      expect(results, isNotEmpty);
      expect(results.every((m) => m.care.toxicity.status == Toxicity.safe), isTrue);
      expect(results.every((m) => m.reasons.contains(FinderReason.safe)), isTrue);
      // Une promesse « sans risque » ne se lit pas sur une fiche de famille :
      // il faut un fait d'espèce ou de genre.
      expect(results.every((m) => m.care.toxicity.isSpecific), isTrue,
          reason: 'un fait hérité de la famille ou de la catégorie n\'est pas une preuve');
    });

    test('un coin sombre ne reçoit pas de plante de lumière vive', () {
      final results = finder.search(const FinderCriteria(spot: FinderSpot.darkRoom), limit: 20);
      expect(results, isNotEmpty);
      expect(results.every((m) => profileOf(m).lightFloor.index <= LightNeed.indirect.index), isTrue);
    });

    test('les autres réponses ne rachètent pas la lumière', () {
      // Qui oublie d'arroser et vit avec un chat : les succulentes cochent
      // les deux cases, mais aucune ne vit dans un coin sombre.
      final results = finder.search(const FinderCriteria(spot: FinderSpot.darkRoom, effort: FinderEffort.forgiving, safeOnly: true), limit: 20);
      expect(results, isNotEmpty);
      expect(results.every((m) => profileOf(m).lightFloor.index <= LightNeed.indirect.index), isTrue);
      expect(results.any((m) => m.entry.category == SpeciesCategory.succulent), isFalse);
    });

    test('dehors : seulement des espèces qui tiennent dehors', () {
      final results = finder.search(const FinderCriteria(spot: FinderSpot.outdoor), limit: 20);
      expect(results, isNotEmpty);
      expect(results.every((m) => profileOf(m).outdoorFriendly), isTrue);
    });

    test('qui oublie d\'arroser ne reçoit rien d\'exigeant', () {
      final results = finder.search(const FinderCriteria(effort: FinderEffort.forgiving), limit: 20);
      expect(results, isNotEmpty);
      expect(results.every((m) => profileOf(m).difficulty != CareDifficulty.demanding), isTrue);
      expect(results.every((m) => profileOf(m).humidity != HumidityNeed.high), isTrue);
    });

    test('des critères contradictoires ne rendent presque rien', () {
      // Un cactus dans un coin sombre : la seule réponse honnête du catalogue
      // est la scille du Cap, une succulente qui tolère l'ombre. Les autres
      // succulentes du catalogue veulent du soleil, et le moteur ne les
      // propose pas — c'est le sens de ce test.
      final results = finder.search(const FinderCriteria(spot: FinderSpot.darkRoom, categories: {SpeciesCategory.succulent}));
      expect(results.map((r) => r.entry.scientificName), ['Ledebouria socialis']);
    });
  });

  group('le resserrement ne vide pas l\'écran', () {
    // Le lot 0 a retiré la toxicité « sans danger » des profils de famille et
    // de catégorie. Le chercheur doit encore proposer, par des fiches espèce
    // ou genre : un trou se comble en écrivant les fiches qui manquent, jamais
    // en rouvrant l'héritage.
    for (final spot in FinderSpot.values) {
      for (final effort in FinderEffort.values) {
        test('$spot avec « $effort » propose encore', () {
          for (final safeOnly in [false, true]) {
            final results = finder.search(FinderCriteria(spot: spot, effort: effort, safeOnly: safeOnly), limit: 5);
            expect(results, isNotEmpty, reason: '$spot / $effort / safeOnly=$safeOnly');
          }
        });
      }
    }

    for (final category in SpeciesCategory.values) {
      test('la catégorie ${category.name} garde des propositions sans risque', () {
        final results = finder.search(FinderCriteria(categories: {category}, safeOnly: true), limit: 5);
        expect(results, isNotEmpty);
      });
    }
  });

  group('sans réponse', () {
    test('propose quand même, en commençant par les plus faciles', () {
      final results = finder.search(const FinderCriteria());
      expect(results, isNotEmpty);
      expect(results.every((m) => profileOf(m).difficulty != CareDifficulty.demanding), isTrue);
    });
  });

  group('la description pour l\'IA', () {
    test('reprend chaque critère, et le texte libre', () {
      const criteria = FinderCriteria(
        spot: FinderSpot.darkRoom,
        effort: FinderEffort.forgiving,
        safeOnly: true,
        categories: {SpeciesCategory.indoor},
        note: 'salle de bain sans fenêtre',
      );
      final described = criteria.describe();
      expect(described, contains('dark indoor corner'));
      expect(described, contains('forgets to water'));
      expect(described, contains('non-toxic'));
      expect(described, contains('indoor'));
      expect(described, contains('salle de bain sans fenêtre'));
    });

    test('sans critère, ne dit rien', () {
      expect(const FinderCriteria().describe(), isEmpty);
      expect(const FinderCriteria().isEmpty, isTrue);
    });
  });

  group('la région', () {
    // Un hiver de Lyon et un hiver de Palerme, sur le même balcon.
    const cold = RegionClimate(winterLowC: -12, summerHighC: 31, years: 3);
    const mild = RegionClimate(winterLowC: 6, summerHighC: 33, years: 3);

    List<String> namesFor(RegionClimate? region) => finder
        .search(FinderCriteria(spot: FinderSpot.outdoor, region: region), limit: 8)
        .map((m) => m.entry.scientificName)
        .toList();

    test('ne pèse que sur un emplacement extérieur', () {
      const indoor = FinderCriteria(spot: FinderSpot.brightRoom, region: cold);
      expect(indoor.outdoorRegion, isNull);
      expect(namesFor(null), isNotEmpty);
    });

    test('change le classement selon l\'hiver du lieu', () {
      expect(namesFor(cold), isNot(equals(namesFor(mild))),
          reason: 'un hiver à −12° et un hiver à 6° ne proposent pas les mêmes plantes');
    });

    bool isHardy(FinderMatch m) => (profileOf(m).winterMinC ?? 99) <= cold.winterLowC;

    test('remonte ce qui passe l\'hiver sur place', () {
      final results = finder.search(const FinderCriteria(spot: FinderSpot.outdoor, region: cold), limit: 8);
      expect(results, isNotEmpty);
      expect(results.where(isHardy), isNotEmpty, reason: 'au moins une rustique dans les huit premières');
      final firstTender = results.indexWhere((m) => !isHardy(m));
      final lastHardy = results.lastIndexWhere(isHardy);
      if (firstTender >= 0) expect(lastHardy, lessThan(firstTender), reason: 'les rustiques passent devant');
    });

    test('n\'écarte personne : un géranium se rentre, il reste une plante de balcon', () {
      // Le rang, pas l'exclusion : une plante frileuse passe après les
      // rustiques, mais reste proposée. On regarde donc toute la liste.
      final results = finder.search(const FinderCriteria(spot: FinderSpot.outdoor, region: cold), limit: 1000);
      expect(results.where((m) => !isHardy(m)), isNotEmpty, reason: 'le rang, pas l\'exclusion');
    });

    test('dit dans la raison si la plante reste dehors l\'hiver', () {
      final results = finder.search(const FinderCriteria(spot: FinderSpot.outdoor, region: cold), limit: 8);
      final hardy = results.firstWhere((m) => (profileOf(m).winterMinC ?? 99) <= cold.winterLowC);
      expect(hardy.reasons, contains(FinderReason.hardy));
      expect(hardy.reasons, isNot(contains(FinderReason.outdoor)), reason: 'la rusticité dit mieux que « tient dehors »');
    });

    test('sans région connue, la raison reste « tient dehors »', () {
      final results = finder.search(const FinderCriteria(spot: FinderSpot.outdoor), limit: 8);
      expect(results.any((m) => m.reasons.contains(FinderReason.outdoor)), isTrue);
      expect(results.any((m) => m.reasons.contains(FinderReason.hardy)), isFalse);
    });

    test('le climat part au prompt de l\'IA, la ville non', () {
      final text = const FinderCriteria(spot: FinderSpot.outdoor, region: cold).describe();
      expect(text, contains('zone'));
      expect(text, contains('-12 °C'));
      expect(const FinderCriteria(spot: FinderSpot.brightRoom, region: cold).describe(), isNot(contains('zone')));
    });
  });
}
