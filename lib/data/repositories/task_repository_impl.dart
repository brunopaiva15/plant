import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/models.dart';
import '../../domain/repositories/repositories.dart';
import '../db/database.dart';
import '../db/mappers.dart';

class DriftTaskRepository implements TaskRepository {
  DriftTaskRepository(this._db, this._gardenId);

  final FloraDatabase _db;
  final String _gardenId;

  SimpleSelectStatement<$TasksTable, TaskRow> get _all => _db.select(_db.tasks)
    ..where((t) => t.gardenId.equals(_gardenId) & t.deletedAt.isNull())
    ..orderBy([
      (t) => OrderingTerm.asc(t.done),
      // Échéance la plus proche d'abord ; sans échéance en dernier.
      (t) => OrderingTerm(expression: t.dueAt.isNull(), mode: OrderingMode.asc),
      (t) => OrderingTerm.asc(t.dueAt),
      (t) => OrderingTerm.desc(t.createdAt),
    ]);

  static List<FreeTask> _map(List<TaskRow> rows) => rows.map((r) => r.toDomain()).toList();

  @override
  Stream<List<FreeTask>> watchAll() => _all.watch().map(_map);

  @override
  Stream<List<FreeTask>> watchOpen() => (_all..where((t) => t.done.equals(false))).watch().map(_map);

  @override
  Stream<List<FreeTask>> watchDone({int limit = 50}) => ((_db.select(_db.tasks)
        ..where((t) => t.gardenId.equals(_gardenId) & t.deletedAt.isNull() & t.done.equals(true))
        ..orderBy([(t) => OrderingTerm.desc(t.doneAt)])
        ..limit(limit)))
      .watch()
      .map(_map);

  @override
  Stream<List<FreeTask>> watchByPlant(String plantId) => (_all..where((t) => t.plantId.equals(plantId))).watch().map(_map);

  @override
  Future<FreeTask?> get(String id) async => (await (_db.select(_db.tasks)..where((t) => t.id.equals(id))).getSingleOrNull())?.toDomain();

  @override
  Future<FreeTask> create(NewTask data) async {
    final now = DateTime.now();
    final id = const Uuid().v4();
    await _db.into(_db.tasks).insert(TasksCompanion.insert(
          id: id,
          gardenId: _gardenId,
          plantId: Value(data.plantId),
          title: data.title.trim(),
          description: Value(_clean(data.description)),
          dueAt: Value(data.dueAt),
          allDay: Value(data.allDay),
          recurrenceValue: Value(data.recurrence?.value),
          recurrenceUnit: Value(data.recurrence?.unit.key),
          createdAt: now,
          updatedAt: now,
        ));
    await _db.enqueueSync('tasks', id, 'upsert', {'title': data.title});
    return (await get(id))!;
  }

  @override
  Future<void> update(FreeTask task) async {
    await (_db.update(_db.tasks)..where((t) => t.id.equals(task.id))).write(TasksCompanion(
      plantId: Value(task.plantId),
      title: Value(task.title.trim()),
      description: Value(_clean(task.description)),
      dueAt: Value(task.dueAt),
      allDay: Value(task.allDay),
      recurrenceValue: Value(task.recurrence?.value),
      recurrenceUnit: Value(task.recurrence?.unit.key),
      done: Value(task.done),
      doneAt: Value(task.doneAt),
      updatedAt: Value(DateTime.now()),
    ));
    await _db.enqueueSync('tasks', task.id, 'upsert', {'title': task.title});
  }

  @override
  Future<FreeTask> complete(String id, {DateTime? now}) async {
    final current = await get(id);
    if (current == null) throw StateError('task not found');
    final at = now ?? DateTime.now();
    final rec = current.recurrence;
    final FreeTask next;
    if (rec == null) {
      next = current.copyWith(done: true, doneAt: () => at);
    } else {
      final base = current.dueAt ?? at;
      next = current.copyWith(done: false, doneAt: () => at, dueAt: () => rec.nextAfter(base, at));
    }
    await update(next);
    return current;
  }

  @override
  Future<void> reopen(String id) async {
    final current = await get(id);
    if (current == null) return;
    await update(current.copyWith(done: false, doneAt: () => null));
  }

  @override
  Future<void> restore(FreeTask previous) async {
    // Undo d'une suppression comme d'une complétion : on lève aussi la
    // suppression logique, sinon la ligne resterait masquée.
    await (_db.update(_db.tasks)..where((t) => t.id.equals(previous.id))).write(const TasksCompanion(deletedAt: Value(null)));
    await update(previous);
  }

  @override
  Future<void> delete(String id) async {
    await (_db.update(_db.tasks)..where((t) => t.id.equals(id))).write(TasksCompanion(deletedAt: Value(DateTime.now()), updatedAt: Value(DateTime.now())));
    await _db.enqueueSync('tasks', id, 'delete', const {});
  }

  static String? _clean(String? s) {
    final t = s?.trim();
    return t == null || t.isEmpty ? null : t;
  }
}
