// ignore_for_file: prefer_initializing_formals
import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../../domain/sync/remote_data_source.dart';
import '../../domain/sync/sync_state.dart';
import '../db/database.dart';
import '../db/row_defaults.dart';
import 'row_codec.dart';

/// Curseurs de synchronisation (dernier `updated_at` / `created_at` tiré par table).
abstract class SyncCursorStore {
  DateTime? read(String table);
  Future<void> write(String table, DateTime value);
  Future<void> clear();
}

class InMemoryCursorStore implements SyncCursorStore {
  final _map = <String, DateTime>{};
  @override
  DateTime? read(String table) => _map[table];
  @override
  Future<void> write(String table, DateTime value) async => _map[table] = value;
  @override
  Future<void> clear() async => _map.clear();
}

/// Résolveur de fichiers photo (chemin relatif local → fichier).
typedef LocalFileResolver = Future<File> Function(String relativePath);

/// Synchronisation offline-first.
///
/// Push : draine `sync_outbox` en relisant la ligne locale courante (pas le
/// payload historique), pousse un upsert / delete et téléverse les photos.
/// Pull : delta par table depuis le curseur, appliqué en last-write-wins.
class SyncService {
  SyncService({
    required FloraDatabase db,
    required RemoteDataSource remote,
    required SyncCursorStore cursors,
    required LocalFileResolver localFile,
    required String gardenId,
    String? userId,
    String? ownedGardenId,
  })  : _db = db,
        _remote = remote,
        _cursors = cursors,
        _localFile = localFile,
        _gardenId = gardenId,
        _userId = userId,
        _ownedGardenId = ownedGardenId;

  final FloraDatabase _db;
  final RemoteDataSource _remote;
  final SyncCursorStore _cursors;
  final LocalFileResolver _localFile;

  /// Jardin ouvert : celui qu'on synchronise.
  final String _gardenId;
  final String? _userId;

  /// Jardin créé sur cet appareil, celui dont le compte est propriétaire.
  /// Les autres sont partagés : leur ligne `gardens` ne nous appartient pas.
  final String? _ownedGardenId;

  final _state = StreamController<SyncState>.broadcast();
  SyncState _current = SyncState.initial;
  bool _running = false;
  bool _again = false;

  Stream<SyncState> get state => _state.stream;
  SyncState get currentState => _current;

  /// Tables synchronisées, dans l'ordre des dépendances (parents d'abord).
  static const tables = ['gardens', 'locations', 'plants', 'action_types', 'plant_photos', 'plant_actions', 'care_schedules', 'tags', 'plant_tags', 'measurements', 'inventory_items', 'tasks', 'attribute_schemas', 'plant_attributes', 'plant_attachments', 'location_logs', 'inventory_groups', 'inventory_tags', 'event_categories', 'calendar_entries'];

  /// Tables avec `updated_at` (last-write-wins) ; les autres sont append-only.
  /// Le delta se lit sur cette colonne : une table absente d'ici verrait ses
  /// modifications passer inaperçues, seules ses créations arrivant.
  static const lwwTables = {'gardens', 'locations', 'plants', 'care_schedules', 'inventory_items', 'tasks', 'attribute_schemas', 'plant_attributes', 'plant_attachments', 'location_logs', 'inventory_groups', 'event_categories', 'calendar_entries'};

  void _emit(SyncState s) {
    _current = s;
    if (!_state.isClosed) _state.add(s);
  }

  /// Marque le jardin « à pousser » (première connexion à un compte).
  ///
  /// Seulement celui-là : depuis le partage, la base peut contenir les plantes
  /// d'un jardin qui appartient à quelqu'un d'autre, et qu'on n'a pas à
  /// renvoyer en bloc.
  Future<void> enqueueEverything({String? gardenId}) async {
    final garden = gardenId ?? _ownedGardenId ?? _gardenId;
    await _db.transaction(() async {
      for (final t in tables) {
        final ids = await _idsOf(t, garden);
        for (final id in ids) {
          await _db.enqueueSync(t, id, 'upsert', const {});
        }
      }
    });
  }

