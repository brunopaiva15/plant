import 'dart:io';

import 'package:flora/data/problems/problem_catalog.dart';
import 'package:flora/domain/care/care_profile.dart';
import 'package:flora/domain/models/models.dart';
import 'package:flora/domain/problems/plant_problem.dart';
import 'package:flora/domain/problems/natural_cause.dart';
import 'package:flora/features/problems/presentation/illustrated_natural.dart';
import 'package:flora/features/problems/presentation/illustrated_problems.dart';
import 'package:flora/features/problems/presentation/problem_kind_icon.dart';
import 'package:flutter_test/flutter_test.dart';

/// Les quatre symboles d'argile des familles de problèmes, et le cinquième —
/// celui de ce qui n'en est pas un. On vérifie les fichiers réellement
/// embarqués : une image renommée ou oubliée dans le pubspec ne se verrait
/// qu'à l'exécution, sur l'appareil.
void main() {
  /// Un fichier livré, et qui est bien une image WebP.
  void verifieWebp(String path, {required String raison}) {
    final file = File(path);
    expect(file.existsSync(), isTrue, reason: '$raison → $path');
    expect(file.lengthSync(), greaterThan(1024), reason: raison);
    // En-tête RIFF/WEBP : le fichier est bien ce qu'il prétend être.
    final head = file.openSync().readSync(12);
    expect(String.fromCharCodes(head.sublist(0, 4)), 'RIFF', reason: raison);
    expect(String.fromCharCodes(head.sublist(8, 12)), 'WEBP', reason: raison);
  }

  test('chaque famille a son image, présente et non vide', () {
    for (final kind in ProblemKind.values) {
      verifieWebp(ProblemKindIcon.assetOf(kind), raison: kind.name);
    }
  });

  test('les quatre pointent sur quatre images différentes', () {
    final paths = {for (final kind in ProblemKind.values) ProblemKindIcon.assetOf(kind)};
    expect(paths, hasLength(ProblemKind.values.length));
  });

  test('ce qui n\'est pas un problème a son propre symbole', () {
    // Une piste naturelle n'emprunte le dessin d'aucune famille : sa carte
    // dirait sinon qu'elle en est une.
    verifieWebp(NaturalCauseIcon.commonAsset, raison: 'phénomène naturel');
    final familles = {for (final kind in ProblemKind.values) ProblemKindIcon.assetOf(kind)};
    expect(familles, isNot(contains(NaturalCauseIcon.commonAsset)));
  });

  group('les illustrations par phénomène naturel', () {
    final base = ProblemCatalog.parseAll((
      File('assets/problems/catalog.txt').readAsStringSync(),
      File('assets/problems/natural.txt').readAsStringSync(),
    ));
    final dossier = Directory('assets/problems/natural');

    test('la liste et le dossier disent la même chose', () {
      // Les deux sont écrits ensemble par tool/pack_natural_icons.py.
      final fichiers = dossier
          .listSync()
          .whereType<File>()
          .map((f) => f.uri.pathSegments.last)
          .where((n) => n.endsWith('.webp'))
          .map((n) => n.substring(0, n.length - 5))
          .toSet();
      expect(fichiers, illustratedNaturalCauses);
      expect(illustratedNaturalCauses, isNotEmpty);
    });

    test('chaque phénomène de la base a son dessin, et rien d\'autre n\'en a', () {
      expect(illustratedNaturalCauses, {for (final n in base.naturalCauses) n.id});
      for (final n in base.naturalCauses) {
        verifieWebp(NaturalCauseIcon.assetOf(n), raison: '${n.id} ${n.fr}');
        expect(NaturalCauseIcon.assetOf(n), isNot(NaturalCauseIcon.commonAsset), reason: n.id);
      }
    });

    test('un phénomène hors base retombe sur le symbole commun', () {
      const inconnu = NaturalCause(
        id: 'N99',
        scope: ProblemScope.wide,
        fr: 'fr',
        en: 'en',
        it: 'it',
        de: 'de',
        hosts: ['Tracheophyta'],
      );
      expect(NaturalCauseIcon.assetOf(inconnu), NaturalCauseIcon.commonAsset);
      expect(NaturalCauseIcon.assetOf(null), NaturalCauseIcon.commonAsset);
    });

    test('le dossier est déclaré dans le pubspec', () {
      expect(File('pubspec.yaml').readAsStringSync(), contains('- assets/problems/natural/'));
    });
  });

  test('le dossier des images est déclaré dans le pubspec', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('- assets/problems/'));
  });

  group('les illustrations par problème', () {
    final catalog = ProblemCatalog.parse(File('assets/problems/catalog.txt').readAsStringSync());
    final dossier = Directory('assets/problems/icons');

    test('la liste et le dossier disent la même chose', () {
      // Les deux sont écrits ensemble par tool/pack_problem_icons.py ; s'ils
      // divergent, c'est qu'une image a été ajoutée ou retirée à la main.
      final fichiers = dossier
          .listSync()
          .whereType<File>()
          .map((f) => f.uri.pathSegments.last)
          .where((n) => n.endsWith('.webp'))
          .map((n) => n.substring(0, n.length - 5))
          .toSet();
      expect(fichiers, illustratedProblems);
      expect(illustratedProblems, isNotEmpty);
    });

    test('chaque illustration désigne une entrée réelle de la base', () {
      for (final id in illustratedProblems) {
        expect(catalog[id], isNotNull, reason: 'illustration $id sans entrée');
      }
    });

    test('chaque fichier est un WebP non vide', () {
      for (final id in illustratedProblems) {
        final file = File('assets/problems/icons/$id.webp');
        expect(file.lengthSync(), greaterThan(1024), reason: id);
        final head = file.openSync().readSync(12);
        expect(String.fromCharCodes(head.sublist(8, 12)), 'WEBP', reason: id);
      }
    });

    test('un problème illustré prend son image', () {
      final illustre = catalog[illustratedProblems.first]!;
      expect(ProblemIcon.isIllustrated(illustre), isTrue);
      expect(ProblemIcon.assetOf(illustre), 'assets/problems/icons/${illustre.id}.webp');
    });

    test('les deux cents entrées de la base ont toutes la leur', () {
      final sansImage = catalog.problems.where((p) => !illustratedProblems.contains(p.id)).map((p) => p.id);
      expect(sansImage, isEmpty, reason: 'ces entrées retomberaient sur le symbole de leur famille');
    });

    test('un problème qu\'on ne sait pas dessiner retombe sur sa famille', () {
      // Le repli n'a plus d'exemple dans la base : les illustrations sont
      // arrivées par lots jusqu'à les couvrir toutes. Il reste le chemin
      // d'une entrée qu'une version plus récente apporterait, et c'est lui
      // qu'on vérifie.
      const inconnu = PlantProblem(
        id: '999',
        kind: ProblemKind.pest,
        scope: ProblemScope.general,
        fr: 'Inconnu',
        en: 'Unknown',
        it: 'Sconosciuto',
        de: 'Unbekannt',
        hosts: ['Tracheophyta'],
      );
      expect(ProblemIcon.isIllustrated(inconnu), isFalse);
      expect(ProblemIcon.assetOf(inconnu), ProblemKindIcon.assetOf(ProblemKind.pest));
    });

    test('le dossier des illustrations est déclaré à part dans le pubspec', () {
      // Une entrée de dossier ne descend pas dans les sous-dossiers.
      expect(File('pubspec.yaml').readAsStringSync(), contains('- assets/problems/icons/'));
    });
  });

  group('les problèmes de santé d\'une fiche', () {
    final catalog = ProblemCatalog.parse(File('assets/problems/catalog.txt').readAsStringSync());

    test('chacun a son image, présente et non vide', () {
      for (final issue in HealthIssue.values) {
        final file = File(HealthIssueIcon.assetOf(issue));
        expect(file.existsSync(), isTrue, reason: '${issue.name} → ${file.path}');
        expect(file.lengthSync(), greaterThan(1024), reason: issue.name);
      }
    });

    test('celui qui désigne une entrée de la base en prend le dessin', () {
      for (final issue in HealthIssue.values.where((i) => i.problemId != null)) {
        expect(HealthIssueIcon.assetOf(issue), 'assets/problems/icons/${issue.problemId}.webp', reason: issue.name);
      }
    });

    test('les deux familles portent le symbole de leur famille', () {
      for (final issue in [HealthIssue.pests, HealthIssue.disease]) {
        expect(issue.problemId, isNull, reason: issue.name);
        expect(HealthIssueIcon.assetOf(issue), ProblemKindIcon.assetOf(issue.kind), reason: issue.name);
      }
    });

    test('l\'entrée désignée dit bien la même chose, et de la même famille', () {
      for (final issue in HealthIssue.values.where((i) => i.problemId != null)) {
        final problem = catalog[issue.problemId];
        expect(problem, isNotNull, reason: '${issue.name} désigne ${issue.problemId}, absent de la base');
        expect(problem!.kind, issue.kind, reason: issue.name);
      }
    });
  });

  group('les soucis « À surveiller » d\'une fiche d\'entretien', () {
    final catalog = ProblemCatalog.parse(File('assets/problems/catalog.txt').readAsStringSync());

    test('chacun a son image, présente et non vide', () {
      for (final issue in CommonIssue.values) {
        final file = File(CommonIssueIcon.assetOf(issue));
        expect(file.existsSync(), isTrue, reason: '${issue.name} → ${file.path}');
        expect(file.lengthSync(), greaterThan(1024), reason: issue.name);
      }
    });

    test('celui qui désigne une entrée de la base en prend le dessin', () {
      for (final issue in CommonIssue.values) {
        final id = ProblemCatalog.idForIssue(issue);
        if (id == null) continue;
        expect(CommonIssueIcon.isIllustrated(issue), isTrue, reason: issue.name);
        expect(CommonIssueIcon.assetOf(issue), 'assets/problems/icons/$id.webp', reason: issue.name);
      }
    });

    test('ceux qui recouvrent plusieurs entrées portent le symbole de leur famille', () {
      // « Taches foliaires » recouvre une dizaine de champignons, « Mildiou »
      // autant, « Punaises » trois familles, et « Chute de feuilles » se dit de
      // tout : aucune ne désigne une entrée sans en désigner une fausse.
      const larges = {CommonIssue.trueBugs, CommonIssue.leafSpot, CommonIssue.blight, CommonIssue.leafDrop};
      for (final issue in larges) {
        expect(ProblemCatalog.idForIssue(issue), isNull, reason: issue.name);
        expect(CommonIssueIcon.isIllustrated(issue), isFalse, reason: issue.name);
        expect(CommonIssueIcon.assetOf(issue), ProblemKindIcon.assetOf(issue.kind), reason: issue.name);
      }
      // Et ce sont les seules : tout le reste de la liste garde son dessin.
      expect(CommonIssue.values.where((i) => !CommonIssueIcon.isIllustrated(i)).toSet(), larges);
    });

    test('l\'entrée désignée dit bien la même chose, et de la même famille', () {
      for (final issue in CommonIssue.values) {
        final id = ProblemCatalog.idForIssue(issue);
        if (id == null) continue;
        final problem = catalog[id];
        expect(problem, isNotNull, reason: '${issue.name} désigne $id, absent de la base');
        expect(problem!.kind, issue.kind, reason: issue.name);
      }
    });
  });
}
