import 'package:flora/core/utils/scientific_name.dart';
import 'package:flutter_test/flutter_test.dart';

/// Même vérité que tools/plant_dataset/tests/test_taxonomy.py : les deux
/// normaliseurs doivent rendre exactement les mêmes clés.
void main() {
  test('strips authorship', () {
    expect(normalizeScientificName('Monstera deliciosa Liebm.'), 'Monstera deliciosa');
    expect(normalizeScientificName('Citrus × limon (L.) Osbeck'), 'Citrus × limon');
    expect(normalizeScientificName('Ficus benjamina var. nuda (Miq.) Barrett'), 'Ficus benjamina var. nuda');
    expect(normalizeScientificName('Rosa canina L.'), 'Rosa canina');
    expect(normalizeScientificName('Monstera deliciosa DC.'), 'Monstera deliciosa');
  });

  test('hybrid sign, case and spacing', () {
    expect(normalizeScientificName('citrus x aurantium L.'), 'Citrus × aurantium');
    expect(normalizeScientificName('MONSTERA DELICIOSA'), 'Monstera deliciosa');
    expect(normalizeScientificName('  Ficus   elastica '), 'Ficus elastica');
    expect(normalizeScientificName('Quercus robur SUBSP. robur'), 'Quercus robur subsp. robur');
  });

  test('hybrid sign glued to the epithet is separated', () {
    // Même vérité que le normaliseur Python : les deux doivent rendre la
    // même clé, sinon la même plante devient deux classes du modèle.
    expect(normalizeScientificName('Citrus ×sinensis'), 'Citrus × sinensis');
    expect(normalizeScientificName('Mentha ×piperita L.'), 'Mentha × piperita');
    expect(internalPlantId('Citrus ×sinensis'), internalPlantId('Citrus × sinensis'));
    expect(internalPlantId('Citrus ×sinensis'), 'citrus-x-sinensis');
  });

  test('cultivar keeps its capitals', () {
    expect(normalizeScientificName("Rosa 'Peace'"), "Rosa 'Peace'");
  });

  test('genus only, empty and dangling hybrid sign', () {
    expect(normalizeScientificName('Monstera'), 'Monstera');
    expect(normalizeScientificName(''), '');
    expect(normalizeScientificName('Citrus ×'), 'Citrus');
  });

  test('internal id matches plants.csv', () {
    expect(internalPlantId('Monstera deliciosa Liebm.'), 'monstera-deliciosa');
    expect(internalPlantId('Citrus × limon'), 'citrus-x-limon');
    expect(internalPlantId('Ficus benjamina var. nuda'), 'ficus-benjamina-var-nuda');
    expect(internalPlantId(''), '');
  });
}
