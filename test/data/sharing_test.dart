import 'package:flora/data/sharing/supabase_sharing_service.dart';
import 'package:flora/domain/sharing/shared_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  SharedLink link({DateTime? expiresAt, DateTime? revokedAt}) => SharedLink(
        id: 'l1',
        plantId: 'p1',
        kind: SharedKind.plant,
        token: 'abcDEF123456789012345x',
        unlisted: true,
        createdAt: DateTime(2026, 1, 1),
        expiresAt: expiresAt,
        revokedAt: revokedAt,
      );

  group('état du lien', () {
    final now = DateTime(2026, 6, 1);

    test('un lien neuf est vivant', () {
      expect(link().isLive(now), isTrue);
    });

    test('un lien révoqué ne l\'est plus', () {
      final l = link(revokedAt: DateTime(2026, 5, 1));
      expect(l.isRevoked, isTrue);
      expect(l.isLive(now), isFalse);
    });

    test('un lien expiré ne l\'est plus', () {
      expect(link(expiresAt: DateTime(2026, 5, 31)).isLive(now), isFalse);
    });

    test('une expiration future ne change rien', () {
      expect(link(expiresAt: DateTime(2026, 7, 1)).isLive(now), isTrue);
    });

    test('l\'instant exact d\'expiration compte comme expiré', () {
      expect(link(expiresAt: now).isLive(now), isFalse);
    });
  });

  group('adresse publique', () {
    test('assemble base et jeton', () {
      expect(link().url('https://x.test/functions/v1/share'), 'https://x.test/functions/v1/share/abcDEF123456789012345x');
    });

    test('la barre finale de la base est ignorée', () {
      expect(link().url('https://x.test/s/'), 'https://x.test/s/abcDEF123456789012345x');
      expect(link().url('https://x.test/s///'), 'https://x.test/s/abcDEF123456789012345x');
    });
  });

  group('jeton', () {
    test('longueur et alphabet sûrs pour une URL', () {
      for (var i = 0; i < 50; i++) {
        final token = SupabaseSharingService.newToken();
        expect(token, hasLength(22));
        expect(RegExp(r'^[A-Za-z0-9]+$').hasMatch(token), isTrue);
        // Les caractères ambigus sont exclus pour la dictée à voix haute.
        expect(token.contains(RegExp('[lIO01]')), isFalse);
      }
    });

    test('deux jetons ne se répètent pas', () {
      final tokens = {for (var i = 0; i < 200; i++) SupabaseSharingService.newToken()};
      expect(tokens, hasLength(200));
    });
  });

  test('sans backend, le service est inerte et ne jette pas', () async {
    const service = UnavailableSharingService();
    expect(service.isAvailable, isFalse);
    expect(await service.list(), isEmpty);
    await service.revoke('x');
    await service.delete('x');
    expect(
      () => service.create(const NewSharedLink(plantId: 'p1', kind: SharedKind.plant)),
      throwsA(isA<StateError>()),
    );
  });
}
