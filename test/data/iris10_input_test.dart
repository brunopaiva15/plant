import 'dart:convert';
import 'dart:io';

import 'package:flora/data/services/iris10_input.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

/// La photo telle qu'Iris 10 la reçoit, comparée à la recette Python :
/// réduction Lanczos du jeu de données, carré central, bicubique de
/// `student.preparer` (`test/fixtures/iris10_input.json`, écrit par PIL).
///
/// Une photo de moins de deux fois 384 px ne passe pas par la moyenne par
/// blocs : la sortie doit donc être celle de PIL, octet pour octet.
void main() {
  final fixture = jsonDecode(File('test/fixtures/iris10_input.json').readAsStringSync()) as Map<String, dynamic>;

  img.Image motif(int w, int h) {
    final im = img.Image(width: w, height: h);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        int v(int c) => (x * 3 + y * 5 + c * 50 + (x ~/ 7) * (y ~/ 11) % 13 * 9) % 256;
        im.setPixelRgb(x, y, v(0), v(1), v(2));
      }
    }
    return im;
  }

  for (final cas in (fixture['cas'] as List).cast<Map<String, dynamic>>()) {
    final w = cas['largeur'] as int;
    final h = cas['hauteur'] as int;
    test('$w×$h : la même entrée que PIL', () {
      final input = iris10Input(motif(w, h));
      expect(input.length, 320 * 320 * 3);
      final bytes = [for (final v in input) (v * 255).round()];
      final sums = [0, 0, 0];
      for (var i = 0; i < bytes.length; i++) {
        sums[i % 3] += bytes[i];
      }
      expect(sums, cas['somme']);
      final step = cas['pas'] as int;
      expect([for (var i = 0; i < bytes.length; i += step) bytes[i]], cas['echantillon']);
      expect(input.every((v) => v >= 0 && v <= 1), isTrue);
    });
  }

  test('une grande photo passe par la moyenne et garde la recette', () {
    final input = iris10Input(motif(4032, 3024));
    expect(input.length, 320 * 320 * 3);
    expect(input.every((v) => v >= 0 && v <= 1), isTrue);
  });
}
