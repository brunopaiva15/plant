import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

/// Durées et courbes. Respecte `reduced motion` via [Motion.of].
abstract final class Motion {
  static const Duration micro = Duration(milliseconds: 150);
  static const Duration standard = Duration(milliseconds: 250);
  static const Duration emphasis = Duration(milliseconds: 400);
  static const Duration slow = Duration(milliseconds: 600);

  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve easeInOut = Curves.easeInOutCubic;
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;
  static const Curve spring = Curves.easeOutBack;

  /// Retourne [duration] ou zéro si l'utilisateur a demandé moins d'animations.
  static Duration of(BuildContext context, Duration duration) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
}

/// Les ressorts : ce qui bouge sous le doigt ou se déplace d'un point à un
/// autre suit une physique, pas une courbe de durée fixe.
///
/// Une courbe met toujours le même temps, quel que soit l'endroit d'où elle
/// part ; un ressort reprend la vitesse en cours. C'est ce qui fait la
/// différence entre une pièce qui répond et une pièce qui rejoue une
/// animation. Le rapport d'amortissement décide du dépassement :
/// `damping / (2·√(mass · stiffness))` — un au-dessus, la pièce se pose sans
/// dépasser ; en dessous, elle dépasse d'autant plus qu'il est petit.
abstract final class Springs {
  /// L'aller sous le doigt : franc et sans dépassement (amortissement 1,0).
  /// L'argile s'enfonce, elle ne tremble pas quand on appuie dessus.
  static const SpringDescription press = SpringDescription(mass: 1, stiffness: 900, damping: 60);

  /// Le retour au relâchement : la pièce remonte et dépasse d'un cheveu
  /// (0,44), comme une pâte qui se détend. C'est ce dépassement qui fait
  /// sentir la matière.
  static const SpringDescription release = SpringDescription(mass: 1, stiffness: 420, damping: 18);

  /// Ce qui se déplace d'un point à un autre — la bulle de la barre
  /// d'onglets : glisse vite, se pose presque sans rebondir (0,81).
  static const SpringDescription glide = SpringDescription(mass: 1, stiffness: 260, damping: 26);
}

/// Un contrôleur sans bornes mené par un ressort.
///
/// Le dépassement d'un ressort sort de l'intervalle 0–1 : c'est exactement ce
/// qu'on veut (une pièce relâchée passe un cheveu au-dessus de sa taille),
/// et c'est pourquoi ces contrôleurs sont `unbounded`.
extension SpringDrive on AnimationController {
  /// Va vers [target] avec [spring], en reprenant la vitesse en cours.
  ///
  /// Saute à la valeur quand la personne a demandé moins d'animations : un
  /// ressort qu'on raccourcit n'est plus un ressort, il vaut mieux ne rien
  /// jouer du tout.
  void springTo(double target, {required SpringDescription spring, required bool animate}) {
    if (!animate) {
      stop();
      value = target;
      return;
    }
    animateWith(SpringSimulation(spring, value, target, velocity));
  }
}
