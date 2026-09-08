import 'package:flora/domain/sharing/garden_collaboration.dart';
import 'package:flora/features/qr/application/plant_links.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('rôles', () {
    test('un rôle inconnu vaut « membre », jamais propriétaire', () {
      expect(GardenRole.parse('owner'), GardenRole.owner);
      expect(GardenRole.parse('viewer'), GardenRole.viewer);
      expect(GardenRole.parse(null), GardenRole.member);
      expect(GardenRole.parse('quelque chose'), GardenRole.member);
    });

    test('le lecteur ne peut rien écrire, le propriétaire seul gère les membres', () {
      expect(GardenRole.viewer.canEdit, isFalse);
      expect(GardenRole.member.canEdit, isTrue);
      expect(GardenRole.owner.canEdit, isTrue);
      expect(GardenRole.member.canManageMembers, isFalse);
      expect(GardenRole.owner.canManageMembers, isTrue);
    });
  });

  group('code d\'invitation', () {
    test('se recopie avec des espaces, des tirets et des minuscules', () {
      expect(CollaborationService.normalizeCode(' k3jm-9p2r '), 'K3JM9P2R');
      expect(CollaborationService.normalizeCode('k3jm 9p2r'), 'K3JM9P2R');
      expect(CollaborationService.normalizeCode(''), '');
    });

    test('s\'affiche en deux groupes de quatre', () {
      final invite = GardenInvite(id: 'i', code: 'K3JM9P2R', role: GardenRole.member, createdAt: DateTime(2026));
      expect(invite.prettyCode, 'K3JM-9P2R');
    });
  });

  group('état d\'une invitation', () {
    final now = DateTime(2026, 9, 8);
    GardenInvite invite({DateTime? expiresAt, DateTime? acceptedAt, DateTime? revokedAt}) => GardenInvite(
          id: 'i',
          code: 'K3JM9P2R',
          role: GardenRole.member,
          createdAt: DateTime(2026),
          expiresAt: expiresAt,
          acceptedAt: acceptedAt,
          revokedAt: revokedAt,
        );

    test('en attente tant qu\'elle n\'a pas servi, ni expiré, ni été révoquée', () {
      expect(invite().isPending(now), isTrue);
      expect(invite(expiresAt: now.add(const Duration(days: 1))).isPending(now), isTrue);
      expect(invite(expiresAt: now.subtract(const Duration(days: 1))).isPending(now), isFalse);
      expect(invite(acceptedAt: now).isPending(now), isFalse);
      expect(invite(revokedAt: now).isPending(now), isFalse);
    });
  });

  group('erreurs remontées par le backend', () {
    CollaborationError from(String message) => CollaborationException.from(Exception(message)).error;

    test('sont traduites en cas nommés', () {
      expect(from('PostgrestException(message: invalid_code)'), CollaborationError.invalidCode);
      expect(from('wrong_email'), CollaborationError.wrongEmail);
      expect(from('not_owner'), CollaborationError.notOwner);
      expect(from('owner_cannot_leave'), CollaborationError.ownerCannotLeave);
      expect(from('not_signed_in'), CollaborationError.notSignedIn);
      expect(from('Connection closed'), CollaborationError.unknown);
    });
  });

  group('lien d\'invitation', () {
    test('le lien de l\'application se décode', () {
      expect(PlantLinks.decodeLink(PlantLinks.encodeJoin('K3JM9P2R')), const FloraLink(FloraLinkKind.join, 'K3JM9P2R'));
    });

    test('la page publique aussi : c\'est elle qu\'on scanne', () {
      expect(
        PlantLinks.decodeLink('https://xyz.supabase.co/functions/v1/share/join/K3JM9P2R'),
        const FloraLink(FloraLinkKind.join, 'K3JM9P2R'),
      );
      expect(PlantLinks.decodeLink('https://vergasta.ch/privacy'), isNull);
      expect(PlantLinks.decodeLink('https://xyz.supabase.co/functions/v1/share/AbCdEfGhIjKlMnOpQrStUv'), isNull);
    });

    test('un lien de plante reste un lien de plante', () {
      expect(PlantLinks.decodeLink(PlantLinks.encode('p1')), const FloraLink(FloraLinkKind.plant, 'p1'));
      expect(PlantLinks.decode(PlantLinks.encodeJoin('K3JM9P2R')), isNull);
    });
  });
}
