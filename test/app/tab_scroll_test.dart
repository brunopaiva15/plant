import 'package:flora/app/providers.dart';
import 'package:flora/app/tab_scroll.dart';
import 'package:flora/design_system/design_system.dart';
import 'package:flora/domain/repositories/repositories.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_smoke_test.dart' as harness;

/// Un second tap sur l'onglet courant ramène sa liste en haut, comme sur iOS.
/// La liste d'un onglet s'attache d'elle-même au contrôleur de sa branche :
/// rien n'est passé de main en main.
///
/// Le test tourne sur les deux plateformes : l'attache dépendait autrefois
/// d'une heuristique de plateforme, et une page qui ne s'attache pas ne
/// remonte pas sans que rien ne le signale.
void main() {
  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    group(platform.name, () {
      setUp(() => debugDefaultTargetPlatformOverride = platform);
      tearDown(() => debugDefaultTargetPlatformOverride = null);

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
        final scrolled = plantsTab.offset;
        expect(scrolled, greaterThan(100));

        // La remontée est une glissade, pas un saut.
        await tester.tap(tab);
        // La première image arme le ticker de la remontée, la suivante la
        // fait avancer.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));
        final midway = plantsTab.offset;
        expect(midway, lessThan(scrolled), reason: 'elle est partie');
        expect(midway, greaterThan(0), reason: 'et elle est encore en route');

        await harness.settle(tester);
        expect(plantsTab.offset, 0);
        await tester.pump(const Duration(seconds: 6));
        debugDefaultTargetPlatformOverride = null;
      });
    });
  }
}