  /// Rattache le jardin de l'appareil au compte qui vient de se connecter :
  /// c'est lui, désormais, qui en est propriétaire — localement comme sur le
  /// serveur, où la ligne partira avec son `owner_id`.
  Future<void> claimGarden(String gardenId, String userId) async {
    await (_db.update(_db.gardens)..where((g) => g.id.equals(gardenId))).write(GardensCompanion(ownerId: Value(userId)));
  }

  /// Un cycle complet : push puis pull. Les appels concurrents sont fusionnés.
  Future<void> sync() async {
    if (_running) {
      _again = true;
      return;
    }
    _running = true;
    try {
      do {
        _again = false;
        _emit(_current.copyWith(status: SyncStatus.syncing, pendingCount: await _pendingCount()));
        await push();
        await pull();
        _emit(SyncState(status: SyncStatus.idle, lastSyncedAt: DateTime.now(), pendingCount: await _pendingCount()));
      } while (_again);
    } on SocketException catch (_) {
      _emit(_current.copyWith(status: SyncStatus.offline, pendingCount: await _pendingCount()));
    } catch (e) {
      _emit(_current.copyWith(status: SyncStatus.error, message: e.toString(), pendingCount: await _pendingCount()));
    } finally {
      _running = false;
    }
  }

  Future<int> _pendingCount() async => (await _db.select(_db.syncOutbox).get()).length;

  // ---------------------------------------------------------------- push

  Future<void> push() async {
    final entries = await (_db.select(_db.syncOutbox)..orderBy([(o) => OrderingTerm.asc(o.id)])).get();
    // Dédoublonnage : la dernière opération par (entité, id) suffit, la ligne locale est relue.
    final latest = <String, SyncOutboxRow>{};
    for (final e in entries) {
      latest['${e.entity}/${e.entityId}'] = e;
    }
    final ordered = latest.values.toList()..sort((a, b) => tables.indexOf(a.entity).compareTo(tables.indexOf(b.entity)));
    for (final e in ordered) {
      await _pushOne(e);
      await (_db.delete(_db.syncOutbox)..where((o) => o.entity.equals(e.entity) & o.entityId.equals(e.entityId))).go();
    }
  }

  Future<void> _pushOne(SyncOutboxRow e) async {
    // La ligne d'un jardin partagé ne se pousse pas : elle appartient à son
    // propriétaire, et le serveur refuserait qu'un invité la réécrive.
    if (e.entity == 'gardens' && _ownedGardenId != null && e.entityId != _ownedGardenId) return;
    final row = await _remoteRowFor(e.entity, e.entityId);
    if (row == null) {
      // La ligne n'existe plus localement : suppression physique distante.
      await _remote.delete(e.entity, _keysFor(e.entity, e.entityId));
      return;
    }
    if (e.entity == 'plant_photos') await _uploadPhoto(e.entityId, row);
    await _remote.upsert(e.entity, row);
  }

  Future<void> _uploadPhoto(String id, Map<String, Object?> row) async {
    final photo = await (_db.select(_db.plantPhotos)..where((x) => x.id.equals(id))).getSingleOrNull();
    if (photo == null) return;
    final plant = await (_db.select(_db.plants)..where((x) => x.id.equals(photo.plantId))).getSingleOrNull();
    // Chemin dans le bucket : {garden}/{plant}/{photo}.jpg (RLS par dossier de jardin).
    final base = '${plant?.gardenId ?? _gardenId}/${photo.plantId}';
    final file = await _localFile(photo.filePath);
    final thumb = await _localFile(photo.thumbPath);
    if (await file.exists()) row['storage_path'] = await _remote.uploadFile('$base/${photo.id}.jpg', file);
    if (await thumb.exists()) row['thumb_path'] = await _remote.uploadFile('$base/${photo.id}_thumb.jpg', thumb);
    row.remove('file_path');
  }

