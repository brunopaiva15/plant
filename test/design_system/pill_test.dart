import 'package:flora/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// La pilule de lecture vit dans une bande qui défile à l'horizontale, où la
/// largeur n'est pas bornée : elle prend celle de son texte, sans s'étirer
/// ni déborder, et se coupe au-delà d'un plafond.
void main() {
  Widget strip(List<Widget> pills) => MaterialApp(
        theme: buildFloraTheme(Brightness.light),
        home: Scaffold(
          body: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: pills),
          ),
        ),
      );

  testWidgets('deux pilules se posent côte à côte dans une bande défilante', (tester) async {
    await tester.pumpWidget(
      strip([
        FloraPill(emoji: '☁️', label: '22° · Nuageux · 38 % de pluie', chevron: true, onTap: () {}),
        FloraPill(emoji: '🏠', label: '25°', detail: 'Salon', chevron: true, onTap: () {}),
      ]),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('22° · Nuageux · 38 % de pluie'), findsOneWidget);
    expect(find.text('Salon'), findsOneWidget);
    // Chacune fait la hauteur de la cible tactile, et pas plus.
    for (final size in find.byType(FloraPill).evaluate().map((e) => e.size!)) {
      expect(size.height, kMinTapTarget);
    }
  });

  testWidgets('un libellé sans fin se coupe au lieu de s\'étirer', (tester) async {
    await tester.pumpWidget(strip([FloraPill(label: 'Véranda du fond, côté jardin, derrière la grande porte vitrée, sur l\'étagère du haut', onTap: () {})]));
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(FloraPill)).width, lessThanOrEqualTo(FloraPill.maxWidth));
  });

  testWidgets('elle répond au doigt', (tester) async {
    var taps = 0;
    await tester.pumpWidget(strip([FloraPill(emoji: '🪴', label: 'Salon', detail: '4', onTap: () => taps++)]));
    await tester.tap(find.text('Salon'));
    expect(taps, 1);
  });
}
