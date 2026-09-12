/// Utilisateur courant. En Phase 1, un compte local sur l'appareil.
class AppUser {
  const AppUser({required this.id, required this.displayName, this.email, this.isLocal = true});

  final String id;
  final String displayName;
  final String? email;

  /// `true` tant que l'utilisateur n'a pas lié de compte distant.
  final bool isLocal;
}

/// Abstraction d'authentification. `LocalAuthRepository` (compte sur l'appareil)
/// ou `SupabaseAuthRepository` (Apple ; Google codé, pas livré) : l'UI ne
/// connaît que cette interface. Pas de connexion par e-mail sur Auxine :
/// un compte, c'est un identifiant Apple.
abstract class AuthRepository {
  Stream<AppUser?> watchUser();
  AppUser? get currentUser;
  Future<AppUser> ensureLocalUser();
  Future<void> updateDisplayName(String name);

  /// `true` si un backend est configuré (connexion possible).
  bool get supportsRemote;

  Future<void> signInWithApple();
  Future<void> signInWithGoogle();
  Future<void> signOut();
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
