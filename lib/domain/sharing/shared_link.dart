/// Ce qui est partagé derrière un lien public.
enum SharedKind { plant, photo }

/// Lien de partage public et révocable vers une plante ou une photo.
class SharedLink {
  const SharedLink({
    required this.id,
    required this.plantId,
    required this.kind,
    required this.token,
    required this.unlisted,
    required this.createdAt,
    this.photoId,
    this.title,
    this.description,
    this.keywords,
    this.expiresAt,
    this.revokedAt,
  });

  final String id;
  final String plantId;
  final String? photoId;
  final SharedKind kind;
  final String token;
  final String? title;
  final String? description;
  final String? keywords;

  /// Non listé : la page publique demande aux moteurs de ne pas l'indexer.
  final bool unlisted;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime? revokedAt;

  bool get isRevoked => revokedAt != null;
  bool isExpired(DateTime now) => expiresAt != null && !expiresAt!.isAfter(now);
  bool isLive(DateTime now) => !isRevoked && !isExpired(now);

  /// Adresse publique complète.
  String url(String baseUrl) => '${baseUrl.replaceAll(RegExp(r'/+$'), '')}/$token';
}

/// Création d'un lien de partage.
class NewSharedLink {
  const NewSharedLink({
    required this.plantId,
    required this.kind,
    this.photoId,
    this.title,
    this.description,
    this.keywords,
    this.unlisted = true,
    this.expiresAt,
  });

  final String plantId;
  final String? photoId;
  final SharedKind kind;
  final String? title;
  final String? description;
  final String? keywords;
  final bool unlisted;
  final DateTime? expiresAt;
}

/// Service de partage public. Nécessite un compte : sans backend, il n'y a
/// rien à publier.
abstract class SharingService {
  /// `false` quand aucun backend n'est configuré : l'UI masque la fonction.
  bool get isAvailable;

  Future<List<SharedLink>> list();
  Future<SharedLink> create(NewSharedLink data);
  Future<void> revoke(String id);
  Future<void> delete(String id);

  /// Base des adresses publiques (`https://…/s`).
  String get baseUrl;
}
