import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flora/data/db/database.dart';
import 'package:flora/data/repositories/task_repository_impl.dart';
import 'package:flora/domain/models/models.dart';
import 'package:flora/domain/repositories/repositories.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FloraDatabase db;
  late TaskRepository repo;
  const gardenId = 'garden-1';

  setUp(() async {
    db = FloraDatabase(NativeDatabase.memory());
    await db.into(db.gardens).insert(GardensCompanion.insert(id: gardenId, ownerId: 'user-1', name: 'Jardin', createdAt: DateTime.now(), updatedAt: DateTime.now()));
    repo = DriftTaskRepository(db, gardenId);
  });

  tearDown(() => db.close());

  test('crée une tâche sans plante ni date', () async {
    final task = await repo.create(const NewTask(title: '  Commander du terreau  '));
    expect(task.title, 'Commander du terreau');
    expect(task.plantId, isNull);
    expect(task.dueAt, isNull);
    expect(task.done, isFalse);
    expect(await repo.watchOpen().first, hasLength(1));
  });

  test('compléter une tâche simple la marque terminée', () async {
    final task = await repo.create(const NewTask(title: 'Nettoyer la serre'));
    await repo.complete(task.id);
    final after = await repo.get(task.id);
    expect(after!.done, isTrue);
    expect(after.doneAt, isNotNull);
    expect(await repo.watchOpen().first, isEmpty);
  });

  test('compléter une tâche récurrente reporte l\'échéance et la garde ouverte', () async {
    // Sans microsecondes : SQLite stocke les dates à la seconde.
    final n = DateTime.now();
    final due = DateTime(n.year, n.month, n.day, n.hour, n.minute).subtract(const Duration(days: 3));
    final task = await repo.create(NewTask(
      title: 'Arroser la serre',
      dueAt: due,
      recurrence: const TaskRecurrence(value: 1, unit: RecurrenceUnit.weeks),
    ));
    await repo.complete(task.id);
    final after = await repo.get(task.id);
    expect(after!.done, isFalse, reason: 'une tâche récurrente reste ouverte');
    expect(after.doneAt, isNotNull);
    expect(after.dueAt!.isAfter(DateTime.now()), isTrue);
    expect(after.dueAt, due.add(const Duration(days: 7)));
  });

  test('restore rétablit l\'état exact (Undo)', () async {
    final task = await repo.create(NewTask(title: 'Semer les tomates', dueAt: DateTime(2026, 3, 1)));
    final before = await repo.complete(task.id);
    await repo.restore(before);
    final after = await repo.get(task.id);
    expect(after!.done, isFalse);
    expect(after.doneAt, isNull);
    expect(after.dueAt, DateTime(2026, 3, 1));
  });

  test('rouvrir une tâche terminée', () async {
    final task = await repo.create(const NewTask(title: 'Tailler'));
    await repo.complete(task.id);
    await repo.reopen(task.id);
    expect((await repo.get(task.id))!.done, isFalse);
  });

  test('supprimer masque la tâche mais restore la ramène', () async {
    final task = await repo.create(const NewTask(title: 'Rempoter'));
    await repo.delete(task.id);
    expect(await repo.watchAll().first, isEmpty);
    await repo.restore(task);
    expect(await repo.watchAll().first, hasLength(1));
  });

  test('les tâches d\'une plante sont filtrées', () async {
    await db.into(db.plants).insert(PlantsCompanion.insert(
          id: 'p1',
          gardenId: gardenId,
          name: 'Monstera',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
    await repo.create(const NewTask(title: 'Bouturer', plantId: 'p1'));
    await repo.create(const NewTask(title: 'Sans plante'));
    expect(await repo.watchByPlant('p1').first, hasLength(1));
  });

  test('chaque écriture est mise en file de synchronisation', () async {
    final task = await repo.create(const NewTask(title: 'Test'));
    final pending = await (db.select(db.syncOutbox)..where((o) => o.entity.equals('tasks') & o.entityId.equals(task.id))).get();
    expect(pending, isNotEmpty);
  });
}
