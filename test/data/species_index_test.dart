import 'package:flora/core/utils/search_text.dart';
import 'package:flora/data/species/species_index.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Un extrait fidèle du vrai format : nom, famille, fr, en, de, it, autres.
  const tsv = 'Leontopodium nivale\tAsteraceae\tedelweiss\tedelweiss\tAlpen-Edelweiß\tstella alpina\t'
      'Édelweiss~Edelweiß~Pied de lion des Alpes~stella alpina dell\'Appennino\n'
      'Gentiana lutea\tGentianaceae\tgentiane jaune\tgreat yellow gentian\tGelber Enzian\tgenziana maggiore\t\n'
      'Acer japonicum\tSapindaceae\térable du Japon\tfullmoon maple\tJapanischer Ahorn\t\tThunbergs Fächer-Ahorn\n'
      'Abelmoschus esculentus\tMalvaceae\tgombo\tokra\tOkra\tocra\tBahmia~Corne grecque\n';

  final index = SpeciesIndex.parse(tsv);

  group('lecture du catalogue', () {
    test('une ligne par espèce', () {
      expect(index.records, hasLength(4));
      expect(index.records.first.scientificName, 'Leontopodium nivale');
      expect(index.records.first.family, 'Asteraceae');
    });

    test('les autres noms sont séparés', () {
      expect(index.find('Leontopodium nivale')!.alternates, contains('Pied de lion des Alpes'));
      expect(index.find('Gentiana lutea')!.alternates, isEmpty);
    });

    test('une ligne tronquée est ignorée plutôt que fatale', () {
      expect(SpeciesIndex.parse('Nom incomplet\tFamille\n').records, isEmpty);
    });

    test('un fichier vide donne un index vide', () {
      expect(SpeciesIndex.parse('').records, isEmpty);
    });
  });

  group('normalisation', () {
    test('accents et casse sont neutralisés', () {
      expect(foldSpeciesName('Édelweiß'), 'edelweiss');
      expect(foldSpeciesName('Érable du Japon'), 'erable du japon');
      expect(foldSpeciesName('GENZIANA'), 'genziana');
    });

    test('les ligatures sont dépliées', () {
      expect(foldSpeciesName('Œillet'), 'oeillet');
      expect(foldSpeciesName('Æthusa'), 'aethusa');
    });

    test('aucun accent ne devient une espace ou disparaît', () {
      // Une table écrite à la main se décale sans prévenir : on la parcourt
      // en entier plutôt que de tester trois lettres au hasard.
      const accented = 'àáâãäåèéêëìíîïòóôõöøùúûüýÿçñšžłđðřťďÀÁÂÄÈÉÊËÌÍÎÏÒÓÔÖØÙÚÛÜÝÇÑ';
      for (final ch in accented.split('')) {
        final folded = foldSpeciesName(ch);
        expect(folded, isNotEmpty, reason: ch);
        expect(RegExp(r'^[a-z]+$').hasMatch(folded), isTrue, reason: '$ch → « $folded »');
      }
    });

    test('les majuscules accentuées se replient comme les minuscules', () {
      expect(foldSpeciesName('ÖSTERREICH'), foldSpeciesName('österreich'));
      expect(foldSpeciesName('Ø'), 'o');
    });
  });

  group('recherche', () {
    List<String> names(String q) => index.search(q).map((r) => r.scientificName).toList();

    test('par nom scientifique', () {
      expect(names('gentiana'), ['Gentiana lutea']);
    });

    test('par nom courant français', () {
      expect(names('gombo'), ['Abelmoschus esculentus']);
    });

    test('« edelweiss » trouve l\'espèce, sans les signes exacts', () {
      expect(names('edelweiss'), ['Leontopodium nivale']);
      expect(names('Edelweiß'), ['Leontopodium nivale']);
      expect(names('édelweiss'), ['Leontopodium nivale']);
    });

    test('un nom secondaire suffit', () {
      expect(names('stella alpina'), ['Leontopodium nivale']);
      expect(names('Corne grecque'), ['Abelmoschus esculentus']);
    });

    test('l\'allemand et l\'italien cherchent aussi', () {
      expect(names('Gelber Enzian'), ['Gentiana lutea']);
      expect(names('ocra'), ['Abelmoschus esculentus']);
    });

    test('les débuts de mot passent devant', () {
      final results = index.search('ap');
      // « Japon » contient « ap » au milieu, « Appennino » commence par « ap ».
      expect(results.first.scientificName, 'Leontopodium nivale');
    });

    test('une recherche vide ne rend rien', () {
      expect(index.search('   '), isEmpty);
    });

    test('les espèces exclues ne remontent pas', () {
      expect(index.search('gentiane', exclude: {'gentiana lutea'}), isEmpty);
    });

    test('la limite est respectée', () {
      expect(index.search('a', limit: 2), hasLength(2));
    });
  });

  group('nom d\'affichage', () {
    test('la langue demandée d\'abord', () {
      final acer = index.find('Acer japonicum')!;
      expect(acer.commonName('fr'), 'érable du Japon');
      expect(acer.commonName('de'), 'Japanischer Ahorn');
    });

    test('à défaut, une autre langue plutôt que rien', () {
      // L'italien manque pour cet érable : l'anglais prend le relais.
      expect(index.find('Acer japonicum')!.commonName('it'), 'fullmoon maple');
    });

    test('sans aucun nom courant, le nom scientifique', () {
      final bare = SpeciesIndex.parse('Silene acaulis\tCaryophyllaceae\t\t\t\t\t\n');
      expect(bare.records.single.commonName('fr'), 'Silene acaulis');
    });
  });
}
