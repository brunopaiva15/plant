import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flora/design_system/design_system.dart';

Widget _host(Widget child, {bool reduceMotion = false}) => Theme(
      data: buildFloraTheme(Brightness.light),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: MediaQueryData(disableAnimations: reduceMotion),
          child: SizedBox(width: 320, child: child),
        ),
      ),
    );

void main() {
  testWidgets('le champ de traitement anime la surface et garde le premier plan', (tester) async {
    await tester.pumpWidget(
      _host(
        const ProcessingField(
          child: ColoredBox(color: Colors.black),
          foreground: IrisMark(size: 56),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(ProcessingField), findsOneWidget);
    expect(find.byType(IrisMark), findsOneWidget);
    expect(tester.hasRunningAnimations, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('le premier plan peut se placer en haut du champ', (tester) async {
    await tester.pumpWidget(
      _host(
        const ProcessingField(
          height: 220,
          child: ColoredBox(color: Colors.black),
          foregroundAlignment: Alignment.topCenter,
          foreground: Padding(
            padding: EdgeInsets.only(top: 20),
            child: IrisMark(size: 56),
          ),
        ),
      ),
    );

    final field = tester.getRect(find.byType(ProcessingField));
    final mark = tester.getRect(find.byType(IrisMark));
    expect(mark.center.dx, closeTo(field.center.dx, 0.5));
    expect(mark.top, closeTo(field.top + 20, 0.5));
  });

  testWidgets('le champ reste fixe avec reduced motion', (tester) async {
    await tester.pumpWidget(
      _host(
        const ProcessingField(child: ColoredBox(color: Colors.black)),
        reduceMotion: true,
      ),
    );

    await tester.pump(const Duration(seconds: 1));
    expect(tester.hasRunningAnimations, isFalse);
    expect(tester.takeException(), isNull);
  });
}
