import 'dart:io';

import 'package:flora/core/utils/search_text.dart';
import 'package:flora/data/problems/problem_catalog.dart';
import 'package:flora/domain/care/care_profile.dart';
import 'package:flora/domain/problems/plant_problem.dart';
import 'package:flutter_test/flutter_test.dart';

/// Vérifie l'actif réellement embarqué : c'est lui que l'application charge,
/// et une base retouchée à la main doit se voir ici.
void main() {
  final file = File('assets/problems/catalog.txt');
  final naturalFile = File('assets/problems/natural.txt');
  final catalog = ProblemCatalog.parseAll((file.readAsStringSync(), naturalFile.readAsStringSync()));

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

    test('chaque synonyme apporte ce que le titre ne dit pas', () {
      // Un synonyme déjà trouvable par le titre n'ajoute rien et alourdit la
      // base : la recherche sans lui doit échouer pour qu'il se justifie.
      for (final p in catalog.problems) {
        final sansSynonymes = PlantProblem(
          id: p.id,
          kind: p.kind,
          scope: p.scope,
          fr: p.fr,
          en: p.en,
          it: p.it,
          de: p.de,
          hosts: p.hosts,
        );
        for (final synonyme in p.aliases) {
          expect(sansSynonymes.matches(synonyme), isFalse, reason: '${p.id} « $synonyme » se trouve déjà par le titre');
        }
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

  group('la base des phénomènes naturels', () {
    test('chaque entrée porte un numéro en N et quatre noms', () {
      expect(catalog.naturalCauses, isNotEmpty);
      for (final n in catalog.naturalCauses) {
        expect(n.id, matches(RegExp(r'^N\d{2}$')), reason: n.fr);
        for (final name in [n.fr, n.en, n.it, n.de]) {
          expect(name.trim(), isNotEmpty, reason: n.id);
        }
        expect(n.hosts, isNotEmpty, reason: n.id);
      }
    });

    test('les numéros sont uniques et ne croisent jamais ceux des problèmes', () {
      final ids = catalog.naturalCauses.map((n) => n.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
      for (final id in ids) {
        expect(catalog[id], isNull, reason: '$id désigne aussi un problème');
      }
    });

    test('la portée générale va de pair avec l\'embranchement entier', () {
      for (final n in catalog.naturalCauses) {
        expect(n.hosts.contains('Tracheophyta'), n.scope == ProblemScope.general, reason: '${n.id} ${n.en}');
      }
    });

    test('le nom suit la langue demandée, le français par défaut', () {
      final nectar = catalog.natural('N01')!;
      expect(nectar.nameIn('fr'), 'Nectar extrafloral');
      expect(nectar.nameIn('en'), 'Extrafloral nectar');
      expect(nectar.nameIn('it'), 'Nettare extrafloreale');
      expect(nectar.nameIn('de'), 'Extrafloraler Nektar');
      expect(nectar.nameIn('es'), 'Nectar extrafloral', reason: 'langue non traduite');
    });

    test('un numéro se relit quelle que soit sa casse, et l\'inconnu ne rend rien', () {
      expect(catalog.natural('n01')?.id, 'N01');
      expect(catalog.natural('N99'), isNull);
      expect(catalog.natural(null), isNull);
    });

    test('se cherche comme un problème : par le nom, le numéro, l\'hôte', () {
      final nectar = catalog.natural('N01')!;
      expect(nectar.matches(''), isTrue);
      expect(nectar.matches('nectar'), isTrue);
      expect(nectar.matches('Extrafloral nectar'), isTrue, reason: 'les quatre langues ensemble');
      expect(nectar.matches('n01'), isTrue);
      expect(nectar.matches('philodendron'), isTrue, reason: 'un hôte');
      expect(nectar.matches('cochenille'), isFalse);
    });

    test('aucun phénomène ne porte le nom d\'un problème', () {
      // Le garde-fou de la base : ce dont il n'y a rien à soigner d'un côté,
      // ce qui se soigne de l'autre. La croûte blanche des sels (023) a sa
      // place dans la seconde et nulle part ailleurs — deux réponses
      // contraires sur la même photo valent moins qu'une seule.
      final problemes = <String, String>{
        for (final p in catalog.problems)
          for (final nom in [p.fr, p.en, p.it, p.de, ...p.aliases]) foldSpeciesName(nom): p.id,
      };
      for (final n in catalog.naturalCauses) {
        for (final nom in [n.fr, n.en, n.it, n.de]) {
          expect(problemes[foldSpeciesName(nom)], isNull, reason: '${n.id} « $nom » est déjà un problème');
        }
      }
    });

    test('la plante attire ce qu\'elle montre, l\'universel vaut pour toutes', () {
      List<String> pour({String? species, String? family}) =>
          catalog.naturalFor(species: species, family: family).map((n) => n.id).toList();

      final philodendron = pour(species: 'Philodendron hederaceum', family: 'Araceae');
      expect(philodendron, contains('N01'), reason: 'des gouttes collantes y sont du nectar aussi souvent que du miellat');
      expect(philodendron, contains('N02'), reason: 'la guttation vaut pour toutes les plantes');
      expect(philodendron, isNot(contains('N17')), reason: 'la mue est affaire de lithops');

      final lithops = pour(species: 'Lithops lesliei');
      expect(lithops, contains('N17'));
      expect(lithops, isNot(contains('N01')));

      expect(pour(), isNotEmpty, reason: 'sans espèce, il reste ce qui vaut pour toutes');
    });

    test('ce qu\'on prend pour un ravageur ou une maladie est rattaché à ses hôtes', () {
      List<String> pour({String? species, String? family}) =>
          catalog.naturalFor(species: species, family: family).map((n) => n.id).toList();

      // Les quatre confusions qui coûtent le plus cher : on traite une plante
      // qui n'a rien.
      expect(pour(species: 'Nephrolepis exaltata', family: 'Nephrolepidaceae'), contains('N19'),
          reason: 'les sores d\'une fougère passent pour des cochenilles');
      expect(pour(species: 'Mammillaria elongata', family: 'Cactaceae'), containsAll(['N22', 'N23']),
          reason: 'le liégeage passe pour une pourriture, la laine des aréoles pour des cochenilles farineuses');
      expect(pour(species: 'Phaseolus vulgaris', family: 'Fabaceae'), contains('N27'),
          reason: 'les nodosités passent pour des galles de nématodes');
      expect(pour(species: 'Cucurbita pepo', family: 'Cucurbitaceae'), contains('N04'),
          reason: 'les marbrures argentées des courges passent pour de l\'oïdium');

      // Et ce qui ne concerne pas la plante ne part pas avec sa photo.
      expect(pour(species: 'Monstera deliciosa', family: 'Araceae'), isNot(contains('N27')));
      expect(pour(species: 'Phaseolus vulgaris', family: 'Fabaceae'), isNot(contains('N23')));
    });

    test('un actif absent laisse la base des problèmes entière', () {
      final sansNaturels = ProblemCatalog.parseAll((file.readAsStringSync(), ''));
      expect(sansNaturels.problems, hasLength(200));
      expect(sansNaturels.naturalCauses, isEmpty);
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

  group('ce que la fiche de soin affiche', () {
    List<String> propres(String species, {String? family, List<CommonIssue> covered = const []}) =>
        catalog.specificTo(species: species, family: family, covered: covered).map((p) => p.id).toList();

    test('l\'universel est écarté, seul le particulier reste', () {
      final monstera = propres('Monstera deliciosa', family: 'Araceae');
      expect(monstera, isNot(contains('001')), reason: 'le manque d\'eau n\'apprend rien sur l\'espèce');
      expect(monstera, ['011', '059', '185'], reason: 'froid, thrips, taches à Pseudomonas');
    });

    test('les entrées visant l\'espèce sont nommées, pas devinées', () {
      expect(propres('Buxus sempervirens', family: 'Buxaceae'), containsAll(['089', '161', '162']));
      expect(propres('Dracaena marginata', family: 'Asparagaceae'), contains('034'));
      expect(propres('Ocimum basilicum', family: 'Lamiaceae'), ['130']);
    });

    test('ce que « À surveiller » dit déjà n\'est pas redit', () {
      expect(propres('Ficus lyrata', family: 'Moraceae'), contains('060'));
      expect(propres('Ficus lyrata', family: 'Moraceae', covered: const [CommonIssue.spiderMites]), isNot(contains('060')));
    });

    test('rien de particulier, donc rien à afficher', () {
      // La moitié du catalogue est dans ce cas : la section disparaît plutôt
      // que de meubler.
      expect(propres('Zamioculcas zamiifolia', family: 'Araceae'), isEmpty);
    });

    test('même une plante très attaquée reste lisible une fois repliée', () {
      final tomate = propres('Solanum lycopersicum', family: 'Solanaceae');
      expect(tomate.length, greaterThan(20));
      expect(tomate.take(6), hasLength(6), reason: 'les six premières suffisent avant « Tout voir »');
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

  group('la recherche de l\'encyclopédie', () {
    List<String> cherche(String q) => catalog.problems.where((p) => p.matches(q)).map((p) => p.id).toList();

    test('le nom courant trouve l\'entrée que la base nomme autrement', () {
      expect(cherche('araignée rouge'), contains('060'), reason: 'la base dit « Tétranyques »');
      expect(cherche('maladie du blanc'), contains('126'), reason: 'la base dit « Oïdiums »');
      expect(cherche('vers blancs'), contains('083'), reason: 'la base dit « larves de hannetons »');
      expect(cherche('cul noir'), contains('039'), reason: 'la base dit « nécrose apicale »');
    });

    test('le singulier trouve le pluriel, et l\'ordre des mots est libre', () {
      expect(cherche('araignees rouges'), contains('060'));
      expect(cherche('rouge araignée'), contains('060'));
      expect(cherche('pourriture racinaire'), containsAll(['172', '173']));
    });

    test('le trait d\'union et l\'apostrophe ne séparent pas deux mondes', () {
      expect(cherche('sur-arrosage'), contains('002'));
      expect(cherche('surarrosage'), contains('002'));
      expect(cherche('l\'oïdium'), contains('126'));
      expect(cherche('(CMV)'), contains('191'));
    });

    test('le mot tapé ouvre un mot de l\'entrée, il ne s\'y cache pas', () {
      // « rosa » est au milieu d'« ar-rosa-ge » : le manque d'eau n'a rien à
      // faire dans une recherche sur les rosiers.
      expect(cherche('rosa'), containsAll(['138', '147']));
      expect(cherche('rosa'), isNot(contains('001')));
      expect(cherche('rosa'), isNot(contains('002')));
    });

    test('un mot long vaut aussi au milieu d\'un autre, pour l\'allemand', () {
      expect(cherche('milben'), contains('060'), reason: 'Spinnmilben');
      expect(cherche('fliege'), contains('110'), reason: 'Zwiebelfliege');
      expect(cherche('mehltau'), contains('126'), reason: 'Echter Mehltau');
      expect(cherche('arrosage'), contains('002'), reason: 'surarrosage');
    });

    test('les quatre langues répondent, quelle que soit celle qu\'on lit', () {
      for (final q in ['tétranyques', 'spider mites', 'ragnetto rosso', 'Spinnmilben']) {
        expect(cherche(q), contains('060'), reason: q);
      }
    });

    test('le numéro et les hôtes restent des entrées de recherche', () {
      expect(cherche('060'), ['060']);
      expect(cherche('rosa'), containsAll(['138', '147']));
    });

    test('sans terme la base entière reste, un mot inconnu ne rend rien', () {
      expect(cherche(''), hasLength(200));
      expect(cherche('   '), hasLength(200));
      expect(cherche('zzzzz'), isEmpty);
    });

    test('le synonyme reste à côté du titre, il ne le remplace pas', () {
      // La fiche du problème donne les autres noms ; le titre, lui, garde un
      // seul nom par langue, pour que deux analyses se lisent pareil.
      final tetranyques = catalog['060']!;
      expect(tetranyques.aliases, contains('Araignées rouges'));
      for (final langue in ['fr', 'en', 'it', 'de']) {
        expect(tetranyques.nameIn(langue).toLowerCase(), isNot(contains('rouge')), reason: langue);
      }
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
        '004|ABIOTIQUE|x|x|x|x|GENERAL|Tracheophyta|Un autre nom;Encore un',
        '005|ABIOTIQUE|x|x|x|x|GENERAL|Tracheophyta|un|champ de trop',
        'trois champs|seulement|ici',
        '',
      ].join('\n'));
      expect(c.problems.map((p) => p.id), ['001', '004']);
      expect(c['001']!.aliases, isEmpty, reason: 'le neuvième champ est facultatif');
      expect(c['004']!.aliases, ['Un autre nom', 'Encore un']);
    });

    test('une base absente ne fait rien planter', () {
      expect(ProblemCatalog.parse('').isEmpty, isTrue);
      expect(ProblemCatalog(const []).candidatesFor(species: 'Rosa'), isEmpty);
    });
  });
}