  Map<String, Object?> _keysFor(String table, String id) {
    if (table == 'plant_tags') {
      final parts = id.split('/');
      return {'plant_id': parts.first, 'tag_id': parts.length > 1 ? parts[1] : ''};
    }
    if (table == 'inventory_tags') {
      final parts = id.split('/');
      return {'item_id': parts.first, 'tag_id': parts.length > 1 ? parts[1] : ''};
    }
    if (table == 'action_types') return {'key': id};
    return {'id': id};
  }

  /// Identifiants des lignes de [table] appartenant à [garden].
  ///
  /// Les tables filles de `plants` n'ont pas de colonne `garden_id` : elles se
  /// filtrent sur les plantes du jardin, relevées une fois pour toutes.
  Future<List<String>> _idsOf(String table, String garden) async {
    final plantIds = (await (_db.select(_db.plants)..where((p) => p.gardenId.equals(garden))).get()).map((p) => p.id).toList();
    return switch (table) {
      'gardens' => (await (_db.select(_db.gardens)..where((r) => r.id.equals(garden))).get()).map((r) => r.id).toList(),
      'locations' => (await (_db.select(_db.locations)..where((r) => r.gardenId.equals(garden))).get()).map((r) => r.id).toList(),
      'plants' => (await (_db.select(_db.plants)..where((r) => r.gardenId.equals(garden))).get()).map((r) => r.id).toList(),
      'action_types' => (await (_db.select(_db.actionTypes)..where((t) => t.isBuiltin.equals(false))).get()).map((r) => r.key).toList(),
      'plant_photos' => (await (_db.select(_db.plantPhotos)..where((r) => r.plantId.isIn(plantIds))).get()).map((r) => r.id).toList(),
      'plant_actions' => (await (_db.select(_db.plantActions)..where((r) => r.plantId.isIn(plantIds))).get()).map((r) => r.id).toList(),
      'care_schedules' => (await (_db.select(_db.careSchedules)..where((r) => r.plantId.isIn(plantIds))).get()).map((r) => r.id).toList(),
      'tags' => (await (_db.select(_db.tags)..where((r) => r.gardenId.equals(garden))).get()).map((r) => r.id).toList(),
      'plant_tags' => (await (_db.select(_db.plantTags)..where((r) => r.plantId.isIn(plantIds))).get()).map((r) => '${r.plantId}/${r.tagId}').toList(),
      'measurements' => (await (_db.select(_db.measurements)..where((r) => r.plantId.isIn(plantIds))).get()).map((r) => r.id).toList(),
      'inventory_items' => (await (_db.select(_db.inventoryItems)..where((r) => r.gardenId.equals(garden))).get()).map((r) => r.id).toList(),
      'tasks' => (await (_db.select(_db.tasks)..where((r) => r.gardenId.equals(garden))).get()).map((r) => r.id).toList(),
      'plant_attributes' => (await (_db.select(_db.plantAttributes)..where((r) => r.gardenId.equals(garden))).get()).map((r) => r.id).toList(),
      'attribute_schemas' => (await (_db.select(_db.attributeSchemas)..where((r) => r.gardenId.equals(garden))).get()).map((r) => r.id).toList(),
      'plant_attachments' => (await (_db.select(_db.plantAttachments)..where((r) => r.gardenId.equals(garden))).get()).map((r) => r.id).toList(),
      'location_logs' => (await (_db.select(_db.locationLogs)..where((r) => r.gardenId.equals(garden))).get()).map((r) => r.id).toList(),
      'inventory_groups' => (await (_db.select(_db.inventoryGroups)..where((r) => r.gardenId.equals(garden))).get()).map((r) => r.id).toList(),
      'inventory_tags' => await _inventoryTagIds(garden),
      'event_categories' => (await (_db.select(_db.eventCategories)..where((r) => r.gardenId.equals(garden))).get()).map((r) => r.id).toList(),
      'calendar_entries' => (await (_db.select(_db.calendarEntries)..where((r) => r.gardenId.equals(garden))).get()).map((r) => r.id).toList(),
      _ => const [],
    };
  }

