import 'package:flora/features/plants/presentation/inline_camera.dart';
import 'package:flora/l10n/generated/app_localizations.dart';
import 'package:flutter/gestures.dart';
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
    // Pas de viseur du tout : la page prend sa mise en page de repli.
    expect(camera.hasViewfinder, isFalse);
  });

  test("passer derrière ne transforme pas une absence de viseur en viseur suspendu", () async {
    final camera = InlineCameraController();
    addTearDown(camera.dispose);
    await camera.start();
    camera.didChangeAppLifecycleState(AppLifecycleState.paused);
    expect(camera.status, InlineCameraStatus.unavailable);
    expect(camera.hasViewfinder, isFalse);
    camera.didChangeAppLifecycleState(AppLifecycleState.resumed);
    expect(camera.status, InlineCameraStatus.unavailable);
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

  test('sans flux, ni flash ni zoom, et les demander ne casse rien', () async {
    final camera = InlineCameraController();
    addTearDown(camera.dispose);
    await camera.start();

    expect(camera.hasFlash, isFalse);
    expect(camera.canZoom, isFalse);
    await camera.toggleFlash();
    expect(camera.flash, isFalse);
    camera.setZoom(3);
    camera.resetZoom();
    expect(camera.zoom.value, 1);
  });

  testWidgets("les commandes ne dessinent rien tant qu'il n'y a pas de flux", (tester) async {
    final camera = InlineCameraController();
    addTearDown(camera.dispose);
    await camera.start();

    await tester.pumpWidget(
      Localizations(
        locale: const Locale('fr'),
        delegates: AppLocalizations.localizationsDelegates,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(width: 200, height: 250, child: InlineCameraControls(controller: camera)),
        ),
      ),
    );

    expect(find.byType(GestureDetector), findsNothing);
    expect(find.byType(Text), findsNothing);
    expect(tester.takeException(), isNull);
  });

  group('le pincement', () {
    // Le cadre du viseur se touche pour déclencher : le pincement vit sous
    // lui, dans le même arbre, comme sur les trois écrans de prise de vue.
    Future<({List<double> scales, int Function() taps})> monter(WidgetTester tester) async {
      final scales = <double>[];
      var taps = 0;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: GestureDetector(
            onTap: () => taps++,
            child: RawGestureDetector(
              behavior: HitTestBehavior.opaque,
              gestures: {
                PinchRecognizer: GestureRecognizerFactoryWithHandlers<PinchRecognizer>(
                  PinchRecognizer.new,
                  (r) => r.onUpdate = (d) {
                    if (d.pointerCount >= 2) scales.add(d.scale);
                  },
                ),
              },
              child: const SizedBox(width: 300, height: 400),
            ),
          ),
        ),
      );
      return (scales: scales, taps: () => taps);
    }

    testWidgets("un toucher d'un doigt déclenche toujours", (tester) async {
      final t = await monter(tester);
      await tester.tapAt(const Offset(150, 200));
      await tester.pump();
      expect(t.taps(), 1);
      expect(t.scales, isEmpty);
    });

    testWidgets("deux doigts qui s'écartent zooment sans déclencher", (tester) async {
      final t = await monter(tester);
      // Le premier doigt reste immobile et le second s'écarte à peine, sous
      // le seuil d'un pincement ordinaire : sans la réservation du geste, le
      // premier doigt déclenchait la photo en se levant.
      final first = await tester.startGesture(const Offset(150, 200), pointer: 1);
      final second = await tester.startGesture(const Offset(150, 240), pointer: 2);
      await tester.pump();
      await second.moveTo(const Offset(150, 250));
      await tester.pump();
      await second.up();
      await first.up();
      await tester.pump();

      expect(t.taps(), 0);
      expect(t.scales, isNotEmpty);
      expect(t.scales.last, greaterThan(1));
    });
  });
}
