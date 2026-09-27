import 'dart:math' as math;

import 'care_profile.dart';

/// La matière du pot. Le nom est ce qui est stocké et synchronisé : il ne
/// bouge pas.
///
/// C'est elle, plus que la taille, qui décide de la vitesse à laquelle le
/// substrat sèche : une terre cuite respire par ses parois, un plastique ne
/// perd son eau que par le haut, un pot à réserve boit par en dessous.
enum PotMaterial {
  terracotta,
  plastic,
  glazed,
  fabric,
  selfWatering;

  /// Depuis la valeur stockée ; `null` pour une valeur inconnue plutôt
  /// qu'une erreur — une version plus récente peut en connaître d'autres.
  static PotMaterial? parse(String? raw) => raw == null ? null : values.asNameMap()[raw];
}

/// Le pot d'une plante, tel que la personne l'a décrit : son diamètre en
/// centimètres, sa matière. L'un et l'autre sont facultatifs, et chacun pèse
/// seul sur l'arrosage.
class Pot {
  const Pot({this.diameterCm, this.material});

  /// Le pot sans rien de connu : il ne change rien à l'arrosage de la fiche.
  static const unknown = Pot();

  final double? diameterCm;
  final PotMaterial? material;

  /// Diamètre de référence : celui pour lequel les intervalles de la fiche
  /// sont écrits. Un pot de 15 cm est le pot courant d'une plante d'intérieur
  /// achetée en jardinerie.
  static const double referenceCm = 15;

  /// Bornes du diamètre retenu dans les calculs : en deçà, c'est un godet de
  /// semis ; au-delà, un bac, et l'arrosage ne se compte plus au pot.
  static const double minCm = 5;
  static const double maxCm = 60;

  bool get isUnknown => _diameter == null && material == null;

  double? get _diameter {
    final d = diameterCm;
    if (d == null || d <= 0) return null;
    return d.clamp(minCm, maxCm).toDouble();
  }

  /// Ce que la taille fait à l'intervalle. Un petit pot tient peu d'eau pour
  /// la surface qui sèche, un grand en garde une réserve : l'intervalle suit
  /// la racine carrée du rapport au pot de référence, borné à 0,7–1,4.
  double get sizeFactor {
    final d = _diameter;
    if (d == null) return 1;
    return math.sqrt(d / referenceCm).clamp(0.7, 1.4).toDouble();
  }

  /// Ce que la matière fait à l'intervalle. Terre cuite et tissu sèchent par
  /// leurs parois ; le pot à réserve ne se vide qu'au rythme où les racines y
  /// puisent.
  double get materialFactor => switch (material) {
        PotMaterial.terracotta => 0.8,
        PotMaterial.fabric => 0.75,
        PotMaterial.selfWatering => 1.6,
        PotMaterial.plastic || PotMaterial.glazed || null => 1,
      };

  /// Le multiplicateur que le pot applique à l'intervalle de la fiche.
  double get intervalFactor => sizeFactor * materialFactor;

  /// Volume du pot, en millilitres. Un pot de jardinerie est à peu près aussi
  /// haut que large, et se resserre vers le fond : 0,6 × d³ le rend à 10 %
  /// près, de 8 à 40 cm.
  double? get volumeMl {
    final d = _diameter;
    if (d == null) return null;
    return 0.6 * d * d * d;
  }

  /// L'eau à verser à chaque arrosage, en millilitres : une fourchette, pas
  /// une cote. `null` sans diamètre, et pour un pot à réserve, qui se remplit
  /// par la réserve et non par le haut.
  ///
  /// Un terreau ressuyé retient environ 30 % de son volume en eau. Le séchage
  /// que la fiche attend dit quelle part de cette réserve est partie ; on la
  /// remplace, avec un cinquième de plus pour que l'eau traverse la motte.
  /// Terre cuite et tissu en boivent une part par leurs parois.
  (int, int)? doseMl(DryDown rule) {
    final volume = volumeMl;
    if (volume == null || material == PotMaterial.selfWatering) return null;
    final spent = switch (rule) {
      DryDown.alwaysMoist => 0.15,
      DryDown.surfaceDry => 0.25,
      DryDown.topQuarterDry => 0.35,
      DryDown.halfDry => 0.5,
      DryDown.mostlyDry => 0.75,
      DryDown.fullyDry => 1.0,
    };
    final walls = switch (material) {
      PotMaterial.terracotta || PotMaterial.fabric => 1.1,
      _ => 1.0,
    };
    final dose = volume * 0.3 * spent * 1.2 * walls;
    final low = _roundMl(dose * 0.85);
    final high = _roundMl(dose * 1.15);
    return (low, high > low ? high : low + _stepMl(low));
  }

  /// Un verre doseur se lit par 10 ml sous 200 ml, par 50 ml au-dessus.
  static int _stepMl(num ml) => ml < 200 ? 10 : 50;

  static int _roundMl(double ml) {
    final step = _stepMl(ml);
    return math.max(step, (ml / step).round() * step);
  }
}
