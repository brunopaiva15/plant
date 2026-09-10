import 'package:flora/features/plants/presentation/inline_camera.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Le viseur intégré n'existe que sur téléphone et tablette. Partout ailleurs
/// — ici, la machine qui fait tourner les tests — il doit se déclarer absent
/// sans rien casser : c'est ce constat qui fait retomber l'étape photo sur
/// l'appareil photo du système, comme avant.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('hors téléphone, le viseur se déclare indisponible', () async {
    expect(InlineCameraController.isSupported, isFalse);
    final camera = InlineCameraController();
    addTearDown(camera.dispose);

    expect(camera.status, InlineCameraStatus.idle);
    await camera.start();
    expect(camera.status, InlineCameraStatus.unavailable);
    expect(camera.isReady, isFalse);
    // Rien à proposer : l'appelant sait qu'il doit ouvrir l'appareil du système.
    expect(await camera.capture(), isNull);
    // Et un refus n'en est pas un : rien à mener aux Réglages.
    expect(camera.permissionDenied, isFalse);
  });

  test('démarrer et arrêter plusieurs fois ne casse rien', () async {
    final camera = InlineCameraController();
    addTearDown(camera.dispose);

    await camera.start();
    await camera.stop();
    await camera.start();
    await camera.stop();
    expect(camera.camera, isNull);
  });

  testWidgets("l'aperçu ne dessine rien tant qu'il n'y a pas de flux", (tester) async {
    final camera = InlineCameraController();
    addTearDown(camera.dispose);
    await camera.start();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(width: 200, height: 250, child: InlineCameraPreview(controller: camera)),
      ),
    );

    expect(find.byType(InlineCameraPreview), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
