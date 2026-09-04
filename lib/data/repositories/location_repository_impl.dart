import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/models.dart';
import '../../domain/repositories/repositories.dart';
import '../db/database.dart';
import '../db/mappers.dart';

class DriftLocationRepository implements LocationRepository {
  DriftLocationRepository(this._db, this._gardenId);

  final FloraDatabase _db;
  final String _gardenId;
  static const _uuid = Uuid();

  SimpleSelectStatement<$LocationsTable, LocationRow> get _all => _db.select(_db.locations)
    ..where((l) => l.gardenId.equals(_gardenId) & l.deletedAt.isNull())
    ..orderBy([(l) => OrderingTerm.asc(l.sortOrder), (l) => OrderingTerm.asc(l.name)]);

  @override
  Stream<List<Location>> watchAll() => _all.watch().map((rows) => rows.map((r) => r.toDomain()).toList());

  @override
  Stream<List<LocationNode>> watchTree() {
    const sql = '''
      SELECT l.*, (SELECT COUNT(*) FROM plants p WHERE p.location_id = l.id AND p.status = 'active' AND p.deleted_at IS NULL) AS plant_count
      FROM locations l WHERE l.garden_id = ? AND l.deleted_at IS NULL ORDER BY l.sort_order, l.name
    ''';
    return _db
        .customSelect(sql, variables: [Variable.withString(_gardenId)], readsFrom: {_db.locations, _db.plants})
        .watch()
        .map((rows) {
      final counts = <String, int>{};
      final locations = <Location>[];
      for (final row in rows) {
        final data = Map<String, Object?>.from(row.data)..remove('plant_count');
        final loc = _db.locations.map(data).toDomain();
        locations.add(loc);
        counts[loc.id] = row.read<int>('plant_count');
      }
      List<LocationNode> build(String? parentId) => locations
          .where((l) => l.parentId == parentId)
          .map((l) => LocationNode(location: l, plantCount: counts[l.id] ?? 0, children: build(l.id)))
          .toList();
      return build(null);
    });
  }

  @override
  Stream<Location?> watch(String id) =>
      (_db.select(_db.locations)..where((l) => l.id.equals(id))).watchSingleOrNull().map((r) => r?.toDomain());

  @override
  Future<Location> create({required String name, required String icon, String? parentId, String? light, String? orientation}) async {
    final now = DateTime.now();
    final id = _uuid.v4();
    final count = await _all.get();
    await _db.into(_db.locations).insert(LocationsCompanion.insert(
          id: id,
          gardenId: _gardenId,
          parentId: Value(parentId),
          name: name.trim(),
          icon: icon,
          light: Value(light),
          orientation: Value(orientation),
          sortOrder: Value(count.length),
          createdAt: now,
          updatedAt: now,
        ));
    await _db.enqueueSync('locations', id, 'upsert', {'name': name});
    return (await (_db.select(_db.locations)..where((l) => l.id.equals(id))).getSingle()).toDomain();
  }

  @override
  Future<void> update(Location location) async {
    await (_db.update(_db.locations)..where((l) => l.id.equals(location.id))).write(LocationsCompanion(
      name: Value(location.name.trim()),
      icon: Value(location.icon),
      parentId: Value(location.parentId),
      light: Value(location.light),
      orientation: Value(location.orientation),
      sortOrder: Value(location.sortOrder),
      updatedAt: Value(DateTime.now()),
    ));
    await _db.enqueueSync('locations', location.id, 'upsert', {'name': location.name});
  }

  @override
  Future<void> delete(String id) async {
    final now = DateTime.now();
    await _db.transaction(() async {
      // Les plantes et sous-emplacements ne sont jamais perdus : ils remontent d'un niveau.
      final parent = await (_db.select(_db.locations)..where((l) => l.id.equals(id))).getSingleOrNull();
      await (_db.update(_db.plants)..where((p) => p.locationId.equals(id)))
          .write(PlantsCompanion(locationId: Value(parent?.parentId), updatedAt: Value(now)));
      await (_db.update(_db.locations)..where((l) => l.parentId.equals(id)))
          .write(LocationsCompanion(parentId: Value(parent?.parentId), updatedAt: Value(now)));
      await (_db.update(_db.locations)..where((l) => l.id.equals(id)))
          .write(LocationsCompanion(deletedAt: Value(now), updatedAt: Value(now)));
      await _db.enqueueSync('locations', id, 'delete', {});
    });
  }

  @override
  Future<void> ensureDefaults(List<({String name, String icon})> defaults) async {
    final existing = await _all.get();
    if (existing.isNotEmpty) return;
    for (final d in defaults) {
      await create(name: d.name, icon: d.icon);
    }
  }
}
