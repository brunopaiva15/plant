import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/config/app_config.dart';
import '../../../core/l10n/l10n.dart';
import '../../../domain/auth/auth_repository.dart';

/// Les connexions d'Auxine : chacune par la feuille de son système, aucune
/// par e-mail.
enum SignInMethod { apple, google }

/// La connexion que cet appareil propose, ou `null` : Apple sur iPhone et
/// iPad, Google sur Android dès que le client OAuth est renseigné
/// ([AppConfig.googleWebClientId]). Sans backend, ou sur Android sans client,
/// le compte reste local — et aucun écran ne promet une connexion qui
/// n'existe pas.
SignInMethod? platformSignInMethod(AuthRepository auth, {String googleClientId = AppConfig.googleWebClientId}) {
  if (!auth.supportsRemote || kIsWeb) return null;
  return switch (defaultTargetPlatform) {
    TargetPlatform.iOS => SignInMethod.apple,
    TargetPlatform.android when googleClientId.isNotEmpty => SignInMethod.google,
    _ => null,
  };
}

/// L'identifiant du client OAuth Web de Google. Un fournisseur plutôt qu'une
/// constante lue sur place, pour qu'un test puisse montrer l'Android connecté
/// sans que le dépôt en porte un.
final googleWebClientIdProvider = Provider<String>((ref) => AppConfig.googleWebClientId);

final signInMethodProvider = Provider<SignInMethod?>(
  (ref) => platformSignInMethod(ref.watch(authRepositoryProvider), googleClientId: ref.watch(googleWebClientIdProvider)),
);

/// `true` quand l'app peut proposer une connexion : celle de l'appareil, ou
/// Google par le navigateur sur iPhone si [AppConfig.googleSignInEnabled].
final signInAvailableProvider = Provider<bool>(
  (ref) =>
      ref.watch(signInMethodProvider) != null || (ref.watch(authRepositoryProvider).supportsRemote && AppConfig.googleSignInEnabled),
);

extension SignInMethodActions on SignInMethod {
  Future<void> signIn(AuthRepository auth) => switch (this) {
        SignInMethod.apple => auth.signInWithApple(),
        SignInMethod.google => auth.signInWithGoogle(),
      };
}

/// Ce que l'écran dit d'une connexion qui n'a pas abouti. `null` quand il
/// n'y a rien à dire : refermer la feuille du système n'est pas une erreur.
String? signInErrorText(AppLocalizations l10n, AuthException e) => switch (e.message) {
      'cancelled' => null,
      'apple_unavailable' => l10n.appleUnavailable,
      _ => l10n.authError,
    };
