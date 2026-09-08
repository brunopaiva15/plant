import 'package:flutter/material.dart';
import 'package:flora/design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';

/// Trois réglages de [FloraListRow] étaient déclarés, documentés, passés par
/// plusieurs écrans, et sans effet : le titre restait sur une ligne, le
/// sous-titre gardait sa couleur, la tâche terminée n'était pas barrée.
void main() {
  Widget page(Widget child) => MaterialApp(
        theme: buildFloraTheme(Brightness.light),
        home: Scaffold(body: Center(child: SizedBox(width: 300, child: child))),
      );

  Text titre(WidgetTester tester) => tester.widget<Text>(find.text('Compléter les fiches avec l\'IA'));

  testWidgets('le titre suit titleMaxLines', (tester) async {
    await tester.pumpWidget(page(const FloraListRow(title: 'Compléter les fiches avec l\'IA')));
    expect(titre(tester).maxLines, 1, reason: 'une ligne par défaut');

    await tester.pumpWidget(page(const FloraListRow(title: 'Compléter les fiches avec l\'IA', titleMaxLines: 2)));
    expect(titre(tester).maxLines, 2);
  });

  testWidgets('une tâche terminée est barrée', (tester) async {
    await tester.pumpWidget(page(const FloraListRow(title: 'Compléter les fiches avec l\'IA', strikethrough: true)));
    expect(titre(tester).style?.decoration, TextDecoration.lineThrough);

    await tester.pumpWidget(page(const FloraListRow(title: 'Compléter les fiches avec l\'IA')));
    expect(titre(tester).style?.decoration, isNull);
  });

  testWidgets('le sous-titre prend la couleur demandée', (tester) async {
    await tester.pumpWidget(page(const FloraListRow(title: 'Compléter les fiches avec l\'IA', subtitle: 'En retard', subtitleColor: Color(0xFFBD5836))));
    expect(tester.widget<Text>(find.text('En retard')).style?.color, const Color(0xFFBD5836));
  });
}
