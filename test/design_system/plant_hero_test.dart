import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flora/design_system/design_system.dart';

/// Deux écrans : une vignette arrondie, puis un en-tête carré. Pendant le
/// vol, les coins doivent être entre les deux, jamais l'un ou l'autre.
void main() {
  testWidgets('les coins du héros s\'interpolent pendant le vol', (tester) async {
    final key = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      navigatorKey: key,
      home: Center(child: SizedBox(width: 80, height: 80, child: PlantHero(tag: 'p', radius: const BorderRadius.all(Radius.circular(20)), child: const ColoredBox(color: Colors.green)))),
    ));
    key.currentState!.push(MaterialPageRoute<void>(
      builder: (_) => const SizedBox.expand(child: PlantHero(tag: 'p', child: ColoredBox(color: Colors.green))),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    final flying = tester.widgetList<ClipRRect>(find.byType(ClipRRect)).map((c) => (c.borderRadius as BorderRadius).topLeft.x).toList();
    expect(flying.any((r) => r > 0.5 && r < 19.5), isTrue, reason: 'rayons pendant le vol : $flying');
    await tester.pumpAndSettle();
    expect(tester.widgetList<ClipRRect>(find.byType(ClipRRect)).map((c) => (c.borderRadius as BorderRadius).topLeft.x), contains(0.0));
  });
}
