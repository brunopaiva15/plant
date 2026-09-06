import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/config/app_config.dart';
import '../../domain/care/care_engine.dart';
import '../../domain/models/models.dart';
import '../../domain/repositories/repositories.dart';
import '../db/database.dart';
import '../db/mappers.dart';

class DriftPlantRepository implements PlantRepository {
  DriftPlantRepository(this._db, this._gardenId);

  final FloraDatabase _db;
  final String _gardenId;
  static const _uuid = Uuid();

  /// Séparateur des tags concaténés ; interdit dans un nom de tag (voir TagRepository).
  static const tagSeparator = '|';

  /// Requête unique pour les cartes : plante + emplacement + miniature + prochain soin.
  static const _summarySql = '''
    SELECT p.*, l.name AS location_name, ph.thumb_path AS thumb_path, ph.remote_url AS thumb_url,
      (SELECT cs.next_due_at FROM care_schedules cs
         WHERE cs.plant_id = p.id AND cs.enabled = 1 AND cs.next_due_at IS NOT NULL
         ORDER BY cs.next_due_at ASC LIMIT 1) AS next_due_at,
      (SELECT cs.type_key FROM care_schedules cs
         WHERE cs.plant_id = p.id AND cs.enabled = 1 AND cs.next_due_at IS NOT NULL
         ORDER BY cs.next_due_at ASC LIMIT 1) AS next_type,
      (SELECT GROUP_CONCAT(t.name, '$tagSeparator') FROM plant_tags pt JOIN tags t ON t.id = pt.tag_id
         WHERE pt.plant_id = p.id) AS tag_names
    FROM plants p
    LEFT JOIN locations l ON l.id = p.location_id
    LEFT JOIN plant_photos ph ON ph.id = p.primary_photo_id
  ''';

  Set<ResultSetImplementation> get _summaryTables =>
      {_db.plants, _db.locations, _db.plantPhotos, _db.careSchedules, _db.plantTags, _db.tags, _db.plantAttributes};

  PlantSummary _mapSummary(QueryRow row) {
    final data = Map<String, Object?>.from(row.data)
      ..remove('location_name')
      ..remove('thumb_path')
      ..remove('thumb_url')
      ..remove('next_due_at')
      ..remove('next_type')
      ..remove('tag_names');
    final plant = _db.plants.map(data).toDomain();
    final rawTags = row.readNullable<String>('tag_names');
    return PlantSummary(
      plant: plant,
      locationName: row.readNullable<String>('location_name'),
      thumbPath: row.readNullable<String>('thumb_path'),
      thumbUrl: row.readNullable<String>('thumb_url'),
      nextDueAt: row.readNullable<DateTime>('next_due_at'),
      nextDueTypeKey: row.readNullable<String>('next_type'),
      tags: rawTags == null || rawTags.isEmpty ? const [] : rawTags.split(tagSeparator),
    );
  }

  @override
  Stream<List<PlantSummary>> watchSummaries(PlantFilter filter) {
    final where = <String>['p.deleted_at IS NULL', 'p.garden_id = ?', 'p.status = ?'];
    final vars = <Variable>[Variable.withString(_gardenId), Variable.withString(filter.status.name)];
    if (filter.locationId != null) {
      where.add('(p.location_id = ? OR p.location_id IN (SELECT id FROM locations WHERE parent_id = ?))');
      vars
        ..add(Variable.withString(filter.locationId!))
        ..add(Variable.withString(filter.locationId!));
    }
    if (filter.favoritesOnly) where.add('p.is_favorite = 1');
    if (filter.tagId != null) {
      where.add('p.id IN (SELECT plant_id FROM plant_tags WHERE tag_id = ?)');
      vars.add(Variable.withString(filter.tagId!));
    }
    final q = filter.query.trim().toLowerCase();
    // « #42 » cherche le numéro exact de la plante, rien d'autre.
    final number = _numberQuery(q);
    if (number != null) {
      where.add('p.number = ?');
      vars.add(Variable.withInt(number));
    } else if (q.isNotEmpty) {
      where.add('''(lower(p.name) LIKE ? OR lower(p.species_name) LIKE ? OR lower(l.name) LIKE ?
        OR lower(p.notes) LIKE ?
        OR p.id IN (SELECT pt.plant_id FROM plant_tags pt JOIN tags t ON t.id = pt.tag_id WHERE lower(t.name) LIKE ?)
        OR p.id IN (SELECT a.plant_id FROM plant_actions a WHERE a.deleted_at IS NULL AND lower(a.notes) LIKE ?)
        OR p.id IN (SELECT pa.plant_id FROM plant_attributes pa WHERE pa.deleted_at IS NULL AND (lower(pa.value) LIKE ? OR lower(pa.label) LIKE ?)))''');
      final like = Variable.withString('%$q%');
      vars.addAll([like, like, like, like, like, like, like, like]);
    }
    final order = switch (filter.sort) {
      PlantSort.name => 'lower(p.name) ASC',
      PlantSort.nextCare => 'next_due_at IS NULL, next_due_at ASC, lower(p.name) ASC',
      PlantSort.recentlyAdded => 'p.created_at DESC',
    };
    final sql = '$_summarySql WHERE ${where.join(' AND ')} ORDER BY $order';
    return _db.customSelect(sql, variables: vars, readsFrom: _summaryTables).watch().map((rows) {
      final list = rows.map(_mapSummary).toList();
      if (!filter.needsAttention) return list;
      final now = DateTime.now();
      return list.where((s) {
        final st = s.dueStatus(now);
        return st == DueStatus.today || st == DueStatus.overdue;
      }).toList();
    });
  }

