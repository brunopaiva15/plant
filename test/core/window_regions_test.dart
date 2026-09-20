import 'package:flora/core/window_regions.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// La lecture de ce que le système réserve dans la fenêtre.
///
/// Le natif rend des rectangles bruts ; c'est ici qu'ils deviennent les trois
/// cotes dont le menu debout a besoin. Le test tient surtout aux refus : une
/// valeur invraisemblable doit disparaître plutôt que déplacer le menu, parce
/// que l'appelant sait retomber sur sa mesure et pas sur un axe absurde.
void main() {
  Map<String, Object?> rect(double x, double y, double w, double h) => {
    'x': x,
    'y': y,
    'width': w,
    'height': h,
  };

  /// L'iPhone Duo ouvert, portrait : pile du système debout contre le bord
  /// droit, caméra en haut de cette pile.
  Map<String, Object?> duoOuvert({
    Object? statusBar,
    List<Object?>? occlusions,
    List<Object?>? divisions,
  }) => {
    'available': true,
    'width': 669.0,
    'height': 951.0,
    'statusBar': statusBar ?? rect(605, 0, 64, 140),
    'occlusions': occlusions ?? [rect(610, 24, 22, 22)],
    'divisions': divisions ?? const <Object?>[],
  };

  test('sans réponse utilisable, rien n\'est annoncé', () {
    expect(WindowRegionsService.parse(const {'available': false, 'reason': 'noView'}).isEmpty, isTrue);
    expect(WindowRegionsService.parse(const {}).isEmpty, isTrue);
    expect(WindowRegionsService.parse(const {'available': true}).isEmpty, isTrue);
    expect(WindowRegionsService.parse(const {'available': true, 'width': 0.0, 'height': 951.0}).isEmpty, isTrue);
  });

  test('la pile descend jusqu\'au bas de la barre d\'état', () {
    expect(WindowRegionsService.parse(duoOuvert()).systemStackBottom, 140);
  });

  test('une occlusion plus basse que la barre d\'état l\'emporte', () {
    final regions = WindowRegionsService.parse(duoOuvert(occlusions: [rect(610, 24, 22, 22), rect(610, 150, 22, 30)]));
    expect(regions.systemStackBottom, 180);
  });

  test('l\'axe se lit sur la caméra', () {
    expect(WindowRegionsService.parse(duoOuvert()).systemAxisFromRight, 48);
  });

  test('sans caméra, l\'axe se lit sur la barre d\'état', () {
    final regions = WindowRegionsService.parse(duoOuvert(occlusions: const <Object?>[]));
    expect(regions.systemAxisFromRight, 32);
  });

  test('une barre d\'état couchée ne donne pas d\'axe', () {
    // Au milieu de la fenêtre : ce n'est pas une colonne de bord.
    final regions = WindowRegionsService.parse(duoOuvert(statusBar: rect(0, 0, 669, 54), occlusions: const <Object?>[]));
    expect(regions.systemAxisFromRight, isNull);
    expect(regions.systemStackBottom, 54);
  });

  test('une pile qui prendrait le tiers de la fenêtre est écartée', () {
    final regions = WindowRegionsService.parse(duoOuvert(statusBar: rect(605, 0, 64, 400)));
    expect(regions.systemStackBottom, isNull);
    // L'axe, lui, reste lisible sur la caméra.
    expect(regions.systemAxisFromRight, 48);
  });

  test('une pile haute de rien est écartée', () {
    final regions = WindowRegionsService.parse(
      duoOuvert(statusBar: rect(605, 0, 64, 4), occlusions: const <Object?>[]),
    );
    expect(regions.systemStackBottom, isNull);
  });

  test('un axe collé au bord est écarté', () {
    final regions = WindowRegionsService.parse(duoOuvert(occlusions: [rect(659, 24, 10, 10)]));
    expect(regions.systemAxisFromRight, isNull);
  });

  test('le pli est rendu tel quel', () {
    final regions = WindowRegionsService.parse(duoOuvert(divisions: [rect(0, 470, 669, 12)]));
    expect(regions.fold, const Rect.fromLTWH(0, 470, 669, 12));
  });

  test('un pli vide n\'est pas un pli', () {
    expect(WindowRegionsService.parse(duoOuvert(divisions: [rect(0, 470, 0, 0)])).fold, isNull);
    expect(WindowRegionsService.parse(duoOuvert()).fold, isNull);
  });

  test('un rectangle incomplet est ignoré', () {
    final regions = WindowRegionsService.parse(
      duoOuvert(statusBar: const {'x': 605.0, 'y': 0.0}, occlusions: const [<String, Object?>{}, 'bruit']),
    );
    expect(regions.isEmpty, isTrue);
  });

  test('une caméra seule ne dit pas où finit la pile', () {
    // La caméra est le haut de la pile, pas son bas : l'heure et le wifi
    // sont dessous, et rien ici ne dit jusqu'où. On garde la mesure.
    final regions = WindowRegionsService.parse(duoOuvert(statusBar: null)..remove('statusBar'));
    expect(regions.systemStackBottom, isNull);
    expect(regions.systemAxisFromRight, 48, reason: 'l\'axe, lui, reste lisible');
  });

  test('la réponse mesurée sur l\'iPhone Duo fermé ne donne rien', () {
    // Relevé le 20 septembre 2026 sur le simulateur, écran extérieur : la
    // barre d'état est debout contre le bord droit, mais `statusBarFrame`
    // rend 466 × 2 points en haut à gauche. Rien n'en sort, et c'est voulu.
    final regions = WindowRegionsService.parse({
      'available': true,
      'width': 466.0,
      'height': 678.0,
      'statusBar': rect(0, 0, 466, 2),
      'occlusions': const <Object?>[],
      'divisions': const <Object?>[],
    });
    expect(regions.isEmpty, isTrue);
  });

  test('deux lectures identiques se valent', () {
    expect(WindowRegionsService.parse(duoOuvert()), WindowRegionsService.parse(duoOuvert()));
    expect(
      WindowRegionsService.parse(duoOuvert()).hashCode,
      WindowRegionsService.parse(duoOuvert()).hashCode,
    );
  });
}