  /// Étiquettes d'inventaire du jardin, identifiées par « article/étiquette ».
  Future<List<String>> _inventoryTagIds(String garden) async {
    final items = (await (_db.select(_db.inventoryItems)..where((i) => i.gardenId.equals(garden))).get()).map((i) => i.id).toList();
    final rows = await (_db.select(_db.inventoryTags)..where((t) => t.itemId.isIn(items))).get();
    return rows.map((r) => '${r.itemId}/${r.tagId}').toList();
  }

  /// Ligne distante correspondant à la ligne locale courante (`null` si absente).
  Future<Map<String, Object?>?> _remoteRowFor(String table, String id) async {
    switch (table) {
      case 'gardens':
        final r = await (_db.select(_db.gardens)..where((x) => x.id.equals(id))).getSingleOrNull();
        return r == null ? null : RowCodec.toRemote(r, extra: {if (_userId != null) 'owner_id': _userId});
      case 'locations':
        final r = await (_db.select(_db.locations)..where((x) => x.id.equals(id))).getSingleOrNull();
        return r == null ? null : RowCodec.toRemote(r);
      case 'plants':
        final r = await (_db.select(_db.plants)..where((x) => x.id.equals(id))).getSingleOrNull();
        return r == null ? null : RowCodec.toRemote(r);
      case 'action_types':
        final r = await (_db.select(_db.actionTypes)..where((x) => x.key.equals(id))).getSingleOrNull();
        return r == null || r.isBuiltin ? null : RowCodec.toRemote(r, extra: {'garden_id': _gardenId});
      case 'plant_photos':
        final r = await (_db.select(_db.plantPhotos)..where((x) => x.id.equals(id))).getSingleOrNull();
        return r == null ? null : RowCodec.toRemote(r, extra: {'storage_path': r.filePath, 'thumb_path': r.thumbPath, 'user_id': r.userId ?? _userId}, drop: {'file_path'});
      case 'plant_actions':
        final r = await (_db.select(_db.plantActions)..where((x) => x.id.equals(id))).getSingleOrNull();
        return r == null ? null : RowCodec.toRemote(r, extra: {'user_id': r.userId ?? _userId});
      case 'care_schedules':
        final r = await (_db.select(_db.careSchedules)..where((x) => x.id.equals(id))).getSingleOrNull();
        return r == null ? null : RowCodec.toRemote(r);
      case 'tags':
        final r = await (_db.select(_db.tags)..where((x) => x.id.equals(id))).getSingleOrNull();
        return r == null ? null : RowCodec.toRemote(r);
      case 'plant_tags':
        final keys = _keysFor(table, id);
        final r = await (_db.select(_db.plantTags)..where((x) => x.plantId.equals(keys['plant_id'] as String) & x.tagId.equals(keys['tag_id'] as String))).getSingleOrNull();
        return r == null ? null : RowCodec.toRemote(r);
      case 'measurements':
        final r = await (_db.select(_db.measurements)..where((x) => x.id.equals(id))).getSingleOrNull();
        return r == null ? null : RowCodec.toRemote(r);
      case 'inventory_items':
        final r = await (_db.select(_db.inventoryItems)..where((x) => x.id.equals(id))).getSingleOrNull();
        return r == null ? null : RowCodec.toRemote(r);
      case 'tasks':
        final r = await (_db.select(_db.tasks)..where((x) => x.id.equals(id))).getSingleOrNull();
        return r == null ? null : RowCodec.toRemote(r);
      case 'plant_attributes':
        final r = await (_db.select(_db.plantAttributes)..where((x) => x.id.equals(id))).getSingleOrNull();
        return r == null ? null : RowCodec.toRemote(r);
      case 'attribute_schemas':
        final r = await (_db.select(_db.attributeSchemas)..where((x) => x.id.equals(id))).getSingleOrNull();
        return r == null ? null : RowCodec.toRemote(r);
      case 'plant_attachments':
        final r = await (_db.select(_db.plantAttachments)..where((x) => x.id.equals(id))).getSingleOrNull();
        return r == null ? null : RowCodec.toRemote(r, extra: {'user_id': r.userId ?? _userId});
      case 'location_logs':
        final r = await (_db.select(_db.locationLogs)..where((x) => x.id.equals(id))).getSingleOrNull();
        return r == null ? null : RowCodec.toRemote(r, extra: {'user_id': r.userId ?? _userId});
      case 'inventory_groups':
        final r = await (_db.select(_db.inventoryGroups)..where((x) => x.id.equals(id))).getSingleOrNull();
        return r == null ? null : RowCodec.toRemote(r);
      case 'inventory_tags':
        final keys = _keysFor(table, id);
        final r = await (_db.select(_db.inventoryTags)
              ..where((x) => x.itemId.equals(keys['item_id'] as String) & x.tagId.equals(keys['tag_id'] as String)))
            .getSingleOrNull();
        return r == null ? null : RowCodec.toRemote(r);
      case 'event_categories':
        final r = await (_db.select(_db.eventCategories)..where((x) => x.id.equals(id))).getSingleOrNull();
        return r == null ? null : RowCodec.toRemote(r);
      case 'calendar_entries':
        final r = await (_db.select(_db.calendarEntries)..where((x) => x.id.equals(id))).getSingleOrNull();
        return r == null ? null : RowCodec.toRemote(r);
    }
    return null;
  }

