import 'dart:io';

import 'package:flora/data/problems/problem_catalog.dart';
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

    test('un problème illustré prend son image, les autres celle de leur famille', () {
      final illustre = catalog[illustratedProblems.first]!;
      expect(ProblemIcon.isIllustrated(illustre), isTrue);
      expect(ProblemIcon.assetOf(illustre), 'assets/problems/icons/${illustre.id}.webp');

      // 001 n'est pas encore dessiné : il retombe sur le symbole des troubles.
      final sansImage = catalog.problems.firstWhere((p) => !illustratedProblems.contains(p.id));
      expect(ProblemIcon.assetOf(sansImage), ProblemKindIcon.assetOf(sansImage.kind));
    });

    test('le dossier des illustrations est déclaré à part dans le pubspec', () {
      // Une entrée de dossier ne descend pas dans les sous-dossiers.
      expect(File('pubspec.yaml').readAsStringSync(), contains('- assets/problems/icons/'));
    });
  });
}
