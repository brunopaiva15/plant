import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;

import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../application/sign_in_availability.dart';

/// Le bouton de connexion de l'appareil : « Continuer avec Apple » sur
/// iPhone, « Continuer avec Google » sur Android. Un seul dessin pour
/// l'onboarding, l'écran Compte et l'invitation à un jardin.
class SignInButton extends StatelessWidget {
  const SignInButton({super.key, required this.method, required this.onPressed, this.loading = false});

  final SignInMethod method;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FloraButton(
      label: switch (method) {
        SignInMethod.apple => l10n.continueWithApple,
        SignInMethod.google => l10n.continueWithGoogle,
      },
      icon: signInIcon(method),
      expand: true,
      loading: loading,
      onPressed: onPressed,
    );
  }
}

/// L'icône d'une connexion, reprise dans la ligne Compte du profil.
IconData signInIcon(SignInMethod method) => switch (method) {
      SignInMethod.apple => Icons.apple,
      SignInMethod.google => CupertinoIcons.globe,
    };
