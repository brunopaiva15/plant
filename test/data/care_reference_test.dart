import 'package:flora/data/species/catalog_care_guide.dart';
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
/// On n'y teste aucune fréquence d'arrosage : elle dépend du pot, de la pièce
/// et de la saison, et un chiffre au jour près n'est pas un fait botanique.
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
      expect(p.soil, SoilKind.standard);
    });
  });
}
