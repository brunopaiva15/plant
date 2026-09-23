import 'package:flora/design_system/design_system.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ce qui bouge sous le doigt suit une physique, pas une courbe de durée
/// fixe : la pièce s'aplatit en s'enfonçant, se détend en dépassant, et la
/// bulle de la barre d'onglets glisse d'un onglet à l'autre.
///
/// Le test regarde les matrices et les rectangles, pas la sensation : ce qu'on
/// verrouille, c'est que les deux axes ne bougent pas de la même façon, que le
/// retour passe au-dessus de la taille au repos, et que rien de tout cela ne
/// joue quand la personne a demandé moins d'animations.

const _tabs = [
  FloraTab(icon: CupertinoIcons.sun_max, activeIcon: CupertinoIcons.sun_max_fill, label: 'Aujourd\'hui'),
  FloraTab(icon: CupertinoIcons.square_grid_2x2, activeIcon: CupertinoIcons.square_grid_2x2_fill, label: 'Plantes'),
  FloraTab(icon: CupertinoIcons.house, activeIcon: CupertinoIcons.house_fill, label: 'Jardin'),
  FloraTab(icon: CupertinoIcons.person, activeIcon: CupertinoIcons.person_fill, label: 'Profil'),
];

Future<void> _pump(WidgetTester tester, Widget child, {bool reduceMotion = false}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildFloraTheme(Brightness.light),
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: Scaffold(body: Center(child: child)),
      ),
    ),
  );
  await tester.pump();
}

/// Les facteurs d'échelle que [Pressable] applique, (largeur, hauteur).
(double, double) _scale(WidgetTester tester) {
  final transform = tester.widget<Transform>(
    find.descendant(of: find.byType(Pressable), matching: find.byType(Transform)).first,
  );
  return (transform.transform.storage[0], transform.transform.storage[5]);
}

/// La pression que l'argile de la pièce reçoit.
double _clayPress(WidgetTester tester) {
  final paint = tester.widgetList<CustomPaint>(find.byType(CustomPaint)).firstWhere((p) => p.painter is ClayPainter);
  return (paint.painter! as ClayPainter).press;
}

/// La bulle de la barre d'onglets : la seule pièce sauge de la barre.
///
/// La couleur se compare en 8 bits : le thème s'interpole d'un cadre à
/// l'autre, et `Color.lerp` entre deux sauges égales peut s'écarter d'un
/// dernier bit.
Rect _bubble(WidgetTester tester, Color sage) {
  return tester.getRect(
    find.byWidgetPredicate((w) => w is DecoratedBox && w.decoration is BoxDecoration && (w.decoration as BoxDecoration).color?.toARGB32() == sage.toARGB32()),
  );
}

