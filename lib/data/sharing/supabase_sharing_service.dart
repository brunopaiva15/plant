import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';
import '../../domain/sharing/shared_link.dart';

/// Partage public adossé à Supabase : la table `shared_links` porte le jeton,
/// la fonction Edge `share` rend la page.
class SupabaseSharingService implements SharingService {
  // ignore: prefer_initializing_formals
  SupabaseSharingService({required this.gardenId, SupabaseClient? client}) : _client = client;

  final String gardenId;
  final SupabaseClient? _client;

  SupabaseClient get _db => _client ?? Supabase.instance.client;

  @override
  bool get isAvailable => SupabaseConfig.isConfigured;

  @override
  String get baseUrl => SupabaseConfig.shareBaseUrl;

  @override
  Future<List<SharedLink>> list() async {
    final rows = await _db.from('shared_links').select().eq('garden_id', gardenId).order('created_at', ascending: false);
    return rows.map(_fromRow).toList();
  }

  @override
  Future<SharedLink> create(NewSharedLink data) async {
    final row = await _db
        .from('shared_links')
        .insert({
          'garden_id': gardenId,
          'plant_id': data.plantId,
          'photo_id': data.photoId,
          'kind': data.kind.name,
          'token': newToken(),
          'title': _clean(data.title),
          'description': _clean(data.description),
          'keywords': _clean(data.keywords),
          'unlisted': data.unlisted,
          'expires_at': data.expiresAt?.toUtc().toIso8601String(),
        })
        .select()
        .single();
    return _fromRow(row);
  }

  @override
  Future<void> revoke(String id) async {
    await _db.from('shared_links').update({'revoked_at': DateTime.now().toUtc().toIso8601String()}).eq('id', id);
  }

  @override
  Future<void> delete(String id) async => _db.from('shared_links').delete().eq('id', id);

  /// Jeton d'URL : 22 caractères tirés d'un générateur cryptographique,
  /// sans caractère ambigu ni besoin d'échappement.
  static String newToken() {
    const alphabet = 'abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(22, (_) => alphabet[rng.nextInt(alphabet.length)]).join();
  }

  static SharedLink _fromRow(Map<String, dynamic> r) => SharedLink(
        id: r['id'] as String,
        plantId: r['plant_id'] as String,
        photoId: r['photo_id'] as String?,
        kind: r['kind'] == 'photo' ? SharedKind.photo : SharedKind.plant,
        token: r['token'] as String,
        title: r['title'] as String?,
        description: r['description'] as String?,
        keywords: r['keywords'] as String?,
        unlisted: (r['unlisted'] as bool?) ?? true,
        expiresAt: _date(r['expires_at']),
        createdAt: _date(r['created_at']) ?? DateTime.now(),
        revokedAt: _date(r['revoked_at']),
      );

  static DateTime? _date(Object? v) => v is String ? DateTime.tryParse(v)?.toLocal() : null;

  static String? _clean(String? s) {
    final t = s?.trim();
    return t == null || t.isEmpty ? null : t;
  }
}

/// Implémentation inerte quand aucun backend n'est configuré.
class UnavailableSharingService implements SharingService {
  const UnavailableSharingService();

  @override
  bool get isAvailable => false;

  @override
  String get baseUrl => '';

  @override
  Future<List<SharedLink>> list() async => const [];

  @override
  Future<SharedLink> create(NewSharedLink data) async => throw StateError('sharing unavailable');

  @override
  Future<void> revoke(String id) async {}

  @override
  Future<void> delete(String id) async {}
}
