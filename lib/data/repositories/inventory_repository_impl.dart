import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/models.dart';
import '../../domain/repositories/repositories.dart';
import '../db/database.dart';
import '../db/mappers.dart';

class DriftInventoryRepository implements InventoryRepository {
  DriftInventoryRepository(this._db, this._gardenId);

  final FloraDatabase _db;
  final String _gardenId;

  SimpleSelectStatement<$InventoryItemsTable, InventoryItemRow> get _all => _db.select(_db.inventoryItems)
    ..where((i) => i.gardenId.equals(_gardenId) & i.deletedAt.isNull())
    ..orderBy([(i) => OrderingTerm.asc(i.categoryKey), (i) => OrderingTerm.asc(i.name)]);

  @override
  Stream<List<InventoryItem>> watchAll() => _all.watch().map((rows) => rows.map((r) => r.toDomain()).toList());

  @override
  Stream<List<InventoryItem>> watchLowStock() => watchAll().map((items) => items.where((i) => i.isLow).toList());

  @override
  Future<InventoryItem> create({
    required InventoryCategory category,
    required String name,
    required double quantity,
    required String unit,
    double? lowThreshold,
    String? locationId,
    String? notes,
    String? photoPath,
    String? thumbPath,
  }) async {
    final now = DateTime.now();
    final id = const Uuid().v4();
    await _db.into(_db.inventoryItems).insert(InventoryItemsCompanion.insert(
          id: id,
          gardenId: _gardenId,
          categoryKey: category.key,
          name: name.trim(),
          quantity: Value(quantity),
          unit: Value(unit),
          lowThreshold: Value(lowThreshold),
          locationId: Value(locationId),
          notes: Value(notes?.trim().isEmpty ?? true ? null : notes!.trim()),
          photoPath: Value(photoPath),
          thumbPath: Value(thumbPath),
          createdAt: now,
          updatedAt: now,
        ));
    await _db.enqueueSync('inventory_items', id, 'upsert', {'name': name});
    return (await (_db.select(_db.inventoryItems)..where((i) => i.id.equals(id))).getSingle()).toDomain();
  }

  @override
  Future<void> update(InventoryItem item) async {
    await (_db.update(_db.inventoryItems)..where((i) => i.id.equals(item.id))).write(InventoryItemsCompanion(
      categoryKey: Value(item.category.key),
      name: Value(item.name.trim()),
      quantity: Value(item.quantity),
      unit: Value(item.unit),
      lowThreshold: Value(item.lowThreshold),
      locationId: Value(item.locationId),
      notes: Value(item.notes?.trim().isEmpty ?? true ? null : item.notes!.trim()),
      photoPath: Value(item.photoPath),
      thumbPath: Value(item.thumbPath),
      updatedAt: Value(DateTime.now()),
    ));
    await _db.enqueueSync('inventory_items', item.id, 'upsert', {'name': item.name});
  }

  @override
  Future<void> adjustQuantity(String id, double delta) async {
    final row = await (_db.select(_db.inventoryItems)..where((i) => i.id.equals(id))).getSingleOrNull();
    if (row == null) return;
    final next = (row.quantity + delta).clamp(0, double.infinity).toDouble();
    await (_db.update(_db.inventoryItems)..where((i) => i.id.equals(id)))
        .write(InventoryItemsCompanion(quantity: Value(next), updatedAt: Value(DateTime.now())));
  }

  @override
  Future<void> delete(String id) async {
    await (_db.update(_db.inventoryItems)..where((i) => i.id.equals(id)))
        .write(InventoryItemsCompanion(deletedAt: Value(DateTime.now())));
    await _db.enqueueSync('inventory_items', id, 'delete', {});
  }
}
