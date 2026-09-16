import 'package:flora/data/species/catalog_care_guide.dart';
import 'package:flora/data/species/toxicity_catalog.dart';
import 'package:flora/domain/care/toxicity.dart';
import 'package:flutter_test/flutter_test.dart';

/// La toxicité vit à part des profils d'entretien, avec sa propre cascade et
/// une règle asymétrique : au-dessus du genre, `toxic` et `mild` se
/// transmettent, `safe` non. Une famille peut se tromper du côté de la
/// prudence ; elle ne peut pas promettre l'innocuité.
void main() {
  const guide = CatalogCareGuide();

  group('l\'héritage de la toxicité', () {
    test('aucune famille ne déclare « sans danger », ni ne se tait', () {
      final fautifs = <String>[
        for (final e in ToxicityCatalog.byFamily.entries)
          if (e.value == Toxicity.safe) '${e.key} (safe)',
        for (final e in ToxicityCatalog.byFamily.entries)
          if (e.value == Toxicity.unknown) '${e.key} (unknown)',
      ];
      expect(fautifs, isEmpty, reason: 'une famille doit dire toxic ou mild : $fautifs');
    });

    test('le code ne rend jamais « sans danger » depuis une famille', () {
      // Même si une entrée famille redevenait `safe`, la résolution la
      // traiterait comme un silence : la promesse ne se délègue pas.
      for (final famille in ToxicityCatalog.byFamily.keys) {
        final fact = ToxicityCatalog.resolve('Espece inconnue', family: famille);
        expect(fact.status, isNot(Toxicity.safe), reason: famille);
      }
    });
  });

  group('les espèces dangereuses', () {
    // Des espèces dont la toxicité ne se discute pas. Leur genre porte
    // maintenant le fait, sans qu'il ait fallu lui inventer un entretien.
    const dangereuses = <String, String>{
      'Abrus precatorius': 'Fabaceae',
      'Laburnum anagyroides': 'Fabaceae',
      'Cytisus scoparius': 'Fabaceae',
      'Lupinus polyphyllus': 'Fabaceae',
      'Robinia pseudoacacia': 'Fabaceae',
      'Wisteria sinensis': 'Fabaceae',
      'Oenanthe aquatica': 'Apiaceae',
      'Oenanthe javanica': 'Apiaceae',
      'Oenanthe picata': 'Apiaceae',
      'Oenanthe pimpinelloides': 'Apiaceae',
      'Heracleum mantegazzianum': 'Apiaceae',
      'Senecio jacobaea': 'Asteraceae',
      'Senecio ovatus': 'Asteraceae',
      'Senecio vulgaris': 'Asteraceae',
      'Atropa bella-donna': 'Solanaceae',
      'Datura stramonium': 'Solanaceae',
      'Hyoscyamus niger': 'Solanaceae',
    };

    for (final MapEntry(key: nom, value: famille) in dangereuses.entries) {
      test('$nom est tenue pour toxique', () {
        final care = guide.resolve(nom, family: famille);
        expect(care.toxicity.status, isNot(Toxicity.safe), reason: '$nom résolu au niveau ${care.toxicity.level.name}');
        expect(care.toxicity.status, isNot(Toxicity.mild), reason: '$nom résolu au niveau ${care.toxicity.level.name}');
      });
    }
  });

  group('les corrections vérifiées', () {
    test('un genre corrigé vaut pour toutes ses espèces', () {
      // ASPCA : le citron, la vigne et le pommier sont toxiques.
      expect(guide.resolve('Citrus × limon', family: 'Rutaceae').toxicity.status, Toxicity.toxic);
      expect(guide.resolve('Citrus paradisi', family: 'Rutaceae').toxicity.status, Toxicity.toxic);
      expect(guide.resolve('Vitis vinifera', family: 'Vitaceae').toxicity.status, Toxicity.toxic);
      expect(guide.resolve('Malus domestica', family: 'Rosaceae').toxicity.status, Toxicity.toxic);
      // Le dahlia irrite plus qu'il n'empoisonne.
      expect(guide.resolve('Dahlia pinnata', family: 'Asteraceae').toxicity.status, Toxicity.mild);
    });

    test('l\'aloe vera quitte son « légèrement irritant »', () {
      final fact = guide.resolve('Aloe vera', family: 'Asphodelaceae').toxicity;
      expect(fact.status, Toxicity.toxic);
      expect(fact.source, 'ASPCA');
    });
  });

  group('la provenance', () {
    test('un genre dangereux se résout au niveau du genre', () {
      final fact = guide.resolve('Atropa bella-donna', family: 'Solanaceae').toxicity;
      expect(fact.status, Toxicity.toxic);
      expect(fact.level, ToxicitySource.genus);
      expect(fact.matchedOn, 'Atropa');
      expect(fact.isSpecific, isTrue);
    });

    test('sans rien, un fait inconnu et sans provenance', () {
      final fact = guide.resolve('Quelquechose inconnu').toxicity;
      expect(fact.status, Toxicity.unknown);
      expect(fact.level, ToxicitySource.none);
      expect(fact.isSpecific, isFalse);
    });
  });
}
