import 'dart:io';

import 'package:flora/data/problems/problem_catalog.dart';
import 'package:flora/domain/models/models.dart';
import 'package:flora/domain/problems/plant_problem.dart';
import 'package:flora/features/problems/presentation/illustrated_problems.dart';
import 'package:flora/features/problems/presentation/problem_kind_icon.dart';
import 'package:flutter_test/flutter_test.dart';

/// Les quatre symboles d'argile des familles de problèmes. On vérifie les
/// fichiers réellement embarqués : une image renommée ou oubliée dans le
/// pubspec ne se verrait qu'à l'exécution, sur l'appareil.
void main() {
  test('chaque famille a son image, présente et non vide', () {
    for (final kind in ProblemKind.values) {
      final file = File(ProblemKindIcon.assetOf(kind));
      expect(file.existsSync(), isTrue, reason: '${kind.name} → ${file.path}');
      expect(file.lengthSync(), greaterThan(1024), reason: kind.name);
      // En-tête RIFF/WEBP : le fichier est bien ce qu'il prétend être.
      final head = file.openSync().readSync(12);
      expect(String.fromCharCodes(head.sublist(0, 4)), 'RIFF', reason: kind.name);
      expect(String.fromCharCodes(head.sublist(8, 12)), 'WEBP', reason: kind.name);
    }
  });

  test('les quatre pointent sur quatre images différentes', () {
    final paths = {for (final kind in ProblemKind.values) ProblemKindIcon.assetOf(kind)};
    expect(paths, hasLength(ProblemKind.values.length));
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
}
