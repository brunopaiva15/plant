import 'package:flora/app/orientation_lock.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Le verrou de portrait, sur un appareil qui change de taille en cours de
/// route.
///
/// Un iPhone Duo fermé montre environ 466 points de large, ouvert 669 : c'est
/// la même application, le même lancement, et pourtant l'un est un téléphone —
/// une colonne, portrait — et l'autre une tablette, qu'iOS fait tourner de toute
/// façon (l'écran intérieur n'honore pas `UISupportedInterfaceOrientations`).
/// Le verrou doit donc se poser et se retirer à chaque pli, là où une mesure
/// prise au démarrage restait pour la séance entière.
const Size closed = Size(466, 678);
const Size opened = Size(669, 951);
const Size tablet = Size(1024, 1366);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<String> requested;

  setUp(() {
    requested = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemChrome.setPreferredOrientations') {
          // Une liste vide : le système reprend la main, l'application ne
          // demande plus rien.
          final orientations = (call.arguments as List).cast<String>();
          requested.add(orientations.isEmpty ? 'libre' : orientations.join(','));
        }
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null);
  });

  /// Pose une fenêtre de [size] points, comme le ferait le système.
  void resize(WidgetTester tester, Size size) {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = size * 3;
  }

  group('le verrou de portrait', () {
    testWidgets('tient le portrait sur un téléphone', (tester) async {
      addTearDown(tester.view.reset);
      resize(tester, closed);
      final lock = OrientationLock();
      addTearDown(lock.detach);

      await lock.attach();
      await tester.idle();

      expect(isCompactWindow(), isTrue);
      expect(requested, ['DeviceOrientation.portraitUp']);
    });

    testWidgets('ne verrouille rien sur une tablette', (tester) async {
      addTearDown(tester.view.reset);
      resize(tester, tablet);
      final lock = OrientationLock();
      addTearDown(lock.detach);

      await lock.attach();
      await tester.idle();

      expect(isCompactWindow(), isFalse);
      expect(requested, ['libre']);
    });

    testWidgets("rend ses orientations à l'appareil qu'on déplie, et les reprend", (tester) async {
      addTearDown(tester.view.reset);
      resize(tester, closed);
      final lock = OrientationLock();
      addTearDown(lock.detach);
      await lock.attach();
      await tester.idle();
      expect(requested, ['DeviceOrientation.portraitUp']);

      resize(tester, opened);
      await tester.idle();
      expect(requested.last, 'libre');
      expect(lock.portrait, isFalse);

      resize(tester, closed);
      await tester.idle();
      expect(requested.last, 'DeviceOrientation.portraitUp');
      expect(lock.portrait, isTrue);
    });

    testWidgets("ne redit rien au système quand la fenêtre bouge sans changer de camp", (tester) async {
      addTearDown(tester.view.reset);
      resize(tester, closed);
      final lock = OrientationLock();
      addTearDown(lock.detach);
      await lock.attach();
      await tester.idle();

      // Un clavier qui monte, une barre d'état qui change : la hauteur bouge,
      // la réponse non.
      resize(tester, const Size(466, 400));
      await tester.idle();
      resize(tester, closed);
      await tester.idle();

      expect(requested, ['DeviceOrientation.portraitUp']);
    });

    testWidgets("ne conclut rien d'une fenêtre pas encore mesurable", (tester) async {
      addTearDown(tester.view.reset);
      resize(tester, Size.zero);

      // Mieux vaut une tablette libre qu'un téléphone bloqué par erreur.
      expect(isCompactWindow(), isFalse);
    });
  });
}
