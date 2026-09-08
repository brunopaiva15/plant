import 'dart:io';

import 'package:flora/data/problems/problem_catalog.dart';
import 'package:flora/domain/care/care_profile.dart';
import 'package:flora/domain/problems/plant_problem.dart';
import 'package:flutter_test/flutter_test.dart';

/// Vérifie l'actif réellement embarqué : c'est lui que l'application charge,
/// et une base retouchée à la main doit se voir ici.
void main() {
  final file = File('assets/problems/catalog.txt');
  final catalog = ProblemCatalog.parse(file.readAsStringSync());

  group('la base embarquée', () {
    test('compte ses deux cents entrées, numérotées sans trou', () {
      expect(catalog.problems, hasLength(200));
      for (var i = 1; i <= 200; i++) {
        expect(catalog['${i.toString().padLeft(3, '0')}'], isNotNull, reason: 'numéro $i manquant');
      }
    });

    test('chaque entrée est nommée dans les quatre langues et a un hôte', () {
      for (final p in catalog.problems) {
        for (final name in [p.fr, p.en, p.it, p.de]) {
          expect(name.trim(), isNotEmpty, reason: p.id);
        }
        expect(p.hosts, isNotEmpty, reason: p.id);
      }
    });

    test('la portée générale va de pair avec l\'embranchement entier', () {
      for (final p in catalog.problems) {
        final universel = p.hosts.contains('Tracheophyta');
        expect(universel, p.scope == ProblemScope.general, reason: '${p.id} ${p.en}');
      }
    });

    test('les trois natures sont représentées', () {
      int combien(ProblemKind k) => catalog.problems.where((p) => p.kind == k).length;
      expect(combien(ProblemKind.disorder), greaterThan(30));
      expect(combien(ProblemKind.pest), greaterThan(50));
      expect(combien(ProblemKind.disease), greaterThan(50));
    });

    test('le nom suit la langue demandée, le français par défaut', () {
      final oidium = catalog['126']!;
      expect(oidium.nameIn('fr'), 'Oïdiums');
      expect(oidium.nameIn('en'), 'Powdery mildews');
      expect(oidium.nameIn('de'), 'Echter Mehltau');
      expect(oidium.nameIn('it'), 'Oidi');
      expect(oidium.nameIn('es'), 'Oïdiums', reason: 'langue non traduite');
    });
  });

  group('les pistes retenues pour une plante', () {
    List<String> pistes({String? species, String? family, Iterable<String> pinned = const []}) =>
        catalog.candidatesFor(species: species, family: family, pinned: pinned).map((p) => p.id).toList();

    test('les troubles universels sont toujours de la partie', () {
      final aucune = pistes();
      expect(aucune, contains('001'), reason: 'le manque d\'eau vaut pour tout le monde');
      expect(aucune, contains('175'), reason: 'la fonte des semis aussi');
      expect(aucune, isNot(contains('039')), reason: 'la nécrose apicale vise des fruits précis');
      expect(aucune.length, lessThan(40), reason: 'sans plante, il ne reste que l\'universel');
    });

    test('l\'espèce attire ce qui la vise', () {
      final tomate = pistes(species: 'Solanum lycopersicum', family: 'Solanaceae');
      expect(tomate, containsAll(['039', '043', '127', '152']));
      expect(tomate, isNot(contains('089')), reason: 'la pyrale du buis n\'a rien à faire là');
    });

    test('le genre suffit, dans un sens comme dans l\'autre', () {
      // Hôte au genre, plante à l'espèce.
      expect(pistes(species: 'Rosa gallica'), contains('147'));
      // Hôte à l'espèce, plante au genre seul.
      expect(pistes(species: 'Prunus'), contains('159'));
    });

    test('la famille rattrape ce que le genre ne dit pas', () {
      expect(pistes(species: 'Brassica oleracea', family: 'Brassicaceae'), contains('189'));
      expect(pistes(species: 'Echeveria elegans', family: 'Crassulaceae'), contains('057'));
    });

    test('les pistes épinglées entrent même sans rapport de taxons', () {
      final sans = pistes(species: 'Monstera deliciosa', family: 'Araceae');
      expect(sans, isNot(contains('060')), reason: 'les tétranyques ne citent pas Monstera');
      expect(pistes(species: 'Monstera deliciosa', family: 'Araceae', pinned: const ['060']), contains('060'));
    });

    test('un numéro épinglé qui n\'existe pas ne casse rien', () {
      expect(pistes(pinned: const ['999']), isNot(contains('999')));
    });

    test('la liste est triée par numéro, sans doublon', () {
      final ids = pistes(species: 'Solanum lycopersicum', family: 'Solanaceae', pinned: const ['002', '039']);
      expect(ids, orderedEquals([...ids]..sort()));
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('elle reste courte assez pour tenir dans une demande', () {
      for (final espece in ['Monstera deliciosa', 'Solanum lycopersicum', 'Rosa gallica', 'Malus domestica']) {
        expect(catalog.candidatesFor(species: espece).length, lessThan(80), reason: espece);
      }
    });
  });

  group('la passerelle depuis la fiche d\'entretien', () {
    test('les soucis sans équivalent unique restent sans numéro', () {
      expect(ProblemCatalog.idForIssue(CommonIssue.leafSpot), isNull);
      expect(ProblemCatalog.idForIssue(CommonIssue.blight), isNull);
    });

    test('ceux qui en ont un pointent sur une entrée réelle', () {
      for (final issue in CommonIssue.values) {
        final id = ProblemCatalog.idForIssue(issue);
        if (id != null) expect(catalog[id], isNotNull, reason: '${issue.name} → $id');
      }
      expect(ProblemCatalog.idsForIssues(const [CommonIssue.spiderMites, CommonIssue.leafSpot]), ['060']);
    });
  });

  group('une base illisible', () {
    test('les lignes mal formées tombent, le reste tient', () {
      final c = ProblemCatalog.parse([
        '# un commentaire',
        'id|type|nom_fr|nom_en|nom_it|nom_de|portee|taxons_hotes_scientifiques',
        '001|ABIOTIQUE|Manque d\'eau|Water deficit|Carenza d\'acqua|Wassermangel|GENERAL|Tracheophyta',
        '002|INCONNU|x|x|x|x|GENERAL|Tracheophyta',
        '003|ABIOTIQUE|x|x|x|x|AILLEURS|Tracheophyta',
        'trois champs|seulement|ici',
        '',
      ].join('\n'));
      expect(c.problems.map((p) => p.id), ['001']);
    });

    test('une base absente ne fait rien planter', () {
      expect(ProblemCatalog.parse('').isEmpty, isTrue);
      expect(ProblemCatalog(const []).candidatesFor(species: 'Rosa'), isEmpty);
    });
  });
}
