import 'dart:io';

import 'package:drift/native.dart';
import 'package:flora/data/db/database.dart';
import 'package:flora/data/repositories/action_repository_impl.dart';
import 'package:flora/data/repositories/location_repository_impl.dart';
import 'package:flora/data/repositories/plant_repository_impl.dart';
import 'package:flora/data/sync/row_codec.dart';
import 'package:flora/data/sync/sync_service.dart';
import 'package:flora/domain/repositories/repositories.dart';
import 'package:flora/domain/sync/remote_data_source.dart';
import 'package:flutter_test/flutter_test.dart';

/// Backend en mémoire : tables → id → ligne.
class FakeRemote implements RemoteDataSource {
  final tables = <String, Map<String, Map<String, Object?>>>{};
  final uploads = <String>[];

  String _key(String table, Map<String, Object?> row) => table == 'plant_tags' ? '${row['plant_id']}/${row['tag_id']}' : (row['id'] ?? row['key']).toString();

  @override
  Future<void> upsert(String table, Map<String, Object?> row) async {
    final copy = Map<String, Object?>.from(row);
    // Le serveur pose updated_at à la réception (trigger).
    if (const {'gardens', 'locations', 'plants', 'care_schedules', 'inventory_items', 'tasks', 'attribute_schemas', 'plant_attributes', 'plant_attachments'}.contains(table)) {
      copy['updated_at'] = DateTime.now().toUtc().toIso8601String();
    }
    tables.putIfAbsent(table, () => {})[_key(table, row)] = copy;
  }

  @override
  Future<void> delete(String table, Map<String, Object?> keys) async {
    tables[table]?.remove(table == 'plant_tags' ? '${keys['plant_id']}/${keys['tag_id']}' : (keys['id'] ?? keys['key']).toString());
  }

  @override
  Future<List<Map<String, Object?>>> pullSince(String table, {required String gardenId, DateTime? since}) async {
    final rows = tables[table]?.values ?? const <Map<String, Object?>>[];
    return rows.where((r) {
      final raw = (r['updated_at'] ?? r['created_at']) as String?;
      if (since == null || raw == null) return true;
      return DateTime.parse(raw).isAfter(since);
    }).map((r) => Map<String, Object?>.from(r)).toList();
  }

  @override
  Future<String> uploadFile(String storagePath, File file) async {
    uploads.add(storagePath);
    return storagePath;
  }

  @override
  Future<void> downloadFile(String storagePath, File target) async => target.writeAsString('remote:$storagePath');

  @override
  Stream<RemoteChange> watchChanges(String gardenId) => const Stream.empty();
}

