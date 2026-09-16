import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const lights = ['shade', 'low_light', 'indirect', 'bright_indirect', 'some_sun', 'full_sun'];
  const plants = ['monstera', 'broad_leaf', 'upright_leaf', 'vine', 'fern', 'rosette', 'cactus', 'tree', 'conifer'];

  final expected = <String>[
    for (final scene in ['indoor', 'outdoor'])
      for (final light in lights) 'assets/care_scene/$scene/$light.webp',
    for (final plant in plants) 'assets/care_scene/plants/$plant.webp',
  ];

  test('chaque couche de la scène est livrée', () {
    for (final path in expected) {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: path);
      expect(file.lengthSync(), greaterThan(1000), reason: path);
    }
  });

  test('la scène garde un budget embarqué de 8 Mo', () {
    final total = expected.fold<int>(0, (sum, path) => sum + File(path).lengthSync());
    expect(total, lessThan(8 * 1000 * 1000));
  });
}
