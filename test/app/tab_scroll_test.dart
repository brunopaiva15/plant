import 'package:flora/app/providers.dart';
import 'package:flora/app/tab_scroll.dart';
import 'package:flora/design_system/design_system.dart';
import 'package:flora/domain/repositories/repositories.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_smoke_test.dart' as harness;

/// Un second tap sur l'onglet courant ramène sa liste en haut, comme sur iOS.
/// La liste d'un onglet s'attache d'elle-même au contrôleur de sa branche :
/// rien n'est passé de main en main.
void main() {
  testWidgets('retaper l\'onglet courant ramène la liste en haut', (tester) async {
    final container = await harness.boot(tester, seed: (c) async {
      final plants = c.read(plantRepositoryProvider);
      for (var i = 0; i < 40; i++) {
        await plants.create(NewPlant(name: 'Plante $i'));
      }
    });
    await harness.pumpApp(tester, container);

    // Le titre de la page s'appelle aussi « Plantes » : on vise l'onglet.
    final tab = find.descendant(of: find.byType(FloraTabBar), matching: find.text('Plantes'));
    await tester.tap(tab);
    await harness.settle(tester);
    final scrolls = container.read(tabScrollsProvider);
    final plantsTab = scrolls.controllers[1];
    expect(plantsTab.hasClients, isTrue, reason: 'la grille des plantes s\'attache au contrôleur de son onglet');
    expect(scrolls.controllers[0].positions.length, 1, reason: 'et celui d\'Aujourd\'hui ne tient que sa propre liste');

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -1500));
    await harness.settle(tester);
    expect(plantsTab.offset, greaterThan(100));

    await tester.tap(tab);
    await harness.settle(tester);
    expect(plantsTab.offset, 0);
    await tester.pump(const Duration(seconds: 6));
  });
}
