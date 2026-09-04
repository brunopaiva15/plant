import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/care/care_engine.dart';
import '../../domain/models/models.dart';
import '../../domain/repositories/repositories.dart';
import '../db/database.dart';
import '../db/mappers.dart';

class DriftActionRepository implements ActionRepository {
  DriftActionRepository(this._db, {String? Function()? currentUserId}) : _currentUserId = currentUserId ?? (() => null);

  final FloraDatabase _db;
  final String? Function() _currentUserId;
  static const _uuid = Uuid();

  @override
  Stream<List<PlantAction>> watchByPlant(String plantId, {int? limit}) {
    final q = _db.select(_db.plantActions)
      ..where((a) => a.plantId.equals(plantId) & a.deletedAt.isNull())
      ..orderBy([(a) => OrderingTerm.desc(a.occurredAt), (a) => OrderingTerm.desc(a.createdAt)]);
    if (limit != null) q.limit(limit);
    return q.watch().map((rows) => rows.map((r) => r.toDomain()).toList());
  }

  @override
  Stream<List<PlantAction>> watchRecent({int limit = 20}) => (_db.select(_db.plantActions)
        ..where((a) => a.deletedAt.isNull())
        ..orderBy([(a) => OrderingTerm.desc(a.occurredAt)])
        ..limit(limit))
      .watch()
      .map((rows) => rows.map((r) => r.toDomain()).toList());

  @override
  Stream<List<PlantAction>> watchBetween(DateTime from, DateTime to) => (_db.select(_db.plantActions)
        ..where((a) => a.deletedAt.isNull() & a.occurredAt.isBetweenValues(from, to))
        ..orderBy([(a) => OrderingTerm.asc(a.occurredAt)]))
      .watch()
      .map((rows) => rows.map((r) => r.toDomain()).toList());

  @override
  Future<PlantAction> log(NewAction data) async {
    final now = DateTime.now();
    final occurredAt = data.occurredAt ?? now;
    final id = _uuid.v4();
    // L'échéance précédente est mémorisée dans les métadonnées pour permettre l'Undo.
    final metadata = Map<String, Object?>.from(data.metadata);
    await _db.transaction(() async {
      final schedule = await _scheduleFor(data.plantId, data.typeKey);
      if (schedule != null) {
        metadata['_prev_next_due'] = schedule.nextDueAt?.toIso8601String();
        metadata['_prev_last_completed'] = schedule.lastCompletedAt?.toIso8601String();
        final completed = CareEngine.complete(schedule, occurredAt);
        await (_db.update(_db.careSchedules)..where((s) => s.id.equals(schedule.id))).write(CareSchedulesCompanion(
          nextDueAt: Value(completed.nextDueAt),
          lastCompletedAt: Value(completed.lastCompletedAt),
          updatedAt: Value(now),
        ));
        await _db.enqueueSync('care_schedules', schedule.id, 'upsert', const {});
      }
      final notes = data.notes?.trim();
      await _db.into(_db.plantActions).insert(PlantActionsCompanion.insert(
            id: id,
            plantId: data.plantId,
            userId: Value(_currentUserId()),
            typeKey: data.typeKey,
            occurredAt: occurredAt,
            notes: Value(notes == null || notes.isEmpty ? null : notes),
            metadata: Value(jsonEncode(metadata)),
            photoId: Value(data.photoId),
            createdAt: now,
          ));
      if (data.typeKey == CareKind.measurement.key && metadata['value'] is num) {
        final measurementId = _uuid.v4();
        await _db.enqueueSync('measurements', measurementId, 'upsert', const {});
        await _db.into(_db.measurements).insert(MeasurementsCompanion.insert(
              id: measurementId,
              plantId: data.plantId,
              actionId: Value(id),
              kind: (metadata['kind'] as String?) ?? 'height',
              value: (metadata['value'] as num).toDouble(),
              unit: (metadata['unit'] as String?) ?? 'cm',
              measuredAt: occurredAt,
            ));
      }
      await (_db.update(_db.plants)..where((p) => p.id.equals(data.plantId)))
          .write(PlantsCompanion(updatedAt: Value(now)));
      await _db.enqueueSync('plant_actions', id, 'upsert', {'type': data.typeKey});
    });
    return (await (_db.select(_db.plantActions)..where((a) => a.id.equals(id))).getSingle()).toDomain();
  }

  @override
  Future<List<PlantAction>> logMany(List<String> plantIds, String typeKey) async {
    final result = <PlantAction>[];
    for (final id in plantIds) {
      result.add(await log(NewAction(plantId: id, typeKey: typeKey)));
    }
    return result;
  }

  @override
  Future<void> undo(PlantAction action) async {
    await _db.transaction(() async {
      final schedule = await _scheduleFor(action.plantId, action.typeKey);
      if (schedule != null && action.metadata.containsKey('_prev_next_due')) {
        final prevDue = action.metadata['_prev_next_due'] as String?;
        final prevCompleted = action.metadata['_prev_last_completed'] as String?;
        await (_db.update(_db.careSchedules)..where((s) => s.id.equals(schedule.id))).write(CareSchedulesCompanion(
          nextDueAt: Value(prevDue == null ? null : DateTime.parse(prevDue)),
          lastCompletedAt: Value(prevCompleted == null ? null : DateTime.parse(prevCompleted)),
          updatedAt: Value(DateTime.now()),
        ));
        await _db.enqueueSync('care_schedules', schedule.id, 'upsert', const {});
      }
      for (final m in await (_db.select(_db.measurements)..where((m) => m.actionId.equals(action.id))).get()) {
        await _db.enqueueSync('measurements', m.id, 'delete', const {});
      }
      await (_db.delete(_db.measurements)..where((m) => m.actionId.equals(action.id))).go();
      await (_db.delete(_db.plantActions)..where((a) => a.id.equals(action.id))).go();
      await _db.enqueueSync('plant_actions', action.id, 'delete', {});
    });
  }

  Future<CareSchedule?> _scheduleFor(String plantId, String typeKey) async {
    final row = await (_db.select(_db.careSchedules)
          ..where((s) => s.plantId.equals(plantId) & s.typeKey.equals(typeKey) & s.enabled.equals(true))
          ..limit(1))
        .getSingleOrNull();
    return row?.toDomain();
  }
}
