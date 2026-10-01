// Iris 10 dans l'application, sur un vrai téléphone : le modèle se charge,
// passe son contrôle, et un scan complet se chronomètre (§ 20 sexdecies de
// docs/14).
//
// Les fichiers d'Iris 10 sont ceux de `exporter.py livrer`, déjà dans
// assets/model/. Depuis le Mac, iPhone branché :
//
//   flutter drive --profile --driver=test_driver/integration_test.dart \
//     --target=integration_test/iris10_test.dart -d <iPhone>
//
// **Ce qui est vérifié** : que la fusion répond (Iris 10 chargé, vecteur de
// contrôle rendu à l'identique de l'export) et à quel seuil. **Ce qui est
// mesuré** : `classify()` en entier sur une photo de 12 Mpx — décodage,
// cadrage des deux entrées, les deux réseaux, les références, la fusion.
// C'est l'attente réelle d'un scan, là où `iris10_vitesse_test.dart` ne
// mesurait que les réseaux.
import 'dart:io';
import 'dart:math' as math;

import 'package:flora/data/services/fused_plant_model.dart';
import 'package:flora/domain/identification/identification_context.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Iris 10 se charge, passe son contrôle et répond', (tester) async {
    final model = FusedPlantModel();
    final chrono = Stopwatch()..start();
    expect(await model.warmUp(), isTrue, reason: 'Iris 9 ne se charge pas : ${model.loadError}');
    final chargement = chrono.elapsedMilliseconds;
    expect(model.fused, isTrue, reason: 'Iris 10 non retenu : ${model.iris10Error}');
    expect(model.version, '10');
    expect(model.acceptThreshold, 0.85);

    // Deux photos : celle de l'appareil photo de l'application
    // (`ResolutionPreset.veryHigh`, 1 920 × 1 080) et une photo de la
    // galerie, 4 032 × 3 024. Le décodage compte autant que les réseaux, et
    // il dépend de la taille du fichier.
    final dir = await Directory.systemTemp.createTemp('iris10');
    final rapport = <String, Object>{'chargement_ms': chargement, 'especes': model.speciesCount};
    final lignes = <String>[];
    for (final (w, h) in [(1920, 1080), (4032, 3024)]) {
      final fichier = File('${dir.path}/photo-$w.jpg')..writeAsBytesSync(img.encodeJpg(_photo(w, h), quality: 90));
      final temps = <int>[];
      var candidats = 0;
      for (var i = 0; i < 6; i++) {
        final t = Stopwatch()..start();
        final rendu = await model.classify(fichier, context: IdentificationContext.indoor);
        temps.add(t.elapsedMilliseconds);
        candidats = rendu.length;
      }
      expect(candidats, greaterThan(0));
      // Le premier tour paie la mise en route des isolats : il est montré à
      // part, la médiane porte sur les cinq suivants.
      final suivants = temps.sublist(1)..sort();
      final mediane = suivants[suivants.length ~/ 2];
      rapport['${w}x$h'] = {'premier_scan_ms': temps.first, 'scan_median_ms': mediane};
      lignes.add('  $w × $h : premier scan ${temps.first} ms, scan médian $mediane ms');
    }
    // ignore: avoid_print
    print('\nIris ${model.version} : ${model.speciesCount} espèces, seuil ${model.acceptThreshold}, '
        'chargement $chargement ms\n${lignes.join('\n')}\n');
    binding.reportData = {'iris10': rapport};

    model.dispose();
    await dir.delete(recursive: true);
  }, timeout: const Timeout(Duration(minutes: 5)));
}

/// Une image à grain de photo : des blocs de 8 px au hasard, que le JPEG ne
/// compresse pas en rien.
img.Image _photo(int w, int h) {
  final hasard = math.Random(20261001);
  final photo = img.Image(width: w, height: h);
  for (var y = 0; y < h; y += 8) {
    for (var x = 0; x < w; x += 8) {
      final c = img.ColorRgb8(hasard.nextInt(256), hasard.nextInt(256), hasard.nextInt(256));
      img.fillRect(photo, x1: x, y1: y, x2: x + 7, y2: y + 7, color: c);
    }
  }
  return photo;
}