  // ---------------------------------------------------------------- pull

  Future<void> pull() async {
    await _pullMembership();
    for (final table in tables) {
      final since = _cursors.read(table);
      final rows = await _remote.pullSince(table, gardenId: _gardenId, since: since);
      if (rows.isEmpty) continue;
      DateTime? newest = since;
      await _db.transaction(() async {
        for (final row in rows) {
          await _applyRemote(table, row);
          final stamp = _stampOf(row);
          if (stamp != null && (newest == null || stamp.isAfter(newest!))) newest = stamp;
        }
      });
      if (newest != null) await _cursors.write(table, newest!);
    }
  }

  /// Membres du jardin et leurs profils : caches locaux en lecture seule.
  Future<void> _pullMembership() async {
    final members = await _remote.pullSince('garden_members', gardenId: _gardenId);
    if (members.isEmpty) return;
    final profiles = await _remote.pullSince('profiles', gardenId: _gardenId);
    await _db.transaction(() async {
      await (_db.delete(_db.gardenMembers)..where((m) => m.gardenId.equals(_gardenId))).go();
      for (final m in members) {
        await _db.into(_db.gardenMembers).insertOnConflictUpdate(GardenMembersCompanion.insert(gardenId: _gardenId, userId: m['user_id'] as String, role: m['role'] as String));
      }
      for (final p in profiles) {
        await _db.into(_db.profiles).insertOnConflictUpdate(ProfilesCompanion.insert(
              id: p['id'] as String,
              displayName: Value((p['display_name'] as String?) ?? ''),
              email: Value(p['email'] as String?),
            ));
      }
    });
  }

  DateTime? _stampOf(Map<String, Object?> row) {
    final raw = row['updated_at'] ?? row['created_at'];
    return raw is String ? DateTime.parse(raw) : null;
  }

