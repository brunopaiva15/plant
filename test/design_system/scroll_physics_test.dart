import 'package:flora/core/l10n/l10n.dart';
import 'package:flora/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Une page dont le contenu tient à l'écran ne défile pas — comme sur iOS.
/// C'est la règle par défaut de Flutter ; le scaffold la contournait avec
/// `AlwaysScrollableScrollPhysics`, et un écran vide se laissait pousser.
void main() {
  Future<double> dragAndMeasure(WidgetTester tester, Widget page) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildFloraTheme(Brightness.light),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: page,
    ));
    await tester.pumpAndSettle();
    final scrollable = find.byType(Scrollable).first;
    await tester.drag(scrollable, const Offset(0, -300));
    await tester.pump();
    return tester.state<ScrollableState>(scrollable).position.pixels;
  }

  testWidgets('un contenu court reste immobile sous le doigt', (tester) async {
    final pixels = await dragAndMeasure(tester, const FloraPage(title: 'Vide', child: Text('trois mots seulement')));
    expect(pixels, 0, reason: 'rien à faire défiler : la page ne doit pas bouger');
  });

  testWidgets('un contenu long défile', (tester) async {
    final pixels = await dragAndMeasure(
      tester,
      FloraPage(title: 'Long', child: Column(children: [for (var i = 0; i < 60; i++) SizedBox(height: 40, child: Text('ligne $i'))])),
    );
    expect(pixels, greaterThan(0));
  });
}
