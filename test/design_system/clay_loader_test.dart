import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flora/design_system/design_system.dart';

Widget _host(Widget child, {bool reduceMotion = false}) => Theme(
      data: buildFloraTheme(Brightness.light),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(data: MediaQueryData(disableAnimations: reduceMotion), child: Center(child: child)),
      ),
    );

void main() {
  testWidgets('la motte boucle sans erreur sur un cycle complet', (tester) async {
    await tester.pumpWidget(_host(const ClayLoader()));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 90));
    }
    expect(find.byType(ClayLoader), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('avec reduced motion, rien ne bouge', (tester) async {
    await tester.pumpWidget(_host(const ClayLoader(), reduceMotion: true));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('AdaptiveProgress et le bouton en chargement montrent la motte', (tester) async {
    await tester.pumpWidget(_host(Column(children: [const AdaptiveProgress(), FloraButton(label: 'Go', onPressed: () {}, loading: true)])));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(ClayLoader), findsNWidgets(2));
  });
}
