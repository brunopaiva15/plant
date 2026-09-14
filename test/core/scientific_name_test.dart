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

  test('intergeneric hybrid: the sign opens the name, the genus follows', () {
    // × Fatshedera lizei se vend en jardinerie, et Pl@ntNet le rend sous ce
    // nom. Le signe de tête n'est pas le genre : tant qu'il passait pour
    // tel, la majuscule du mot suivant se lisait comme un nom d'auteur, le
    // nom se coupait là et ne rendait rien — donc aucune fiche d'entretien.
    expect(normalizeScientificName('× Fatshedera lizei'), '× Fatshedera lizei');
    expect(normalizeScientificName('×Fatshedera lizei'), '× Fatshedera lizei');
    expect(normalizeScientificName('x Fatshedera lizei'), '× Fatshedera lizei');
    expect(normalizeScientificName('×'), '');
    expect(internalPlantId('× Fatshedera lizei'), 'x-fatshedera-lizei');
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