void main() {
  late FloraDatabase db;
  late FakeRemote remote;
  late SyncService sync;
  late Directory tmp;
  const garden = 'garden-1';

  setUp(() async {
    db = FloraDatabase(NativeDatabase.memory());
    remote = FakeRemote();
    tmp = await Directory.systemTemp.createTemp('flora-sync');
    sync = SyncService(
      db: db,
      remote: remote,
      cursors: InMemoryCursorStore(),
      localFile: (rel) async => File('${tmp.path}/$rel'),
      gardenId: garden,
      userId: 'user-1',
    );
  });

  tearDown(() async {
    sync.dispose();
    await db.close();
    await tmp.delete(recursive: true);
  });

  test('row codec converts keys and dates both ways', () {
    expect(RowCodec.toSnake('primaryPhotoId'), 'primary_photo_id');
    expect(RowCodec.toCamel('next_due_at'), 'nextDueAt');
    final json = RowCodec.toLocalJson({'id': 'x', 'updated_at': '2026-09-04T10:00:00.000Z'});
    expect(json['updatedAt'], '2026-09-04T10:00:00.000Z');
    expect(RowCodec.serializer.fromJson<DateTime>('2026-09-04T10:00:00.000Z').toUtc(), DateTime.utc(2026, 9, 4, 10));
  });

  test('push sends local rows with snake_case columns and drains the outbox', () async {
    final plants = DriftPlantRepository(db, garden);
    final locations = DriftLocationRepository(db, garden);
    final salon = await locations.create(name: 'Salon', icon: '🛋️');
    final plant = await plants.create(NewPlant(name: 'Monstera', locationId: salon.id));
    await DriftActionRepository(db).log(NewAction(plantId: plant.id, typeKey: 'watering'));
    await sync.sync();
    expect(sync.currentState.message, isNull, reason: 'sync error: ${sync.currentState.message}');

    expect(remote.tables['plants']![plant.id]!['location_id'], salon.id);
    expect(remote.tables['plants']![plant.id]!['garden_id'], garden);
    expect(remote.tables['locations']![salon.id]!['name'], 'Salon');
    expect(remote.tables['care_schedules']!.length, 2);
    expect(remote.tables['plant_actions']!.values.single['user_id'], 'user-1');
    expect(remote.tables['plant_actions']!.values.single['occurred_at'], isA<String>());
    expect(await db.select(db.syncOutbox).get(), isEmpty);
    expect(sync.currentState.pendingCount, 0);
    expect(sync.currentState.lastSyncedAt, isNotNull);
  });

  test('pull applies remote rows created elsewhere and downloads their photos', () async {
    final now = DateTime.now().toUtc().toIso8601String();
    remote.tables['plants'] = {
      'p-remote': {'id': 'p-remote', 'garden_id': garden, 'name': 'Pilea', 'species_name': null, 'location_id': null, 'primary_photo_id': null, 'status': 'active', 'health': 'healthy', 'is_favorite': true, 'acquired_at': null, 'source': null, 'price': null, 'pot_size': null, 'notes': null, 'parent_plant_id': null, 'archived_at': null, 'archive_reason': null, 'created_at': now, 'updated_at': now, 'deleted_at': null},
    };
    remote.tables['plant_photos'] = {
      'ph-1': {'id': 'ph-1', 'plant_id': 'p-remote', 'user_id': 'user-2', 'storage_path': 'plant-photos/$garden/p-remote/ph-1.jpg', 'thumb_path': 'plant-photos/$garden/p-remote/ph-1_thumb.jpg', 'width': 100, 'height': 100, 'taken_at': now, 'created_at': now, 'deleted_at': null},
    };
    await sync.sync();

    final plant = await DriftPlantRepository(db, garden).getPlant('p-remote');
    expect(plant!.name, 'Pilea');
    expect(plant.isFavorite, isTrue);
    final photo = (await db.select(db.plantPhotos).get()).single;
    expect(photo.filePath, 'ph-1.jpg');
    expect(await File('${tmp.path}/ph-1.jpg').readAsString(), contains('remote:'));
  });

  test('last-write-wins keeps the newer side and never overwrites pending local edits', () async {
    final plants = DriftPlantRepository(db, garden);
    final plant = await plants.create(const NewPlant(name: 'Ficus'));
    await sync.sync();

    // Modification distante plus récente → appliquée.
    final remoteRow = remote.tables['plants']![plant.id]!;
    remoteRow['name'] = 'Ficus lyrata';
    remoteRow['updated_at'] = DateTime.now().add(const Duration(seconds: 5)).toUtc().toIso8601String();
    await sync.sync();
    expect((await plants.getPlant(plant.id))!.name, 'Ficus lyrata');

    // Modification locale en attente → la distante (plus ancienne) ne l'écrase pas.
    await plants.update((await plants.getPlant(plant.id))!.copyWith(name: 'Mon Ficus'));
    remoteRow['name'] = 'Autre nom';
    remoteRow['updated_at'] = DateTime.now().add(const Duration(seconds: 10)).toUtc().toIso8601String();
    await sync.pull();
    expect((await plants.getPlant(plant.id))!.name, 'Mon Ficus');
    await sync.push();
    expect(remote.tables['plants']![plant.id]!['name'], 'Mon Ficus');
  });

  test('deleting forever removes the remote row', () async {
    final plants = DriftPlantRepository(db, garden);
    final plant = await plants.create(const NewPlant(name: 'Cactus'));
    await sync.sync();
    expect(remote.tables['plants']!.containsKey(plant.id), isTrue);
    await plants.deleteForever(plant.id);
    await sync.sync();
    expect(remote.tables['plants']!.containsKey(plant.id), isFalse);
  });

  test('enqueueEverything pushes an existing local garden on first sign-in', () async {
    final plants = DriftPlantRepository(db, garden);
    await plants.create(const NewPlant(name: 'A'));
    await plants.create(const NewPlant(name: 'B'));
    await db.delete(db.syncOutbox).go();
    await sync.enqueueEverything();
    await sync.sync();
    expect(remote.tables['plants']!.length, 2);
    expect(remote.tables['care_schedules']!.length, 4);
  });
}
