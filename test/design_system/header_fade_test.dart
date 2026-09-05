import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flora/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Le fond de l'écran, et donc la couleur que l'en-tête doit avoir atteinte
/// quand le contenu commence.
const _canvas = Color(0xFFF3F6F1);

/// Une fausse photo bien plus sombre que le fond : toute rupture se voit.
const _photo = Color(0xFF6E6A66);

const _expanded = 400.0;

Widget _page({required bool fade, double expanded = _expanded}) {
  Widget header = const FlexibleSpaceBar(
    stretchModes: [StretchMode.zoomBackground],
    background: ColoredBox(color: _photo),
  );
  if (fade) header = HeaderFade(child: header);
  return MaterialApp(
    // La capture englobe le fond de l'écran : c'est lui que l'en-tête doit
    // rejoindre sans marche.
    home: RepaintBoundary(
      key: const Key('shot'),
      child: Scaffold(
        backgroundColor: _canvas,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(expandedHeight: expanded, pinned: true, backgroundColor: _canvas, surfaceTintColor: Colors.transparent, toolbarHeight: 56, flexibleSpace: header),
            const SliverToBoxAdapter(child: SizedBox(height: 1200)),
          ],
        ),
      ),
    ),
  );
}

/// La colonne centrale de l'écran rendu, du haut vers le bas, en luminance.
Future<List<int>> _column(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(const Key('shot')));
  final ui.Image image = await boundary.toImage();
  final ByteData data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  final x = image.width ~/ 2;
  final column = <int>[
    for (var y = 0; y < image.height; y++)
      // Le vert suffit : les deux couleurs de ce test ne se confondent pas.
      data.getUint8((y * image.width + x) * 4 + 1),
  ];
  image.dispose();
  return column;
}

Future<List<int>> _render(WidgetTester tester, {required bool fade, required double offset, double expanded = _expanded}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_page(fade: fade, expanded: expanded));
  await tester.pumpAndSettle();
  if (offset > 0) {
    tester.state<ScrollableState>(find.byType(Scrollable)).position.jumpTo(offset);
    await tester.pumpAndSettle();
  }
  // La capture d'image demande du vrai temps asynchrone.
  late List<int> column;
  await tester.runAsync(() async => column = await _column(tester));
  return column;
}

/// Le plus grand écart entre deux lignes voisines : la mesure d'une rupture.
int _biggestStep(List<int> column) {
  var worst = 0;
  for (var y = 1; y < column.length; y++) {
    final step = (column[y] - column[y - 1]).abs();
    if (step > worst) worst = step;
  }
  return worst;
}

void main() {
  // À chaque hauteur : en-tête déployé, à demi replié, presque replié.
  const offsets = [0.0, 60.0, 140.0, 260.0];

  group('HeaderFade', () {
    for (final offset in offsets) {
      testWidgets('aucune rupture visible à $offset px de défilement', (tester) async {
        final column = await _render(tester, fade: true, offset: offset);
        // Un fondu de 180 px entre deux couleurs séparées de ~135 niveaux ne
        // peut pas varier de plus de deux ou trois niveaux d'une ligne à
        // l'autre. Une coupure franche, elle, saute d'un coup.
        expect(_biggestStep(column), lessThan(8), reason: 'le fondu doit rester progressif');
      });
    }

    // Sur un iPhone, la hauteur de l'en-tête vaut la largeur × 1,05 : elle
    // tombe presque toujours sur une fraction de pixel, et c'est là que la
    // ligne se cachait — une rangée où la photo passait sans fondu.
    for (final expanded in [412.65, 409.5, 400.25]) {
      for (final offset in [0.0, 37.5, 120.0]) {
        testWidgets('aucune rupture à $expanded px de haut, défilé de $offset', (tester) async {
          final column = await _render(tester, fade: true, offset: offset, expanded: expanded);
          expect(_biggestStep(column), lessThan(8), reason: 'la ligne au bord fractionnaire');
        });
      }
    }

    testWidgets('sans fondu, la coupure est bien là (le test mesure ce qu il faut)', (tester) async {
      final column = await _render(tester, fade: false, offset: 60);
      expect(_biggestStep(column), greaterThan(60));
    });

    testWidgets('l en-tête a rejoint le fond quand le contenu commence', (tester) async {
      final column = await _render(tester, fade: true, offset: 60);
      // La dernière ligne de l'en-tête vaut le fond, à un cheveu près.
      final seam = (_expanded - 60).round();
      expect((column[seam - 1] - column[seam + 4]).abs(), lessThan(4));
    });

    testWidgets('replié, l en-tête ne laisse plus voir la photo', (tester) async {
      final column = await _render(tester, fade: true, offset: 400);
      // Sur toute la barre repliée, plus rien d'aussi sombre que la photo.
      expect(column.take(56).every((v) => v > 200), isTrue);
    });
  });
}
