import 'package:flora/core/window_regions.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// La lecture de ce que le système réserve dans la fenêtre.
///
/// Le natif rend des rectangles bruts ; c'est ici qu'ils deviennent les trois
/// cotes dont le menu debout a besoin. Le test tient autant aux refus qu'aux
/// lectures : une valeur invraisemblable doit disparaître plutôt que déplacer
/// le menu, parce que l'appelant sait retomber sur sa mesure et pas sur un axe
/// absurde.
void main() {
  Map<String, Object?> rect(double x, double y, double w, double h) => {
    'x': x,
    'y': y,
    'width': w,
    'height': h,
  };

  /// La bande du système sur l'iPhone Duo fermé : elle part du bord haut,
  /// fait 84 points de large — la marge sûre de ce côté — et 170 de haut.
  final bande = rect(382, 0, 84, 170);

  /// La caméra, qui flotte dedans. Son milieu est à 47,8 points du bord
  /// droit ; celui de la bande à 42.
  final camera = rect(399.667, 29.333, 37, 37);

  /// Ce que `statusBarFrame` rend sur cet appareil : 466 × 2 points en haut à
  /// gauche, pendant que l'heure est debout contre le bord droit.
  final barreInutile = rect(0, 0, 466, 2);

  /// Le relevé du 20 septembre 2026, tel qu'il est sorti du simulateur.
  Map<String, Object?> duo({
    Object? statusBar,
    List<Object?>? occlusions,
    List<Object?>? divisions,
  }) => {
    'available': true,
    'width': 466.0,
    'height': 678.0,
    'statusBar': ?statusBar,
    'occlusions': occlusions ?? [camera, bande],
    'divisions': divisions ?? const <Object?>[],
  };

  group('ce qui ne se lit pas', () {
    test('une réponse sans régions n\'annonce rien', () {
      expect(WindowRegionsService.parse(const {'available': false, 'reason': 'noView'}).isEmpty, isTrue);
      expect(WindowRegionsService.parse(const {}).isEmpty, isTrue);
      expect(WindowRegionsService.parse(const {'available': true}).isEmpty, isTrue);
      expect(WindowRegionsService.parse(const {'available': true, 'width': 0.0, 'height': 678.0}).isEmpty, isTrue);
    });

    test('un rectangle incomplet est ignoré', () {
      final regions = WindowRegionsService.parse(
        duo(statusBar: const {'x': 0.0, 'y': 0.0}, occlusions: const [<String, Object?>{}, 'bruit']),
      );
      expect(regions.isEmpty, isTrue);
    });
  });

  group('le bas de la pile', () {
    test('vient de la bande, qui part du bord haut', () {
      expect(WindowRegionsService.parse(duo(statusBar: barreInutile)).systemStackBottom, 170);
    });

    test('la caméra seule ne le donne pas', () {
      // Elle est le haut de la pile, jamais son bas : l'heure et le wifi sont
      // dessous, et rien ici ne dit jusqu'où. On garde la mesure.
      expect(WindowRegionsService.parse(duo(occlusions: [camera])).systemStackBottom, isNull);
    });

    test('la barre d\'état du Duo ne le donne pas non plus', () {
      // Deux points de haut : un cadre dégénéré ne borne rien.
      final regions = WindowRegionsService.parse(duo(statusBar: barreInutile, occlusions: const <Object?>[]));
      expect(regions.systemStackBottom, isNull);
    });

    test('sur un appareil d\'un seul écran, la barre d\'état le donne', () {
      final regions = WindowRegionsService.parse({
        'available': true,
        'width': 402.0,
        'height': 874.0,
        'statusBar': rect(0, 0, 402, 54),
        'occlusions': const <Object?>[],
        'divisions': const <Object?>[],
      });
      expect(regions.systemStackBottom, 54);
    });

    test('une pile de plus d\'un tiers de la fenêtre est écartée', () {
      final regions = WindowRegionsService.parse(duo(occlusions: [camera, rect(382, 0, 84, 400)]));
      expect(regions.systemStackBottom, isNull);
      // L'axe, lui, reste lisible sur la caméra.
      expect(regions.systemAxisFromRight, closeTo(47.8, 0.1));
    });
  });

  group('l\'axe', () {
    test('se lit sur la plus étroite des régions, la caméra', () {
      // 47,8 points du bord droit — et non les 42 du milieu de la bande.
      expect(WindowRegionsService.parse(duo()).systemAxisFromRight, closeTo(47.8, 0.1));
    });

    test('sans caméra, la bande fait l\'affaire', () {
      expect(WindowRegionsService.parse(duo(occlusions: [bande])).systemAxisFromRight, 42);
    });

    test('sans région, il se lit sur la barre d\'état', () {
      final regions = WindowRegionsService.parse(
        duo(statusBar: rect(402, 0, 64, 170), occlusions: const <Object?>[]),
      );
      expect(regions.systemAxisFromRight, 32);
    });

    test('une barre d\'état couchée n\'en donne pas', () {
      // Son milieu est au milieu de l'écran : ce n'est pas une colonne.
      final regions = WindowRegionsService.parse(duo(statusBar: barreInutile, occlusions: const <Object?>[]));
      expect(regions.systemAxisFromRight, isNull);
    });

    test('collé au bord, il est écarté', () {
      expect(WindowRegionsService.parse(duo(occlusions: [rect(456, 24, 10, 10)])).systemAxisFromRight, isNull);
    });
  });

  group('le pli', () {
    test('est rendu tel quel', () {
      expect(
        WindowRegionsService.parse(duo(divisions: [rect(0, 333, 466, 12)])).fold,
        const Rect.fromLTWH(0, 333, 466, 12),
      );
    });

    test('vide, ce n\'est pas un pli', () {
      expect(WindowRegionsService.parse(duo(divisions: [rect(0, 333, 0, 0)])).fold, isNull);
      expect(WindowRegionsService.parse(duo()).fold, isNull);
    });
  });

  group('le canal', () {
    const canal = MethodChannel('ch.vergasta.plant/window_regions');
    late Object? reponse;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      WindowRegionsService.debugForceSupported = true;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(canal, (call) async => reponse);
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(canal, null);
      WindowRegionsService.debugForceSupported = false;
      WindowRegionsService.detach();
      WindowRegionsService.regions.value = const WindowRegions();
      WindowRegionsService.lastAnswer.value = 'pas encore demandé';
    });

    test('les régions sont à jour avant que la réponse ne s\'annonce', () async {
      // L'ordre n'est pas un détail : la sonde écoute la réponse pour écrire
      // son relevé, et elle lisait des régions encore vides. Une seule
      // réponse suffisant à l'appareil, le relevé restait faux pour de bon.
      reponse = duo(statusBar: barreInutile);
      WindowRegions? vuesParLAuditeur;
      void auditeur() => vuesParLAuditeur = WindowRegionsService.regions.value;
      WindowRegionsService.lastAnswer.addListener(auditeur);
      addTearDown(() => WindowRegionsService.lastAnswer.removeListener(auditeur));

      await WindowRegionsService.refresh();

      expect(vuesParLAuditeur?.systemStackBottom, 170);
      expect(vuesParLAuditeur?.systemAxisFromRight, closeTo(47.8, 0.1));
    });

    test('un canal absent laisse les mesures et le dit', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(canal, null);
      await WindowRegionsService.refresh();
      expect(WindowRegionsService.regions.value.isEmpty, isTrue);
      expect(WindowRegionsService.lastAnswer.value, contains('canal absent'));
    });

    test('la réponse s\'écrit à clés triées', () async {
      reponse = duo(statusBar: barreInutile);
      await WindowRegionsService.refresh();
      final rendu = WindowRegionsService.lastAnswer.value;
      expect(rendu.indexOf('available'), lessThan(rendu.indexOf('divisions')));
      expect(rendu.indexOf('occlusions'), lessThan(rendu.indexOf('statusBar')));
    });
  });

  test('deux lectures identiques se valent', () {
    expect(WindowRegionsService.parse(duo()), WindowRegionsService.parse(duo()));
    expect(WindowRegionsService.parse(duo()).hashCode, WindowRegionsService.parse(duo()).hashCode);
  });
}
