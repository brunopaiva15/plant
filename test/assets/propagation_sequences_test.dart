import 'dart:io';
import 'dart:ui' as ui;

import 'package:flora/domain/cuttings/propagation_guide.dart';
import 'package:flora/features/cuttings/application/propagation_guides.dart';
import 'package:flutter_test/flutter_test.dart';

/// Les séquences des guides de multiplication sont embarquées, une par
/// étape de chaque archétype, et chacune est une vraie animation : plusieurs
/// images, carrées, avec de la transparence. Une séquence oubliée au rendu
/// se verrait ici avant de se voir dans l'application.
///
/// Rien ici ne suppose six étapes : le guide dit combien il en a, et le
/// test suit.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('chaque archétype a son guide, et chaque guide ses étapes', () {
    for (final kind in PropagationGuideKind.values) {
      final guide = propagationGuideOf(kind);
      expect(guide.steps, isNotEmpty, reason: '${kind.name} : un guide sans étape');
      expect(guide.stepIds, propagationStepIds[kind], reason: '${kind.name} : les étapes ne suivent plus le domaine');
      // Deux étapes ne partagent ni leur identifiant ni leur séquence.
      expect(guide.stepIds.toSet(), hasLength(guide.length));
      expect({for (final s in guide.steps) s.asset}, hasLength(guide.length));
    }
  });

  test('deux guides ne montrent jamais la même séquence', () {
    final vus = <String, String>{};
    for (final kind in PropagationGuideKind.values) {
      for (final step in propagationGuideOf(kind).steps) {
        final deja = vus[step.asset];
        expect(deja, isNull, reason: '${step.asset} sert à ${kind.name} et à $deja');
        vus[step.asset] = kind.name;
      }
    }
  });

  for (final kind in PropagationGuideKind.values) {
    for (final step in propagationGuideOf(kind).steps) {
      test('${kind.name} / ${step.id} : la séquence est là et s\'anime', () async {
        final file = File(step.asset);
        expect(file.existsSync(), isTrue, reason: '${file.path} manque : voir tool/build_cutting_assets.py');
        final bytes = await file.readAsBytes();
        // Une séquence pèse quelques centaines de kilooctets : au-delà d'un
        // mégaoctet et demi, c'est le rendu ou l'emballage qui a changé.
        expect(bytes.length, lessThan(1500 * 1024), reason: '${file.path} est trop lourde');
        final codec = await ui.instantiateImageCodec(bytes);
        // L'emballage fond les images identiques qui se suivent (la pose
        // tenue au début, à la fin) en une seule, plus longue : le nombre
        // d'images varie, la durée du geste ne bouge pas. Une étape où seul
        // un anneau se pose sur une plante immobile en garde moins qu'une
        // où tout bouge — le plancher est là pour repérer une image fixe
        // livrée comme une animation, pas pour compter les images.
        expect(codec.frameCount, greaterThanOrEqualTo(8), reason: '${file.path} : trop peu d\'images');
        var total = Duration.zero;
        for (var i = 0; i < codec.frameCount; i++) {
          final frame = await codec.getNextFrame();
          if (i == 0) {
            expect(frame.image.width, frame.image.height, reason: 'les images sont carrées');
            final data = await frame.image.toByteData();
            // Le fond est transparent : l'application pose son propre halo
            // derrière l'objet. Le coin supérieur gauche ne porte jamais le
            // sujet, quel que soit le cadrage.
            expect(data!.getUint8(3), 0, reason: '${file.path} : le fond n\'est pas transparent');
          }
          total += frame.duration;
          frame.image.dispose();
        }
        expect(total.inMilliseconds, inInclusiveRange(1500, 3200),
            reason: '${file.path} : un geste dure entre une seconde et demie et trois secondes');
        codec.dispose();
      });
    }
  }
}
