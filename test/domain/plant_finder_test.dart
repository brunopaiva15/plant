import 'package:flora/data/species/catalog_care_guide.dart';
import 'package:flora/data/species/species_catalog.dart';
import 'package:flora/domain/care/care_profile.dart';
import 'package:flora/domain/species/plant_finder.dart';
import 'package:flora/domain/species/species_info.dart';
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
      expect(results.every((m) => profileOf(m).toxicity == Toxicity.safe), isTrue);
      expect(results.every((m) => m.reasons.contains(FinderReason.safe)), isTrue);
    });

    test('un coin sombre ne reçoit pas de plante de lumière vive', () {
      final results = finder.search(const FinderCriteria(spot: FinderSpot.darkRoom), limit: 20);
      expect(results, isNotEmpty);
      expect(results.every((m) => profileOf(m).light.index <= LightNeed.indirect.index), isTrue);
    });

    test('les autres réponses ne rachètent pas la lumière', () {
      // Qui oublie d'arroser et vit avec un chat : les succulentes cochent
      // les deux cases, mais aucune ne vit dans un coin sombre.
      final results = finder.search(const FinderCriteria(spot: FinderSpot.darkRoom, effort: FinderEffort.forgiving, safeOnly: true), limit: 20);
      expect(results, isNotEmpty);
      expect(results.every((m) => profileOf(m).light.index <= LightNeed.indirect.index), isTrue);
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

    test('des critères contradictoires ne rendent rien plutôt que n\'importe quoi', () {
      // Un cactus dans un coin sombre : le catalogue n'a rien d'honnête à dire.
      final results = finder.search(const FinderCriteria(spot: FinderSpot.darkRoom, categories: {SpeciesCategory.succulent}));
      expect(results, isEmpty);
    });
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
}
