import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../core/config/app_config.dart';
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

  /// Connexion Apple, native (feuille système, sans navigateur).
  ///
  /// Le jeton d'identité signé par Apple est échangé contre une session
  /// Supabase (`signInWithIdToken`), avec un nonce pour lier les deux. Côté
  /// iOS, l'appel ne peut aboutir que si le binaire est signé avec
  /// l'entitlement `com.apple.developer.applesignin`
  /// (`ios/Runner/Runner.entitlements`), lequel exige que la capability
  /// « Sign In with Apple » soit active sur l'App ID `ch.vergasta.plant` :
  /// sinon la signature échoue. Côté Supabase, le fournisseur Apple doit
  /// lister ce même identifiant de bundle dans ses *Authorized Client IDs*.
  /// Voir docs/08-sync-and-collaboration.md.
  @override
  Future<void> signInWithApple() async {
    if (defaultTargetPlatform != TargetPlatform.iOS && defaultTargetPlatform != TargetPlatform.macOS) {
      throw const AuthException('apple_unavailable');
    }
    final rawNonce = _client.auth.generateRawNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();
    final AuthorizationCredentialAppleID credential;
    try {
      credential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
        nonce: hashedNonce,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      // Refermer la feuille d'Apple : l'UI ne montre rien. Le reste est une
      // erreur, dite comme telle.
      throw AuthException(e.code == AuthorizationErrorCode.canceled ? 'cancelled' : e.message);
    }
    final idToken = credential.identityToken;
    if (idToken == null) throw const AuthException('apple_no_token');
    try {
      await _client.auth.signInWithIdToken(provider: sb.OAuthProvider.apple, idToken: idToken, nonce: rawNonce);
    } on sb.AuthException catch (e) {
      throw AuthException(e.message);
    }
    // La session existe : la connexion a abouti. Le prénom qu'Apple ne donne
    // qu'à la première autorisation vient en supplément, et son écriture part
    // sur le réseau (`auth.updateUser`, puis la table `profiles`). Son échec
    // ne dit rien de la connexion : le remonter ferait annoncer « Connexion
    // impossible » à un appareil connecté, qui se retrouverait connecté au
    // lancement suivant. Le nom local, lui, est déjà écrit.
    final given = credential.givenName;
    if (given != null && given.isNotEmpty && (_prefs.displayName ?? '').isEmpty) {
      try {
        await updateDisplayName(given);
      } catch (_) {
        _emit();
      }
    }
  }

  static const MethodChannel _google = MethodChannel('ch.vergasta.plant/google_sign_in');

  /// Connexion Google.
  ///
  /// Sur Android, native, comme Apple sur iPhone : la feuille du système
  /// (Credential Manager, `android/.../GoogleSignInChannel.kt`) rend un jeton
  /// d'identité signé par Google, échangé contre une session Supabase avec un
  /// nonce pour lier les deux. L'appel ne revient qu'une fois connecté.
  ///
  /// Ailleurs, par le navigateur (OAuth) : la session arrive plus tard, par
  /// le lien de retour `auxine://login-callback`.
  ///
  /// Côté Supabase, le fournisseur Google doit connaître le client OAuth Web
  /// ([AppConfig.googleWebClientId]) ; côté Google Cloud, un client Android
  /// doit porter le nom du paquet et l'empreinte SHA-1 de la clé de
  /// signature. Voir docs/20-android.md.
  @override
  Future<void> signInWithGoogle() async {
    if (defaultTargetPlatform == TargetPlatform.android) return _signInWithGoogleOnAndroid();
    try {
      await _client.auth.signInWithOAuth(sb.OAuthProvider.google, redirectTo: SupabaseConfig.authRedirect, authScreenLaunchMode: sb.LaunchMode.externalApplication);
    } on sb.AuthException catch (e) {
      throw AuthException(e.message);
    }
  }

  Future<void> _signInWithGoogleOnAndroid() async {
    if (AppConfig.googleWebClientId.isEmpty) throw const AuthException('google_unavailable');
    final rawNonce = _client.auth.generateRawNonce();
    final Map<Object?, Object?> credential;
    try {
      credential = await _google.invokeMapMethod<Object?, Object?>('signIn', {
            'serverClientId': AppConfig.googleWebClientId,
            // Google scelle le condensé ; Supabase le recalcule depuis le
            // nonce brut, et refuse un jeton qui ne serait pas le sien.
            'nonce': sha256.convert(utf8.encode(rawNonce)).toString(),
          }) ??
          const {};
    } on MissingPluginException {
      throw const AuthException('google_unavailable');
    } on PlatformException catch (e) {
      // Refermer la feuille : l'UI ne montre rien. Le reste est une erreur,
      // dite comme telle.
      throw AuthException(e.code == 'cancelled' ? 'cancelled' : (e.message ?? e.code));
    }
    final idToken = credential['idToken'];
    if (idToken is! String || idToken.isEmpty) throw const AuthException('google_no_token');
    try {
      await _client.auth.signInWithIdToken(provider: sb.OAuthProvider.google, idToken: idToken, nonce: rawNonce);
    } on sb.AuthException catch (e) {
      throw AuthException(e.message);
    }
    // Comme pour Apple : le prénom est un supplément, son échec ne dit rien
    // de la connexion.
    final given = credential['givenName'];
    if (given is String && given.isNotEmpty && (_prefs.displayName ?? '').isEmpty) {
      try {
        await updateDisplayName(given);
      } catch (_) {
        _emit();
      }
    }
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Oublier le compte choisi : la prochaine connexion reproposera la
      // liste, au lieu de reprendre d'office celui qu'on vient de quitter.
      try {
        await _google.invokeMethod<void>('signOut');
      } on MissingPluginException {
        // Un binaire sans le canal : rien à oublier.
      } on PlatformException {
        // Rien de grave : la session Supabase, elle, est bien fermée.
      }
    }
    _emit();
  }

  void dispose() {
    _sub?.cancel();
    _controller.close();
  }
}
