import 'package:flutter/material.dart';

import '../tokens/spacing.dart';
import 'pressable.dart';

/// Le déclencheur : un anneau blanc et son disque, posés sur le viseur.
///
/// Le même sur toutes les pages qui visent, la création d'une plante comme
/// le diagnostic. C'est le geste de l'appareil photo du système, et il n'a
/// pas à changer d'allure d'un écran à l'autre.
///
/// Le design system ne lit pas les ARB : le libellé lu par VoiceOver lui est
/// passé, comme pour le retour des pages.
class Shutter extends StatelessWidget {
  const Shutter({
    super.key,
    required this.onTap,
    required this.busy,
    required this.semanticLabel,
    this.enabled = true,
  });

  final VoidCallback onTap;
  final bool busy;
  final String semanticLabel;

  /// Faux tant que le flux n'est pas prêt : le déclencheur est là, il
  /// n'écoute pas encore.
  final bool enabled;

  /// Côté du déclencheur.
  static const double side = 68;

  /// Ce dont une commande posée à sa gauche doit s'écarter du centre pour
  /// laisser douze points entre les deux : demi-déclencheur, l'écart, puis
  /// le demi-bouton de 40.
  static const double asideOffset = side / 2 + Space.sm + 20;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: busy || !enabled ? null : onTap,
      enabled: enabled,
      scale: 0.86,
      semanticLabel: semanticLabel,
      child: Container(
        width: side,
        height: side,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 3))],
        ),
        child: Container(
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        ),
      ),
    );
  }
}
