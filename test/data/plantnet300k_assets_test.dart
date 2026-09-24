import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pl@ntNet-300K, tel que `tools/plant_model/plantnet300k_export.py` le livre
/// à côté d'Iris (docs/09 § 15).
///
/// `TflitePlantModel` lit les trois fichiers sans rien vérifier de leur
/// accord : une ligne de trop dans `labels.txt` décalerait tous les noms d'un
/// cran, et la comparaison montrerait des espèces fausses avec des scores
/// justes — le pire des résultats pour un banc d'essai. Ce test tient les
/// trois ensemble.
void main() {
  const dir = 'assets/model/plantnet300k';
  final meta = jsonDecode(File('$dir/model.json').readAsStringSync()) as Map<String, dynamic>;
  final labels = [
    for (final l in File('$dir/labels.txt').readAsLinesSync())
      if (l.trim().isNotEmpty) l.trim(),
  ];

  test('une classe par espèce, et chacune une seule fois', () {
    expect(labels, hasLength(meta['classes']));
    expect(labels.toSet(), hasLength(labels.length),
        reason: 'une espèce en double se partagerait le score et s\'afficherait deux fois');
    // Nos identifiants internes : minuscules, tirets, rien d'autre.
    expect(labels.where((l) => !RegExp(r'^[a-z×-]+$').hasMatch(l)), isEmpty);
  });

  test('le fichier de poids est celui que décrit model.json', () {
    final bytes = File('$dir/plants.tflite').readAsBytesSync();
    expect(bytes, hasLength(meta['bytes']));
    expect(sha256.convert(bytes).toString(), meta['sha256']);
  });

  test('la recette de cadrage est celle des auteurs, lisible par l\'application', () {
    // Resize(256) puis CenterCrop(224), normalisation dans le graphe.
    expect(meta['input_size'], 224);
    expect(meta['load_size'], 256);
    expect(meta['preprocessing'], 'included_in_graph_uint8_0_255');
    // Pas de masque de lieu : la comparaison ne renormalise rien.
    expect(meta.containsKey('masks'), isFalse);
  });
}
