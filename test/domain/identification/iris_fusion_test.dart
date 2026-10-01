import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flora/domain/identification/context_mask.dart';
import 'package:flora/domain/identification/iris_fusion.dart';
import 'package:flutter_test/flutter_test.dart';

/// La fusion de l'application comparée à celle du banc.
///
/// `test/fixtures/iris_fusion.json` a été écrit par les fonctions Python
/// elles-mêmes — `paquet_references`, `voisins.classer`,
/// `arbitre.fusionner_synonymes` et `aligner`, `seuils.fusion_probas` — sur
/// un petit cas qui a tout : un synonyme, des vues `#pot` et `#captive`, une
/// espèce d'Iris 9 sans référence, une référence hors d'Iris 9.
void main() {
  final fixture = jsonDecode(File('test/fixtures/iris_fusion.json').readAsStringSync()) as Map<String, dynamic>;
  final labels = (fixture['labels'] as List).cast<String>();
  final meta = jsonEncode(fixture['meta']);
  final refs = ByteData.sublistView(base64Decode(fixture['references'] as String));
  List<double> doubles(String key) => [for (final v in fixture[key] as List) (v as num).toDouble()];

  final references = Iris10References.parse(meta, refs, labels);
  final embedding = Float32List.fromList(doubles('embedding'));

  test('Iris 10 rend la distribution de voisins.classer', () {
    final p10 = references.speciesProbabilities(embedding);
    final expected = doubles('iris10');
    expect(p10.length, expected.length);
    for (var i = 0; i < p10.length; i++) {
      expect(p10[i], closeTo(expected[i], 1e-5));
    }
  });

  test('la fusion rend celle de seuils.fusion_probas, synonymes additionnés', () {
    final fused = references.fuse(
        references.iris9ToSpecies(doubles('iris9')), references.speciesProbabilities(embedding));
    final expected = doubles('fusion');
    for (var i = 0; i < fused.length; i++) {
      expect(fused[i], closeTo(expected[i], 1e-5));
    }
    expect(fused.reduce((a, b) => a + b), closeTo(1, 1e-9));
  });

  test('masquer après la fusion rend la fusion des deux distributions masquées', () {
    final fused = references.fuse(
        references.iris9ToSpecies(doubles('iris9')), references.speciesProbabilities(embedding));
    final mask = references.speciesMask((fixture['masque'] as List).cast<int>().toSet());
    final candidates = maskedCandidates(fused, references.species, nameOf: (id) => id, mask: mask);
    final inside = {for (final c in candidates) if (c.inContext) c.scientificName: c.score};
    final expected = (fixture['fusion_masquee'] as Map<String, dynamic>).cast<String, num>();
    expect(inside.keys.toSet(), expected.keys.toSet());
    for (final e in expected.entries) {
      // Le plancher de 1e-6 ne s'applique pas aux mêmes zéros des deux côtés.
      expect(inside[e.key], closeTo(e.value, 1e-4), reason: e.key);
    }
  });

  test('un iris10.json d\'un autre export est refusé', () {
    final other = [...labels]..[0] = 'ficus-elastica';
    expect(() => Iris10References.parse(meta, refs, other), throwsFormatException);
    expect(() => Iris10References.parse(meta, refs, labels.sublist(1)), throwsFormatException);
    expect(() => Iris10References.parse(meta, ByteData(6), labels), throwsFormatException);
  });

  test('le réglage vient du fichier', () {
    expect(references.version, '10');
    expect(references.acceptThreshold, 0.85);
    expect(references.iris9Weight, 0.5);
    expect(references.species, ['monstera-deliciosa', 'schefflera-arboricola', 'pilea-peperomioides',
        'hedera-helix', 'acer-palmatum']);
  });

  test('le contrôle accepte quelques millièmes, pas un autre vecteur', () {
    expect(references.matchesControl(Float32List.fromList([0.104, -0.197, 0.5])), isTrue);
    expect(references.matchesControl(Float32List.fromList([0.2, -0.2])), isFalse);
    expect(references.matchesControl(Float32List(1)), isFalse);
  });

  test('le motif de contrôle est celui de l\'export', () {
    final m = iris10ControlInput(4);
    expect(m.length, 48);
    expect(m[0], 0);
    expect(m[1], closeTo(919 / 999, 1e-7));
    expect(m[47], closeTo(47 * 7919 % 1000 / 999, 1e-7));
  });

  test('les demi-flottants', () {
    final b = ByteData(12)
      ..setUint16(0, 0x3c00, Endian.little) // 1
      ..setUint16(2, 0xc000, Endian.little) // −2
      ..setUint16(4, 0x3555, Endian.little) // ≈ 1/3
      ..setUint16(6, 0x0001, Endian.little) // plus petit sous-normal
      ..setUint16(8, 0x0000, Endian.little)
      ..setUint16(10, 0x7bff, Endian.little); // 65504
    final f = float16ToFloat32(b);
    expect(f[0], 1);
    expect(f[1], -2);
    expect(f[2], closeTo(0.333251953125, 1e-12));
    expect(f[3], closeTo(5.960464477539063e-8, 1e-20));
    expect(f[4], 0);
    expect(f[5], 65504);
  });
}
