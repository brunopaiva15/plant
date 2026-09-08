/// Collaboration : plusieurs comptes dans un même jardin.
///
/// Le propriétaire crée une invitation, en partage le lien ou le code, et
/// l'invité échange ce code contre une place. Chacun voit ensuite les mêmes
/// plantes ; un `member` peut ajouter, modifier et supprimer, un `viewer`
/// regarde seulement.
library;

/// Ce qu'un compte a le droit de faire dans un jardin.
enum GardenRole {
  owner,
  member,
  viewer;

  /// Valeur stockée en base (`garden_members.role`).
  String get key => name;

  static GardenRole parse(String? raw) => switch (raw) {
        'owner' => GardenRole.owner,
        'viewer' => GardenRole.viewer,
        _ => GardenRole.member,
      };

  /// Ajouter, modifier, supprimer : tout le monde sauf le lecteur.
  bool get canEdit => this != GardenRole.viewer;

  /// Inviter, changer un rôle, retirer quelqu'un : le propriétaire seul.
  bool get canManageMembers => this == GardenRole.owner;
}

/// Un jardin accessible au compte courant, avec son rôle dedans.
class GardenAccess {
  const GardenAccess({
    required this.id,
    required this.name,
    required this.role,
    this.ownerId,
    this.ownerName = '',
    this.memberCount = 1,
    this.plantCount = 0,
  });

  final String id;
  final String name;
  final GardenRole role;
  final String? ownerId;

  /// Nom du propriétaire, pour distinguer « le jardin de Laura » du sien.
  final String ownerName;
  final int memberCount;
  final int plantCount;

  bool get isMine => role == GardenRole.owner;

  /// Partagé dès qu'il y a quelqu'un d'autre dedans.
  bool get isShared => memberCount > 1;
}

/// Un membre du jardin, avec de quoi l'afficher.
class GardenMemberInfo {
  const GardenMemberInfo({required this.userId, required this.role, this.displayName = '', this.email});

  final String userId;
  final GardenRole role;
  final String displayName;
  final String? email;

  /// Le nom si on le connaît, l'adresse sinon.
  String get label => displayName.isNotEmpty ? displayName : (email ?? userId);
}

/// Une invitation en attente : un code à usage unique.
class GardenInvite {
  const GardenInvite({
    required this.id,
    required this.code,
    required this.role,
    required this.createdAt,
    this.email,
    this.expiresAt,
    this.acceptedAt,
    this.revokedAt,
  });

  final String id;
  final String code;
  final GardenRole role;

  /// Renseignée, seule cette adresse peut accepter l'invitation.
  final String? email;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final DateTime? acceptedAt;
  final DateTime? revokedAt;

  bool get isAccepted => acceptedAt != null;
  bool get isRevoked => revokedAt != null;
  bool isExpired(DateTime now) => expiresAt != null && !expiresAt!.isAfter(now);

  /// En attente : ni acceptée, ni révoquée, ni périmée.
  bool isPending(DateTime now) => !isAccepted && !isRevoked && !isExpired(now);

  /// Code présenté en deux groupes de quatre : plus facile à recopier.
  String get prettyCode => code.length == 8 ? '${code.substring(0, 4)}-${code.substring(4)}' : code;
}

/// Ce que l'invité voit avant d'accepter.
class InvitePreview {
  const InvitePreview({
    required this.gardenId,
    required this.gardenName,
    required this.role,
    this.ownerName = '',
    this.email,
    this.alreadyMember = false,
  });

  final String gardenId;
  final String gardenName;
  final GardenRole role;
  final String ownerName;
  final String? email;

  /// Le compte est déjà dans ce jardin : accepter ne fera que l'y ramener.
  final bool alreadyMember;
}

/// Échecs prévus d'une opération de collaboration, traduits par l'interface.
enum CollaborationError {
  /// Le code est inconnu, déjà utilisé, révoqué ou périmé.
  invalidCode,

  /// L'invitation est réservée à une autre adresse e-mail.
  wrongEmail,

  /// L'action demande d'être propriétaire du jardin.
  notOwner,

