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
