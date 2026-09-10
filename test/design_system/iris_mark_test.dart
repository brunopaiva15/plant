import 'package:flora/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// La marque est entièrement peinte : son rendu ne se teste pas ici. Trois
/// choses se vérifient — elle tient dans le carré demandé, elle se peint dans
/// les quatre palettes, et elle se tait tant qu'on ne la nomme pas.

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
