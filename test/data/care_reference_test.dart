import 'package:flora/data/species/catalog_care_guide.dart';
import 'package:flora/data/species/care_profiles.dart';
import 'package:flora/domain/care/care_guide.dart';
import 'package:flora/domain/care/care_profile.dart';
import 'package:flora/domain/care/toxicity.dart';
import 'package:flutter_test/flutter_test.dart';

/// Des faits botaniques que personne ne discute, la source en commentaire.
///
/// Les tests structurels vérifient qu'une fiche tient debout — résolution,
/// cohérence été/hiver, plages valides, traductions —, jamais qu'elle est
/// vraie. Une valeur fausse mais bien formée leur échappe. Cette petite suite
/// de références la rattrape, sur ce qui ne bouge pas : toxicité, terrain
/// acide, carnivorie, rusticité grossière.
///
/// Un chiffre d'arrosage au jour près n'est pas un fait botanique : on y
/// vérifie seulement la règle de séchage, et que les jours en sont dérivés.
void main() {
  const guide = CatalogCareGuide();

  ResolvedCare care(String name, String family) => guide.resolve(name, family: family);

  void expectsToxicity(String name, String family, Toxicity expected) {
    final fact = care(name, family).toxicity;
    expect(fact.status, expected, reason: '$name : ${fact.status.name} au niveau ${fact.level.name}');
  }

  group('toxicité', () {
    // Source : ASPCA Animal Poison Control, « Toxic and Non-Toxic Plants ».
    const dangereuses = <String, String>{
      'Atropa bella-donna': 'Solanaceae',
      'Aconitum napellus': 'Ranunculaceae',
      'Conium maculatum': 'Apiaceae',
      'Datura stramonium': 'Solanaceae',
      'Digitalis purpurea': 'Plantaginaceae',
      'Nerium oleander': 'Apocynaceae',
      'Ricinus communis': 'Euphorbiaceae',
      'Taxus baccata': 'Taxaceae',
      'Wisteria sinensis': 'Fabaceae',
    };
    for (final MapEntry(key: name, value: family) in dangereuses.entries) {
      test('$name est toxique', () => expectsToxicity(name, family, Toxicity.toxic));
    }

    const toxiquesCourantes = <String, String>{
      'Aloe vera': 'Asphodelaceae',
      'Buxus sempervirens': 'Buxaceae',
      'Citrus × limon': 'Rutaceae',
      'Dieffenbachia seguine': 'Araceae',
      'Epipremnum aureum': 'Araceae',
      'Hedera helix': 'Araliaceae',
      'Kalanchoe blossfeldiana': 'Crassulaceae',
      'Malus domestica': 'Rosaceae',
      'Monstera deliciosa': 'Araceae',
      'Narcissus pseudonarcissus': 'Amaryllidaceae',
      'Rhododendron simsii': 'Ericaceae',
      'Spathiphyllum wallisii': 'Araceae',
      'Vitis vinifera': 'Vitaceae',
    };
    for (final MapEntry(key: name, value: family) in toxiquesCourantes.entries) {
      test('$name est toxique', () => expectsToxicity(name, family, Toxicity.toxic));
    }

    const sansDanger = <String, String>{
      'Camellia japonica': 'Theaceae',
      'Chlorophytum comosum': 'Asparagaceae',
      'Echeveria elegans': 'Crassulaceae',
      'Goeppertia orbifolia': 'Marantaceae',
      'Hoya carnosa': 'Apocynaceae',
      'Lavandula angustifolia': 'Lamiaceae',
      'Maranta leuconeura': 'Marantaceae',
      'Nephrolepis exaltata': 'Nephrolepidaceae',
      'Ocimum basilicum': 'Lamiaceae',
      'Olea europaea': 'Oleaceae',
      'Phalaenopsis amabilis': 'Orchidaceae',
      'Pilea peperomioides': 'Urticaceae',
      'Saintpaulia ionantha': 'Gesneriaceae',
    };
    for (final MapEntry(key: name, value: family) in sansDanger.entries) {
      test('$name n\'est pas toxique', () => expectsToxicity(name, family, Toxicity.safe));
    }
  });

  group('terrain acide', () {
    // Source : RHS, fiches de culture — terre de bruyère et eau sans calcaire.
    const acidophiles = <String, String>{
      'Camellia japonica': 'Theaceae',
      'Gardenia jasminoides': 'Rubiaceae',
      'Hydrangea macrophylla': 'Hydrangeaceae',
      'Rhododendron simsii': 'Ericaceae',
      'Vaccinium corymbosum': 'Ericaceae',
    };
    for (final MapEntry(key: name, value: family) in acidophiles.entries) {
      test('$name veut une terre acide', () {
        final p = care(name, family).profile;
        expect(p.soil, SoilKind.acidic);
        expect(p.water, WaterTolerance.strict);
        expect(p.calciumNeed, CalciumNeed.avoid);
      });
    }
  });

  group('plantes carnivores', () {
    // Source : RHS — sol pauvre et acide, jamais d'engrais.
    const carnivores = <String, String>{
      'Dionaea muscipula': 'Droseraceae',
      'Nepenthes alata': 'Nepenthaceae',
      'Sarracenia purpurea': 'Sarraceniaceae',
    };
    for (final MapEntry(key: name, value: family) in carnivores.entries) {
      test('$name ne se fertilise pas', () {
        final p = care(name, family).profile;
        expect(p.fertilizingDays, isNull);
        expect(p.water, WaterTolerance.strict);
      });
    }
  });

  group('succulentes', () {
    // Source : RHS — substrat minéral, air sec.
    const succulentes = <String, String>{
      'Aloe vera': 'Asphodelaceae',
      'Echeveria elegans': 'Crassulaceae',
      'Kalanchoe blossfeldiana': 'Crassulaceae',
    };
    for (final MapEntry(key: name, value: family) in succulentes.entries) {
      test('$name vit en substrat minéral', () {
        final p = care(name, family).profile;
        expect(p.soil, SoilKind.cactus);
        expect(p.humidity, HumidityNeed.low);
      });
    }
  });

  group('rusticité, grossièrement', () {
    // Source : RHS, zone de rusticité — on ne teste pas le degré exact.
    const dehors = <String, String>{
      'Buxus sempervirens': 'Buxaceae',
      'Lavandula angustifolia': 'Lamiaceae',
      'Malus domestica': 'Rosaceae',
      'Taxus baccata': 'Taxaceae',
      'Vitis vinifera': 'Vitaceae',
    };
    for (final MapEntry(key: name, value: family) in dehors.entries) {
      test('$name passe l\'hiver dehors', () => expect(care(name, family).profile.frostHardy, isTrue));
    }

    const aRentrer = <String, String>{
      'Aloe vera': 'Asphodelaceae',
      'Citrus × limon': 'Rutaceae',
      'Dieffenbachia seguine': 'Araceae',
      'Monstera deliciosa': 'Araceae',
      'Phalaenopsis amabilis': 'Orchidaceae',
    };
    for (final MapEntry(key: name, value: family) in aRentrer.entries) {
      test('$name ne passe pas l\'hiver dehors', () => expect(care(name, family).profile.frostHardy, isFalse));
    }
  });

  group('épiphytes', () {
    const epiphytes = <String, String>{
      'Phalaenopsis amabilis': 'Orchidaceae',
      'Platycerium bifurcatum': 'Polypodiaceae',
      'Tillandsia ionantha': 'Bromeliaceae',
    };
    for (final MapEntry(key: name, value: family) in epiphytes.entries) {
      test('$name vit sur un support', () {
        expect(care(name, family).profile.growthMedium, GrowthMedium.epiphytic);
      });
    }

    test('une tillandsie ne pousse dans aucun substrat', () {
      expect(care('Tillandsia ionantha', 'Bromeliaceae').profile.soil, SoilKind.none);
    });

    test('un nymphéa vit dans l\'eau, pas dans un terreau', () {
      final p = care('Nymphaea alba', 'Nymphaeaceae').profile;
      expect(p.growthMedium, GrowthMedium.aquatic);
      expect(p.soil, SoilKind.none);
      expect(p.inWater, SoilFreeFit.yes);
    });

    test('une plante de terreau reste terrestre', () {
      final p = care('Pilea peperomioides', 'Urticaceae').profile;
      expect(p.growthMedium, GrowthMedium.terrestrial);
      expect(p.soil, isNot(SoilKind.none));
    });
  });

  group('substrat, d\'après la RHS', () {
    test('Camellia : terre de bruyère et eau stricte', () {
      final p = care('Camellia japonica', 'Theaceae').profile;
      expect(p.soil, SoilKind.acidic);
      expect(p.water, WaterTolerance.strict);
      expect(p.sourcing[CareField.soil], CareSource.rhs);
      expect(p.sourcing[CareField.water], CareSource.rhs);
    });

    test('Aloe vera : mélange cactus, bien drainé', () {
      final p = care('Aloe vera', 'Asphodelaceae').profile;
      expect(p.soil, SoilKind.cactus);
      expect(p.sourcing[CareField.soil], CareSource.rhs);
    });

    test('un phalaenopsis garde son écorce : le loam RHS n\'est pas le pot', () {
      final p = care('Phalaenopsis amabilis', 'Orchidaceae').profile;
      expect(p.soil, SoilKind.orchid);
      expect(p.sourcing[CareField.soil], isNull);
    });

    test('une tomate n\'est pas calcifuge', () {
      final p = care('Solanum lycopersicum', 'Solanaceae').profile;
      expect(p.soil, isNot(SoilKind.acidic));
      expect(p.water, isNot(WaterTolerance.strict));
    });
  });

  group('problèmes, d\'après la RHS', () {
    test('Monstera : cochenilles et araignées, pas la liste tropicale entière', () {
      final p = care('Monstera deliciosa', 'Araceae').profile;
      expect(p.issues, containsAll([CommonIssue.overwatering, CommonIssue.spiderMites, CommonIssue.scale]));
      expect(p.issues, isNot(contains(CommonIssue.thrips)));
      expect(p.issues, isNot(contains(CommonIssue.leafSpot)));
      expect(p.sourcing[CareField.issues], CareSource.rhs);
    });

    test('une tomate n\'a plus les pucerons collés à tout le monde', () {
      final p = care('Solanum lycopersicum', 'Solanaceae').profile;
      expect(p.issues, contains(CommonIssue.whitefly));
      expect(p.issues, contains(CommonIssue.blossomEndRot));
      expect(p.issues, isNot(contains(CommonIssue.aphids)));
      expect(p.sourcing[CareField.issues], CareSource.rhs);
    });

    test('Aloe vera : cochenilles que la RHS nomme', () {
      final p = care('Aloe vera', 'Asphodelaceae').profile;
      expect(p.issues, containsAll([CommonIssue.scale, CommonIssue.mealybugs, CommonIssue.overwatering]));
      expect(p.sourcing[CareField.issues], CareSource.rhs);
    });
  });

  group('lumière, d\'après la RHS', () {
    test('Monstera deliciosa : mi-ombre', () {
      final p = care('Monstera deliciosa', 'Araceae').profile;
      expect(p.light, LightNeed.brightIndirect);
      expect(p.sourcing[CareField.light], CareSource.rhs);
    });

    test('la sansevière veut du soleil et tient à l\'ombre', () {
      final p = care('Dracaena trifasciata', 'Asparagaceae').profile;
      expect(p.light, LightNeed.someSun);
      expect(p.lightTolerance, LightNeed.lowLight);
      expect(p.lightFloor, LightNeed.lowLight);
      expect(p.sourcing[CareField.light], CareSource.rhs);
    });

    test('la scille du Cap : soleil, tient à la lumière indirecte', () {
      final p = care('Ledebouria socialis', 'Asparagaceae').profile;
      expect(p.light, LightNeed.fullSun);
      expect(p.lightFloor, LightNeed.indirect);
      expect(p.sourcing[CareField.light], CareSource.rhs);
    });
  });

  group('multiplication, d\'après la RHS', () {
    test('Monstera : bouture de tige et semis, l\'eau reste le milieu', () {
      final p = care('Monstera deliciosa', 'Araceae').profile;
      expect(p.propagationMethods, [Propagation.stemCutting, Propagation.seed]);
      expect(p.propagation, contains(Propagation.water));
      expect(p.sourcing[CareField.propagation], CareSource.rhs);
    });

    test('une tomate se sème', () {
      final p = care('Solanum lycopersicum', 'Solanaceae').profile;
      expect(p.propagationMethods, [Propagation.seed]);
      expect(p.sourcing[CareField.propagation], CareSource.rhs);
    });

    test('Aloe vera : rejets et semis', () {
      final p = care('Aloe vera', 'Asphodelaceae').profile;
      expect(p.propagationMethods, containsAll([Propagation.offsets, Propagation.seed]));
      expect(p.sourcing[CareField.propagation], CareSource.rhs);
    });

    test('le zamioculcas se bouture en feuille', () {
      final p = care('Zamioculcas zamiifolia', 'Araceae').profile;
      expect(p.propagationMethods, [Propagation.leafCutting]);
      expect(p.sourcing[CareField.propagation], CareSource.rhs);
    });
  });

  group('floraison, d\'après la RHS', () {
    test('Lavande : été, on garde le rabattage', () {
      final p = care('Lavandula angustifolia', 'Lamiaceae').profile;
      expect(p.bloom!.window.from, 6);
      expect(p.bloom!.window.to, 8);
      expect(p.bloom!.triggers, contains(BloomTrigger.deadhead));
      expect(p.sourcing[CareField.bloom], CareSource.rhs);
    });

    test('Monstera : printemps-été, toujours hors pot', () {
      final p = care('Monstera deliciosa', 'Araceae').profile;
      expect(p.bloom!.window.from, 3);
      expect(p.bloom!.window.to, 8);
      expect(p.bloom!.indoors, isFalse);
      expect(p.bloom!.triggers, [BloomTrigger.maturity]);
      expect(p.sourcing[CareField.bloom], CareSource.rhs);
    });

    test('Poinsettia : hiver', () {
      final p = care('Euphorbia pulcherrima', 'Euphorbiaceae').profile;
      expect(p.bloom!.window.from, 12);
      expect(p.bloom!.window.to, 2);
      expect(p.sourcing[CareField.bloom], CareSource.rhs);
    });

    test('Schlumbergera : automne-hiver, jours courts conservés', () {
      final p = care('Schlumbergera truncata', 'Cactaceae').profile;
      expect(p.bloom!.window.from, 9);
      expect(p.bloom!.window.to, 2);
      expect(p.bloom!.triggers, contains(BloomTrigger.shortDays));
      expect(p.sourcing[CareField.bloom], CareSource.rhs);
    });
  });

  group('humidité, d\'après l\'habitat', () {
    test('Monstera : forêt humide, plage chiffrée conservée', () {
      final p = care('Monstera deliciosa', 'Araceae').profile;
      expect(p.humidity, HumidityNeed.high);
      expect(p.humidityIdealMin, 55);
      expect(p.humidityIdealMax, 75);
      expect(p.sourcing[CareField.humidity], CareSource.habitat);
    });

    test('Lavande : bassin méditerranéen', () {
      final p = care('Lavandula angustifolia', 'Lamiaceae').profile;
      expect(p.humidity, HumidityNeed.low);
      expect(p.sourcing[CareField.humidity], CareSource.habitat);
    });

    test('Schlumbergera : forêt humide, pas un cactus du désert', () {
      final p = care('Schlumbergera truncata', 'Cactaceae').profile;
      expect(p.humidity, HumidityNeed.high);
      expect(p.bloom!.triggers, contains(BloomTrigger.shortDays));
      expect(p.sourcing[CareField.humidity], CareSource.habitat);
    });

    test('une famille n\'est pas un taxon', () {
      final p = CareProfiles.byFamily['Orchidaceae']!;
      expect(p.humidity, HumidityNeed.high);
      expect(p.sourcing[CareField.humidity], isNull);
    });
  });

  group('arrosage, dérivé de la règle de séchage', () {
    test('Aloe : substrat cactus, sèche à fond', () {
      final p = care('Aloe vera', 'Asphodelaceae').profile;
      expect(p.dryDown, DryDown.fullyDry);
      expect(p.wateringSummerDays, 30);
      expect(p.wateringWinterDays, 75);
      expect(p.sourcing[CareField.watering], CareSource.derived);
    });

    test('Monstera : quart supérieur, 7 et 14 conservés', () {
      final p = care('Monstera deliciosa', 'Araceae').profile;
      expect(p.dryDown, DryDown.topQuarterDry);
      expect(p.wateringSummerDays, 7);
      expect(p.wateringWinterDays, 14);
      expect(p.sourcing[CareField.watering], CareSource.derived);
    });

    test('jacinthe : l\'hiver reste la saison active', () {
      final p = care('Hyacinthus orientalis', 'Asparagaceae').profile;
      expect(p.dryDown, DryDown.halfDry);
      expect(p.wateringWinterDays, lessThan(p.wateringSummerDays));
      expect(p.sourcing[CareField.watering], CareSource.derived);
    });

    test('basilic : terre drainante n\'est pas un arrosage rare', () {
      final p = care('Ocimum basilicum', 'Lamiaceae').profile;
      expect(p.soil, SoilKind.draining);
      expect(p.dryDown, DryDown.alwaysMoist);
      expect(p.wateringSummerDays, 2);
      expect(p.sourcing[CareField.watering], CareSource.derived);
    });

    test('Schlumbergera : épiphyte, le substrat ne sèche pas à fond', () {
      final p = care('Schlumbergera truncata', 'Cactaceae').profile;
      expect(p.soil, SoilKind.draining);
      expect(p.dryDown, DryDown.halfDry);
      expect(p.sourcing[CareField.watering], CareSource.derived);
    });

    test('tillandsie : pas de substrat à faire sécher', () {
      final p = CareProfiles.byGenus['Tillandsia']!;
      expect(p.soil, SoilKind.none);
      expect(p.dryDown, isNull);
      expect(p.sourcing[CareField.watering], isNull);
    });
  });

  group('engrais et rempotage, dérivés de la maturité RHS', () {
    test('Aloe : cactus, 60 jours, le pot étroit n\'accélère pas', () {
      final p = care('Aloe vera', 'Asphodelaceae').profile;
      expect(p.fertilizingDays, 60);
      expect(p.repotEveryMonths, 30);
      expect(p.sourcing[CareField.feeding], CareSource.derived);
      expect(p.sourcing[CareField.repotting], CareSource.derived);
    });

    test('basilic : annuel, 21 jours, pas de rempotage', () {
      final p = care('Ocimum basilicum', 'Lamiaceae').profile;
      expect(p.fertilizingDays, 21);
      expect(p.repotEveryMonths, isNull);
      expect(p.sourcing[CareField.feeding], CareSource.derived);
      expect(p.sourcing[CareField.repotting], CareSource.derived);
    });

    test('tomate : nécrose apicale, 14 jours, pas de rempotage', () {
      final p = care('Solanum lycopersicum', 'Solanaceae').profile;
      expect(p.fertilizingDays, 14);
      expect(p.fertilizerKind, FertilizerKind.vegetable);
      expect(p.repotEveryMonths, isNull);
      expect(p.sourcing[CareField.feeding], CareSource.derived);
    });

    test('lavande : pas d\'engrais, fenêtre intacte absente', () {
      final p = care('Lavandula angustifolia', 'Lamiaceae').profile;
      expect(p.fertilizingDays, isNull);
      expect(p.sourcing[CareField.feeding], CareSource.derived);
    });

    test('phalaenopsis : orchidée, fenêtre conservée', () {
      final p = care('Phalaenopsis amabilis', 'Orchidaceae').profile;
      expect(p.soil, SoilKind.orchid);
      expect(p.fertilizingDays, lessThanOrEqualTo(30));
      expect(p.fertilizingWindow.from, 2);
      expect(p.fertilizingWindow.to, 10);
      expect(p.sourcing[CareField.feeding], CareSource.derived);
    });

    test('Monstera : en pot, 30 jours, pas la famine de jardin', () {
      final p = care('Monstera deliciosa', 'Araceae').profile;
      expect(p.fertilizingDays, 30);
      expect(p.repotEveryMonths, 36);
      expect(p.sourcing[CareField.feeding], CareSource.derived);
      expect(p.sourcing[CareField.repotting], CareSource.derived);
    });

    test('citronnier : en pot, 30 jours, type d\'engrais conservé', () {
      final p = care('Citrus × limon', 'Rutaceae').profile;
      expect(p.fertilizingDays, 30);
      expect(p.fertilizerKind, FertilizerKind.citrus);
      expect(p.fertilizingWindow.from, 3);
      expect(p.fertilizingWindow.to, 9);
      expect(p.sourcing[CareField.feeding], CareSource.derived);
    });
  });

  group('familles, ancrées sur une espèce représentative', () {
    test('Orchidaceae : le keiki reste hors source, les nuits fraîches restent', () {
      final p = CareProfiles.byFamily['Orchidaceae']!;
      expect(p.sourcing[CareField.propagation], isNull);
      expect(p.bloom!.triggers, contains(BloomTrigger.coolNights));
      expect(p.humidityIdealMin, 50);
      expect(p.sourcing[CareField.feeding], CareSource.derived);
      expect(p.sourcing[CareField.watering], CareSource.derived);
    });

    test('Cactaceae : pas l\'air ni l\'hiver d\'un cactus de Noël', () {
      final p = CareProfiles.byFamily['Cactaceae']!;
      expect(p.humidity, HumidityNeed.low);
      expect(p.sourcing[CareField.humidity], isNull);
      expect(p.bloom!.window.from, 4);
      expect(p.bloom!.window.to, 6);
      expect(p.sourcing[CareField.bloom], isNull);
      expect(p.dryDown, DryDown.fullyDry);
      expect(p.sourcing[CareField.watering], CareSource.derived);
    });

    test('Araceae : humidité de forêt, via Monstera', () {
      final p = CareProfiles.byFamily['Araceae']!;
      expect(p.humidity, HumidityNeed.high);
      expect(p.sourcing[CareField.humidity], CareSource.habitat);
      expect(p.propagation, contains(Propagation.water));
    });

    test('Lamiaceae : un basilic annuel n\'efface pas une famille rustique', () {
      final p = CareProfiles.byFamily['Lamiaceae']!;
      expect(p.sourcing[CareField.repotting], isNull);
      expect(p.sourcing[CareField.feeding], CareSource.derived);
    });

    test('sans représentant RHS, rien de plus n\'est sourcé', () {
      final p = CareProfiles.byFamily['Acoraceae']!;
      expect(p.sourcing[CareField.watering], isNull);
      expect(p.sourcing[CareField.feeding], isNull);
    });
  });
}
