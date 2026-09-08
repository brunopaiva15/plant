import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Hiérarchie typographique. Les grands titres et les titres de section sont
/// en Shantell Sans, une police à la main ; tout le reste — listes, boutons,
/// champs — garde la police du système (SF Pro sur iOS, Roboto sur Android).
/// C'est ce partage qui donne le côté fait-main sans tomber dans le carnet
/// d'enfant sur quarante écrans.
///
/// Sept styles seulement : trop de tailles nuit à la cohérence.
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

  /// La police à la main des titres. Fonte variable : le poids se règle
  /// par [FontVariation], le [FontWeight] sert de repli.
  static const String handFamily = 'ShantellSans';

  List<FontVariation> _wght(double weight) => [FontVariation('wght', math.min(800, weight + _boost))];

  List<FontVariation> get _bold => _wght(700);

  List<FontVariation> get _semibold => _wght(600);

  TextStyle get display => TextStyle(
        fontFamily: handFamily,
        fontVariations: _bold,
        fontSize: 34,
        height: 1.15,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: _ink,
      );

  TextStyle get title1 => TextStyle(
        fontFamily: handFamily,
        fontVariations: _bold,
        fontSize: 28,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: _ink,
      );

  TextStyle get title2 => TextStyle(
        fontFamily: handFamily,
        fontVariations: _semibold,
        fontSize: 22,
        height: 1.25,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
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
