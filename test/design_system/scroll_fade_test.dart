import 'package:flora/core/l10n/l10n.dart';
import 'package:flora/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Une page que la barre du bas referme s'arrêtait net sur elle : le dernier
/// élément visible touchait le bord au pixel près, et rien ne distinguait une
/// page qui se termine là d'une page qui continue. Le bas s'efface donc tant
/// qu'il reste quelque chose dessous, et seulement tant qu'il en reste.
void main() {
  Future<void> open(WidgetTester tester, {required int lignes, bool barre = true}) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildFloraTheme(Brightness.light),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: FloraPage(
        title: 'Page',
        bottom: barre ? const SizedBox(height: 60) : null,
        child: Column(children: [for (var i = 0; i < lignes; i++) SizedBox(height: 40, child: Text('ligne $i'))]),
      ),
    ));
    await tester.pumpAndSettle();
  }

  final voile = find.descendant(of: find.byType(ScrollFade), matching: find.byType(DecoratedBox));

  testWidgets('du contenu dessous : le bas de la page s’efface', (tester) async {
    await open(tester, lignes: 60);
    expect(voile, findsOneWidget);
  });

  testWidgets('une fois le bas atteint, le voile s’en va', (tester) async {
    await open(tester, lignes: 60);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(voile, findsNothing, reason: 'plus rien dessous, plus rien à annoncer');
  });

  testWidgets('un contenu qui tient à l’écran n’annonce rien', (tester) async {
    await open(tester, lignes: 3);
    expect(voile, findsNothing);
  });

  testWidgets('sans barre du bas, la page touche déjà le bord', (tester) async {
    await open(tester, lignes: 60, barre: false);
    expect(find.byType(ScrollFade), findsNothing);
  });
}
