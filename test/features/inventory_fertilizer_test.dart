import 'package:flora/app/providers.dart';
import 'package:flora/domain/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../app/app_smoke_test.dart' as harness;

/// La forme, l'origine et le NPK caractérisent un engrais, et rien d'autre :
/// la feuille d'un article ne les montre que tant que la catégorie choisie est
/// « Engrais ». Basculer sur une autre catégorie les fait disparaître — et
/// enregistrer là-dessus les efface pour de bon, ce que vérifie
/// `test/data/inventory_repository_test.dart`.
void main() {
  Future<void> openItem(WidgetTester tester, String name) async {
    await tester.tap(find.text('Jardin'));
    await harness.settle(tester);
    await tester.tap(find.text('Inventaire'));
    await harness.settle(tester);
    await tester.tap(find.text(name));
    await harness.settle(tester);
  }

  testWidgets('les champs d\'engrais ne s\'affichent que pour la catégorie Engrais', (tester) async {
    final container = await harness.boot(tester, seed: (c) async {
      await c.read(inventoryRepositoryProvider).create(
            category: InventoryCategory.fertilizer,
            name: 'Engrais tomates',
            quantity: 1,
            unit: 'L',
            fertilizerForm: FertilizerForm.liquid,
            fertilizerOrigin: FertilizerOrigin.organic,
            nitrogen: 7,
            phosphorus: 3,
            potassium: 5,
          );
    });
    await harness.pumpApp(tester, container);
    await openItem(tester, 'Engrais tomates');

    expect(find.text('Forme'), findsOneWidget);
    expect(find.text('Origine'), findsOneWidget);
    expect(find.text('NPK (%)'), findsOneWidget);
    expect(find.text('Liquide'), findsOneWidget);

    // Rangé en pots, l'article n'est plus un engrais : les trois champs s'en vont.
    await tester.tap(find.text('Pots'));
    await harness.settle(tester);
    expect(find.text('Forme'), findsNothing);
    expect(find.text('Origine'), findsNothing);
    expect(find.text('NPK (%)'), findsNothing);

    // Et reviennent avec la catégorie, la saisie intacte.
    await tester.tap(find.text('Engrais'));
    await harness.settle(tester);
    expect(find.text('NPK (%)'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
  });

  testWidgets('un article d\'une autre catégorie n\'en voit jamais la trace', (tester) async {
    final container = await harness.boot(tester, seed: (c) async {
      await c.read(inventoryRepositoryProvider).create(category: InventoryCategory.pot, name: 'Pots Ø15 cm', quantity: 4, unit: '');
    });
    await harness.pumpApp(tester, container);
    await openItem(tester, 'Pots Ø15 cm');

    expect(find.text('Forme'), findsNothing);
    expect(find.text('Origine'), findsNothing);
    expect(find.text('NPK (%)'), findsNothing);
  });

  testWidgets('la liste dit la forme et le dosage sous le nom de l\'engrais', (tester) async {
    final container = await harness.boot(tester, seed: (c) async {
      await c.read(inventoryRepositoryProvider).create(
            category: InventoryCategory.fertilizer,
            name: 'Corne broyée',
            quantity: 2,
            unit: 'kg',
            fertilizerForm: FertilizerForm.granules,
            fertilizerOrigin: FertilizerOrigin.organic,
            nitrogen: 12,
          );
    });
    await harness.pumpApp(tester, container);
    await tester.tap(find.text('Jardin'));
    await harness.settle(tester);
    await tester.tap(find.text('Inventaire'));
    await harness.settle(tester);

    expect(find.textContaining('Granulés'), findsOneWidget);
    expect(find.textContaining('NPK 12-–-–'), findsOneWidget);
  });
}
