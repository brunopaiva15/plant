import 'package:drift/native.dart';
import 'package:flora/data/db/database.dart';
import 'package:flora/data/repositories/action_repository_impl.dart';
import 'package:flora/data/repositories/care_repository_impl.dart';
import 'package:flora/data/repositories/location_repository_impl.dart';
import 'package:flora/data/repositories/plant_repository_impl.dart';
import 'package:flora/data/repositories/tag_repository_impl.dart';
import 'package:flora/domain/care/care_engine.dart';
import 'package:flora/domain/models/models.dart';
import 'package:flora/domain/repositories/repositories.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FloraDatabase db;
  late DriftPlantRepository plants;
  late DriftLocationRepository locations;
  late DriftActionRepository actions;
  late DriftCareRepository care;
  late DriftTagRepository tags;
  const garden = 'garden-1';

  setUp(() async {
    db = FloraDatabase(NativeDatabase.memory());
    plants = DriftPlantRepository(db, garden);
    locations = DriftLocationRepository(db, garden);
    actions = DriftActionRepository(db);
    care = DriftCareRepository(db, plants);
    tags = DriftTagRepository(db, garden);
  });

  tearDown(() => db.close());

  test('creating a plant seeds default watering and fertilizing routines', () async {
    final plant = await plants.create(const NewPlant(name: 'Monstera'));
    final schedules = await care.watchByPlant(plant.id).first;
    expect(schedules.map((s) => s.typeKey), containsAll(['watering', 'fertilizing']));
    final watering = schedules.firstWhere((s) => s.typeKey == 'watering');
    expect(watering.nextDueAt, isNotNull);
    expect(CareEngine.daysUntil(watering.nextDueAt, DateTime.now()), 7);
  });

  test('summaries expose location name and next care', () async {
    final salon = await locations.create(name: 'Salon', icon: '🛋️');
    await plants.create(NewPlant(name: 'Pilea', locationId: salon.id));
    final list = await plants.watchSummaries(const PlantFilter()).first;
    expect(list, hasLength(1));
    expect(list.first.locationName, 'Salon');
    expect(list.first.nextDueTypeKey, 'watering');
  });

  test('watering logs an action, completes the routine, and undo restores it', () async {
    final plant = await plants.create(const NewPlant(name: 'Ficus'));
    final before = (await care.watchByPlant(plant.id).first).firstWhere((s) => s.typeKey == 'watering');

    final action = await actions.log(NewAction(plantId: plant.id, typeKey: 'watering'));
    final after = (await care.watchByPlant(plant.id).first).firstWhere((s) => s.typeKey == 'watering');
    expect(after.lastCompletedAt, isNotNull);
    expect(after.nextDueAt!.isAfter(before.nextDueAt!) || after.nextDueAt == before.nextDueAt, isTrue);
    expect(await actions.watchByPlant(plant.id).first, hasLength(1));

    await actions.undo(action);
    final restored = (await care.watchByPlant(plant.id).first).firstWhere((s) => s.typeKey == 'watering');
    expect(restored.nextDueAt, before.nextDueAt);
    expect(restored.lastCompletedAt, before.lastCompletedAt);
    expect(await actions.watchByPlant(plant.id).first, isEmpty);
  });

  test('due tasks only include active plants with due schedules', () async {
    final p = await plants.create(const NewPlant(name: 'Calathea'));
    // Force the watering routine to be due today.
    final s = (await care.watchByPlant(p.id).first).firstWhere((x) => x.typeKey == 'watering');
    await care.upsert(s.copyWith(intervalDays: 1));
    await actions.log(NewAction(plantId: p.id, typeKey: 'watering', occurredAt: DateTime.now().subtract(const Duration(days: 3))));
    final due = await care.watchDueTasks(DateTime.now()).first;
    expect(due.map((t) => t.typeKey), contains('watering'));

    await plants.archive([p.id], reason: 'died');
    expect(await care.watchDueTasks(DateTime.now()).first, isEmpty);
  });

  test('archive and restore keep history and re-enable routines', () async {
    final p = await plants.create(const NewPlant(name: 'Alocasia'));
    await actions.log(NewAction(plantId: p.id, typeKey: 'note', notes: 'Nouvelle feuille'));
    await plants.archive([p.id], reason: 'given');
    expect(await plants.watchSummaries(const PlantFilter()).first, isEmpty);
    expect((await plants.watchArchived().first).single.plant.archiveReason, 'given');

    await plants.restore([p.id]);
    final restored = (await plants.watchSummaries(const PlantFilter()).first).single;
    expect(restored.plant.status, PlantStatus.active);
    expect(restored.nextDueAt, isNotNull);
    expect(await actions.watchByPlant(p.id).first, hasLength(1));
  });

  test('search matches name, species, location, tags and notes', () async {
    final balcon = await locations.create(name: 'Balcon', icon: '🌤️');
    final a = await plants.create(NewPlant(name: 'Olivier', speciesName: 'Olea europaea', locationId: balcon.id));
    final b = await plants.create(const NewPlant(name: 'Pothos'));
    final rare = await tags.create('Rare');
    await tags.setPlantTags(b.id, [rare.id]);
    await actions.log(NewAction(plantId: b.id, typeKey: 'note', notes: 'racines aériennes'));

    Future<List<String>> search(String q) async =>
        (await plants.watchSummaries(PlantFilter(query: q)).first).map((s) => s.plant.name).toList();

    expect(await search('oliv'), ['Olivier']);
    expect(await search('europaea'), ['Olivier']);
    expect(await search('balcon'), ['Olivier']);
    expect(await search('rare'), ['Pothos']);
    expect(await search('aériennes'), ['Pothos']);
    expect((await plants.watchSummaries(PlantFilter(tagId: rare.id)).first).single.plant.id, b.id);
    expect((await plants.watchSummaries(PlantFilter(locationId: balcon.id)).first).single.plant.id, a.id);
  });

  test('deleting a location moves its plants to the parent location', () async {
    final maison = await locations.create(name: 'Maison', icon: '🏠');
    final salon = await locations.create(name: 'Salon', icon: '🛋️', parentId: maison.id);
    final p = await plants.create(NewPlant(name: 'Ficus', locationId: salon.id));
    await locations.delete(salon.id);
    expect((await plants.getPlant(p.id))!.locationId, maison.id);
    final tree = await locations.watchTree().first;
    expect(tree.single.location.id, maison.id);
    expect(tree.single.plantCount, 1);
  });

  test('location tree counts plants per node', () async {
    final maison = await locations.create(name: 'Maison', icon: '🏠');
    final salon = await locations.create(name: 'Salon', icon: '🛋️', parentId: maison.id);
    await plants.create(NewPlant(name: 'A', locationId: salon.id));
    await plants.create(NewPlant(name: 'B', locationId: salon.id));
    final tree = await locations.watchTree().first;
    expect(tree.single.children.single.plantCount, 2);
    expect(tree.single.totalPlantCount, 2);
  });

  test('changing a routine interval recomputes the due date from the last completion', () async {
    final p = await plants.create(const NewPlant(name: 'Hoya'));
    await actions.log(NewAction(plantId: p.id, typeKey: 'watering', occurredAt: DateTime.now().subtract(const Duration(days: 2))));
    final s = (await care.watchByPlant(p.id).first).firstWhere((x) => x.typeKey == 'watering');
    final updated = await care.upsert(s.copyWith(intervalDays: 10));
    expect(CareEngine.daysUntil(updated.nextDueAt, DateTime.now()), 8);
    final manual = await care.upsert(updated.copyWith(strategy: CareStrategy.manual));
    expect(manual.nextDueAt, isNull);
  });
}
