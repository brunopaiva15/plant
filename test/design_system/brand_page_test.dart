import 'package:flora/core/native_shell.dart';
import 'package:flora/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Une page à tête verte : la barre d'iOS reste la sienne, mais elle se fait
/// transparente tant que le vert est dessous, et reprend son ton ordinaire
/// une fois qu'il est passé.
void main() {
  const canal = MethodChannel('ch.vergasta.plant/native_shell');
  final tons = <String>[];

  setUp(() {
    tons.clear();
    NativeShell.debugForceSupported = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(canal, (call) async {
      if (call.method == 'setActions') tons.add((call.arguments as Map)['tone'] as String);
      return true;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(canal, null);
    NativeShell.debugReset();
  });

  Future<void> pumpPage(WidgetTester tester, {bool brand = true}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFloraTheme(Brightness.light),
        home: MediaQuery(
          data: const MediaQueryData(size: Size(390, 844), padding: EdgeInsets.only(top: 100)),
          child: LargeTitlePage(
            title: 'Plantes',
            brand: brand,
            hero: const SizedBox(height: 200, child: Text('8 plantes')),
            actions: const [],
            slivers: [SliverList.list(children: [for (var i = 0; i < 30; i++) SizedBox(height: 80, child: Text('ligne $i'))])],
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('la barre part transparente, sur le vert', (tester) async {
    await pumpPage(tester);
    expect(tons.last, 'brand');
    expect(find.text('Plantes'), findsOneWidget);
    expect(DefaultTextStyle.of(tester.element(find.text('8 plantes'))).style.color, FloraColors.light.onBrand);
  });

  testWidgets('elle reprend son ton une fois le vert passé, et le rend au retour', (tester) async {
    await pumpPage(tester);
    // Un peu de défilement : le vert est encore sous la barre.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -80));
    await tester.pumpAndSettle();
    expect(tons.last, 'brand');

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(tons.last, 'plain');

    await tester.drag(find.byType(CustomScrollView), const Offset(0, 1500));
    await tester.pumpAndSettle();
    expect(tons.last, 'brand');
  });

  testWidgets('tirée vers le bas, la page ne découvre pas de crème au-dessus du vert', (tester) async {
    await pumpPage(tester);
    final geste = await tester.startGesture(tester.getCenter(find.byType(CustomScrollView)));
    await geste.moveBy(const Offset(0, 120));
    await tester.pump();
    final fond = find.byWidgetPredicate((w) => w is ColoredBox && w.color == FloraColors.light.brand);
    final hauteurs = [for (final e in fond.evaluate()) tester.getSize(find.byWidget(e.widget)).height];
    expect(hauteurs.any((h) => h > 40), isTrue, reason: 'le vert remplit ce que le rebond découvre');
    await geste.up();
    await tester.pumpAndSettle();
  });

  testWidgets('une page sans tête verte garde la barre ordinaire', (tester) async {
    await pumpPage(tester, brand: false);
    expect(tons, isNot(contains('brand')));
  });
}