  @override
  Stream<PlantSummary?> watchSummary(String id) => _db
      .customSelect('$_summarySql WHERE p.id = ?', variables: [Variable.withString(id)], readsFrom: _summaryTables)
      .watchSingleOrNull()
      .map((r) => r == null ? null : _mapSummary(r));

  @override
  Stream<List<PlantSummary>> watchChildren(String parentId) => _db
      .customSelect('$_summarySql WHERE p.parent_plant_id = ? AND p.deleted_at IS NULL ORDER BY p.created_at ASC',
          variables: [Variable.withString(parentId)], readsFrom: _summaryTables)
      .watch()
      .map((rows) => rows.map(_mapSummary).toList());

  @override
  Stream<List<PlantSummary>> watchArchived() => _db
      .customSelect("$_summarySql WHERE p.status = 'archived' AND p.deleted_at IS NULL ORDER BY p.archived_at DESC",
          readsFrom: _summaryTables)
      .watch()
      .map((rows) => rows.map(_mapSummary).toList());

  @override
  Stream<Plant?> watchPlant(String id) =>
      (_db.select(_db.plants)..where((p) => p.id.equals(id))).watchSingleOrNull().map((r) => r?.toDomain());

  @override
  Future<Plant?> getPlant(String id) async =>
      (await (_db.select(_db.plants)..where((p) => p.id.equals(id))).getSingleOrNull())?.toDomain();

  @override
  Stream<int> watchActiveCount() {
    final count = _db.plants.id.count();
    final q = _db.selectOnly(_db.plants)
      ..addColumns([count])
      ..where(_db.plants.status.equals('active') & _db.plants.deletedAt.isNull() & _db.plants.gardenId.equals(_gardenId));
    return q.watchSingle().map((r) => r.read(count) ?? 0);
  }

  @override
  Future<Plant> create(NewPlant data) async {
    final now = DateTime.now();
    final id = _uuid.v4();
    final number = await _nextNumber();
    await _db.transaction(() async {
      await _db.into(_db.plants).insert(PlantsCompanion.insert(
            number: Value(number),
            id: id,
            gardenId: _gardenId,
            name: data.name.trim(),
            speciesName: Value(data.speciesName?.trim().nullIfEmpty),
            locationId: Value(data.locationId),
            acquiredAt: Value(data.acquiredAt),
            notes: Value(data.notes?.trim().nullIfEmpty),
            parentPlantId: Value(data.parentPlantId),
            createdAt: now,
            updatedAt: now,
          ));
      // Routines par défaut : l'utilisateur n'a rien à configurer pour recevoir des rappels.
      final defaults = [
        (CareKind.watering, data.wateringIntervalDays ?? AppConfig.defaultWateringInterval),
        (CareKind.fertilizing, data.fertilizingIntervalDays ?? AppConfig.defaultFertilizingInterval),
      ];
      for (final (kind, days) in defaults) {
        if (days <= 0) continue;
        final schedule = CareSchedule(
          id: _uuid.v4(),
          plantId: id,
          typeKey: kind.key,
          strategy: CareStrategy.fixed,
          intervalDays: days,
          enabled: true,
          createdAt: now,
          updatedAt: now,
        );
        await _db.into(_db.careSchedules).insert(CareSchedulesCompanion.insert(
              id: schedule.id,
              plantId: id,
              typeKey: kind.key,
              strategy: schedule.strategy.name,
              intervalDays: days,
              nextDueAt: Value(CareEngine.initialDue(schedule, now)),
              createdAt: now,
              updatedAt: now,
            ));
        await _db.enqueueSync('care_schedules', schedule.id, 'upsert', const {});
      }
      await _db.enqueueSync('plants', id, 'upsert', {'name': data.name});
    });
    return (await getPlant(id))!;
  }

  @override
  Future<void> update(Plant plant) async {
    final now = DateTime.now();
    await (_db.update(_db.plants)..where((p) => p.id.equals(plant.id))).write(PlantsCompanion(
      name: Value(plant.name.trim()),
      speciesName: Value(plant.speciesName?.trim().nullIfEmpty),
      locationId: Value(plant.locationId),
      primaryPhotoId: Value(plant.primaryPhotoId),
      status: Value(plant.status.name),
      health: Value(plant.health.name),
      isFavorite: Value(plant.isFavorite),
      acquiredAt: Value(plant.acquiredAt),
      source: Value(plant.source?.trim().nullIfEmpty),
      price: Value(plant.price),
      potSize: Value(plant.potSize),
      notes: Value(plant.notes?.trim().nullIfEmpty),
      parentPlantId: Value(plant.parentPlantId),
      updatedAt: Value(now),
    ));
    await _db.enqueueSync('plants', plant.id, 'upsert', {'name': plant.name});
  }

