import 'dart:io';
import 'dart:typed_data';

import 'package:flora/domain/identification/iris_fusion.dart';
import 'package:flutter_test/flutter_test.dart';

/// Les fichiers d'Iris 10 livrés dans `assets/model/` parlent des mêmes
/// sorties qu'Iris 9.
///
/// L'application vérifie la même chose au chargement, et retombe sur Iris 9
/// seul si elle échoue — sans bruit, puisque l'utilisateur n'y peut rien.
/// Ce test fait de ce repli silencieux une erreur visible avant la
/// livraison : un `labels.txt` régénéré sans relancer `exporter.py livrer`
/// éteindrait Iris 10 sur tous les téléphones.
void main() {
  test('iris10.json, ses références et les labels d\'Iris 9 concordent', () {
    final labels = [
      for (final l in File('assets/model/labels.txt').readAsLinesSync())
        if (l.trim().isNotEmpty) l.trim(),
    ];
    final references = Iris10References.parse(
      File('assets/model/iris10.json').readAsStringSync(),
      ByteData.sublistView(File('assets/model/iris10-references.bin').readAsBytesSync()),
      labels,
    );
    expect(references.version, '10');
    expect(references.acceptThreshold, 0.85);
    expect(references.iris9Weight, 0.5);
    // Toutes les sorties d'Iris 9 ont une espèce dans la fusion : seules
    // les deux paires de synonymes se rejoignent.
    expect(references.iris9Species.every((s) => s >= 0), isTrue);
    expect(references.species.length, labels.length - 2);
    expect(references.control, hasLength(16));
  });
}
