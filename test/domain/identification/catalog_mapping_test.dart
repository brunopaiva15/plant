import 'package:flora/app/providers.dart';
import 'package:flora/data/species/species_index.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('names from Pl@ntNet or a model map to the curated catalogue', () {
    expect(catalogPlantId('Monstera deliciosa Liebm.', null), 'monstera-deliciosa');
    expect(catalogPlantId('monstera deliciosa', null), 'monstera-deliciosa');
    expect(catalogPlantId('Plantus imaginarius', null), isNull);
    expect(catalogPlantId('', null), isNull);
  });

  test('the common name follows the language of the user', () {
    expect(catalogLookup('Monstera deliciosa Liebm.', null, 'fr')?.commonName, 'Monstera');
    expect(catalogLookup('Monstera deliciosa', null, 'en')?.commonName, 'Swiss cheese plant');
    expect(catalogLookup('Monstera deliciosa', null, 'xx')?.commonName, 'Swiss cheese plant', reason: 'langue inconnue : anglais');
    final index = SpeciesIndex.parse('Quercus petraea\tFagaceae\tChêne sessile\tSessile oak\tTraubeneiche\tRovere\n');
    expect(catalogLookup('Quercus petraea', index, 'de')?.commonName, 'Traubeneiche');
    expect(catalogLookup('Plantus imaginarius', index, 'fr'), isNull);
  });

  test('the extended index is consulted when it is loaded', () {
    final index = SpeciesIndex.parse('Quercus petraea\tFagaceae\tChêne sessile\tSessile oak\tTraubeneiche\tRovere\n');
    expect(catalogPlantId('Quercus petraea (Matt.) Liebl.', index), 'quercus-petraea');
    expect(catalogPlantId('Quercus petraea', null), isNull);
  });

  group('deux noms pour une plante', () {
    // Six plantes du catalogue sont la même sous deux noms (§ 12.14), et les
    // deux noms sont des classes du modèle : sans ce rattachement, la photo
    // décide laquelle des deux fiches l'utilisateur obtient.
    test('le synonyme trouve la fiche soignée, et le même identifiant', () {
      expect(catalogLookup('Sansevieria trifasciata', null, 'fr')?.commonName, 'Langue de belle-mère');
      expect(catalogPlantId('Sansevieria trifasciata', null), 'dracaena-trifasciata',
          reason: 'une seule plante, un seul identifiant, donc un seul profil de soin');
      expect(catalogPlantId('Dracaena trifasciata', null), 'dracaena-trifasciata');
    });

    test("l'auteur et la casse ne gênent pas le rattachement", () {
      expect(catalogPlantId('Sansevieria trifasciata Prain', null), 'dracaena-trifasciata');
      expect(catalogPlantId('sansevieria trifasciata', null), 'dracaena-trifasciata');
    });

    test('la flèche va vers ce que l\'app sait nommer, pas vers GBIF', () {
      // GBIF dit « Kroenleinia grusonii » et « Coleus scutellarioides ».
      // Suivre GBIF perdrait la fiche soignée du premier et, pour le second,
      // rendrait la plante introuvable : aucun des deux catalogues ne la
      // porte sous ce nom.
      expect(catalogLookup('Kroenleinia grusonii', null, 'fr')?.commonName, 'Coussin de belle-mère');
      final index = SpeciesIndex.parse(
          'Plectranthus scutellarioides\tLamiaceae\t\tcoleus\tBuntnessel\t\n');
      expect(catalogLookup('Coleus scutellarioides', index, 'en')?.commonName, 'coleus');
      expect(catalogPlantId('Coleus scutellarioides', index), 'plectranthus-scutellarioides');
    });

    test('une plante sans doublon traverse la table sans rien changer', () {
      expect(catalogPlantId('Monstera deliciosa', null), 'monstera-deliciosa');
      expect(catalogLookup('Monstera deliciosa', null, 'fr')?.commonName, 'Monstera');
    });
  });
}
