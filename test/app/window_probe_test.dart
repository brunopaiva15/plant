import 'package:flora/app/window_probe.dart';
import 'package:flora/core/window_regions.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// La sonde de fenêtre écrit les cotes dans la console, en debug.
///
/// Elle est passée par une version derrière `--dart-define=WINDOW_DEBUG`, où
/// elle n'écrivait rien du tout sur un vrai appareil : le drapeau se passe
/// silencieusement de travers, et un relevé écrit depuis `main()` — avant que
/// l'application ait ouvert sa fenêtre — n'atteint pas la console de
/// `flutter run`. D'où les deux choses que ce test tient : elle écrit sans
/// qu'on lui demande rien, et elle attend la première image pour le faire.
Future<List<String>> _capture(WidgetTester tester, Future<void> Function() body) async {
  final lignes = <String>[];
  final original = debugPrint;
  // `debugPrint` est rendu dans le corps du test, jamais dans un teardown : la
  // suite vérifie les variables de debug avant d'appeler ceux-ci.
  debugPrint = (String? message, {int? wrapWidth}) => lignes.add(message ?? '');
  try {
    await body();
  } finally {
    debugPrint = original;
  }
  return lignes;
}

void main() {
  /// Pose une fenêtre de [size] points, comme le ferait le système.
  void resize(WidgetTester tester, Size size) {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = size * 3;
  }

  testWidgets('elle écrit sans qu\'on lui demande rien, une fois la première image passée', (tester) async {
    addTearDown(WindowProbe.detach);
    addTearDown(tester.view.reset);
    // L'écran intérieur du Duo ouvert, mesuré dans Xcode 27.1 sur un binaire
    // bord-à-bord.
    resize(tester, const Size(669, 951));

    final lignes = await _capture(tester, () async {
      // `main()` appelle la sonde avant qu'aucune image n'ait été rendue.
      WindowProbe.attach();
      await tester.pumpWidget(const SizedBox());
      await tester.idle();
    });

    expect(lignes, isNotEmpty, reason: 'la sonde n\'a rien écrit');
    final bloc = lignes.join('\n');
    expect(bloc, contains('[auxine:fenêtre]'));
    expect(bloc, contains('669.0 × 951.0 pt'));
    expect(bloc, contains('displayFeatures est vide'));
    // Le menu relevé est celui qui sera posé : 669 × 951 le met debout.
    expect(bloc, contains('debout, à droite'));
  });

  testWidgets('elle dit pourquoi le système n\'annonce rien', (tester) async {
    addTearDown(WindowProbe.detach);
    addTearDown(tester.view.reset);
    resize(tester, const Size(669, 951));

    final lignes = await _capture(tester, () async {
      WindowProbe.attach();
      await tester.pumpWidget(const SizedBox());
      await tester.idle();
    });

    // « Aucune région annoncée » a trop de causes pour se lire seul : la
    // ligne suivante les distingue, et c'est elle qu'on lira sur l'appareil.
    final bloc = lignes.join('\n');
    expect(bloc, contains('régions système'));
    expect(bloc, contains('réponse du natif'));
  });

  testWidgets('une réponse tardive du natif donne un relevé de plus', (tester) async {
    addTearDown(WindowProbe.detach);
    addTearDown(tester.view.reset);
    addTearDown(() => WindowRegionsService.lastAnswer.value = 'pas encore demandé');
    resize(tester, const Size(669, 951));

    final lignes = await _capture(tester, () async {
      WindowProbe.attach();
      await tester.pumpWidget(const SizedBox());
      await tester.idle();

      // Le natif répond après la première image : sans l'écoute, le relevé
      // resterait sur son « pas encore demandé ».
      WindowRegionsService.lastAnswer.value = '{available: true}';
      await tester.idle();
    });

    final releves = lignes.where((l) => l.startsWith('[auxine:fenêtre] relevé ')).toList();
    expect(releves.length, 2);
    expect(releves.last, contains('{available: true}'));
  });

  testWidgets('un pli donne un nouveau relevé, un clavier n\'en donne pas', (tester) async {
    addTearDown(WindowProbe.detach);
    addTearDown(tester.view.reset);
    resize(tester, const Size(466, 678));

    final lignes = await _capture(tester, () async {
      WindowProbe.attach();
      await tester.pumpWidget(const SizedBox());
      await tester.idle();

      // L'appareil s'ouvre : la fenêtre change, un relevé de plus.
      resize(tester, const Size(669, 951));
      await tester.idle();

      // La même fenêtre redite : rien à réécrire.
      resize(tester, const Size(669, 951));
      await tester.idle();
    });

    final releves = lignes.where((l) => l.startsWith('[auxine:fenêtre] relevé ')).toList();
    expect(releves.length, 2, reason: 'un relevé au départ, un à l\'ouverture, et pas un de plus');
    expect(releves.first, contains('466.0 × 678.0 pt'));
    expect(releves.last, contains('669.0 × 951.0 pt'));
  });
}
