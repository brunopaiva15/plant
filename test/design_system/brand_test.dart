import 'package:flora/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Les pièces de la tête verte : ce qu'on y pose est blanc, le grand chiffre
/// se lit d'un tenant, la feuille remonte sur le vert.
void main() {
  Future<void> pump(WidgetTester tester, Widget child, {Brightness brightness = Brightness.light}) => tester.pumpWidget(
        MaterialApp(
          theme: buildFloraTheme(brightness),
          home: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      );

  for (final brightness in Brightness.values) {
    testWidgets('la tête verte écrit en blanc (${brightness.name})', (tester) async {
      await pump(
        tester,
        const BrandHeader(child: Column(children: [Text('Plantes'), Icon(Icons.add)])),
        brightness: brightness,
      );
      final c = brightness == Brightness.dark ? FloraColors.dark : FloraColors.light;
      final style = DefaultTextStyle.of(tester.element(find.text('Plantes'))).style;
      expect(style.color, c.onBrand);
      expect(IconTheme.of(tester.element(find.byIcon(Icons.add))).color, c.onBrand);
    });
  }

  testWidgets('le grand chiffre se lit avec ce qu’il compte', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, const BrandHeader(child: HeroNumber(value: '3', label: 'soins aujourd’hui')));
    expect(find.bySemanticsLabel(RegExp('3.*soins aujourd’hui', dotAll: true)), findsOneWidget);
    handle.dispose();
  });

  testWidgets('la feuille remonte sur le vert', (tester) async {
    await pump(
      tester,
      const Column(
        children: [
          BrandHeader(child: SizedBox(height: 100, width: double.infinity)),
          BrandSheet(child: SizedBox(height: 100, width: double.infinity, child: Text('feuille'))),
        ],
      ),
    );
    final header = tester.getRect(find.byType(BrandHeader));
    final sheet = tester.getRect(find.byType(DecoratedBox).last);
    expect(sheet.top, lessThan(header.bottom), reason: 'le coin arrondi se découpe sur le vert');
  });

  testWidgets('une carte vive pose son encre', (tester) async {
    await pump(tester, PopCard(color: FloraColors.light.terracottaPop, child: const Text('Prochain arrosage')));
    expect(DefaultTextStyle.of(tester.element(find.text('Prochain arrosage'))).style.color, FloraColors.light.onPop);
  });

  testWidgets('une pastille de verre choisie s’annonce choisie', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, BrandHeader(child: GlassChip(label: 'Salon', selected: true, onTap: () {})));
    // ignore: deprecated_member_use
    expect(tester.getSemantics(find.text('Salon')), containsSemantics(label: 'Salon', isSelected: true));
    handle.dispose();
  });

  testWidgets('un chiffre de carte garde son unité', (tester) async {
    await pump(tester, const StatBlock(label: 'Hauteur', value: '42', unit: 'cm'));
    expect(find.textContaining('42'), findsOneWidget);
    expect(find.textContaining('cm', findRichText: true), findsOneWidget);
  });
}
