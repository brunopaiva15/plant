/// Utilisateur courant. En Phase 1, un compte local sur l'appareil.
class AppUser {
  const AppUser({required this.id, required this.displayName, this.email, this.isLocal = true});

  final String id;
  final String displayName;
  final String? email;

  /// `true` tant que l'utilisateur n'a pas lié de compte distant.
  final bool isLocal;
}

/// Abstraction d'authentification. L'implémentation Supabase (Apple, Google,
/// e-mail) remplacera [LocalAuthRepository] en Phase 2 sans toucher l'UI.
abstract class AuthRepository {
  Stream<AppUser?> watchUser();
  Future<AppUser> ensureLocalUser();
  Future<void> updateDisplayName(String name);
  Future<void> signOut();
}
