import 'dart:typed_data';

import 'package:flora/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Une photo devient sa vignette, à la manière de l'application ChatGPT :
/// elle part de l'endroit exact où elle était à l'écran — le viseur, le
/// bouton de la galerie — et se rétracte ou grandit jusqu'à sa place, vite,
/// sans fondu ni temps d'arrêt.
///
/// Le test regarde les rectangles, pas la sensation : la photo part du
/// départ, se rapproche de sa place, s'y pose ; la place reste cachée tant
/// qu'elle vole ; rien ne vole sans annonce, ni deux fois pour la même, ni
/// avec *réduire les animations*.

/// Un PNG d'un pixel. Le décodage n'aboutit pas sous l'horloge des tests :
/// c'est le délai [PhotoLanding.decodeWait] qui donne le départ.
final _pixel = MemoryImage(Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, //
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0xF8, 0xCF, 0xC0, 0xF0,
  0x1F, 0x00, 0x05, 0x00, 0x01, 0xFF, 0x89, 0x99, 0x3D, 0x1D, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45,
  0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]));

const _slot = Key('slot');
const _button = Key('button');

/// Le cadre du viseur, en haut ; la case, en bas à gauche.
const _viewfinder = Rect.fromLTWH(20, 60, 360, 450);

Future<void> _pump(WidgetTester tester, {Object? tag = 'photo', bool reduceMotion = false}) async {
  tester.view
    ..physicalSize = const Size(400, 800)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: const Size(400, 800), disableAnimations: reduceMotion),
        child: Scaffold(
          body: Stack(
            children: [
              const Positioned(left: 300, top: 700, width: 40, height: 40, child: ColoredBox(key: _button, color: Color(0xFF000000))),
              Positioned(
                left: 24,
                top: 712,
                width: 64,
                height: 64,
                child: PhotoLanding(tag: tag, child: const ColoredBox(key: _slot, color: Color(0xFF00AA00))),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Avance de [duration], une image à la fois.
Future<void> _frames(WidgetTester tester, Duration duration) async {
  const frame = Duration(milliseconds: 16);
  for (var t = Duration.zero; t < duration; t += frame) {
    await tester.pump(frame);
  }
}

/// Jusqu'au départ : le délai de décodage, puis l'image qui l'insère.
Future<void> _launch(WidgetTester tester) async {
  await tester.pump(PhotoLanding.decodeWait);
  await tester.pump();
}

/// La photo en vol, s'il y en a une : la seule image de l'arbre.
Finder get _flight => find.byType(Image);

double _flightOpacity(WidgetTester tester) => tester.widget<Opacity>(find.ancestor(of: _flight, matching: find.byType(Opacity)).first).opacity;

BorderRadius _flightRadius(WidgetTester tester) =>
    tester.widget<ClipRRect>(find.ancestor(of: _flight, matching: find.byType(ClipRRect))).borderRadius as BorderRadius;

double _slotOpacity(WidgetTester tester) =>
    tester.widget<Opacity>(find.ancestor(of: find.byKey(_slot), matching: find.byType(Opacity)).first).opacity;

void main() {
  tearDown(PhotoLanding.reset);

  testWidgets('prise dans le viseur, la photo s’en détache et se rétracte dans sa case', (tester) async {
    PhotoLanding.expect('photo', _pixel, from: const PhotoOrigin(_viewfinder, radius: Radii.xlAll, showsPhoto: true));
    await _pump(tester);
    final target = tester.getRect(find.byKey(_slot));

    // Tant qu'elle vole, sa place est vide : deux photos à l'écran, ce serait
    // un fondu, pas un déplacement.
    expect(_slotOpacity(tester), 0);
    await _launch(tester);
    expect(_flight, findsOneWidget);
    // Elle est exactement le viseur, et déjà tout entière : le viseur la
    // montrait.
    final start = tester.getRect(_flight);
    expect(start.left, closeTo(_viewfinder.left, 1));
    expect(start.width, closeTo(_viewfinder.width, 8));
    expect(_flightOpacity(tester), 1);

    // Vive : aux neuf dixièmes du trajet en 150 ms.
    await _frames(tester, const Duration(milliseconds: 150));
    final mid = tester.getRect(_flight);
    final done = 1 - (mid.center - target.center).distance / (_viewfinder.center - target.center).distance;
    expect(done, greaterThan(0.85));

    await tester.pumpAndSettle();
    expect(_flight, findsNothing);
    expect(_slotOpacity(tester), 1);
    expect(PhotoLanding.pending, 0);
  });

  testWidgets('choisie dans la galerie, la photo sort du bouton touché', (tester) async {
    await _pump(tester, tag: null);
    final button = PhotoOrigin.of(tester.element(find.byKey(_button)));
    expect(button, isNotNull);
    // Un bouton rond : le rayon est ramené à la demi-largeur, pas laissé à
    // 999, sans quoi la photo resterait ronde jusqu'au dernier instant.
    expect(button!.radius.topLeft.x, 20);

    PhotoLanding.expect('photo', _pixel, from: button);
    await _pump(tester);
    await _launch(tester);
    expect(tester.getRect(_flight).center.dx, closeTo(320, 2));
    expect(_flightRadius(tester).topLeft.x, closeTo(20, 1));
    // Le bouton ne montrait pas la photo : elle s'y dessine en partant.
    expect(_flightOpacity(tester), lessThan(1));

    await _frames(tester, const Duration(milliseconds: 400));
    expect(_flightOpacity(tester), 1);
    expect(_flightRadius(tester).topLeft.x, closeTo(Radii.medium, 0.5));
    await tester.pumpAndSettle();
    expect(_slotOpacity(tester), 1);
  });

  testWidgets('sans point de départ, elle se pose sur place', (tester) async {
    PhotoLanding.expect('photo', _pixel);
    await _pump(tester);
    final target = tester.getRect(find.byKey(_slot));
    await _launch(tester);
    final start = tester.getRect(_flight);
    expect(start.center, offsetMoreOrLessEquals(target.center, epsilon: 1));
    expect(start.width, lessThan(target.width));
    await tester.pumpAndSettle();
    expect(_slotOpacity(tester), 1);
  });

  testWidgets('sans annonce, la photo est simplement là', (tester) async {
    await _pump(tester);
    expect(_slotOpacity(tester), 1);
    await tester.pump(PhotoLanding.decodeWait);
    expect(_flight, findsNothing);
  });

  testWidgets('une annonce ne sert qu’une fois', (tester) async {
    PhotoLanding.expect('photo', _pixel);
    await _pump(tester);
    await _launch(tester);
    await tester.pumpAndSettle();

    // La même place se reconstruit ailleurs dans l'arbre : rien ne revole.
    await tester.pumpWidget(const SizedBox());
    await _pump(tester);
    await tester.pump(PhotoLanding.decodeWait);
    expect(_flight, findsNothing);
    expect(_slotOpacity(tester), 1);
  });

  testWidgets('une place qui change de photo la fait venir', (tester) async {
    await _pump(tester, tag: 'avant');
    PhotoLanding.expect('après', _pixel);
    await _pump(tester, tag: 'après');
    expect(_slotOpacity(tester), 0);
    await _launch(tester);
    expect(_flight, findsOneWidget);
    await tester.pumpAndSettle();
    expect(_slotOpacity(tester), 1);
  });

  testWidgets('avec réduire les animations, pas de vol', (tester) async {
    PhotoLanding.expect('photo', _pixel, from: const PhotoOrigin(_viewfinder, showsPhoto: true));
    await _pump(tester, reduceMotion: true);
    expect(_slotOpacity(tester), 1);
    await tester.pump(PhotoLanding.decodeWait);
    expect(_flight, findsNothing);
    expect(PhotoLanding.pending, 0);
  });

  testWidgets('une place qui s’en va pendant le vol emporte la photo', (tester) async {
    PhotoLanding.expect('photo', _pixel, from: const PhotoOrigin(_viewfinder, showsPhoto: true));
    await _pump(tester);
    await _launch(tester);
    expect(_flight, findsOneWidget);
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pumpAndSettle();
    expect(_flight, findsNothing);
  });
}
