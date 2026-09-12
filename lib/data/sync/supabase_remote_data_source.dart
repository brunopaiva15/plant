import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';
import '../../domain/sync/remote_data_source.dart';
import 'sync_service.dart';

/// Implémentation Supabase de [RemoteDataSource] (PostgREST, Storage, Realtime).
class SupabaseRemoteDataSource implements RemoteDataSource {
  SupabaseRemoteDataSource(this._client);

  final SupabaseClient _client;

  /// Tables sans `garden_id` : filtrées via la plante parente.
  static const _childOfPlant = {'plant_photos', 'plant_actions', 'care_schedules', 'plant_tags', 'measurements'};

  /// Tables sans aucune colonne de date : ni `updated_at`, ni `created_at`.
  /// Elles ne se lisent pas en delta — on les tire en entier à chaque fois,
  /// et le local les applique en « insert or ignore » ou en « upsert ». Les
  /// filtrer sur une date qu'elles n'ont pas, c'était une requête refusée à
  /// la deuxième synchronisation (« column measurements.created_at does not
  /// exist »), et donc plus aucune lecture.
  static const _unstamped = {'plant_tags', 'inventory_tags', 'action_types', 'measurements'};

  @override
  Future<void> upsert(String table, RemoteRow row) async {
    await _client.from(table).upsert(row);
  }

  @override
  Future<void> delete(String table, Map<String, Object?> keys) async {
    await _client.from(table).delete().match(keys.map((k, v) => MapEntry(k, v as Object)));
  }

  @override
  Future<List<RemoteRow>> pullSince(String table, {required String gardenId, DateTime? since}) async {
    if (table == 'garden_members' || table == 'profiles') return _pullMembership(table, gardenId);
    // Le curseur est posé sur `updated_at` pour ces tables : le delta doit se
    // lire sur la même colonne, sinon une modification faite par quelqu'un
    // d'autre n'arriverait jamais.
    final stamp = SyncService.lwwTables.contains(table) ? 'updated_at' : 'created_at';
    PostgrestFilterBuilder<PostgrestList> query;
    if (table == 'gardens') {
      query = _client.from(table).select().eq('id', gardenId);
    } else if (_childOfPlant.contains(table)) {
      query = _client.from(table).select('*, plants!inner(garden_id)').eq('plants.garden_id', gardenId);
    } else if (table == 'inventory_tags') {
      // Pas de `garden_id` sur la liaison : il se lit sur l'objet.
      query = _client.from(table).select('*, inventory_items!inner(garden_id)').eq('inventory_items.garden_id', gardenId);
    } else {
      query = _client.from(table).select().eq('garden_id', gardenId);
    }
    if (since != null && !_unstamped.contains(table)) query = query.gt(stamp, since.toUtc().toIso8601String());
    final rows = await query;
    return [
      for (final r in rows)
        Map<String, Object?>.from(r)
          ..remove('plants')
          ..remove('inventory_items'),
    ];
  }

  /// Membres et profils via la fonction `garden_members_with_names` (RLS-safe).
  Future<List<RemoteRow>> _pullMembership(String table, String gardenId) async {
    final rows = await _client.rpc<List<dynamic>>('garden_members_with_names', params: {'p_garden_id': gardenId});
    final list = rows.cast<Map<String, dynamic>>();
    if (table == 'garden_members') {
      return [for (final r in list) {'garden_id': gardenId, 'user_id': r['user_id'], 'role': r['role']}];
    }
    return [for (final r in list) {'id': r['user_id'], 'display_name': r['display_name'], 'email': r['email']}];
  }

  @override
  Future<String> uploadFile(String storagePath, File file) async {
    await _client.storage.from(SupabaseConfig.photoBucket).upload(storagePath, file, fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'));
    return storagePath;
  }

  @override
  Future<void> downloadFile(String storagePath, File target) async {
    final bytes = await _client.storage.from(SupabaseConfig.photoBucket).download(storagePath);
    await target.parent.create(recursive: true);
    await target.writeAsBytes(bytes, flush: true);
  }

  @override
  Future<void> removeFiles(List<String> paths) async {
    if (paths.isEmpty) return;
    await _client.storage.from(SupabaseConfig.photoBucket).remove(paths);
  }

  @override
  Stream<RemoteChange> watchChanges(String gardenId) {
    late StreamController<RemoteChange> controller;
    RealtimeChannel? channel;
    controller = StreamController<RemoteChange>(
      onListen: () {
        var c = _client.channel('garden-$gardenId');
        for (final table in SyncService.tables) {
          c = c.onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: table,
            callback: (payload) {
              final record = payload.newRecord.isNotEmpty ? payload.newRecord : payload.oldRecord;
              controller.add(RemoteChange(table: table, id: (record['id'] ?? record['key'] ?? '').toString()));
            },
          );
        }
        channel = c.subscribe();
      },
      onCancel: () async {
        if (channel != null) await _client.removeChannel(channel!);
      },
    );
    return controller.stream;
  }
}
