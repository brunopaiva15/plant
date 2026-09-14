import 'package:flora/data/species/genus_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

/// Les noms de genres servent à dire « un érable, espèce incertaine » plutôt
/// que « Acer, espèce incertaine ». Ce qui compte ici : n'en inventer aucun,
/// et les avoir dans les quatre langues quand on en a un.
void main() {
  test('chaque genre nommé l’est dans les quatre langues', () {
    for (final entry in GenusCatalog.names.entries) {
      expect(entry.value.keys.toSet(), {'fr', 'en', 'de', 'it'}, reason: entry.key);
      for (final name in entry.value.values) {
        expect(name.trim(), isNotEmpty, reason: entry.key);
      }
    }
  });

  test('les clés sont des genres capitalisés, jamais des binômes', () {
    for (final genus in GenusCatalog.names.keys) {
      expect(genus, isNot(contains(' ')), reason: genus);
      expect(genus[0], genus[0].toUpperCase(), reason: genus);
    }
  });

  test('un nom commun se lit dans la langue demandée', () {
    expect(GenusCatalog.commonName('Acer', 'fr'), 'Érable');
    expect(GenusCatalog.commonName('Acer', 'de'), 'Ahorn');
  });

  test('une langue inconnue retombe sur l’anglais plutôt que sur rien', () {
    expect(GenusCatalog.commonName('Acer', 'es'), 'Maple');
  });

  test('un genre sans nom commun n’en reçoit pas d’inventé', () {
    // Le nom scientifique s'affichera : il ne ment pas.
    expect(GenusCatalog.commonName('Gymnadenia', 'fr'), isNull);
    expect(GenusCatalog.commonName('', 'fr'), isNull);
  });
}
