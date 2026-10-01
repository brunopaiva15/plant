import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flora/data/services/pil_resample.dart';
import 'package:flutter_test/flutter_test.dart';

/// Le redimensionnement d'Iris 10 comparé à PIL lui-même.
///
/// `test/fixtures/pil_resample.json` porte ce que Pillow rend sur un motif
/// que les deux côtés savent écrire : réduction, agrandissement, Lanczos et
/// bicubique, une seule dimension ou les deux. L'attendu est l'égalité au
/// pixel près — c'est tout l'intérêt d'avoir recopié l'algorithme.
void main() {
  final fixture = jsonDecode(File('test/fixtures/pil_resample.json').readAsStringSync()) as Map<String, dynamic>;
  final width = fixture['largeur'] as int;
  final height = fixture['hauteur'] as int;
  final source = Uint8List(width * height * 3);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      for (var c = 0; c < 3; c++) {
        source[(y * width + x) * 3 + c] = (x * 37 + y * 91 + c * 53 + (x * y) % 17 * 11) % 256;
      }
    }
  }

  for (final cas in (fixture['cas'] as List).cast<Map<String, dynamic>>()) {
    final filter = ResampleFilter.values.byName(cas['filtre'] as String);
    final w = cas['largeur'] as int;
    final h = cas['hauteur'] as int;
    test('${filter.name} $width×$height → $w×$h, comme Pillow ${fixture['pillow']}', () {
      final expected = base64Decode(cas['octets'] as String);
      final got = resampleRgb(source, width, height, w, h, filter);
      expect(got.length, expected.length);
      var differing = 0;
      for (var i = 0; i < got.length; i++) {
        if (got[i] != expected[i]) differing++;
      }
      expect(differing, 0, reason: '$differing octets sur ${got.length} diffèrent de PIL');
    });
  }

  test('la même taille rend une copie', () {
    final got = resampleRgb(source, width, height, width, height, ResampleFilter.bicubic);
    expect(got, source);
    expect(identical(got, source), isFalse);
  });

  test('une taille qui ne colle pas aux octets est refusée', () {
    expect(() => resampleRgb(Uint8List(10), 2, 2, 1, 1, ResampleFilter.bicubic), throwsArgumentError);
  });
}
