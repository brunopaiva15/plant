import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../../../design_system/design_system.dart';
import '../../../domain/identification/plant_identifier.dart';

/// D'où vient la liste, dit d'un signe autant que d'une phrase : un téléphone
/// quand le modèle embarqué a répondu, un nuage quand la photo est partie
/// chez Pl@ntNet.
///
/// La phrase le disait déjà — « Trouvé sur votre appareil, sans réseau » —
/// et elle reste, mot pour mot : le signe ne la remplace pas, il se lit
/// avant elle. Une légende grise au-dessus d'une liste se saute ; un nuage,
/// non. C'est pourtant la seule information de cet écran qui engage la vie
/// privée (§ 3.6 de docs/09-plant-recognition.md) : savoir si la photo est
/// sortie de l'appareil ne doit pas dépendre du fait qu'on ait lu la
/// légende.
///
/// [IdentificationSource.unknown] n'a pas de signe. Un dessin qui affirme
/// « appareil » ou « réseau » quand on ne sait pas mentirait ; la phrase
/// générique, elle, ne promet rien.
class IdentificationSourceNote extends StatelessWidget {
  const IdentificationSourceNote({super.key, required this.source, required this.label});

  final IdentificationSource source;

  /// La phrase, déjà traduite et déjà choisie par l'appelant : la feuille
  /// d'identification et le flux de création ne disent pas la même chose de
  /// la même source.
  final String label;

  /// Le signe se pose un peu au-dessus de la taille de la légende — un
  /// glyphe d'icône garde de l'air dans son cadre, et à 13 le téléphone
  /// devenait un trait. Figé, il deviendrait un point à 350 % de
  /// grossissement : il suit donc `textScaler` comme le texte qu'il
  /// accompagne.
  static const double _iconSize = 16;

  @override
  Widget build(BuildContext context) {
    final style = context.text.caption;
    final icon = switch (source) {
      IdentificationSource.local => CupertinoIcons.device_phone_portrait,
      IdentificationSource.remote => CupertinoIcons.cloud,
      IdentificationSource.unknown => null,
    };
    if (icon == null) return Text(label, style: style);
    final scaler = MediaQuery.textScalerOf(context);
    final size = scaler.scale(_iconSize);
    // Aligné sur la première ligne, pas sur le bloc : la phrase passe à deux
    // lignes dès qu'on grossit le texte, et un signe centré sur les deux se
    // retrouverait à mi-hauteur, loin du mot qu'il qualifie.
    final lead = math.max(0.0, (scaler.scale(style.fontSize ?? _iconSize) * (style.height ?? 1.3) - size) / 2);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sans libellé : la phrase à côté dit déjà la même chose, et la
        // synthèse vocale n'a pas à l'entendre deux fois.
        Padding(
          padding: EdgeInsets.only(top: lead),
          child: Icon(icon, size: size, color: style.color),
        ),
        const SizedBox(width: Space.xxs),
        Flexible(child: Text(label, style: style)),
      ],
    );
  }
}
