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

double? _fieldTime(WidgetTester tester) {
  for (final paint in tester.widgetList<CustomPaint>(
    find.descendant(
      of: find.byType(ProcessingField),
      matching: find.byType(CustomPaint),
    ),
  )) {
    final painter = paint.painter;
    if (painter != null &&
        painter.runtimeType.toString() == '_ProcessingFieldPainter') {
      return (painter as dynamic).time as double?;
    }
  }
  return null;
}

void main() {
  testWidgets(
    'le champ de traitement anime la surface et garde le premier plan',
    (tester) async {
      await tester.pumpWidget(
        _host(
          const ProcessingField(
            child: ColoredBox(color: Colors.black),
            foreground: IrisMark(size: 56),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(ProcessingField), findsOneWidget);
      expect(find.byType(IrisMark), findsOneWidget);
      expect(find.byType(FadeTransition), findsWidgets);
      expect(find.byType(ScaleTransition), findsWidgets);
      expect(tester.hasRunningAnimations, isTrue);
      expect(tester.takeException(), isNull);

      final atStart = _fieldTime(tester);
      expect(atStart, isNotNull);
      await tester.pump(const Duration(milliseconds: 500));
      final later = _fieldTime(tester);
      expect(later, isNotNull);
      expect(later!, greaterThan(atStart! + 0.4));
      expect(tester.hasRunningAnimations, isTrue);
    },
  );

  testWidgets('le premier plan peut se placer en haut du champ', (
    tester,
  ) async {
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

    // L'entrée d'échelle (0,988 → 1) doit être finie, sinon le transform
    // décale le premier plan. Le battement de la masse, lui, ne s'arrête pas.
    await tester.pump(const Duration(milliseconds: 400));

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
    expect(_fieldTime(tester), isNull);
    expect(tester.takeException(), isNull);
  });
}
