import 'package:flora/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Le recentrage du contenu sur les écrans larges, vérifié dans une vraie
/// page — pas dans un montage de laboratoire.
///
/// Ce chemin ne s'active qu'au-delà de 700 points : sur téléphone il ne doit
/// rien changer du tout, et sur tablette il doit rendre le surplus en marges
/// sans rien casser ni rien faire disparaître.

Future<void> _pumpPage(WidgetTester tester, Size size) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: buildFloraTheme(Brightness.light),
      home: MediaQuery(
        data: MediaQueryData(size: size),
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
}
