import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Hiérarchie typographique. Les grands titres, les titres de section et les
/// chiffres sont en Bricolage Grotesque, très gras et serré ; tout le reste —
/// listes, boutons, champs — garde la police du système (SF Pro sur iOS,
/// Roboto sur Android). Le contraste entre les deux fait le caractère : une
/// voix forte pour ce qui se voit de loin, la police du téléphone pour ce qui
/// se lit.
///
/// Sept styles de texte, et deux de chiffres ([hero], [stat]) : trop de
/// tailles nuit à la cohérence.
class FloraTypography {
  const FloraTypography._(this._ink, this._secondary, this._boost);

  final Color _ink;
  final Color _secondary;

  /// Ce qu'on ajoute à l'axe de graisse de la fonte variable.
  final double _boost;

  factory FloraTypography.forColors({required Color ink, required Color secondary}) =>
      FloraTypography._(ink, secondary, 0);

  /// La variante « Texte en gras » (Réglages > Accessibilité > Affichage).
  ///
  /// Flutter épaissit tout seul les styles à [FontWeight], mais la fonte
  /// variable des titres ne l'écoute pas : sur elle, c'est [FontVariation] qui
  /// décide, et un `fontWeight` posé à côté reste lettre morte. Sans ce
  /// décalage explicite, activer le réglage épaississait les listes et
  /// laissait les grands titres exactement comme avant.
  FloraTypography get bolder => FloraTypography._(_ink, _secondary, 100);

  /// La police des titres. Les titres restent sous la graisse maximale de la
  /// fonte (800) pour que « Texte en gras » ait encore de la marge ; seuls les
  /// chiffres y sont d'emblée. Fonte variable : le poids et la taille optique se
  /// règlent par [FontVariation], le [FontWeight] sert de repli.
  static const String displayFamily = 'BricolageGrotesque';

  /// La taille optique suit la taille du texte, dans les bornes de la fonte :
  /// les petits titres s'ouvrent, les grands chiffres se resserrent.
  List<FontVariation> _axes(double weight, double size) => [
        FontVariation('wght', math.min(800, weight + _boost)),
        FontVariation('opsz', size.clamp(12, 96).toDouble()),
      ];

  /// Le grand chiffre d'une tête d'écran : trois soins, huit plantes.
  TextStyle get hero => TextStyle(
        fontFamily: displayFamily,
        fontVariations: _axes(800, 96),
        fontSize: 96,
        height: 0.9,
        fontWeight: FontWeight.w800,
        letterSpacing: -4,
        color: _ink,
      );

  /// Un chiffre de carte : la hauteur d'une plante, les jours avant
  /// l'arrosage.
  TextStyle get stat => TextStyle(
        fontFamily: displayFamily,
        fontVariations: _axes(800, 34),
        fontSize: 34,
        height: 1,
        fontWeight: FontWeight.w800,
        letterSpacing: -1,
        color: _ink,
      );

  TextStyle get display => TextStyle(
        fontFamily: displayFamily,
        fontVariations: _axes(720, 34),
        fontSize: 34,
        height: 1.1,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        color: _ink,
      );

  TextStyle get title1 => TextStyle(
        fontFamily: displayFamily,
        fontVariations: _axes(720, 28),
        fontSize: 28,
        height: 1.15,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: _ink,
      );

  TextStyle get title2 => TextStyle(
        fontFamily: displayFamily,
        fontVariations: _axes(650, 22),
        fontSize: 22,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: _ink,
      );

  TextStyle get title3 => TextStyle(
        fontSize: 17,
        height: 1.3,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: _ink,
      );

  TextStyle get body => TextStyle(
        fontSize: 17,
        height: 1.35,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.2,
        color: _ink,
      );

  TextStyle get callout => TextStyle(
        fontSize: 15,
        height: 1.35,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.1,
        color: _secondary,
      );

  TextStyle get caption => TextStyle(
        fontSize: 13,
        height: 1.3,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        color: _secondary,
      );
}
