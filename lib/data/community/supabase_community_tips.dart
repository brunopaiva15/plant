import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';
import '../../core/network/network_failure.dart';
import '../../domain/community/species_tip.dart';

/// Les conseils de la communauté, adossés à Supabase.
///
/// Tout passe par des fonctions SQL `security definer`
/// (`species_tips_for`, `publish_species_tip`, `vote_species_tip`…) : le client ne
/// touche jamais aux tables de votes ni de signalements, et les règles — un
/// conseil par personne et par espèce, une voix par conseil, le seuil qui
/// masque — tiennent côté serveur. C'est le même partage des rôles que la
/// collaboration (docs/08).
///
/// La table est commune à tous les jardins : c'est la seule de l'application
/// que `garden_members` ne gouverne pas. La lecture est ouverte à la clé
/// anonyme, l'écriture demande un compte — d'où [userId], `null` tant que la
/// personne n'en a pas.
class SupabaseCommunityTips implements CommunityTipsService {
  SupabaseCommunityTips({this.userId, SupabaseClient? client}) : _client = client;

  /// Compte distant, quand il y en a un. Il ne sert pas à signer les appels —
  /// la session s'en charge —, seulement à savoir si l'écriture est ouverte.
  final String? userId;

  final SupabaseClient? _client;

  SupabaseClient get _db => _client ?? Supabase.instance.client;

  @override
  bool get isAvailable => SupabaseConfig.isConfigured;

  @override
  bool get canPublish => isAvailable && userId != null;

  /// Un appel RPC borné dans le temps, réseau absent traduit.
  ///
  /// Postgrest attend une réponse aussi longtemps qu'il faut ; hors ligne elle
  /// ne vient jamais, et la section resterait sur son tourniquet.
  Future<T> _rpc<T>(Future<T> Function() call) async {
    try {
      return await call().timeout(networkTimeout);
    } catch (e) {
      if (isNetworkFailure(e)) throw const OfflineException();
      rethrow;
    }
  }

  @override
  Future<List<SpeciesTip>> tips(String speciesId) => _rpc(() async {
        final rows = await _db.rpc<List<dynamic>>('species_tips_for', params: {'p_species_id': speciesId});
        return SpeciesTip.sorted([for (final r in rows.cast<Map<String, dynamic>>()) _tip(r)]);
      });

  @override
  Future<SpeciesTip> publish({required String speciesId, required String speciesName, required String body}) => _rpc(() async {
        final row = await _db.rpc<Map<String, dynamic>>('publish_species_tip', params: {
          'p_species_id': speciesId,
          'p_species_name': speciesName,
          'p_body': body,
        });
        return _tip(row);
      });

  @override
  Future<void> withdraw(String tipId) => _rpc(() async {
        await _db.rpc('withdraw_species_tip', params: {'p_id': tipId});
      });

  @override
  Future<SpeciesTip> vote(String tipId, {required bool helpful}) => _rpc(() async {
        final row = await _db.rpc<Map<String, dynamic>>('vote_species_tip', params: {'p_id': tipId, 'p_helpful': helpful});
        return _tip(row);
      });

  @override
  Future<void> report(String tipId) => _rpc(() async {
        await _db.rpc('report_species_tip', params: {'p_id': tipId});
      });

  @override
  Future<bool> isModerator() async {
    if (userId == null) return false;
    return _rpc(() async => await _db.rpc<bool>('is_moderator') == true);
  }

  @override
  Future<List<SpeciesTip>> reported() => _rpc(() async {
        final rows = await _db.rpc<List<dynamic>>('reported_species_tips');
        return [for (final r in rows.cast<Map<String, dynamic>>()) _tip(r)];
      });

  @override
  Future<void> moderate(String tipId, {required bool hidden}) => _rpc(() async {
        await _db.rpc('moderate_species_tip', params: {'p_id': tipId, 'p_hidden': hidden});
      });

  @override
  Future<void> remove(String tipId) => _rpc(() async {
        await _db.rpc('remove_species_tip', params: {'p_id': tipId});
      });

  static SpeciesTip _tip(Map<String, dynamic> r) => SpeciesTip(
        id: r['id'] as String,
        speciesId: (r['species_id'] as String?) ?? '',
        speciesName: (r['species_name'] as String?)?.trim() ?? '',
        authorName: (r['author_name'] as String?)?.trim() ?? '',
        body: (r['body'] as String?) ?? '',
        votes: (r['votes'] as num?)?.toInt() ?? 0,
        createdAt: _date(r['created_at']) ?? DateTime.now(),
        mine: (r['mine'] as bool?) ?? false,
        voted: (r['voted'] as bool?) ?? false,
        hidden: (r['hidden'] as bool?) ?? false,
        reports: (r['reports'] as num?)?.toInt() ?? 0,
      );

  static DateTime? _date(Object? v) => v is String ? DateTime.tryParse(v)?.toLocal() : null;
}

/// Implémentation inerte quand aucun backend n'est configuré : la section ne
/// se dessine pas, et rien ne part.
class UnavailableCommunityTips implements CommunityTipsService {
  const UnavailableCommunityTips();

  @override
  bool get isAvailable => false;

  @override
  bool get canPublish => false;

  @override
  Future<List<SpeciesTip>> tips(String speciesId) async => const [];

  @override
  Future<SpeciesTip> publish({required String speciesId, required String speciesName, required String body}) async =>
      throw StateError('community tips unavailable');

  @override
  Future<void> withdraw(String tipId) async {}

  @override
  Future<SpeciesTip> vote(String tipId, {required bool helpful}) async => throw StateError('community tips unavailable');

  @override
  Future<void> report(String tipId) async {}

  @override
  Future<bool> isModerator() async => false;

  @override
  Future<List<SpeciesTip>> reported() async => const [];

  @override
  Future<void> moderate(String tipId, {required bool hidden}) async {}

  @override
  Future<void> remove(String tipId) async {}
}
