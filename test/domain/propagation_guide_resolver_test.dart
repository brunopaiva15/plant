import 'package:flora/domain/care/care_profile.dart';
import 'package:flora/domain/cuttings/propagation_guide.dart';
import 'package:flora/domain/cuttings/propagation_guide_resolver.dart';
import 'package:flora/data/species/care_profiles.dart';
import 'package:flora/data/species/catalog_care_guide.dart';
import 'package:flutter_test/flutter_test.dart';

/// Le choix du guide : à partir de l'espèce, de la famille et de la fiche
/// d'entretien, quel geste montre-t-on ?
///
/// C'est la seule règle de l'application sur ce sujet : une monstera ne doit
/// jamais tomber sur une division, ni un spathiphyllum sur une bouture de
/// liane.

const _guide = CatalogCareGuide();

List<PropagationOption> _options(String species, {String? family}) {
  final care = _guide.resolve(species, family: family);
  return resolvePropagationOptions(profile: care.profile, scientificName: species, family: family ?? care.matchedOn);
}

PropagationGuideKind _kind(String species, {String? family}) => _options(species, family: family).first.kind;

void main() {
  group('le geste choisi', () {
    test('une liane à nœud pour les aracées grimpantes', () {
      expect(_kind('Monstera deliciosa'), PropagationGuideKind.stemNodeVine);
      expect(_kind('Epipremnum aureum'), PropagationGuideKind.stemNodeVine);
      expect(_kind('Philodendron hederaceum'), PropagationGuideKind.stemNodeVine);
      expect(_kind('Scindapsus pictus'), PropagationGuideKind.stemNodeVine);
    });

    test('une tige tendre pour les aromatiques', () {
      expect(_kind('Mentha spicata'), PropagationGuideKind.stemSoft);
      expect(_kind('Ocimum basilicum'), PropagationGuideKind.stemSoft);
    });

    test('une division pour les touffes', () {
      expect(_kind('Spathiphyllum wallisii'), PropagationGuideKind.division);
      expect(_kind('Festuca glauca', family: 'Poaceae'), PropagationGuideKind.division);
    });

    test('un rejet pour les rosettes et les plantules', () {
      expect(_kind('Pilea peperomioides'), PropagationGuideKind.offset);
      expect(_kind('Aloe vera'), PropagationGuideKind.offset);
      expect(_kind('Chlorophytum comosum'), PropagationGuideKind.offset);
    });

    test('un keiki pour les orchidées à hampe', () {
      expect(_kind('Phalaenopsis amabilis'), PropagationGuideKind.keiki);
      expect(_kind('Phalaenopsis equestris'), PropagationGuideKind.keiki,
          reason: 'une orchidée d\'un seul pied n\'a rien à diviser');
      // Le dendrobium, lui, se divise aussi : le choix reste ouvert.
      expect(_options('Dendrobium nobile').map((o) => o.kind),
          contains(PropagationGuideKind.keiki));
      // Le keiki s'installe dans le substrat de l'espèce, pas dans rien.
      expect(_options('Phalaenopsis amabilis').single.medium, RootingMedium.substrate);
    });

    test('une orchidée de pleine terre se divise, pas de rejet au pied', () {
      // Le genre n'est pas dans la liste des keikis : le geste du rejet au
      // pied ne se montre pas pour une orchidée.
      final options = _options('Ophrys sphegodes', family: 'Orchidaceae');
      expect(options.map((o) => o.kind), [PropagationGuideKind.division]);
    });

    test('un segment pour les cactus et les succulentes à cicatriser', () {
      expect(_kind('Schlumbergera truncata'), PropagationGuideKind.succulentSegment);
      expect(_kind('Opuntia microdasys', family: 'Cactaceae'), PropagationGuideKind.succulentSegment);
      expect(_kind('Crassula ovata'), PropagationGuideKind.succulentSegment);
    });

    test('une bouture de feuille reste disponible pour le sansevieria', () {
      final options = _options('Dracaena trifasciata');
      expect(options.map((o) => o.kind), [PropagationGuideKind.division, PropagationGuideKind.leafCutting]);
      // La division vient en premier : c'est la méthode conseillée.
      expect(options.first.method, Propagation.division);
    });

    test('le zamioculcas propose les deux mêmes gestes', () {
      expect(_options('Zamioculcas zamiifolia').map((o) => o.kind),
          [PropagationGuideKind.division, PropagationGuideKind.leafCutting]);
    });
  });

  group('le choix entre plusieurs méthodes', () {
    test("une seule façon connue n'ouvre pas de choix", () {
      expect(_options('Monstera deliciosa'), hasLength(1));
      expect(_options('Spathiphyllum wallisii'), hasLength(1));
    });

    test('deux gestes différents en proposent deux', () {
      expect(_options('Dracaena trifasciata').length, greaterThan(1));
      expect(_options('Chlorophytum comosum').length, greaterThan(1));
    });

    test('deux méthodes qui montrent le même geste ne comptent que pour une', () {
      // Un cactus se bouture par segment et fait des rejets : les deux
      // aboutissent au même geste, inutile de le proposer deux fois.
      const cactus = CareProfile(
        wateringSummerDays: 14,
        wateringWinterDays: 40,
        light: LightNeed.someSun,
        humidity: HumidityNeed.low,
        difficulty: CareDifficulty.easy,
        soil: SoilKind.cactus,
        propagation: [Propagation.stemCutting, Propagation.offsets],
      );
      final options = resolvePropagationOptions(profile: cactus, scientificName: 'Cereus repandus', family: 'Cactaceae');
      expect(options, hasLength(1));
      expect(options.single.kind, PropagationGuideKind.succulentSegment);
    });

    test('jamais plus de trois choix : au-delà, ce serait une fiche', () {
      const tout = CareProfile(
        wateringSummerDays: 7,
        wateringWinterDays: 12,
        light: LightNeed.brightIndirect,
        humidity: HumidityNeed.average,
        difficulty: CareDifficulty.easy,
        soil: SoilKind.standard,
        repotEveryMonths: 24,
        propagation: [Propagation.stemCutting, Propagation.leafCutting, Propagation.division, Propagation.offsets],
      );
      expect(resolvePropagationOptions(profile: tout).length, lessThanOrEqualTo(3));
    });
  });

  group('les cas de repli', () {
    test('une fiche qui ne connaît que le semis rend quand même un guide', () {
      const semis = CareProfile(
        wateringSummerDays: 5,
        wateringWinterDays: 10,
        light: LightNeed.fullSun,
        humidity: HumidityNeed.average,
        difficulty: CareDifficulty.easy,
        soil: SoilKind.rich,
        propagation: [Propagation.seed],
      );
      final options = resolvePropagationOptions(profile: semis, scientificName: 'Solanum lycopersicum');
      expect(options, hasLength(1));
      // Pas de rempotage prévu : c'est une annuelle, donc une tige tendre.
      expect(options.single.kind, PropagationGuideKind.stemSoft);
    });

    test('une espèce inconnue retombe sur le profil générique, jamais sur rien', () {
      final options = _options('Quercus robur');
      expect(options, isNotEmpty);
      expect(propagationStepIds[options.first.kind], isNotEmpty);
    });

    test('le repli suit le port de la plante, pas une règle unique', () {
      const semis = CareProfile(
        wateringSummerDays: 7,
        wateringWinterDays: 14,
        light: LightNeed.brightIndirect,
        humidity: HumidityNeed.average,
        difficulty: CareDifficulty.easy,
        soil: SoilKind.standard,
        repotEveryMonths: 24,
        propagation: [Propagation.seed],
      );
      // Une plante à rosette part par son rejet, une graminée par sa touffe.
      expect(resolvePropagationOptions(profile: semis, scientificName: 'Haworthia fasciata').single.kind,
          PropagationGuideKind.offset);
      expect(resolvePropagationOptions(profile: semis, scientificName: 'Carex morrowii', family: 'Cyperaceae').single.kind,
          PropagationGuideKind.division);
    });

    test('le marcottage seul se montre comme une bouture à nœud', () {
      const marcotte = CareProfile(
        wateringSummerDays: 7,
        wateringWinterDays: 14,
        light: LightNeed.brightIndirect,
        humidity: HumidityNeed.average,
        difficulty: CareDifficulty.medium,
        soil: SoilKind.standard,
        repotEveryMonths: 24,
        propagation: [Propagation.layering],
      );
      expect(resolvePropagationOptions(profile: marcotte).single.kind, PropagationGuideKind.stemNodeVine);
    });

    test('le marcottage accompagné ne fait pas doublon avec la bouture', () {
      final options = _options('Ficus lyrata');
      expect(options, hasLength(1));
      expect(options.single.kind, PropagationGuideKind.stemNodeVine);
    });
  });

  group("le milieu d'enracinement", () {
    test("« water » n'est pas une méthode, c'est un milieu", () {
      final monstera = CareProfiles.bySpecies['Monstera deliciosa']!;
      expect(monstera.propagation, contains(Propagation.water));
      expect(monstera.propagationMethods, [Propagation.stemCutting]);
      expect(monstera.rootingMedium, RootingMedium.water);
    });

    test('une succulente ne trempe pas', () {
      expect(CareProfiles.byGenus['Crassula']!.rootingMedium, RootingMedium.substrate);
    });

    test("une division n'a rien à enraciner", () {
      expect(CareProfiles.bySpecies['Spathiphyllum wallisii']!.rootingMedium, RootingMedium.none);
      expect(_options('Spathiphyllum wallisii').single.medium, RootingMedium.none);
    });

    test('une bouture de liane part dans l\'eau', () {
      expect(_options('Monstera deliciosa').single.medium, RootingMedium.water);
    });
  });

  test('le genre se lit sur le premier mot', () {
    expect(genusOf('Monstera deliciosa'), 'monstera');
    expect(genusOf('  Aloe   vera '), 'aloe');
    expect(genusOf(''), isNull);
    expect(genusOf(null), isNull);
  });
}
