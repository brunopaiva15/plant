import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';
import '../../domain/sharing/garden_collaboration.dart';

/// Collaboration adossée à Supabase. Tout passe par des fonctions SQL
/// `security definer` (`create_invite`, `accept_invite`, `my_gardens`…) :
/// le client ne touche jamais directement à `garden_members`, et les règles
/// — qui peut inviter, qui peut changer un rôle — tiennent côté serveur.
class SupabaseCollaborationService implements CollaborationService {
  SupabaseCollaborationService({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;

  SupabaseClient get _db => _client ?? Supabase.instance.client;

  @override
  bool get isAvailable => SupabaseConfig.isConfigured;

  /// Un appel RPC, avec les erreurs du backend traduites en [CollaborationException].
  Future<T> _rpc<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on CollaborationException {
      rethrow;
    } catch (e) {
      throw CollaborationException.from(e);
    }
  }

  @override
  Future<List<GardenAccess>> gardens() => _rpc(() async {
        final rows = await _db.rpc<List<dynamic>>('my_gardens');
        return [
          for (final r in rows.cast<Map<String, dynamic>>())
            GardenAccess(
              id: r['id'] as String,
              name: (r['name'] as String?) ?? '',
              role: GardenRole.parse(r['role'] as String?),
              ownerId: r['owner_id'] as String?,
              ownerName: (r['owner_name'] as String?) ?? '',
              memberCount: (r['member_count'] as num?)?.toInt() ?? 1,
              plantCount: (r['plant_count'] as num?)?.toInt() ?? 0,
            ),
        ];
      });

  @override
  Future<List<GardenMemberInfo>> members(String gardenId) => _rpc(() async {
        final rows = await _db.rpc<List<dynamic>>('garden_members_with_names', params: {'p_garden_id': gardenId});
        final members = [
          for (final r in rows.cast<Map<String, dynamic>>())
            GardenMemberInfo(
              userId: r['user_id'] as String,
              role: GardenRole.parse(r['role'] as String?),
              displayName: (r['display_name'] as String?) ?? '',
              email: r['email'] as String?,
            ),
        ];
        members.sort((a, b) => a.role == b.role ? a.label.compareTo(b.label) : (a.role == GardenRole.owner ? -1 : 1));
        return members;
      });

  @override
  Future<GardenInvite> createInvite({required String gardenId, String? email, GardenRole role = GardenRole.member, int days = 14}) =>
      _rpc(() async {
        final row = await _db.rpc<Map<String, dynamic>>('create_invite', params: {
          'p_garden_id': gardenId,
          'p_email': _clean(email),
          'p_role': role == GardenRole.viewer ? 'viewer' : 'member',
          'p_days': days,
        });
        return _invite(row);
      });

  @override
  Future<List<GardenInvite>> invites(String gardenId) => _rpc(() async {
        final rows = await _db.from('garden_invites').select().eq('garden_id', gardenId).order('created_at', ascending: false);
        return [for (final r in rows) _invite(r)];
      });

  @override
  Future<void> revokeInvite(String inviteId) => _rpc(() async {
        await _db.rpc('revoke_invite', params: {'p_id': inviteId});
      });

  @override
  Future<InvitePreview?> previewInvite(String code) => _rpc(() async {
        final rows = await _db.rpc<List<dynamic>>('preview_invite', params: {'p_code': CollaborationService.normalizeCode(code)});
        if (rows.isEmpty) return null;
        final r = rows.first as Map<String, dynamic>;
        return InvitePreview(
          gardenId: r['garden_id'] as String,
          gardenName: (r['garden_name'] as String?) ?? '',
          role: GardenRole.parse(r['role'] as String?),
          ownerName: (r['owner_name'] as String?) ?? '',
          email: r['email'] as String?,
          alreadyMember: (r['already_member'] as bool?) ?? false,
        );
      });

  @override
  Future<String> acceptInvite(String code) =>
      _rpc(() async => await _db.rpc<String>('accept_invite', params: {'p_code': CollaborationService.normalizeCode(code)}));

  @override
  Future<void> setRole({required String gardenId, required String userId, required GardenRole role}) => _rpc(() async {
        await _db.rpc('set_member_role',
            params: {'p_garden_id': gardenId, 'p_user_id': userId, 'p_role': role == GardenRole.viewer ? 'viewer' : 'member'});
      });

  @override
  Future<void> removeMember({required String gardenId, required String userId}) => _rpc(() async {
        await _db.rpc('remove_member', params: {'p_garden_id': gardenId, 'p_user_id': userId});
      });

  @override
  Future<void> leaveGarden(String gardenId) => _rpc(() async {
        await _db.rpc('leave_garden', params: {'p_garden_id': gardenId});
      });

  /// Adresse https, pour que le lien reste cliquable dans un message ; la page
  /// qu'elle sert ne fait qu'ouvrir l'application sur `flora://join/<code>`.
  @override
  String inviteLink(String code) => '${SupabaseConfig.shareBaseUrl.replaceAll(RegExp(r'/+$'), '')}/join/$code';

  static GardenInvite _invite(Map<String, dynamic> r) => GardenInvite(
        id: r['id'] as String,
        code: (r['code'] as String?) ?? '',
        role: GardenRole.parse(r['role'] as String?),
        email: r['email'] as String?,
        createdAt: _date(r['created_at']) ?? DateTime.now(),
        expiresAt: _date(r['expires_at']),
        acceptedAt: _date(r['accepted_at']),
        revokedAt: _date(r['revoked_at']),
      );

  static DateTime? _date(Object? v) => v is String ? DateTime.tryParse(v)?.toLocal() : null;

  static String? _clean(String? s) {
    final t = s?.trim();
    return t == null || t.isEmpty ? null : t;
  }
}
