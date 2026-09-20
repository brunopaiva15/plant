import 'package:flora/app/window.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Dans quelle fenêtre l'application se trouve, mesuré à chaque fois plutôt
/// que lu au démarrage.
///
/// C'est la seule question qui reste de ce côté. Il y a eu ici un verrou
/// d'orientation ; il est parti, parce que l'iPhone Duo refuse la demande
/// (`UISceneErrorDomain Code=101`) et que partout ailleurs `Info.plist` et le
/// manifeste Android disaient déjà la même chose. Ce qui compte, c'est que la
/// réponse suive le pli : un appareil qui s'ouvre passe de 466 à 669 points
/// de large sans rien relancer.
///
/// Les cotes viennent de Xcode 27.1, sur un binaire construit avec le SDK
/// 27.1 — celui qui dessine bord-à-bord.
const Size closed = Size(466, 678);
const Size opened = Size(669, 951);
const Size tablet = Size(1024, 1366);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Pose une fenêtre de [size] points, comme le ferait le système.
  void resize(WidgetTester tester, Size size) {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = size * 3;
  }

  group('la fenêtre courante', () {
    testWidgets('un téléphone est compact', (tester) async {
      addTearDown(tester.view.reset);
      resize(tester, closed);
      expect(isCompactWindow(), isTrue);
    });

    testWidgets('une tablette ne l\'est pas', (tester) async {
      addTearDown(tester.view.reset);
      resize(tester, tablet);
      expect(isCompactWindow(), isFalse);
    });

    testWidgets('et la réponse change au pli, sans relancer quoi que ce soit', (tester) async {
      addTearDown(tester.view.reset);
      resize(tester, closed);
      expect(isCompactWindow(), isTrue);

      resize(tester, opened);
      expect(isCompactWindow(), isFalse, reason: 'une taille lue au démarrage resterait pour la séance');

      resize(tester, closed);
      expect(isCompactWindow(), isTrue);
    });

    testWidgets('une fenêtre pas encore mesurable ne conclut rien', (tester) async {
      addTearDown(tester.view.reset);
      resize(tester, Size.zero);
      // Mieux vaut une tablette libre qu'un téléphone bloqué par erreur.
      expect(isCompactWindow(), isFalse);
    });
  });
}
