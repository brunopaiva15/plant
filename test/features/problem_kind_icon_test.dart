import 'dart:io';

import 'package:flora/domain/problems/plant_problem.dart';
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
}
