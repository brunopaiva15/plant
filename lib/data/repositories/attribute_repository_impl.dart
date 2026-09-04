import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/models.dart';
import '../../domain/repositories/repositories.dart';
import '../db/database.dart';
import '../db/mappers.dart';

class DriftAttributeRepository implements AttributeRepository {
  DriftAttributeRepository(this._db, this._gardenId);

  final FloraDatabase _db;
  final String _gardenId;

  @override
  Stream<List<PlantAttribute>> watchForPlant(String plantId) => (_db.select(_db.plantAttributes)
        ..where((a) => a.plantId.equals(plantId) & a.deletedAt.isNull())
        ..orderBy([(a) => OrderingTerm.asc(a.position), (a) => OrderingTerm.asc(a.createdAt)]))
      .watch()
      .map((rows) => rows.map((r) => r.toDomain()).toList());

  @override
  Stream<List<AttributeSchema>> watchSchemas({bool activeOnly = false}) {
    final q = _db.select(_db.attributeSchemas)
      ..where((s) => s.gardenId.equals(_gardenId) & s.deletedAt.isNull())
      ..orderBy([(s) => OrderingTerm.asc(s.position), (s) => OrderingTerm.asc(s.label)]);
    if (activeOnly) q.where((s) => s.active.equals(true));
    return q.watch().map((rows) => rows.map((r) => r.toDomain()).toList());
  }

  @override
  Future<PlantAttribute> add({required String plantId, required String label, required AttributeType type, String? value}) async {
    final id = await _insert(plantId: plantId, label: label, type: type, value: value);
    return (await (_db.select(_db.plantAttributes)..where((a) => a.id.equals(id))).getSingle()).toDomain();
  }

  Future<String> _insert({required String plantId, required String label, required AttributeType type, String? value}) async {
    final now = DateTime.now();
    final id = const Uuid().v4();
    final next = await _nextPosition(plantId);
    await _db.into(_db.plantAttributes).insert(PlantAttributesCompanion.insert(
          id: id,
          gardenId: _gardenId,
          plantId: plantId,
          label: label.trim(),
          datatype: type.key,
          value: Value(_clean(value)),
          position: Value(next),
          createdAt: now,
          updatedAt: now,
        ));
    await _db.enqueueSync('plant_attributes', id, 'upsert', {'label': label});
    return id;
  }

  Future<int> _nextPosition(String plantId) async {
    final rows = await (_db.select(_db.plantAttributes)..where((a) => a.plantId.equals(plantId) & a.deletedAt.isNull())).get();
    return rows.fold<int>(-1, (m, r) => r.position > m ? r.position : m) + 1;
  }

  @override
  Future<void> update(PlantAttribute attribute) async {
    await (_db.update(_db.plantAttributes)..where((a) => a.id.equals(attribute.id))).write(PlantAttributesCompanion(
      label: Value(attribute.label.trim()),
      datatype: Value(attribute.type.key),
      value: Value(_clean(attribute.value)),
      position: Value(attribute.position),
      updatedAt: Value(DateTime.now()),
    ));
    await _db.enqueueSync('plant_attributes', attribute.id, 'upsert', {'label': attribute.label});
  }

  @override
  Future<void> delete(String id) async {
    await (_db.update(_db.plantAttributes)..where((a) => a.id.equals(id)))
        .write(PlantAttributesCompanion(deletedAt: Value(DateTime.now()), updatedAt: Value(DateTime.now())));
    await _db.enqueueSync('plant_attributes', id, 'delete', const {});
  }

  @override
  Future<void> applyToPlants(List<String> plantIds, {required String label, required AttributeType type, String? value}) async {
    final trimmed = label.trim();
    for (final plantId in plantIds) {
      // Un même libellé n'est jamais dupliqué sur une plante : on met à jour.
      final existing = await (_db.select(_db.plantAttributes)
            ..where((a) => a.plantId.equals(plantId) & a.label.equals(trimmed) & a.deletedAt.isNull()))
          .getSingleOrNull();
      if (existing == null) {
        await _insert(plantId: plantId, label: trimmed, type: type, value: value);
      } else {
        await update(existing.toDomain().copyWith(type: type, value: () => value));
      }
    }
  }

  @override
  Future<void> cloneAttributes({required String fromPlantId, required String toPlantId}) async {
    final source = await (_db.select(_db.plantAttributes)..where((a) => a.plantId.equals(fromPlantId) & a.deletedAt.isNull())).get();
    for (final row in source) {
      await _insert(plantId: toPlantId, label: row.label, type: AttributeType.fromKey(row.datatype), value: row.value);
    }
  }

  @override
  Future<Set<String>> searchPlantIds(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const {};
    final rows = await (_db.select(_db.plantAttributes)
          ..where((a) => a.gardenId.equals(_gardenId) & a.deletedAt.isNull() & (a.value.lower().contains(q.toLowerCase()) | a.label.lower().contains(q.toLowerCase()))))
        .get();
    return rows.map((r) => r.plantId).toSet();
  }

  @override
  Future<AttributeSchema> createSchema({required String label, required AttributeType type}) async {
    final now = DateTime.now();
    final id = const Uuid().v4();
    final existing = await (_db.select(_db.attributeSchemas)..where((s) => s.gardenId.equals(_gardenId) & s.deletedAt.isNull())).get();
    final position = existing.fold<int>(-1, (m, r) => r.position > m ? r.position : m) + 1;
    await _db.into(_db.attributeSchemas).insert(AttributeSchemasCompanion.insert(
          id: id,
          gardenId: _gardenId,
          label: label.trim(),
          datatype: type.key,
          position: Value(position),
          createdAt: now,
          updatedAt: now,
        ));
    await _db.enqueueSync('attribute_schemas', id, 'upsert', {'label': label});
    return (await (_db.select(_db.attributeSchemas)..where((s) => s.id.equals(id))).getSingle()).toDomain();
  }

  @override
  Future<void> updateSchema(AttributeSchema schema) async {
    await (_db.update(_db.attributeSchemas)..where((s) => s.id.equals(schema.id))).write(AttributeSchemasCompanion(
      label: Value(schema.label.trim()),
      datatype: Value(schema.type.key),
      active: Value(schema.active),
      position: Value(schema.position),
      updatedAt: Value(DateTime.now()),
    ));
    await _db.enqueueSync('attribute_schemas', schema.id, 'upsert', {'label': schema.label});
  }

  @override
  Future<void> deleteSchema(String id) async {
    await (_db.update(_db.attributeSchemas)..where((s) => s.id.equals(id)))
        .write(AttributeSchemasCompanion(deletedAt: Value(DateTime.now()), updatedAt: Value(DateTime.now())));
    await _db.enqueueSync('attribute_schemas', id, 'delete', const {});
  }

  static String? _clean(String? s) {
    final t = s?.trim();
    return t == null || t.isEmpty ? null : t;
  }
}