  Future<void> _applyRemote(String table, Map<String, Object?> remote) async {
    // `owner_id` est gardé : c'est lui qui dit si le jardin est le nôtre ou
    // celui de quelqu'un qui nous y a invités.
    final json = RowCodec.toLocalJson(remote, drop: {'storage_path'});
    // Une ligne écrite par un client plus ancien n'a pas les colonnes ajoutées
    // depuis : on comble avec la valeur par défaut plutôt que d'échouer.
    RowDefaults.fill(table, json);
    final s = RowCodec.serializer;
    switch (table) {
      case 'gardens':
        final row = GardenRow.fromJson(json, serializer: s);
        if (await _isNewer('gardens', row.id, row.updatedAt)) await _db.into(_db.gardens).insertOnConflictUpdate(row);
      case 'locations':
        final row = LocationRow.fromJson(json, serializer: s);
        if (await _isNewer('locations', row.id, row.updatedAt)) await _db.into(_db.locations).insertOnConflictUpdate(row);
      case 'plants':
        final row = PlantRow.fromJson(json, serializer: s);
        if (await _isNewer('plants', row.id, row.updatedAt)) await _db.into(_db.plants).insertOnConflictUpdate(row);
      case 'action_types':
        final row = ActionTypeRow.fromJson(json, serializer: s);
        await _db.into(_db.actionTypes).insertOnConflictUpdate(row);
      case 'plant_photos':
        await _applyPhoto(remote, json);
      case 'plant_actions':
        final row = PlantActionRow.fromJson(json, serializer: s);
        await _db.into(_db.plantActions).insertOnConflictUpdate(row);
      case 'care_schedules':
        final row = CareScheduleRow.fromJson(json, serializer: s);
        if (await _isNewer('care_schedules', row.id, row.updatedAt)) await _db.into(_db.careSchedules).insertOnConflictUpdate(row);
      case 'tags':
        await _db.into(_db.tags).insertOnConflictUpdate(TagRow.fromJson(json, serializer: s));
      case 'plant_tags':
        await _db.into(_db.plantTags).insert(PlantTagRow.fromJson(json, serializer: s), mode: InsertMode.insertOrIgnore);
      case 'measurements':
        await _db.into(_db.measurements).insertOnConflictUpdate(MeasurementRow.fromJson(json, serializer: s));
      case 'inventory_items':
        final row = InventoryItemRow.fromJson(json, serializer: s);
        if (await _isNewer('inventory_items', row.id, row.updatedAt)) await _db.into(_db.inventoryItems).insertOnConflictUpdate(row);
      case 'tasks':
        final row = TaskRow.fromJson(json, serializer: s);
        if (await _isNewer('tasks', row.id, row.updatedAt)) await _db.into(_db.tasks).insertOnConflictUpdate(row);
      case 'plant_attributes':
        final row = PlantAttributeRow.fromJson(json, serializer: s);
        if (await _isNewer('plant_attributes', row.id, row.updatedAt)) await _db.into(_db.plantAttributes).insertOnConflictUpdate(row);
      case 'attribute_schemas':
        final row = AttributeSchemaRow.fromJson(json, serializer: s);
        if (await _isNewer('attribute_schemas', row.id, row.updatedAt)) await _db.into(_db.attributeSchemas).insertOnConflictUpdate(row);
      case 'plant_attachments':
        final row = PlantAttachmentRow.fromJson(json, serializer: s);
        if (await _isNewer('plant_attachments', row.id, row.updatedAt)) await _db.into(_db.plantAttachments).insertOnConflictUpdate(row);
      case 'location_logs':
        final row = LocationLogRow.fromJson(json, serializer: s);
        if (await _isNewer('location_logs', row.id, row.updatedAt)) await _db.into(_db.locationLogs).insertOnConflictUpdate(row);
      case 'inventory_groups':
        final row = InventoryGroupRow.fromJson(json, serializer: s);
        if (await _isNewer('inventory_groups', row.id, row.updatedAt)) await _db.into(_db.inventoryGroups).insertOnConflictUpdate(row);
      case 'inventory_tags':
        await _db.into(_db.inventoryTags).insert(InventoryTagRow.fromJson(json, serializer: s), mode: InsertMode.insertOrIgnore);
      case 'event_categories':
        final row = EventCategoryRow.fromJson(json, serializer: s);
        if (await _isNewer('event_categories', row.id, row.updatedAt)) await _db.into(_db.eventCategories).insertOnConflictUpdate(row);
      case 'calendar_entries':
        final row = CalendarEntryRow.fromJson(json, serializer: s);
        if (await _isNewer('calendar_entries', row.id, row.updatedAt)) await _db.into(_db.calendarEntries).insertOnConflictUpdate(row);
    }
  }