void main() {
  group('la pièce sous le doigt', () {
    testWidgets('s\'aplatit plus qu\'elle ne s\'éloigne', (tester) async {
      await _pump(tester, FloraCard(onTap: () {}, child: const SizedBox(width: 200, height: 80)));
      expect(_scale(tester), (1.0, 1.0), reason: 'au repos, la pièce est à sa taille');

      final gesture = await tester.startGesture(tester.getCenter(find.byType(FloraCard)));
      addTearDown(() => gesture.up());
      // La première image arme le ressort (temps écoulé nul), la suivante le
      // fait avancer.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));

      final (sx, sy) = _scale(tester);
      expect(sy, lessThan(sx), reason: 'la hauteur doit céder plus que la largeur');
      expect(sx, lessThan(1), reason: 'la pièce ne déborde pas de ses marges sous le doigt');
      expect(1 - sy, greaterThan((1 - sx) * 2), reason: 'l\'écrasement doit se voir, pas se deviner');
    });

    testWidgets('enfonce le relief de l\'argile, puis le rend', (tester) async {
      await _pump(tester, FloraCard(onTap: () {}, child: const SizedBox(width: 200, height: 80)));
      expect(_clayPress(tester), 0);

      final gesture = await tester.startGesture(tester.getCenter(find.byType(FloraCard)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      expect(_clayPress(tester), greaterThan(0.8), reason: 'la pression descend jusqu\'au peintre');

      await gesture.up();
      await tester.pumpAndSettle();
      expect(_clayPress(tester), moreOrLessEquals(0, epsilon: 0.01));
    });

    testWidgets('dépasse sa taille en se détendant', (tester) async {
      await _pump(tester, FloraCard(onTap: () {}, child: const SizedBox(width: 200, height: 80)));
      final gesture = await tester.startGesture(tester.getCenter(find.byType(FloraCard)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      await gesture.up();

      var widest = 0.0;
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        final (sx, _) = _scale(tester);
        if (sx > widest) widest = sx;
      }
      expect(widest, greaterThan(1), reason: 'un ressort qui ne dépasse pas est une courbe');

      await tester.pumpAndSettle();
      final (sx, sy) = _scale(tester);
      expect(sx, moreOrLessEquals(1, epsilon: 0.001), reason: 'et il finit par se poser');
      expect(sy, moreOrLessEquals(1, epsilon: 0.001));
    });

    testWidgets('ne joue rien avec « réduire les animations »', (tester) async {
      await _pump(tester, FloraCard(onTap: () {}, child: const SizedBox(width: 200, height: 80)), reduceMotion: true);
      final gesture = await tester.startGesture(tester.getCenter(find.byType(FloraCard)));
      addTearDown(() => gesture.up());
      // Une seule image, et sans avancer le temps : la pièce est déjà
      // enfoncée, il n'y a pas eu d'images intermédiaires.
      await tester.pump();
      expect(_clayPress(tester), 1);
    });
  });

  group('la bulle de la barre d\'onglets', () {
    Future<void> pumpBar(WidgetTester tester, int index, {bool reduceMotion = false}) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildFloraTheme(Brightness.light),
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduceMotion),
            child: Scaffold(
              bottomNavigationBar: FloraTabBar(tabs: _tabs, index: index, onSelect: (_) {}),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('glisse jusqu\'à l\'onglet choisi au lieu de s\'y allumer', (tester) async {
      final sage = FloraColors.light.sage;
      await pumpBar(tester, 0);
      final start = _bubble(tester, sage);

      await pumpBar(tester, 2);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      final middle = _bubble(tester, sage);
      expect(middle.left, greaterThan(start.left), reason: 'elle est partie');
      expect(middle.left, lessThan(start.left + start.width * 2), reason: 'et elle est encore en route');

      await tester.pumpAndSettle();
      final end = _bubble(tester, sage);
      expect(end.left, moreOrLessEquals(start.left + start.width * 2, epsilon: 1));
      expect(end.width, moreOrLessEquals(start.width, epsilon: 0.5), reason: 'la bulle se déplace, elle ne s\'étire pas');
    });

    testWidgets('annonce le bon onglet dès qu\'il est choisi', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpBar(tester, 0);
      await pumpBar(tester, 2);
      // Sans attendre que la bulle arrive : ce que VoiceOver lit suit
      // l'onglet choisi, pas le déplacement.
      expect(
        tester.getSemantics(find.descendant(of: find.byType(FloraTabBar), matching: find.text('Jardin'))),
        containsSemantics(label: 'Jardin', isSelected: true, isButton: true),
      );
      expect(
        tester.getSemantics(find.descendant(of: find.byType(FloraTabBar), matching: find.text('Aujourd\'hui'))),
        containsSemantics(label: 'Aujourd\'hui', isSelected: false, isButton: true),
      );
      await tester.pumpAndSettle();
      handle.dispose();
    });

    testWidgets('arrive tout de suite avec « réduire les animations »', (tester) async {
      final sage = FloraColors.light.sage;
      await pumpBar(tester, 0, reduceMotion: true);
      final start = _bubble(tester, sage);
      await pumpBar(tester, 1, reduceMotion: true);
      expect(_bubble(tester, sage).left, moreOrLessEquals(start.left + start.width, epsilon: 0.5));
    });
  });

  group('une liste qui se pose', () {
    testWidgets('monte et s\'éclaircit, rang après rang', (tester) async {
      await _pump(
        tester,
        Column(mainAxisSize: MainAxisSize.min, children: [for (var i = 0; i < 3; i++) Appear(rank: i, child: Text('ligne $i'))]),
      );
      double opacityOf(int i) => tester.widget<Opacity>(
        find.ancestor(of: find.text('ligne $i'), matching: find.byType(Opacity)).first,
      ).opacity;

      expect(opacityOf(0), lessThan(1), reason: 'la première part de rien');
      await tester.pump(const Duration(milliseconds: 120));
      expect(opacityOf(0), greaterThan(opacityOf(2)), reason: 'la première a de l\'avance sur la troisième');

      await tester.pumpAndSettle();
      for (var i = 0; i < 3; i++) {
        expect(opacityOf(i), 1);
      }
    });

    testWidgets('est déjà là avec « réduire les animations »', (tester) async {
      await _pump(tester, const Appear(rank: 5, child: Text('ligne')), reduceMotion: true);
      final opacity = tester.widget<Opacity>(find.ancestor(of: find.text('ligne'), matching: find.byType(Opacity)).first);
      expect(opacity.opacity, 1);
    });
  });
}
