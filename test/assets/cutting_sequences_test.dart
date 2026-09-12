import 'dart:io';
import 'dart:ui' as ui;

import 'package:flora/domain/cuttings/cutting_guide.dart';
import 'package:flora/features/cuttings/application/cutting_guide_steps.dart';
import 'package:flutter_test/flutter_test.dart';

/// Les six séquences du guide de bouturage sont embarquées, une par étape,
/// et chacune est une vraie animation : plusieurs images, carrées, avec de
/// la transparence. Une séquence oubliée au rendu se verrait ici avant de se
/// voir dans l'application.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final step in CuttingStep.values) {
    test('la séquence « ${step.name} » est là et s\'anime', () async {
      final file = File(CuttingGuideStep.assetOf(step));
      expect(file.existsSync(), isTrue, reason: '${file.path} manque : voir tool/build_cutting_guide.py');
      final bytes = await file.readAsBytes();
      // Une séquence pèse quelques centaines de kilooctets : au-delà d'un
      // mégaoctet et demi, c'est le rendu ou l'emballage qui a changé.
      expect(bytes.length, lessThan(1500 * 1024), reason: '${file.path} est trop lourde');
      final codec = await ui.instantiateImageCodec(bytes);
      // L'emballage fond les images identiques qui se suivent (la pose
      // tenue au début, à la fin) en une seule, plus longue : le nombre
      // d'images varie, la durée du geste ne bouge pas.
      expect(codec.frameCount, greaterThanOrEqualTo(12), reason: '${file.path} : trop peu d\'images');
      var total = Duration.zero;
      for (var i = 0; i < codec.frameCount; i++) {
        final frame = await codec.getNextFrame();
        if (i == 0) expect(frame.image.width, frame.image.height, reason: 'les images sont carrées');
        total += frame.duration;
        frame.image.dispose();
      }
      expect(total.inMilliseconds, inInclusiveRange(1500, 5000), reason: '${file.path} : un geste dure deux ou trois secondes');
      codec.dispose();
    });
  }
}
