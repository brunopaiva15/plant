import 'dart:typed_data';

import 'package:flora/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Une photo choisie dans la galerie reste devant quand le sélecteur se
/// referme, puis file à sa place, portée par un ressort.
///
/// Le test regarde les rectangles, pas la sensation : la photo part en grand,
/// se rapproche de sa place, et s'y pose ; la place reste cachée tant qu'elle
/// vole ; rien ne vole sans annonce, ni deux fois pour la même, ni avec
/// *réduire les animations*.

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
          body: Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: 64,
                height: 64,
                child: PhotoLanding(tag: tag, child: const ColoredBox(key: _slot, color: Color(0xFF00AA00))),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Avance de [duration], une image à la fois : le ressort part à l'image qui
/// suit la fin de l'apparition.
Future<void> _frames(WidgetTester tester, Duration duration) async {
  const frame = Duration(milliseconds: 16);
  for (var t = Duration.zero; t < duration; t += frame) {
    await tester.pump(frame);
  }
}

/// La photo en vol, s'il y en a une : la seule image de l'arbre.
Finder get _flight => find.byType(Image);

double _slotOpacity(WidgetTester tester) =>
    tester.widget<Opacity>(find.ancestor(of: find.byKey(_slot), matching: find.byType(Opacity)).first).opacity;

void main() {
  tearDown(PhotoLanding.reset);

  testWidgets('la photo part en grand et se pose à sa place', (tester) async {
    PhotoLanding.expect('photo', _pixel);
    await _pump(tester);
    final target = tester.getRect(find.byKey(_slot));

    // Tant qu'elle vole, sa place est vide : deux photos à l'écran, ce serait
    // un fondu, pas un déplacement.
    expect(_slotOpacity(tester), 0);
    await tester.pump(PhotoLanding.decodeWait);
    await tester.pump();
    expect(_flight, findsOneWidget);
    final start = tester.getRect(_flight);
    expect(start.width, greaterThan(target.width * 3), reason: 'elle part en grand, au centre');
    expect((start.center.dx - 200).abs(), lessThan(1));

    // Elle se pose en s'éclaircissant, puis se met en route.
    await _frames(tester, Motion.micro + const Duration(milliseconds: 120));
    final mid = tester.getRect(_flight);
    expect((mid.center - target.center).distance, lessThan((start.center - target.center).distance));
    expect(mid.width, lessThan(start.width));

    await tester.pumpAndSettle();
    expect(_flight, findsNothing);
    expect(_slotOpacity(tester), 1);
    expect(PhotoLanding.pending, 0);
  });

  testWidgets('les coins prennent l’arrondi de l’arrivée', (tester) async {
    PhotoLanding.expect('photo', _pixel);
    await _pump(tester);
    await tester.pump(PhotoLanding.decodeWait);
    await tester.pump();
    BorderRadius radius() => tester.widget<ClipRRect>(find.ancestor(of: _flight, matching: find.byType(ClipRRect))).borderRadius as BorderRadius;
    expect(radius(), PhotoLanding.departureRadius);
    await _frames(tester, Motion.micro + const Duration(milliseconds: 600));
    expect(radius().topLeft.x, closeTo(Radii.medium, 0.5));
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
    await tester.pump(PhotoLanding.decodeWait);
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
    await tester.pump(PhotoLanding.decodeWait);
    await tester.pump();
    expect(_flight, findsOneWidget);
    await tester.pumpAndSettle();
    expect(_slotOpacity(tester), 1);
  });

  testWidgets('avec réduire les animations, pas de vol', (tester) async {
    PhotoLanding.expect('photo', _pixel);
    await _pump(tester, reduceMotion: true);
    expect(_slotOpacity(tester), 1);
    await tester.pump(PhotoLanding.decodeWait);
    expect(_flight, findsNothing);
    expect(PhotoLanding.pending, 0);
  });

  testWidgets('une place qui s’en va pendant le vol emporte la photo', (tester) async {
    PhotoLanding.expect('photo', _pixel);
    await _pump(tester);
    await tester.pump(PhotoLanding.decodeWait);
    await tester.pump();
    expect(_flight, findsOneWidget);
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pumpAndSettle();
    expect(_flight, findsNothing);
  });
}