  /// Un propriétaire ne quitte pas son propre jardin.
  ownerCannotLeave,

  /// Il faut un compte pour rejoindre un jardin.
  notSignedIn,

  /// Réseau, serveur, ou tout ce qu'on n'a pas su nommer.
  unknown,
}

class CollaborationException implements Exception {
  const CollaborationException(this.error, [this.detail]);

  final CollaborationError error;
  final String? detail;

  /// Traduit le message d'erreur remonté par le backend.
  factory CollaborationException.from(Object error) {
    final text = error.toString();
    bool says(String code) => text.contains(code);
    return CollaborationException(
      switch (true) {
        _ when says('invalid_code') => CollaborationError.invalidCode,
        _ when says('wrong_email') => CollaborationError.wrongEmail,
        _ when says('not_owner') || says('not_yourself') || says('bad_role') => CollaborationError.notOwner,
        _ when says('owner_cannot_leave') => CollaborationError.ownerCannotLeave,
        _ when says('not_signed_in') => CollaborationError.notSignedIn,
        _ => CollaborationError.unknown,
      },
      text,
    );
  }

  @override
  String toString() => 'CollaborationException(${error.name})';
}

/// Partage d'un jardin entre comptes. Sans backend, rien de tout cela
/// n'existe : [isAvailable] vaut `false` et l'interface masque la fonction.
abstract class CollaborationService {
  bool get isAvailable;

  /// Les jardins du compte : le sien, puis ceux partagés avec lui.
  Future<List<GardenAccess>> gardens();

  /// Membres d'un jardin, propriétaire en tête.
  Future<List<GardenMemberInfo>> members(String gardenId);

  /// Crée une invitation à usage unique. [email] la réserve à cette adresse ;
  /// [days] la fait expirer (0 ou `null` : sans limite).
  Future<GardenInvite> createInvite({required String gardenId, String? email, GardenRole role = GardenRole.member, int days = 14});

  Future<List<GardenInvite>> invites(String gardenId);
  Future<void> revokeInvite(String inviteId);

  /// Ce que promet un code, sans l'utiliser. `null` s'il ne vaut plus rien.
  Future<InvitePreview?> previewInvite(String code);

  /// Échange le code contre une place ; retourne l'identifiant du jardin.
  Future<String> acceptInvite(String code);

  Future<void> setRole({required String gardenId, required String userId, required GardenRole role});
  Future<void> removeMember({required String gardenId, required String userId});
  Future<void> leaveGarden(String gardenId);

  /// Lien à envoyer à l'invité : ouvre l'application sur l'invitation.
  String inviteLink(String code);

  /// Nettoie un code recopié à la main (espaces, tirets, minuscules).
  static String normalizeCode(String raw) => raw.replaceAll(RegExp('[^A-Za-z0-9]'), '').toUpperCase();
}

/// Implémentation inerte quand aucun backend n'est configuré.
class UnavailableCollaborationService implements CollaborationService {
  const UnavailableCollaborationService();

  @override
  bool get isAvailable => false;

  @override
  Future<List<GardenAccess>> gardens() async => const [];

  @override
  Future<List<GardenMemberInfo>> members(String gardenId) async => const [];

  @override
  Future<GardenInvite> createInvite({required String gardenId, String? email, GardenRole role = GardenRole.member, int days = 14}) =>
      throw const CollaborationException(CollaborationError.notSignedIn);

  @override
  Future<List<GardenInvite>> invites(String gardenId) async => const [];

  @override
  Future<void> revokeInvite(String inviteId) async {}

  @override
  Future<InvitePreview?> previewInvite(String code) async => null;

  @override
  Future<String> acceptInvite(String code) => throw const CollaborationException(CollaborationError.notSignedIn);

  @override
  Future<void> setRole({required String gardenId, required String userId, required GardenRole role}) async {}

  @override
  Future<void> removeMember({required String gardenId, required String userId}) async {}

  @override
  Future<void> leaveGarden(String gardenId) async {}

  @override
  String inviteLink(String code) => '';
}
