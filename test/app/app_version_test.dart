import 'dart:io';

import 'package:flora/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

/// La version affichée est recopiée du pubspec, donc susceptible de dériver.
/// Elle l'avait déjà fait : l'écran annonçait 0.1.0 pour une application en
/// 1.0.0, et personne ne l'avait vu. Ce test rend la dérive impossible.
void main() {
  test('la version affichée est celle du pubspec', () {
    final ligne = File('pubspec.yaml')
        .readAsLinesSync()
        .firstWhere((l) => l.startsWith('version:'), orElse: () => '');
    expect(ligne, isNotEmpty, reason: 'pubspec.yaml sans ligne « version: »');

    final valeur = ligne.substring('version:'.length).trim();
    final parts = valeur.split('+');
    expect(parts, hasLength(2), reason: 'la version du pubspec doit porter un numéro de compilation : $valeur');
    expect(AppConfig.version, parts[0], reason: 'AppConfig.version doit suivre pubspec.yaml');
    expect('${AppConfig.build}', parts[1], reason: 'AppConfig.build doit suivre pubspec.yaml');
  });
}
