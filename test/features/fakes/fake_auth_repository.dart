import 'package:flora/domain/auth/auth_repository.dart';

/// Un dépôt d'auth de laboratoire : un compte local, et un backend ou non.
/// `signInWithApple` et `signInWithGoogle` réussissent sans rien demander et
/// comptent leurs appels.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({required this.remote});

  final bool remote;
  int appleSignIns = 0;
  int googleSignIns = 0;
  final _user = const AppUser(id: 'u', displayName: '');

  @override
  bool get supportsRemote => remote;

  @override
  AppUser? get currentUser => _user;

  @override
  Stream<AppUser?> watchUser() => Stream.value(_user);

  @override
  Future<AppUser> ensureLocalUser() async => _user;

  @override
  Future<void> updateDisplayName(String name) async {}

  @override
  Future<void> signInWithApple() async => appleSignIns++;

  @override
  Future<void> signInWithGoogle() async => googleSignIns++;

  @override
  Future<void> signOut() async {}
}
