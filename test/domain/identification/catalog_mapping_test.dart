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
}
