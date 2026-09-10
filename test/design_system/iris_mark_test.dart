import 'package:flora/design_system/design_system.dart';
import 'package:flora/design_system/tokens/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// La marque est entièrement peinte : son rendu ne se teste pas ici. Quatre
/// choses se vérifient — elle tient dans le carré demandé, elle se peint dans
/// les quatre palettes, elle y est rigoureusement la même, et elle se tait
/// tant qu'on ne la nomme pas.

Widget _host(Widget child, {Brightness brightness = Brightness.light, bool highContrast = false}) => MaterialApp(
      theme: buildFloraTheme(brightness, highContrast: highContrast),
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  testWidgets('elle occupe exactement le carré demandé', (tester) async {
    await tester.pumpWidget(_host(const IrisMark(size: 64)));
    expect(tester.getSize(find.byType(IrisMark)), const Size(64, 64));
  });

  for (final (brightness, contrast, name) in [
    (Brightness.light, false, 'clair'),
    (Brightness.dark, false, 'sombre'),
    (Brightness.light, true, 'clair renforcé'),
    (Brightness.dark, true, 'sombre renforcé'),
  ]) {
    testWidgets('elle se peint en $name, de 24 à 96 points', (tester) async {
      for (final size in [24.0, 44.0, 64.0, 96.0]) {
        await tester.pumpWidget(_host(IrisMark(size: size), brightness: brightness, highContrast: contrast));
        await tester.pump();
        expect(tester.takeException(), isNull, reason: '$name, $size points');
      }
    });
  }

  testWidgets('elle est la même en clair et en sombre', (tester) async {
    // Le peintre n'a plus de champ : le même exemplaire `const` sert les
    // quatre palettes, et deux rendus ne peuvent donc pas différer d'un pixel.
    // C'est la façon la plus courte de vérifier qu'un logo est un logo.
    final painters = <CustomPainter?>[];
    for (final (brightness, contrast) in [
      (Brightness.light, false),
      (Brightness.dark, false),
      (Brightness.light, true),
      (Brightness.dark, true),
    ]) {
      await tester.pumpWidget(_host(const IrisMark(size: 64), brightness: brightness, highContrast: contrast));
      final paint = find.descendant(of: find.byType(IrisMark), matching: find.byType(CustomPaint));
      painters.add(tester.widget<CustomPaint>(paint).painter);
    }
    expect(painters.every((p) => identical(p, painters.first)), isTrue);
  });

  test('ses couleurs sont les siennes, pas celles de la palette', () {
    // Elles ne doivent surtout pas être reprises d'un thème : c'est le bug
    // qu'on vient de corriger, où la marque se retournait en sombre.
    expect(IrisMark.blade, isNot(FloraColors.light.sage));
    expect(IrisMark.blade, isNot(FloraColors.dark.sage));
    expect(IrisMark.iris, isNot(FloraColors.dark.onAccent));
    expect(IrisMark.heart, isNot(FloraColors.dark.terracotta));
  });

  testWidgets('sans nom, elle est décorative et VoiceOver l\'ignore', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(const IrisMark()));
    expect(find.bySemanticsLabel('Iris'), findsNothing);
    handle.dispose();
  });

  testWidgets('avec un nom, elle s\'annonce comme une image', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(const IrisMark(semanticLabel: 'Iris')));
    expect(find.bySemanticsLabel('Iris'), findsOneWidget);
    handle.dispose();
  });
}
