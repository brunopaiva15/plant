import 'package:flora/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// La ligne « Arrosage — 14 jours + » telle qu'elle apparaît dans le flow de
/// création, posée dans une largeur donnée.
Future<void> _pumpRow(WidgetTester tester, {required double width, required String label}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildFloraTheme(Brightness.light),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: FloraGroup(
              children: [
                FloraListRow(
                  leading: const Text('💧'),
                  title: 'Arrosage',
                  trailing: QuantityStepper(value: 14, min: 0, max: 365, label: label, onChanged: (_) {}),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('la ligne à stepper', () {
    // De l'iPhone SE à la tablette : le « + » doit rester dans la pilule.
    for (final width in [280.0, 320.0, 350.0, 390.0, 430.0, 600.0]) {
      testWidgets('ne déborde pas sur $width points', (tester) async {
        await _pumpRow(tester, width: width, label: '14 jours');
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets("un libellé démesuré resserre le texte, pas les boutons", (tester) async {
      await _pumpRow(tester, width: 320, label: 'Tous les quatorze jours ou presque');
      expect(tester.takeException(), isNull);
      // Les deux boutons gardent leur taille : c'est le texte qui cède.
      final buttons = tester.widgetList<SizedBox>(find.byType(SizedBox)).where((b) => b.width == 40 && b.height == 40);
      expect(buttons, hasLength(2));
    });

    testWidgets("posé dans une rangée sans borne, il ne s'effondre pas", (tester) async {
      // Le cas de la feuille de tâche : le stepper est un enfant non flexible
      // d'une rangée, et reçoit donc une largeur sans limite.
      await tester.pumpWidget(
        MaterialApp(
          theme: buildFloraTheme(Brightness.light),
          home: Scaffold(
            body: Row(
              children: [
                const Expanded(child: Text('Toutes les')),
                QuantityStepper(value: 3, min: 1, max: 999, label: '3 semaines', onChanged: (_) {}),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('3 semaines'), findsOneWidget);
    });

    testWidgets('le stepper reste calé à droite de la ligne', (tester) async {
      await _pumpRow(tester, width: 390, label: '14 jours');
      final row = tester.getRect(find.byType(FloraListRow));
      final stepper = tester.getRect(find.byType(QuantityStepper));
      expect(stepper.right, lessThanOrEqualTo(row.right));
      expect(stepper.right, closeTo(row.right - Space.md, 1));
    });
  });
}
