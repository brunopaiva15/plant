// ignore_for_file: prefer_initializing_formals
import 'dart:async';
import 'dart:convert';
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

  /// Dernier passage de rattrapage des fichiers photo manquants.
  DateTime? _lastRepair;

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
        await _throttledRepair();
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
    // Les fichiers d'une photo ne repartent que si une des écritures en
    // attente les touche. Renommer une photo renvoyait sinon l'original et sa
    // miniature — quelques centaines de kilo-octets pour un titre.
    final withFiles = <String>{
      for (final e in entries)
        if (e.entity == 'plant_photos' && _touchesFiles(e.payload)) e.entityId,
    };
    final ordered = latest.values.toList()..sort((a, b) => tables.indexOf(a.entity).compareTo(tables.indexOf(b.entity)));
    for (final e in ordered) {
      await _pushOne(e, withFiles: withFiles.contains(e.entityId));
      await (_db.delete(_db.syncOutbox)..where((o) => o.entity.equals(e.entity) & o.entityId.equals(e.entityId))).go();
    }
  }

  Future<void> _pushOne(SyncOutboxRow e, {bool withFiles = true}) async {
    // La ligne d'un jardin partagé ne se pousse pas : elle appartient à son
    // propriétaire, et le serveur refuserait qu'un invité la réécrive.
    if (e.entity == 'gardens' && _ownedGardenId != null && e.entityId != _ownedGardenId) return;
    final row = await _remoteRowFor(e.entity, e.entityId);
    if (row == null) {
      // La ligne n'existe plus localement : suppression physique distante.
      // Pour une photo, le bucket garderait un fichier que plus rien ne
      // réclame : son chemin se relit dans le payload de la suppression.
      if (e.entity == 'plant_photos') await _removePhotoObjects(_objectPathsFromPayload(e));
      await _remote.delete(e.entity, _keysFor(e.entity, e.entityId));
      return;
    }
    if (e.entity == 'plant_photos') await _pushPhotoFiles(e.entityId, row, withFiles: withFiles);
    await _remote.upsert(e.entity, row);
  }

  /// Une écriture qui ne touche qu'aux métadonnées le dit dans son payload
  /// (`{"files": false}`). Tout le reste — création, réenfilage complet —
  /// vaut téléversement.
  static bool _touchesFiles(String payload) {
    try {
      final json = jsonDecode(payload);
      return json is! Map || json['files'] != false;
    } catch (_) {
      // Payload illisible : on ne prend pas le risque de ne rien envoyer.
      return true;
    }
  }

  /// Les fichiers d'une photo : téléversés, retirés, ou laissés tranquilles.
  Future<void> _pushPhotoFiles(String id, Map<String, Object?> row, {required bool withFiles}) async {
    // `storage_path` et `thumb_path` appartiennent à cette méthode seule
    // ([_remoteRowFor] les laisse de côté) : soit le téléversement vient de
    // les écrire, soit elles restent absentes et le serveur garde les siennes.
    final photo = await (_db.select(_db.plantPhotos)..where((x) => x.id.equals(id))).getSingleOrNull();
    if (photo == null) return;
    final paths = _objectPaths(await _bucketBase(photo.plantId), id);
    if (photo.deletedAt != null) {
      // Photo supprimée : le bucket n'a plus de raison de la garder. Le
      // chemin distant ne s'efface que si le retrait a bien eu lieu — sinon
      // on perdrait la seule trace d'un fichier resté là-bas.
      if (await _removePhotoObjects(paths)) {
        row['storage_path'] = '';
        row['thumb_path'] = '';
      }
      return;
    }
    if (!withFiles) return;
    final file = await _localFile(photo.filePath);
    final thumb = await _localFile(photo.thumbPath);
    if (photo.filePath.isNotEmpty && await file.exists()) row['storage_path'] = await _remote.uploadFile(paths.file, file);
    if (photo.thumbPath.isNotEmpty && await thumb.exists()) row['thumb_path'] = await _remote.uploadFile(paths.thumb, thumb);
    // Rien à téléverser — photo hébergée ailleurs, fichier disparu : les
    // colonnes du serveur sont obligatoires, et une insertion sans elles
    // échouerait en boucle, bloquant toute la file d'envoi derrière elle.
    row['storage_path'] ??= '';
    row['thumb_path'] ??= '';
  }

  /// Dossier du bucket d'une plante : `{garden}/{plant}` — les politiques RLS
  /// lisent le jardin dans le premier segment.
  Future<String> _bucketBase(String plantId) async {
    final plant = await (_db.select(_db.plants)..where((x) => x.id.equals(plantId))).getSingleOrNull();
    return '${plant?.gardenId ?? _gardenId}/$plantId';
  }

  ({String file, String thumb}) _objectPaths(String base, String id) => (file: '$base/$id.jpg', thumb: '$base/${id}_thumb.jpg');

  /// Chemins du bucket reconstruits depuis le payload d'une suppression
  /// définitive, la ligne locale n'étant plus là pour les dire.
  ({String file, String thumb})? _objectPathsFromPayload(SyncOutboxRow e) {
    try {
      final json = jsonDecode(e.payload);
      if (json is! Map) return null;
      final plantId = json['plant_id'] as String?;
      if (plantId == null) return null;
      return _objectPaths('${(json['garden_id'] as String?) ?? _gardenId}/$plantId', e.entityId);
    } catch (_) {
      // Payload d'une version antérieure : le fichier restera, tant pis.
      return null;
    }
  }

  /// Retire les fichiers du bucket. `false` si le stockage n'a pas répondu :
  /// mieux vaut un fichier orphelin qu'un chemin perdu.
  Future<bool> _removePhotoObjects(({String file, String thumb})? paths) async {
    if (paths == null) return false;
    try {
      await _remote.removeFiles([paths.file, paths.thumb]);
      return true;
    } catch (_) {
      // Le ménage se retentera à la prochaine suppression touchant ce dossier.
      return false;
    }
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
        // `file_path` et `thumb_path` nomment des fichiers locaux ; les
        // colonnes du même nom, côté serveur, désignent des objets du bucket.
        // Elles n'appartiennent qu'à [_pushPhotoFiles], qui sait ce qui est
        // vraiment là-bas — les renseigner ici renvoyait le nom local, et un
        // simple changement de titre effaçait le chemin distant.
        return r == null ? null : RowCodec.toRemote(r, extra: {'user_id': r.userId ?? _userId}, drop: {'file_path', 'thumb_path'});
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
      // Les fichiers descendent avant la transaction : télécharger, c'est du
      // réseau, et le réseau n'a rien à faire dans un verrou SQLite. Une
      // photo qui ne descend pas n'emporte plus le lot entier avec elle — ni
      // les tables qui la suivent, arrosages compris ; le prochain cycle la
      // rattrapera (voir [repairPhotoFiles]).
      if (table == 'plant_photos') await _fetchNewPhotoFiles(rows);
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


  /// Applique une ligne photo. Les fichiers ont déjà été descendus avant la
  /// transaction ([_fetchNewPhotoFiles]) : rien ici ne touche au réseau.
  Future<void> _applyPhoto(Map<String, Object?> remote, Map<String, Object?> json) async {
    final id = remote['id'] as String;
    final existing = await (_db.select(_db.plantPhotos)..where((x) => x.id.equals(id))).getSingleOrNull();
    // Une photo hébergée ailleurs n'a pas de fichier : lui en inventer un
    // laisserait un chemin qui ne mène nulle part.
    final hasFiles = ((remote['storage_path'] as String?) ?? '').isNotEmpty;
    json['filePath'] = existing?.filePath ?? (hasFiles ? _localNames(id).file : '');
    json['thumbPath'] = existing?.thumbPath ?? (hasFiles ? _localNames(id).thumb : '');
    json.remove('storagePath');
    await _db.into(_db.plantPhotos).insertOnConflictUpdate(PlantPhotoRow.fromJson(json, serializer: RowCodec.serializer));
  }

  /// Noms locaux d'une photo arrivée d'ailleurs : son identifiant suffit.
  ({String file, String thumb}) _localNames(String id) => (file: '$id.jpg', thumb: '${id}_thumb.jpg');

  /// Descend les fichiers des photos que cet appareil ne connaît pas encore.
  ///
  /// Une panne n'arrête rien : la ligne s'applique quand même, et le fichier
  /// manquant se rattrape plus tard.
  Future<void> _fetchNewPhotoFiles(List<RemoteRow> rows) async {
    for (final row in rows) {
      final id = row['id'] as String?;
      // Une photo déjà supprimée ailleurs n'a pas à descendre ici.
      if (id == null || row['deleted_at'] != null) continue;
      final known = await (_db.select(_db.plantPhotos)..where((x) => x.id.equals(id))).getSingleOrNull();
      if (known != null) continue;
      final names = _localNames(id);
      await _downloadPhotoFiles(
        storagePath: row['storage_path'] as String?,
        fileName: names.file,
        thumbPath: row['thumb_path'] as String?,
        thumbName: names.thumb,
      );
    }
  }

  Future<void> _downloadPhotoFiles({required String? storagePath, required String fileName, required String? thumbPath, required String thumbName}) async {
    Future<void> fetch(String? remotePath, String localName) async {
      if (remotePath == null || remotePath.isEmpty) return;
      try {
        await _remote.downloadFile(remotePath, await _localFile(localName));
      } catch (_) {
        // Réseau coupé, objet pas encore téléversé : [repairPhotoFiles] repassera.
      }
    }

    await fetch(storagePath, fileName);
    await fetch(thumbPath, thumbName);
  }

  /// Rattrape les fichiers photo manquants.
  ///
  /// Un téléchargement raté laissait un carré gris définitif : la ligne
  /// existait, et seule une ligne inconnue déclenchait un téléchargement. On
  /// repasse donc sur les photos dont le fichier n'est pas là. Le repérage se
  /// fait sur le disque : tant que rien ne manque, la réparation ne coûte pas
  /// un octet de réseau. [sync] l'appelle au plus une fois par dizaine de
  /// minutes ; l'appel direct, lui, passe tout de suite.
  Future<void> repairPhotoFiles({int limit = 20}) async {
    final missing = <({PlantPhotoRow photo, bool file, bool thumb})>[];
    final photos = await (_db.select(_db.plantPhotos)
          ..where((x) => x.deletedAt.isNull() & x.filePath.equals('').not())
          ..orderBy([(x) => OrderingTerm.desc(x.takenAt)]))
        .get();
    for (final photo in photos) {
      if (missing.length >= limit) break;
      final file = !await (await _localFile(photo.filePath)).exists();
      final thumb = photo.thumbPath.isNotEmpty && !await (await _localFile(photo.thumbPath)).exists();
      if (file || thumb) missing.add((photo: photo, file: file, thumb: thumb));
    }
    if (missing.isEmpty) return;
    // Le chemin du bucket se lit sur le serveur : le reconstruire supposerait
    // que la plante n'a jamais changé de jardin.
    final remoteRows = <String, RemoteRow>{};
    for (final row in await _remote.pullSince('plant_photos', gardenId: _gardenId)) {
      final id = row['id'];
      if (id is String) remoteRows[id] = row;
    }
    for (final entry in missing) {
      final row = remoteRows[entry.photo.id];
      if (row == null) continue;
      await _downloadPhotoFiles(
        storagePath: entry.file ? (row['storage_path'] as String?) : null,
        fileName: entry.photo.filePath,
        thumbPath: entry.thumb ? (row['thumb_path'] as String?) : null,
        thumbName: entry.photo.thumbPath,
      );
    }
  }

  /// Le rattrapage vu par le cycle de synchronisation : rare, et silencieux.
  Future<void> _throttledRepair() async {
    final now = DateTime.now();
    if (_lastRepair != null && now.difference(_lastRepair!) < const Duration(minutes: 10)) return;
    _lastRepair = now;
    await repairPhotoFiles();
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
