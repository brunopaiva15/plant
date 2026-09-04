import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/models.dart';
import '../../domain/repositories/repositories.dart';
import '../db/database.dart';
import '../db/mappers.dart';

class DriftActionTypeRepository implements ActionTypeRepository {
  DriftActionTypeRepository(this._db);

  final FloraDatabase _db;

  @override
  Stream<List<ActionType>> watchAll() => (_db.select(_db.actionTypes)..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
      .watch()
      .map((rows) => rows.map((r) => r.toDomain()).toList());

  @override
  Future<ActionType> createCustom({required String label, required String emoji, bool schedulable = true}) async {
    final key = '${ActionType.customPrefix}${const Uuid().v4()}';
    final count = await _db.select(_db.actionTypes).get();
    await _db.into(_db.actionTypes).insert(ActionTypesCompanion.insert(
          key: key,
          label: Value(label.trim()),
          emoji: emoji,
          isBuiltin: false,
          schedulable: Value(schedulable),
          sortOrder: count.length,
        ));
    return (await (_db.select(_db.actionTypes)..where((t) => t.key.equals(key))).getSingle()).toDomain();
  }

  @override
  Future<void> deleteCustom(String key) async {
    if (!key.startsWith(ActionType.customPrefix)) return;
    await _db.transaction(() async {
      await (_db.delete(_db.careSchedules)..where((s) => s.typeKey.equals(key))).go();
      await (_db.delete(_db.actionTypes)..where((t) => t.key.equals(key))).go();
    });
  }
}
