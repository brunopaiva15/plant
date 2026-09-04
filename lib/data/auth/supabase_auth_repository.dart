import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../core/config/supabase_config.dart';
import '../../domain/auth/auth_repository.dart';
import '../db/database.dart';
import '../services/preferences_service.dart';
import 'local_auth_repository.dart';

/// Compte distant (Supabase). Tant que personne n'est connecté, le compte local
/// continue de fonctionner : l'utilisateur découvre l'app avant de s'inscrire.
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client, FloraDatabase db, PreferencesService prefs)
      : _local = LocalAuthRepository(db, prefs),
        _prefs = prefs {
    _sub = _client.auth.onAuthStateChange.listen((_) => _emit());
  }

  final sb.SupabaseClient _client;
  final LocalAuthRepository _local;
  final PreferencesService _prefs;
  final _controller = StreamController<AppUser?>.broadcast();
  StreamSubscription<sb.AuthState>? _sub;

  String get gardenId => _local.gardenId;

  AppUser? _build() {
    final user = _client.auth.currentUser;
    if (user == null) return _local.currentUser;
    final name = _prefs.displayName ?? (user.userMetadata?['display_name'] as String?) ?? '';
    return AppUser(id: user.id, displayName: name, email: user.email, isLocal: false);
  }

  void _emit() => _controller.add(_build());

  @override
  Stream<AppUser?> watchUser() async* {
    yield _build();
    yield* _controller.stream;
  }

  @override
  AppUser? get currentUser => _build();

  @override
  Future<AppUser> ensureLocalUser() async {
    await _local.ensureLocalUser();
    return _build()!;
  }

  @override
  Future<void> updateDisplayName(String name) async {
    await _local.updateDisplayName(name);
    if (_client.auth.currentUser != null) {
      await _client.auth.updateUser(sb.UserAttributes(data: {'display_name': name.trim()}));
      await _client.from('profiles').upsert({'id': _client.auth.currentUser!.id, 'display_name': name.trim()});
    }
    _emit();
  }

  @override
  bool get supportsRemote => true;

  @override
  Future<void> requestEmailCode(String email) async {
    try {
      await _client.auth.signInWithOtp(email: email.trim(), shouldCreateUser: true);
    } on sb.AuthException catch (e) {
      throw AuthException(e.message);
    }
  }

  @override
  Future<void> verifyEmailCode({required String email, required String code}) async {
    try {
      await _client.auth.verifyOTP(email: email.trim(), token: code.trim(), type: sb.OtpType.email);
    } on sb.AuthException catch (e) {
      throw AuthException(e.message);
    }
  }

  @override
  Future<void> signInWithApple() async {
    if (defaultTargetPlatform != TargetPlatform.iOS && defaultTargetPlatform != TargetPlatform.macOS) {
      throw const AuthException('apple_unavailable');
    }
    final rawNonce = _client.auth.generateRawNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      nonce: hashedNonce,
    );
    final idToken = credential.identityToken;
    if (idToken == null) throw const AuthException('apple_no_token');
    try {
      await _client.auth.signInWithIdToken(provider: sb.OAuthProvider.apple, idToken: idToken, nonce: rawNonce);
    } on sb.AuthException catch (e) {
      throw AuthException(e.message);
    }
    final given = credential.givenName;
    if (given != null && given.isNotEmpty && (_prefs.displayName ?? '').isEmpty) await updateDisplayName(given);
  }

  @override
  Future<void> signInWithGoogle() async {
    try {
      await _client.auth.signInWithOAuth(sb.OAuthProvider.google, redirectTo: SupabaseConfig.authRedirect, authScreenLaunchMode: sb.LaunchMode.externalApplication);
    } on sb.AuthException catch (e) {
      throw AuthException(e.message);
    }
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
    _emit();
  }

  void dispose() {
    _sub?.cancel();
    _controller.close();
  }
}
