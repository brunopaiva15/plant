import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flora/data/db/database.dart';
import 'package:flora/data/repositories/location_repository_impl.dart';
import 'package:flora/data/repositories/plant_repository_impl.dart';
import 'package:flora/domain/repositories/repositories.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FloraDatabase db;
  late PlantRepository plants;
  late LocationRepository locations;
  const gardenId = 'g1';

  setUp(() async {
    db = FloraDatabase(NativeDatabase.memory());
    await db.into(db.gardens).insert(GardensCompanion.insert(id: gardenId, ownerId: 'u1', name: 'Jardin', createdAt: DateTime.now(), updatedAt: DateTime.now()));
    plants = DriftPlantRepository(db, gardenId);
    locations = DriftLocationRepository(db, gardenId);
  });

  tearDown(() => db.close());

  group('numéro de plante', () {
    test('les numéros se suivent à partir de 1', () async {
      final a = await plants.create(const NewPlant(name: 'A'));
      final b = await plants.create(const NewPlant(name: 'B'));
      expect(a.number, 1);
      expect(b.number, 2);
    });

    test('un numéro supprimé n\'est jamais réattribué', () async {
      final a = await plants.create(const NewPlant(name: 'A'));
      final b = await plants.create(const NewPlant(name: 'B'));
      await plants.deleteForever(b.id);
      final c = await plants.create(const NewPlant(name: 'C'));
      expect(c.number, 3, reason: 'un numéro imprimé sur une étiquette reste unique');
      expect(a.number, 1);
    });

    test('la recherche « #2 » ne remonte que cette plante', () async {
      await plants.create(const NewPlant(name: 'Monstera'));
      final second = await plants.create(const NewPlant(name: 'Pilea'));
      final found = await plants.watchSummaries(const PlantFilter(query: '#2')).first;
      expect(found.map((s) => s.plant.id), [second.id]);
    });

    test('« #  2 » avec espaces fonctionne aussi', () async {
      await plants.create(const NewPlant(name: 'A'));
      final b = await plants.create(const NewPlant(name: 'B'));
      expect((await plants.watchSummaries(const PlantFilter(query: '# 2')).first).single.plant.id, b.id);
    });

    test('un numéro inexistant ne remonte rien', () async {
      await plants.create(const NewPlant(name: 'A'));
      expect(await plants.watchSummaries(const PlantFilter(query: '#99')).first, isEmpty);
    });

    test('un dièse dans du texte reste une recherche texte', () async {
      await plants.create(const NewPlant(name: 'Monstera #rare'));
      final found = await plants.watchSummaries(const PlantFilter(query: '#rare')).first;
      expect(found, hasLength(1));
    });
  });

  group('emplacement', () {
    test('notes et photo sont enregistrées', () async {
      final loc = await locations.create(name: 'Serre', icon: '🏡');
      await locations.update(loc.copyWith(notes: () => '  Store changé  ', photoPath: () => 'a.jpg', thumbPath: () => 'a_thumb.jpg'));
      final stored = (await locations.watchAll().first).single;
      expect(stored.notes, 'Store changé');
      expect(stored.thumbPath, 'a_thumb.jpg');
    });

    test('des notes vides sont effacées', () async {
      final loc = await locations.create(name: 'Serre', icon: '🏡');
      await locations.update(loc.copyWith(notes: () => '   '));
      expect((await locations.watchAll().first).single.notes, isNull);
    });

    group('journal', () {
      test('ajout, modification et suppression', () async {
        final loc = await locations.create(name: 'Balcon', icon: '🌤️');
        final entry = await locations.addLogEntry(loc.id, '  Store changé  ');
        expect(entry.content, 'Store changé');
        expect(await locations.watchLog(loc.id).first, hasLength(1));

        await locations.editLogEntry(entry.id, 'Store réparé');
        expect((await locations.watchLog(loc.id).first).single.content, 'Store réparé');

        await locations.deleteLogEntry(entry.id);
        expect(await locations.watchLog(loc.id).first, isEmpty);
      });

      test('le journal est propre à un emplacement', () async {
        final a = await locations.create(name: 'A', icon: '🪴');
        final b = await locations.create(name: 'B', icon: '🪴');
        await locations.addLogEntry(a.id, 'chez A');
        expect(await locations.watchLog(b.id).first, isEmpty);
      });

      test('chaque écriture est mise en file de synchronisation', () async {
        final loc = await locations.create(name: 'Balcon', icon: '🌤️');
        final entry = await locations.addLogEntry(loc.id, 'test');
        final pending = await (db.select(db.syncOutbox)..where((o) => o.entity.equals('location_logs') & o.entityId.equals(entry.id))).get();
        expect(pending, isNotEmpty);
      });
    });
  });
}
