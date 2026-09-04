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

  static const _lww = {'gardens', 'locations', 'plants', 'care_schedules', 'inventory_items'};

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
    final stamp = _lww.contains(table) ? 'updated_at' : 'created_at';
    PostgrestFilterBuilder<PostgrestList> query;
    if (table == 'gardens') {
      query = _client.from(table).select().eq('id', gardenId);
    } else if (_childOfPlant.contains(table)) {
      query = _client.from(table).select('*, plants!inner(garden_id)').eq('plants.garden_id', gardenId);
    } else {
      query = _client.from(table).select().eq('garden_id', gardenId);
    }
    if (since != null && table != 'plant_tags') query = query.gt(stamp, since.toUtc().toIso8601String());
    final rows = await query;
    return [
      for (final r in rows)
        Map<String, Object?>.from(r)..remove('plants'),
    ];
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