  @override
  Future<void> setFavorite(String id, bool value) async {
    await (_db.update(_db.plants)..where((p) => p.id.equals(id))).write(PlantsCompanion(isFavorite: Value(value), updatedAt: Value(DateTime.now())));
    await _db.enqueueSync('plants', id, 'upsert', const {});
  }

  @override
  Future<void> moveToLocation(List<String> ids, String? locationId) async {
    await (_db.update(_db.plants)..where((p) => p.id.isIn(ids))).write(PlantsCompanion(locationId: Value(locationId), updatedAt: Value(DateTime.now())));
    for (final id in ids) {
      await _db.enqueueSync('plants', id, 'upsert', const {});
    }
  }

  @override
  Future<void> archive(List<String> ids, {String? reason}) async {
    final now = DateTime.now();
    await _db.transaction(() async {
      await (_db.update(_db.plants)..where((p) => p.id.isIn(ids))).write(PlantsCompanion(
        status: const Value('archived'),
        archivedAt: Value(now),
        archiveReason: Value(reason),
        updatedAt: Value(now),
      ));
      // Une plante archivée ne génère plus de rappel.
      await (_db.update(_db.careSchedules)..where((s) => s.plantId.isIn(ids)))
          .write(CareSchedulesCompanion(enabled: const Value(false), updatedAt: Value(now)));
      for (final id in ids) {
        await _db.enqueueSync('plants', id, 'upsert', {'status': 'archived'});
      }
      for (final s in await (_db.select(_db.careSchedules)..where((s) => s.plantId.isIn(ids))).get()) {
        await _db.enqueueSync('care_schedules', s.id, 'upsert', const {});
      }
    });
  }

  @override
  Future<void> restore(List<String> ids) async {
    final now = DateTime.now();
    await _db.transaction(() async {
      await (_db.update(_db.plants)..where((p) => p.id.isIn(ids))).write(PlantsCompanion(
        status: const Value('active'),
        archivedAt: const Value(null),
        archiveReason: const Value(null),
        updatedAt: Value(now),
      ));
      // Les routines reprennent à partir d'aujourd'hui.
      final schedules = await (_db.select(_db.careSchedules)..where((s) => s.plantId.isIn(ids))).get();
      for (final row in schedules) {
        final s = row.toDomain().copyWith(enabled: true);
        await (_db.update(_db.careSchedules)..where((x) => x.id.equals(s.id))).write(CareSchedulesCompanion(
          enabled: const Value(true),
          nextDueAt: Value(CareEngine.initialDue(s, now)),
          updatedAt: Value(now),
        ));
        await _db.enqueueSync('care_schedules', s.id, 'upsert', const {});
      }
      for (final id in ids) {
        await _db.enqueueSync('plants', id, 'upsert', const {});
      }
    });
  }

  @override
  Future<void> deleteForever(String id) async {
    await _db.transaction(() async {
      await (_db.delete(_db.careSchedules)..where((s) => s.plantId.equals(id))).go();
      await (_db.delete(_db.plantActions)..where((a) => a.plantId.equals(id))).go();
      await (_db.delete(_db.plantPhotos)..where((p) => p.plantId.equals(id))).go();
      await (_db.delete(_db.plantTags)..where((p) => p.plantId.equals(id))).go();
      await (_db.delete(_db.plants)..where((p) => p.id.equals(id))).go();
      await _db.enqueueSync('plants', id, 'delete', {});
    });
  }

  /// Prochain numéro du jardin, pris sur un compteur qui ne recule jamais :
  /// même après une suppression définitive, un numéro déjà imprimé sur une
  /// étiquette n'est pas réattribué à une autre plante.
  Future<int> _nextNumber() async {
    final garden = await (_db.select(_db.gardens)..where((g) => g.id.equals(_gardenId))).getSingleOrNull();
    // Les plantes existantes font foi si le compteur est en retard (base
    // migrée, ou jardin arrivé par synchronisation).
    final fromPlants = await _db.customSelect(
      'SELECT COALESCE(MAX(number), 0) AS m FROM plants WHERE garden_id = ?',
      variables: [Variable.withString(_gardenId)],
      readsFrom: {_db.plants},
    ).getSingle();
    final next = ((garden?.plantCounter ?? 0) > (fromPlants.data['m'] as int? ?? 0) ? garden!.plantCounter : (fromPlants.data['m'] as int? ?? 0)) + 1;
    await (_db.update(_db.gardens)..where((g) => g.id.equals(_gardenId))).write(GardensCompanion(plantCounter: Value(next)));
    return next;
  }

  /// « #42 » → 42, sinon `null`.
  static int? _numberQuery(String query) {
    final m = RegExp(r'^#\s*(\d{1,9})$').firstMatch(query);
    return m == null ? null : int.tryParse(m.group(1)!);
  }
}

extension on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}
