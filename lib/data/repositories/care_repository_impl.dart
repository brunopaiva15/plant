import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/care/care_engine.dart';
import '../../domain/models/models.dart';
import '../../domain/repositories/repositories.dart';
import '../db/database.dart';
import '../db/mappers.dart';

class DriftCareRepository implements CareRepository {
  DriftCareRepository(this._db, this._plants);

  final FloraDatabase _db;
  final PlantRepository _plants;
  static const _uuid = Uuid();

  @override
  Stream<List<CareSchedule>> watchByPlant(String plantId) => (_db.select(_db.careSchedules)
        ..where((s) => s.plantId.equals(plantId))
        ..orderBy([(s) => OrderingTerm.asc(s.nextDueAt), (s) => OrderingTerm.asc(s.createdAt)]))
      .watch()
      .map((rows) => rows.map((r) => r.toDomain()).toList());

  /// Routines actives dont l'échéance est ≤ [until], jointes à leurs plantes actives.
  @override
  Stream<List<CareTask>> watchTasks({required DateTime until}) {
    final schedules = (_db.select(_db.careSchedules)
          ..where((s) => s.enabled.equals(true) & s.nextDueAt.isSmallerOrEqualValue(until))
          ..orderBy([(s) => OrderingTerm.asc(s.nextDueAt)]))
        .watch();
    final summaries = _plants.watchSummaries(const PlantFilter());
    return _combine(schedules, summaries);
  }

  @override
  Stream<List<CareTask>> watchDueTasks(DateTime now) =>
      watchTasks(until: DateTime(now.year, now.month, now.day, 23, 59, 59));

  Stream<List<CareTask>> _combine(Stream<List<CareScheduleRow>> schedules, Stream<List<PlantSummary>> summaries) {
    List<CareScheduleRow>? lastSchedules;
    List<PlantSummary>? lastSummaries;
    late StreamController<List<CareTask>> controller;
    StreamSubscription<Object?>? a;
    StreamSubscription<Object?>? b;
    void emit() {
      if (lastSchedules == null || lastSummaries == null) return;
      final byId = {for (final s in lastSummaries!) s.plant.id: s};
      controller.add([
        for (final row in lastSchedules!)
          if (byId[row.plantId] case final summary?) CareTask(summary: summary, schedule: row.toDomain()),
      ]);
    }

    controller = StreamController<List<CareTask>>(
      onListen: () {
        a = schedules.listen((v) {
          lastSchedules = v;
          emit();
        }, onError: controller.addError);
        b = summaries.listen((v) {
          lastSummaries = v;
          emit();
        }, onError: controller.addError);
      },
      onCancel: () async {
        await a?.cancel();
        await b?.cancel();
      },
    );
    return controller.stream;
  }

  @override
  Future<CareSchedule> upsert(CareSchedule schedule) async {
    final now = DateTime.now();
    final id = schedule.id.isEmpty ? _uuid.v4() : schedule.id;
    final existing = await (_db.select(_db.careSchedules)..where((s) => s.id.equals(id))).getSingleOrNull();
    final lastCompleted = schedule.lastCompletedAt ?? existing?.lastCompletedAt;
    final withId = CareSchedule(
      id: id,
      plantId: schedule.plantId,
      typeKey: schedule.typeKey,
      strategy: schedule.strategy,
      intervalDays: schedule.intervalDays,
      seasonalRules: schedule.seasonalRules,
      enabled: schedule.enabled,
      lastCompletedAt: lastCompleted,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    // L'échéance n'est recalculée que si la routine change réellement ; elle
    // repart de la dernière complétion (ou d'aujourd'hui) et n'est jamais dans le passé.
    final changed = existing == null ||
        existing.strategy != schedule.strategy.name ||
        existing.intervalDays != schedule.intervalDays ||
        existing.enabled != schedule.enabled;
    DateTime? nextDue = existing?.nextDueAt;
    if (changed) {
      nextDue = CareEngine.nextDueAfter(withId, lastCompleted ?? now);
      final today = DateTime(now.year, now.month, now.day);
      if (nextDue != null && nextDue.isBefore(today)) nextDue = today;
    }
    await _db.into(_db.careSchedules).insertOnConflictUpdate(CareSchedulesCompanion.insert(
          id: id,
          plantId: withId.plantId,
          typeKey: withId.typeKey,
          strategy: withId.strategy.name,
          intervalDays: withId.intervalDays,
          seasonalRules: Value(withId.seasonalRules == null ? null : jsonEncode(withId.seasonalRules)),
          nextDueAt: Value(withId.enabled ? nextDue : null),
          lastCompletedAt: Value(withId.lastCompletedAt),
          enabled: Value(withId.enabled),
          createdAt: withId.createdAt,
          updatedAt: now,
        ));
    await _db.enqueueSync('care_schedules', id, 'upsert', {'type': withId.typeKey});
    return (await (_db.select(_db.careSchedules)..where((s) => s.id.equals(id))).getSingle()).toDomain();
  }

  @override
  Future<void> delete(String id) async {
    await (_db.delete(_db.careSchedules)..where((s) => s.id.equals(id))).go();
    await _db.enqueueSync('care_schedules', id, 'delete', {});
  }

  @override
  Future<void> snooze(String scheduleId, DateTime now, {int days = 1}) async {
    final row = await (_db.select(_db.careSchedules)..where((s) => s.id.equals(scheduleId))).getSingleOrNull();
    if (row == null) return;
    final updated = CareEngine.snooze(row.toDomain(), now, days: days);
    await (_db.update(_db.careSchedules)..where((s) => s.id.equals(scheduleId)))
        .write(CareSchedulesCompanion(nextDueAt: Value(updated.nextDueAt), updatedAt: Value(now)));
  }
}
