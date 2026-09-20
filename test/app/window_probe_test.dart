import 'package:flora/app/window_probe.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// La sonde de fenêtre écrit dans la console, et seulement quand on la
/// demande : `--dart-define=WINDOW_DEBUG=true`, ou `?window` sur le web.
///
/// C'est cette réserve qui est tenue ici. Le relevé lui-même se lit en
/// lançant l'application avec la demande — le voir passer dans une suite de
/// tests n'apprendrait rien que la console n'apprenne mieux :
///
/// ```
/// flutter test --dart-define=WINDOW_DEBUG=true test/app/window_probe_test.dart
/// ```
void main() {
  testWidgets('sans demande, la sonde reste muette', (tester) async {
    addTearDown(WindowProbe.detach);
    addTearDown(tester.view.reset);
    final lignes = <String>[];
    final original = debugPrint;
    // `debugPrint` est rendu dans le corps du test, pas dans un teardown : la
    // suite vérifie les variables de debug avant d'appeler ceux-ci.
    debugPrint = (String? message, {int? wrapWidth}) => lignes.add(message ?? '');
    try {
      WindowProbe.attachIfRequested();
      tester.view.devicePixelRatio = 3;
      await tester.idle();
    } finally {
      debugPrint = original;
    }

    // Avec la demande, ces deux lignes-là seraient un en-tête et un relevé.
    expect(lignes, WindowProbe.requested ? isNotEmpty : isEmpty);
  });
}
