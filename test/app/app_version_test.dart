import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// La version n'est plus écrite qu'à un endroit : la ligne `version:` du
/// pubspec. Xcode, Gradle et `AppVersion` la lisent tous là — plus rien ne
/// la recopie, donc plus rien ne peut diverger. Reste à vérifier la forme :
/// une ligne mal écrite casserait les trois d'un coup, et un numéro de
/// compilation oublié empêche la livraison sur les deux magasins.
void main() {
  test('le pubspec porte une version et un numéro de compilation', () {
    final ligne = File('pubspec.yaml')
        .readAsLinesSync()
        .firstWhere((l) => l.startsWith('version:'), orElse: () => '');
    expect(ligne, isNotEmpty, reason: 'pubspec.yaml sans ligne « version: »');

    final valeur = ligne.substring('version:'.length).trim();
    expect(
      RegExp(r'^\d+\.\d+\.\d+\+\d+$').hasMatch(valeur),
      isTrue,
      reason: 'la version doit s\'écrire « x.y.z+build » : $valeur',
    );
  });
}
