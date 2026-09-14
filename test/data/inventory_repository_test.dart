import 'dart:io';

import 'package:drift/native.dart';
import 'package:flora/data/db/database.dart';
import 'package:flora/data/repositories/action_repository_impl.dart';
import 'package:flora/data/repositories/inventory_repository_impl.dart';
import 'package:flora/data/repositories/measurement_repository_impl.dart';
import 'package:flora/data/repositories/plant_repository_impl.dart';
import 'package:flora/domain/models/models.dart';
import 'package:flora/domain/repositories/repositories.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FloraDatabase db;
  late DriftInventoryRepository inventory;
  const garden = 'g1';

  setUp(() {
    db = FloraDatabase(NativeDatabase.memory());
    inventory = DriftInventoryRepository(db, garden);
  });
  tearDown(() => db.close());

  test('creates, adjusts and flags low stock', () async {
    final item = await inventory.create(category: InventoryCategory.fertilizer, name: 'Engrais vert', quantity: 500, unit: 'ml', lowThreshold: 100);
    expect(item.isLow, isFalse);
    await inventory.adjustQuantity(item.id, -450);
    final low = await inventory.watchLowStock().first;
    expect(low.single.quantity, 50);
    expect(low.single.isLow, isTrue);
    await inventory.adjustQuantity(item.id, -100);
    expect((await inventory.watchAll().first).single.quantity, 0);
  });

  test('update and soft delete', () async {
    final item = await inventory.create(category: InventoryCategory.pot, name: 'Pots 15', quantity: 4, unit: '');
    await inventory.update(item.copyWith(name: 'Pots Ø15 cm', quantity: 6));
    expect((await inventory.watchAll().first).single.name, 'Pots Ø15 cm');
    await inventory.delete(item.id);
    expect(await inventory.watchAll().first, isEmpty);
  });

  group('engrais', () {
    test('forme, origine et NPK se relisent tels qu\'ils ont été saisis', () async {
      final item = await inventory.create(
        category: InventoryCategory.fertilizer,
        name: 'Engrais tomates',
        quantity: 1,
        unit: 'L',
        fertilizerForm: FertilizerForm.liquid,
        fertilizerOrigin: FertilizerOrigin.organic,
        nitrogen: 7,
        phosphorus: 3,
        potassium: 5.5,
      );
      final reread = (await inventory.get(item.id))!;
      expect(reread.fertilizerForm, FertilizerForm.liquid);
      expect(reread.fertilizerOrigin, FertilizerOrigin.organic);
      expect(reread.npk, '7-3-5.5');
    });

    test('une autre catégorie ne retient rien de tout cela', () async {
      final item = await inventory.create(
        category: InventoryCategory.pot,
        name: 'Pots 15',
        quantity: 4,
        unit: '',
        fertilizerForm: FertilizerForm.granules,
        fertilizerOrigin: FertilizerOrigin.mineral,
        nitrogen: 7,
      );
      expect(item.fertilizerForm, isNull);
      expect(item.fertilizerOrigin, isNull);
      expect(item.npk, isNull);
    });

    test('un engrais rangé ailleurs perd ses champs d\'engrais', () async {
      final item = await inventory.create(
        category: InventoryCategory.fertilizer,
        name: 'Corne broyée',
        quantity: 2,
        unit: 'kg',
        fertilizerForm: FertilizerForm.granules,
        fertilizerOrigin: FertilizerOrigin.organic,
        nitrogen: 12,
      );
      await inventory.update(item.copyWith(category: InventoryCategory.substrate));
      final moved = (await inventory.get(item.id))!;
      expect(moved.fertilizerForm, isNull);
      expect(moved.fertilizerOrigin, isNull);
      expect(moved.npk, isNull);
      expect(moved.name, 'Corne broyée', reason: 'le reste de l\'article ne bouge pas');
    });

    test('un pourcentage hors bornes est ramené entre 0 et 100', () async {
      final item = await inventory.create(
        category: InventoryCategory.fertilizer,
        name: 'Saisie fantaisiste',
        quantity: 1,
        unit: 'L',
        nitrogen: -4,
        phosphorus: 250,
      );
      expect(item.nitrogen, 0);
      expect(item.phosphorus, 100);
    });

    test('le NPK écrit « – » pour un élément non renseigné, et rien du tout sans aucun', () {
      InventoryItem fertilizer({double? n, double? p, double? k}) => InventoryItem(
            id: 'i1',
            gardenId: garden,
            category: InventoryCategory.fertilizer,
            name: 'Engrais',
            quantity: 1,
            unit: 'L',
            nitrogen: n,
            phosphorus: p,
            potassium: k,
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
          );
      expect(fertilizer(n: 7, p: 3, k: 5).npk, '7-3-5');
      expect(fertilizer(n: 7).npk, '7-–-–');
      expect(fertilizer(k: 0).npk, '–-–-0', reason: 'zéro est une valeur, pas une absence');
      expect(fertilizer().npk, isNull);
    });

    test('une base d\'avant la v12 se relit après migration, ses articles intacts', () async {
      final dir = await Directory.systemTemp.createTemp('flora_v12');
      final file = File('${dir.path}/flora.sqlite');
      addTearDown(() => dir.delete(recursive: true));

      // Un article écrit puis une base ramenée au schéma v11 : les cinq
      // colonnes des engrais n'existent pas encore.
      var old = FloraDatabase(NativeDatabase(file));
      final before = await DriftInventoryRepository(old, garden).create(
        category: InventoryCategory.fertilizer,
        name: 'Engrais d\'avant',
        quantity: 420,
        unit: 'ml',
        lowThreshold: 100,
      );
      for (final column in ['fertilizer_form', 'fertilizer_origin', 'nitrogen', 'phosphorus', 'potassium']) {
        await old.customStatement('ALTER TABLE inventory_items DROP COLUMN $column');
      }
      await old.customStatement('PRAGMA user_version = 11');
      await old.close();

      final migrated = FloraDatabase(NativeDatabase(file));
      addTearDown(migrated.close);
      final repo = DriftInventoryRepository(migrated, garden);
      final after = (await repo.get(before.id))!;
      expect(after.name, 'Engrais d\'avant');
      expect(after.quantity, 420);
      expect(after.fertilizerForm, isNull, reason: 'non renseigné, pas une valeur par défaut');
      expect(after.npk, isNull);

      // Et la colonne est bien là : on peut désormais la remplir.
      await repo.update(after.copyWith(fertilizerForm: () => FertilizerForm.liquid, nitrogen: () => 7));
      expect((await repo.get(before.id))!.fertilizerForm, FertilizerForm.liquid);
    });
  });

  test('measurement series are grouped by kind in chronological order', () async {
    final plants = DriftPlantRepository(db, garden);
    final actions = DriftActionRepository(db);
    final measurements = DriftMeasurementRepository(db);
    final p = await plants.create(const NewPlant(name: 'Monstera'));
    await actions.log(NewAction(plantId: p.id, typeKey: 'measurement', occurredAt: DateTime(2026, 6, 1), metadata: {'kind': 'height', 'value': 34, 'unit': 'cm'}));
    await actions.log(NewAction(plantId: p.id, typeKey: 'measurement', occurredAt: DateTime(2026, 8, 1), metadata: {'kind': 'height', 'value': 42, 'unit': 'cm'}));
    await actions.log(NewAction(plantId: p.id, typeKey: 'measurement', occurredAt: DateTime(2026, 7, 1), metadata: {'kind': 'leaves', 'value': 9, 'unit': ''}));
    final series = await measurements.watchSeries(p.id).first;
    expect(series.map((s) => s.kind), [MeasurementKind.height, MeasurementKind.leaves]);
    final height = series.first;
    expect(height.points.map((m) => m.value), [34, 42]);
    expect(height.delta, 8);
    expect(height.hasTrend, isTrue);
  });
}
