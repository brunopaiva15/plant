import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../../onboarding/presentation/onboarding_stage.dart';
import '../application/cutting_guide_steps.dart';
import 'clay_sequence.dart';
import 'cutting_intro_cluster.dart';

/// La scène du guide de bouturage : les six gestes réunis, puis l'objet de
/// chaque étape, qui se succèdent au centre de l'écran sur un halo de
/// couleur.
///
/// C'est la scène de l'onboarding, en plus simple : le halo reste là et
/// change de couleur, les objets changent de place au rythme du doigt. Celui
/// de l'étape courante est au centre, net, et joue sa séquence ; les autres
/// attendent hors champ.
class CuttingGuideStage extends StatelessWidget {
  const CuttingGuideStage({
    super.key,
    required this.offset,
    required this.page,
    required this.entry,
    required this.height,
    required this.reduceMotion,
    required this.tint,
  });

  /// Position continue du carrousel. C'est la seule source du mouvement.
  final double offset;

  /// L'étape affichée, celle dont l'objet joue.
  final int page;

  /// Avancement de l'entrée de la scène (0 → 1), jouée à l'ouverture et une
  /// seule fois.
  final double entry;

  /// Hauteur de la scène, accordée à celle de l'écran.
  final double height;

  final bool reduceMotion;

  /// La couleur de l'étape courante, déjà mêlée à celle de la suivante
  /// pendant le geste.
  final Color tint;

  /// Nombre d'objets : la page d'introduction, puis une étape par objet.
  static int get count => cuttingGuideSteps.length + 1;

  /// Côté de l'objet central pour une scène donnée : il prend presque toute
  /// la hauteur, sans jamais déborder des marges de la page.
  static double sideOf(double height, double width) => math.min(height * 0.92, width - 2 * Space.page).roundToDouble();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final width = MediaQuery.sizeOf(context).width;
    final side = sideOf(height, width);
    final rise = Curves.easeOutCubic.transform(entry);
    return SizedBox(
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Transform.scale(
            scale: reduceMotion ? 1 : 0.9 + 0.1 * rise,
            child: ClayHalo(color: tint, size: side * 1.18, dark: c.isDark),
          ),
          for (var i = count - 1; i >= 0; i--) _object(i, width, side, rise),
        ],
      ),
    );
  }

  Widget _object(int index, double width, double side, double rise) {
    // Distance continue à la place centrale, en écrans.
    final d = index - offset;
    // Un voisin n'existe que le temps du geste : à l'arrêt, il ne reste que
    // l'objet du milieu. Un objet défait puis refait rejoue sa séquence.
    final opacity = 1 - (d.abs() / 0.8).clamp(0.0, 1.0);
    if (opacity <= 0.01) return const SizedBox.shrink();

    final near = d.abs().clamp(0.0, 1.0);
    final scale = 1 - 0.4 * Curves.easeOutCubic.transform(near);
    // Ceux qui arrivent montent à droite et descendent à gauche.
    final dx = d * 0.7 * width;
    final dy = -24 * d.sign * near + 20 * (1 - rise) * (1 - near);
    final blur = reduceMotion ? 0.0 : 5.0 * Curves.easeIn.transform(near);
    final settle = reduceMotion ? 1.0 : 0.96 + 0.04 * rise;
    final vivant = index == page && near < 0.02;

    // La première place réunit les six gestes ; les autres en montrent un.
    final object = ImageFiltered(
      enabled: blur > 0.05,
      imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
      child: index == 0
          ? CuttingIntroCluster(side: side, animate: vivant)
          : ClaySequence(asset: cuttingGuideSteps[index - 1].asset, side: side, animate: vivant),
    );
    return Transform.translate(
      offset: Offset(dx, dy),
      child: Opacity(
        opacity: (opacity * (near < 0.02 ? (reduceMotion ? 1 : 0.4 + 0.6 * rise) : 1)).clamp(0.0, 1.0),
        child: Transform.scale(scale: scale * settle, child: object),
      ),
    );
  }
}
