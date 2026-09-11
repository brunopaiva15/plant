import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flora/data/db/database.dart';
import 'package:flora/data/repositories/action_repository_impl.dart';
import 'package:flora/data/repositories/location_repository_impl.dart';
import 'package:flora/data/repositories/plant_repository_impl.dart';
import 'package:flora/data/repositories/photo_repository_impl.dart';
import 'package:flora/data/sync/sync_service.dart';
import 'package:flora/domain/models/models.dart';
import 'package:flora/domain/repositories/repositories.dart';
import 'package:flutter_test/flutter_test.dart';

import 'sync_service_test.dart' show FakeRemote;

/// Un appareil dont la base porte deux jardins : celui du compte, et un
/// jardin partagé arrivé par la synchronisation.
void main() {
  late FloraDatabase db;
  late FakeRemote remote;
  late SyncService sync;
  late Directory tmp;
  const own = 'garden-mine';
  const shared = 'garden-theirs';

  SyncService serviceFor(String garden) => SyncService(
        db: db,
        remote: remote,
        cursors: InMemoryCursorStore(),
        localFile: (rel) async => File('${tmp.path}/$rel'),
        gardenId: garden,
        userId: 'user-1',
        ownedGardenId: own,
      );

  setUp(() async {
    db = FloraDatabase(NativeDatabase.memory());
    remote = FakeRemote();
    tmp = await Directory.systemTemp.createTemp('flora-collab');
    final now = DateTime.now();
    for (final (id, owner, name) in [(own, 'user-1', 'home'), (shared, 'user-2', 'Chez Laura')]) {
      await db.into(db.gardens).insert(GardensCompanion.insert(id: id, ownerId: owner, name: name, createdAt: now, updatedAt: now));
    }
    sync = serviceFor(own);
  });

  tearDown(() async {
    sync.dispose();
    await db.close();
    await tmp.delete(recursive: true);
  });

  test('la première connexion ne met en file que le jardin de l\'appareil', () async {
    final mine = await DriftPlantRepository(db, own).create(const NewPlant(name: 'Monstera'));
    final theirs = await DriftPlantRepository(db, shared).create(const NewPlant(name: 'Pilea'));
    await DriftLocationRepository(db, shared).create(name: 'Véranda', icon: '🌤️');
    await db.delete(db.syncOutbox).go();

    await sync.enqueueEverything(gardenId: own);

    final queued = await db.select(db.syncOutbox).get();
    final plants = queued.where((e) => e.entity == 'plants').map((e) => e.entityId);
    expect(plants, [mine.id]);
    expect(plants, isNot(contains(theirs.id)));
    expect(queued.where((e) => e.entity == 'locations'), isEmpty);
    expect(queued.where((e) => e.entity == 'gardens').map((e) => e.entityId), [own]);
  });

  test('la ligne d\'un jardin partagé n\'est jamais poussée', () async {
    await db.enqueueSync('gardens', shared, 'upsert', const {});
    await db.enqueueSync('gardens', own, 'upsert', const {});

    await sync.push();

    expect(remote.tables['gardens']?.keys, [own]);
    expect(remote.tables['gardens']![own]!['owner_id'], 'user-1');
    expect(await db.select(db.syncOutbox).get(), isEmpty, reason: 'la ligne écartée quitte la file');
  });

  test('un jardin tiré du serveur garde son propriétaire', () async {
    final now = DateTime.now().toUtc().toIso8601String();
    remote.tables['gardens'] = {
      'garden-new': {'id': 'garden-new', 'owner_id': 'user-3', 'name': 'Le potager', 'plant_counter': 4, 'created_at': now, 'updated_at': now, 'deleted_at': null},
    };
    final other = serviceFor('garden-new');
    addTearDown(other.dispose);

    await other.pull();

    final row = await (db.select(db.gardens)..where((g) => g.id.equals('garden-new'))).getSingleOrNull();
    expect(row, isNotNull, reason: 'sans owner_id, la ligne ne se décodait pas');
    expect(row!.ownerId, 'user-3');
    expect(row.name, 'Le potager');
  });

  test('le rattachement au compte passe le jardin de l\'appareil au compte', () async {
    await sync.claimGarden(own, 'user-42');
    final row = await (db.select(db.gardens)..where((g) => g.id.equals(own))).getSingleOrNull();
    expect(row!.ownerId, 'user-42');
  });

  test('journal et galerie ne montrent que le jardin ouvert', () async {
    final mine = await DriftPlantRepository(db, own).create(const NewPlant(name: 'Monstera'));
    final theirs = await DriftPlantRepository(db, shared).create(const NewPlant(name: 'Pilea'));
    await DriftActionRepository(db).log(NewAction(plantId: mine.id, typeKey: 'watering'));
    await DriftActionRepository(db).log(NewAction(plantId: theirs.id, typeKey: 'watering'));
    await DriftPhotoRepository(db).add(plantId: mine.id, filePath: 'a.jpg', thumbPath: 'a_thumb.jpg', width: 10, height: 10);
    await DriftPhotoRepository(db).add(plantId: theirs.id, filePath: 'b.jpg', thumbPath: 'b_thumb.jpg', width: 10, height: 10);

    final actions = await DriftActionRepository(db, gardenId: own).watchRecent().first;
    expect(actions.map((a) => a.plantId), [mine.id]);
    final photos = await DriftPhotoRepository(db, gardenId: own).watchRecent().first;
    expect(photos.map((p) => p.plantId), [mine.id]);

    // Sans jardin — export, sauvegarde — tout reste visible.
    expect((await DriftActionRepository(db).watchRecent().first).length, 2);
  });
}
