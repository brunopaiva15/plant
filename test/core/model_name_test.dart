import 'dart:convert';
import 'dart:io';

import 'package:flora/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

/// Le nom du modèle est composé, jamais écrit en entier : « Iris » vient du
/// code, le numéro du modèle livré. Ces tests gardent les deux moitiés
/// ensemble — un modèle réentraîné doit suffire à changer le nom affiché, et
/// l'écran ne doit jamais annoncer un numéro que le modèle ne porte pas.
void main() {
  test('le nom affiché colle le numéro annoncé par le modèle', () {
    expect(AppConfig.modelDisplayName('6'), 'Iris 6');
    expect(AppConfig.modelDisplayName('7'), 'Iris 7');
  });

  test('sans numéro, le nom reste nu plutôt que d’en inventer un', () {
    expect(AppConfig.modelDisplayName(), 'Iris');
    expect(AppConfig.modelDisplayName(null), 'Iris');
    expect(AppConfig.modelDisplayName(''), 'Iris');
  });

  test('le modèle livré annonce bien un numéro', () {
    final meta = jsonDecode(File('assets/model/model.json').readAsStringSync()) as Map<String, dynamic>;
    final version = meta['version'] as String?;
    expect(version, isNotNull, reason: 'assets/model/model.json sans « version »');
    expect(version, isNotEmpty);
    expect(AppConfig.modelDisplayName(version), '${AppConfig.modelName} $version');
  });
}
