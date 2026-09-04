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


  @override
  Stream<List<InventoryItem>> watchAll() => _db
      .customSelect(
        '''SELECT i.*, (
             SELECT GROUP_CONCAT(t.name, '|') FROM inventory_tags it
             JOIN tags t ON t.id = it.tag_id
             WHERE it.item_id = i.id
           ) AS tag_names
           FROM inventory_items i
           WHERE i.garden_id = ? AND i.deleted_at IS NULL
           ORDER BY i.category_key ASC, lower(i.name) ASC''',
        variables: [Variable.withString(_gardenId)],
        readsFrom: {_db.inventoryItems, _db.inventoryTags, _db.tags},
      )
      .watch()
      .map((rows) => rows.map(_mapItem).toList());

  InventoryItem _mapItem(QueryRow row) {
    final data = Map<String, Object?>.from(row.data);
    final names = data.remove('tag_names') as String?;
    return _db.inventoryItems
        .map(data)
        .toDomain(tags: names == null || names.isEmpty ? const [] : names.split('|'));
  }

  @override
  Future<InventoryItem?> get(String id) async {
    final row = await (_db.select(_db.inventoryItems)..where((i) => i.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    // Les tags viennent d'une table à part : sans eux, un article relu ici
    // paraîtrait avoir perdu ses étiquettes.
    return row.toDomain(tags: await _tagNames(id));
  }

  Future<List<String>> _tagNames(String itemId) async {
    final query = _db.select(_db.inventoryTags).join([
      innerJoin(_db.tags, _db.tags.id.equalsExp(_db.inventoryTags.tagId)),
    ])
      ..where(_db.inventoryTags.itemId.equals(itemId))
      ..orderBy([OrderingTerm.asc(_db.tags.name)]);
    return (await query.get()).map((r) => r.readTable(_db.tags).name).toList();
  }

  @override
  Stream<List<InventoryItem>> watchLowStock() => watchAll().map((items) => items.where((i) => i.isLow).toList());

  @override
  Future<InventoryItem> create({
    required InventoryCategory category,
    required String name,
    required double quantity,
    required String unit,
    String? groupId,
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
          groupId: Value(groupId),
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
      groupId: Value(item.groupId),
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
    await _db.enqueueSync('inventory_items', id, 'upsert', const {});
  }

  @override
  Future<void> delete(String id) async {
    await (_db.update(_db.inventoryItems)..where((i) => i.id.equals(id)))
        .write(InventoryItemsCompanion(deletedAt: Value(DateTime.now())));
    await _db.enqueueSync('inventory_items', id, 'upsert', {});
  }

  // ----------------------------------------------------------------- tags

  @override
  Stream<List<Tag>> watchItemTags(String itemId) {
    final query = _db.select(_db.inventoryTags).join([
      innerJoin(_db.tags, _db.tags.id.equalsExp(_db.inventoryTags.tagId)),
    ])
      ..where(_db.inventoryTags.itemId.equals(itemId))
      ..orderBy([OrderingTerm.asc(_db.tags.name)]);
    return query.watch().map((rows) => rows.map((r) => r.readTable(_db.tags).toDomain()).toList());
  }

  @override
  Future<void> setItemTags(String itemId, List<String> tagIds) async {
    await _db.transaction(() async {
      await (_db.delete(_db.inventoryTags)..where((t) => t.itemId.equals(itemId))).go();
      for (final tagId in tagIds) {
        await _db.into(_db.inventoryTags).insert(InventoryTagsCompanion.insert(itemId: itemId, tagId: tagId), mode: InsertMode.insertOrIgnore);
      }
    });
    await _db.enqueueSync('inventory_items', itemId, 'upsert', const {});
  }

  // --------------------------------------------------------------- groupes

  @override
  Stream<List<InventoryGroup>> watchGroups() => (_db.select(_db.inventoryGroups)
        ..where((g) => g.gardenId.equals(_gardenId) & g.deletedAt.isNull())
        ..orderBy([(g) => OrderingTerm.asc(g.position), (g) => OrderingTerm.asc(g.label)]))
      .watch()
      .map((rows) => rows.map((r) => r.toDomain()).toList());

  @override
  Future<InventoryGroup> createGroup({required String label, String emoji = '📦'}) async {
    final now = DateTime.now();
    final id = const Uuid().v4();
    final existing = await (_db.select(_db.inventoryGroups)..where((g) => g.gardenId.equals(_gardenId) & g.deletedAt.isNull())).get();
    final position = existing.fold<int>(-1, (m, r) => r.position > m ? r.position : m) + 1;
    await _db.into(_db.inventoryGroups).insert(InventoryGroupsCompanion.insert(
          id: id,
          gardenId: _gardenId,
          label: label.trim(),
          emoji: Value(emoji),
          position: Value(position),
          createdAt: now,
          updatedAt: now,
        ));
    await _db.enqueueSync('inventory_groups', id, 'upsert', {'label': label});
    return (await (_db.select(_db.inventoryGroups)..where((g) => g.id.equals(id))).getSingle()).toDomain();
  }

  @override
  Future<void> updateGroup(InventoryGroup group) async {
    await (_db.update(_db.inventoryGroups)..where((g) => g.id.equals(group.id))).write(InventoryGroupsCompanion(
      label: Value(group.label.trim()),
      emoji: Value(group.emoji),
      position: Value(group.position),
      updatedAt: Value(DateTime.now()),
    ));
    await _db.enqueueSync('inventory_groups', group.id, 'upsert', {'label': group.label});
  }

  @override
  Future<void> deleteGroup(String id, {String? moveTo}) async {
    final now = DateTime.now();
    await _db.transaction(() async {
      // Les articles ne disparaissent jamais avec leur groupe.
      final moved = await (_db.select(_db.inventoryItems)..where((i) => i.groupId.equals(id) & i.deletedAt.isNull())).get();
      await (_db.update(_db.inventoryItems)..where((i) => i.groupId.equals(id)))
          .write(InventoryItemsCompanion(groupId: Value(moveTo), updatedAt: Value(now)));
      await (_db.update(_db.inventoryGroups)..where((g) => g.id.equals(id)))
          .write(InventoryGroupsCompanion(deletedAt: Value(now), updatedAt: Value(now)));
      for (final item in moved) {
        await _db.enqueueSync('inventory_items', item.id, 'upsert', const {});
      }
    });
    await _db.enqueueSync('inventory_groups', id, 'delete', const {});
  }

  @override
  Future<void> reorderGroups(List<String> orderedIds) async {
    final now = DateTime.now();
    await _db.transaction(() async {
      for (final (i, id) in orderedIds.indexed) {
        await (_db.update(_db.inventoryGroups)..where((g) => g.id.equals(id)))
            .write(InventoryGroupsCompanion(position: Value(i), updatedAt: Value(now)));
      }
    });
    for (final id in orderedIds) {
      await _db.enqueueSync('inventory_groups', id, 'upsert', const {});
    }
  }
}