  Future<void> _applyPhoto(Map<String, Object?> remote, Map<String, Object?> json) async {
    final id = remote['id'] as String;
    final existing = await (_db.select(_db.plantPhotos)..where((x) => x.id.equals(id))).getSingleOrNull();
    final fileName = existing?.filePath ?? '$id.jpg';
    final thumbName = existing?.thumbPath ?? '${id}_thumb.jpg';
    if (existing == null) {
      // Photo créée sur un autre appareil : on récupère les fichiers.
      final storagePath = remote['storage_path'] as String?;
      final thumbPath = remote['thumb_path'] as String?;
      if (storagePath != null) await _remote.downloadFile(storagePath, await _localFile(fileName));
      if (thumbPath != null) await _remote.downloadFile(thumbPath, await _localFile(thumbName));
    }
    json['filePath'] = fileName;
    json['thumbPath'] = thumbName;
    json.remove('storagePath');
    await _db.into(_db.plantPhotos).insertOnConflictUpdate(PlantPhotoRow.fromJson(json, serializer: RowCodec.serializer));
  }

  /// Last-write-wins : n'écrase la ligne locale que si la distante est plus récente
  /// et que la locale n'a pas de modification en attente de push.
  Future<bool> _isNewer(String table, String id, DateTime remoteUpdatedAt) async {
    if (!lwwTables.contains(table)) return true;
    final pending = await (_db.select(_db.syncOutbox)..where((o) => o.entity.equals(table) & o.entityId.equals(id))).get();
    if (pending.isNotEmpty) return false;
    final local = await _localUpdatedAt(table, id);
    return local == null || remoteUpdatedAt.isAfter(local);
  }

  Future<DateTime?> _localUpdatedAt(String table, String id) async => switch (table) {
        'gardens' => (await (_db.select(_db.gardens)..where((x) => x.id.equals(id))).getSingleOrNull())?.updatedAt,
        'locations' => (await (_db.select(_db.locations)..where((x) => x.id.equals(id))).getSingleOrNull())?.updatedAt,
        'plants' => (await (_db.select(_db.plants)..where((x) => x.id.equals(id))).getSingleOrNull())?.updatedAt,
        'care_schedules' => (await (_db.select(_db.careSchedules)..where((x) => x.id.equals(id))).getSingleOrNull())?.updatedAt,
        'inventory_items' => (await (_db.select(_db.inventoryItems)..where((x) => x.id.equals(id))).getSingleOrNull())?.updatedAt,
        'tasks' => (await (_db.select(_db.tasks)..where((x) => x.id.equals(id))).getSingleOrNull())?.updatedAt,
        'plant_attributes' => (await (_db.select(_db.plantAttributes)..where((x) => x.id.equals(id))).getSingleOrNull())?.updatedAt,
        'attribute_schemas' => (await (_db.select(_db.attributeSchemas)..where((x) => x.id.equals(id))).getSingleOrNull())?.updatedAt,
        'plant_attachments' => (await (_db.select(_db.plantAttachments)..where((x) => x.id.equals(id))).getSingleOrNull())?.updatedAt,
        'location_logs' => (await (_db.select(_db.locationLogs)..where((x) => x.id.equals(id))).getSingleOrNull())?.updatedAt,
        'inventory_groups' => (await (_db.select(_db.inventoryGroups)..where((x) => x.id.equals(id))).getSingleOrNull())?.updatedAt,
        'event_categories' => (await (_db.select(_db.eventCategories)..where((x) => x.id.equals(id))).getSingleOrNull())?.updatedAt,
        'calendar_entries' => (await (_db.select(_db.calendarEntries)..where((x) => x.id.equals(id))).getSingleOrNull())?.updatedAt,
        _ => null,
      };

  void dispose() => _state.close();
}

/// Nom de fichier local d'une photo distante (utilitaire de test).
String photoFileName(String id) => p.setExtension(id, '.jpg');
