import 'package:flora/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Le recentrage du contenu sur les écrans larges, vérifié dans une vraie
/// page — pas dans un montage de laboratoire.
///
/// Ce chemin ne s'active qu'au-delà de 700 points : sur téléphone il ne doit
/// rien changer du tout, et sur tablette il doit rendre le surplus en marges
/// sans rien casser ni rien faire disparaître.

Future<void> _pumpPage(WidgetTester tester, Size size, {EdgeInsets marges = EdgeInsets.zero}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: buildFloraTheme(Brightness.light),
      home: MediaQuery(
        data: MediaQueryData(size: size, padding: marges, viewPadding: marges),
        child: LargeTitlePage(
          title: 'Mes plantes',
          slivers: [
            SliverList.list(
              children: [for (var i = 0; i < 8; i++) FloraCard(child: Text('carte $i'))],
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('le recentrage sur écran large', () {
    testWidgets('ne touche à rien sur un téléphone', (tester) async {
      await _pumpPage(tester, const Size(390, 844));
      expect(tester.takeException(), isNull);
      expect(readableInset(tester.element(find.text('carte 0'))), 0);
      // La carte occupe la largeur, marges de page comprises.
      expect(tester.getRect(find.byType(FloraCard).first).width, greaterThan(300));
    });

    testWidgets('rend le surplus en marges sur une tablette', (tester) async {
      await _pumpPage(tester, const Size(1180, 820));
      expect(tester.takeException(), isNull);
      final card = tester.getRect(find.byType(FloraCard).first);
      // Le contenu ne traverse plus l'écran…
      expect(card.width, lessThanOrEqualTo(700));
      // … et il est centré, pas collé au bord gauche.
      expect(card.center.dx, closeTo(1180 / 2, 1));
    });

    // Sur un pliable, la bande de la caméra passe sur un bord — 84 points
    // mesurés dans Xcode 27.1 —, et rien ne dit qu'elle soit symétrique. Le
    // contenu doit s'en écarter : sans ça, une liste ou un sélecteur de
    // section court dessous, et on lit « Calen… » sous l'heure du système.
    testWidgets('il s\'écarte de la bande que le système réserve à droite', (tester) async {
      await _pumpPage(tester, const Size(466, 678), marges: const EdgeInsets.only(right: 84, top: 82, bottom: 34));
      expect(tester.takeException(), isNull);
      expect(tester.getRect(find.byType(FloraCard).first).right, lessThanOrEqualTo(466 - 84 + 0.5));
    });

    testWidgets('et de la même bande passée à gauche', (tester) async {
      await _pumpPage(tester, const Size(466, 678), marges: const EdgeInsets.only(left: 84, bottom: 34));
      expect(tester.getRect(find.byType(FloraCard).first).left, greaterThanOrEqualTo(84 - 0.5));
    });

    testWidgets('le contenu reste présent et défilable', (tester) async {
      await _pumpPage(tester, const Size(1180, 820));
      // Le groupe de slivers ne doit rien avaler au passage.
      expect(find.text('carte 0'), findsOneWidget);
      expect(find.text('Mes plantes'), findsWidgets);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('carte 7'), findsOneWidget);
    });
  });

  _testsDeLaRecherche();
}

/// Le champ de recherche vit dans la barre, qui garde toute la largeur : il
/// n'est pas couvert par la marge des contenus, et il lui faut la sienne.
Future<void> _pumpAvecRecherche(
  WidgetTester tester,
  Size size,
  EdgeInsets marges, {
  TargetPlatform platform = TargetPlatform.iOS,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      // La barre d'iOS et celle de Material ne posent pas leur `bottom` de la
      // même façon : c'est la première qui laissait passer le champ.
      theme: buildFloraTheme(Brightness.light).copyWith(platform: platform),
      home: MediaQuery(
        data: MediaQueryData(size: size, padding: marges, viewPadding: marges),
        child: LargeTitlePage(
          title: 'Plantes',
          searchField: const TextField(key: Key('recherche')),
          slivers: [
            SliverList.list(children: [for (var i = 0; i < 4; i++) FloraCard(child: Text('carte $i'))]),
          ],
        ),
      ),
    ),
  );
  await tester.pump();
}

void _testsDeLaRecherche() {
  group('le champ de recherche', () {
    testWidgets('s\'arrête avant la bande du système', (tester) async {
      // Un iPhone Duo fermé : la bande de l'heure et de la caméra prend 84
      // points à droite. Le champ passait dessous.
      await _pumpAvecRecherche(tester, const Size(466, 678), const EdgeInsets.only(right: 84));
      expect(tester.takeException(), isNull);
      expect(tester.getRect(find.byKey(const Key('recherche'))).right, lessThanOrEqualTo(466 - 84));
    });

    testWidgets('garde sa marge ordinaire sans bande', (tester) async {
      await _pumpAvecRecherche(tester, const Size(390, 844), EdgeInsets.zero);
      final champ = tester.getRect(find.byKey(const Key('recherche')));
      expect(champ.left, moreOrLessEquals(Space.md, epsilon: 0.5));
      expect(390 - champ.right, moreOrLessEquals(Space.md, epsilon: 0.5));
    });

    testWidgets('et s\'arrête avant la bande sur Material aussi', (tester) async {
      await _pumpAvecRecherche(
        tester,
        const Size(466, 678),
        const EdgeInsets.only(right: 84),
        platform: TargetPlatform.android,
      );
      expect(tester.getRect(find.byKey(const Key('recherche'))).right, lessThanOrEqualTo(466 - 84));
    });
  });
}
