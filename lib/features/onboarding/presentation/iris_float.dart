import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import 'clay_illustration.dart';

/// La marque d'Iris au centre de la scène, pour l'écran du modèle embarqué.
///
/// Les autres objets du jardin sont des rendus posés sur le sol, avec leur
/// ombre portée ; la marque, elle, est peinte par `paintClay` et porte déjà
/// le relief et l'ombre d'une pièce d'argile. Lui ajouter l'ombre au sol de
/// [ClayFloat] la ferait flotter deux fois. Elle ne prend donc de la
/// respiration que la montée et l'inclinaison — le même souffle que ses
/// voisines, à la même cadence.
class IrisFloat extends StatelessWidget {
  const IrisFloat({super.key, required this.side, this.animate = true});

  /// Côté de la place sur la scène, comme pour les images d'argile.
  final double side;

  /// L'écran est-il à l'affichage ? À `false`, la marque reste posée.
  final bool animate;

  /// Ce que la marque prend de sa place. Les objets d'argile occupent un peu
  /// moins des quatre cinquièmes de leur carré ; la feuille penchée, à taille
  /// égale, en remplirait presque toute la largeur. Réduite d'un sixième,
  /// elle a le même encombrement qu'eux — quatre cinquièmes de large, trois
  /// de haut —, et la scène garde son rythme d'un écran à l'autre.
  static const double fill = 0.85;

  @override
  Widget build(BuildContext context) {
    return Breathing(
      animate: animate,
      builder: (context, pose) => SizedBox.square(
        dimension: side,
        child: Center(
          child: Transform.translate(
            offset: Offset(0, -pose.lift * side * 0.02),
            child: Transform.rotate(
              angle: pose.tilt * 0.018,
              // Décorative : le titre de l'écran nomme le modèle juste en
              // dessous, et le lire deux fois n'apprendrait rien.
              child: IrisMark(size: side * fill),
            ),
          ),
        ),
      ),
    );
  }
}
