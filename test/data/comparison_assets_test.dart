import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flora/domain/identification/comparison_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// Les modèles qu'on mesure contre Iris, tels que leurs scripts d'export les
/// livrent (`tools/plant_model/*_export.py`, docs/09 § 15).
///
/// `TflitePlantModel` lit les trois fichiers sans rien vérifier de leur
/// accord : une ligne de trop dans `labels.txt` décalerait tous les noms d'un
/// cran, et la comparaison montrerait des espèces fausses avec des scores
/// justes — le pire des résultats pour un banc d'essai. Ce test tient les
/// trois ensemble, pour chaque modèle de [ComparisonModel].
void main() {
  for (final model in ComparisonModel.values) {
    group(model.displayName, () {
      final dir = 'assets/model/${model.key}';
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

      test('la recette de cadrage se lit comme celle d\'Iris', () {
        final input = meta['input_size'] as int;
        final load = meta['load_size'] as int;
        final source = meta['source_size'] as int;
        expect(load, greaterThanOrEqualTo(input));
        // Sans source plus grande que le chargement, l'application sauterait
        // la moyenne de zone et réduirait une photo de 4 000 px par un
        // bilinéaire seul (`TflitePlantModel._decode`).
        expect(source, greaterThan(load));
        expect(meta['preprocessing'], 'included_in_graph_uint8_0_255');
        // Pas de masque de lieu : la comparaison ne renormalise rien.
        expect(meta.containsKey('masks'), isFalse);
      });
    });
  }
}
