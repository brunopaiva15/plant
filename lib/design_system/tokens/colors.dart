import 'package:flutter/material.dart';

/// Palette Flora : de l'argile et de la terre cuite. Fond crème grainé,
/// surfaces crème claire, encre brune ; le vert reste la couleur de l'action,
/// la terre cuite devient la couleur phare ; ocre, bleu poussière et rose
/// pour les indicateurs de soin.
///
/// ## Le contrat de contraste
///
/// Un accent sert tantôt de texte sur un fond pâle (la pastille d'échéance),
/// tantôt de fond sous du texte (le bouton « Arroser »). Les deux sens sont
/// donc tenus, et `colors_contrast_test.dart` les vérifie :
///
/// - encre, encre secondaire et encre tertiaire : **≥ 4.5:1** sur `canvas`,
///   `surface` et `surfaceMuted` — l'encre tertiaire porte les libellés des
///   champs, elle ne peut pas se contenter d'un gris décoratif ;
/// - `sage`, `terracotta`, `water`, `danger` : **≥ 4.5:1** sur ces trois fonds
///   et sur leur pastel — ils portent du texte de 13 pt ;
/// - `sun` et `rose` ne servent que d'icônes : **≥ 3:1** suffit ;
/// - tout accent employé comme fond porte [onAccent], **≥ 4.5:1** dessus.
///
/// C'est ce dernier point qui gouverne la clarté des accents : sombres en
/// thème clair pour que le blanc tienne dessus, clairs en thème sombre pour
/// que l'encre tienne. Les séparateurs (`line`) restent volontairement ténus
/// — ils ne portent aucune information — et ne se renforcent qu'en contraste
/// élevé.
class FloraColors {
  const FloraColors({
    required this.canvas,
    required this.surface,
    required this.surfaceMuted,
    required this.surfaceElevated,
    required this.ink,
    required this.inkSecondary,
    required this.inkTertiary,
    required this.line,
    required this.sage,
    required this.sageSoft,
    required this.onSage,
    required this.terracotta,
    required this.terracottaSoft,
    required this.water,
    required this.waterSoft,
    required this.sun,
    required this.sunSoft,
    required this.rose,
    required this.roseSoft,
    required this.danger,
    required this.shadow,
    required this.brightness,
  });

  final Color canvas;
  final Color surface;
  final Color surfaceMuted;
  final Color surfaceElevated;
  final Color ink;
  final Color inkSecondary;
  final Color inkTertiary;
  final Color line;
  final Color sage;
  final Color sageSoft;
  final Color onSage;
  final Color terracotta;
  final Color terracottaSoft;
  final Color water;
  final Color waterSoft;
  final Color sun;
  final Color sunSoft;
  final Color rose;
  final Color roseSoft;
  final Color danger;
  final Color shadow;
  final Brightness brightness;

  bool get isDark => brightness == Brightness.dark;

  static const light = FloraColors(
    canvas: Color(0xFFF6EFE4),
    surface: Color(0xFFFBF6EE),
    surfaceMuted: Color(0xFFEFE4D4),
    surfaceElevated: Color(0xFFFFFBF5),
    ink: Color(0xFF4A3528),
    inkSecondary: Color(0xFF6F5A4E),
    inkTertiary: Color(0xFF746256),
    line: Color(0xFFE6D9C8),
    sage: Color(0xFF2C774E),
    sageSoft: Color(0xFFE4EFE6),
    onSage: Color(0xFFFFFFFF),
    terracotta: Color(0xFF9C482C),
    terracottaSoft: Color(0xFFF2D9CB),
    water: Color(0xFF39689A),
    waterSoft: Color(0xFFDCE7F3),
    sun: Color(0xFF966E2C),
    sunSoft: Color(0xFFF3E3C2),
    rose: Color(0xFFC64A61),
    roseSoft: Color(0xFFF5DDE0),
    danger: Color(0xFFC0392B),
    shadow: Color(0x245E2C14),
    brightness: Brightness.light,
  );

  /// Sombre : la même terre, dans l'ombre. Un brun profond, chaud, sur
  /// lequel le vert et la terre cuite s'éclaircissent pour rester lisibles.
  static const dark = FloraColors(
    canvas: Color(0xFF221A15),
    surface: Color(0xFF2E2219),
    surfaceMuted: Color(0xFF3A2C22),
    surfaceElevated: Color(0xFF443428),
    ink: Color(0xFFF6EFE4),
    inkSecondary: Color(0xFFC2AE9C),
    inkTertiary: Color(0xFFA69485),
    line: Color(0xFF4A3A2E),
    sage: Color(0xFF6DC48D),
    sageSoft: Color(0xFF2C3D31),
    onSage: Color(0xFF0B1A10),
    terracotta: Color(0xFFE59A70),
    terracottaSoft: Color(0xFF4A2E22),
    water: Color(0xFF8FB8E4),
    waterSoft: Color(0xFF2B3644),
    sun: Color(0xFFE7C15C),
    sunSoft: Color(0xFF45391F),
    rose: Color(0xFFEC8A9B),
    roseSoft: Color(0xFF4A2C31),
    danger: Color(0xFFE47064),
    shadow: Color(0x00000000),
    brightness: Brightness.dark,
  );

  /// Contraste élevé (« Augmenter le contraste » dans Réglages > Accessibilité).
  ///
  /// Même matière, mêmes teintes : seule la clarté bouge. Le texte vise AAA
  /// (≥ 7:1), les icônes 4.5:1, et les séparateurs deviennent enfin visibles
  /// — c'est la première chose que ce réglage est censé rendre.
  static const lightHighContrast = FloraColors(
    canvas: Color(0xFFF6EFE4),
    surface: Color(0xFFFBF6EE),
    surfaceMuted: Color(0xFFEFE4D4),
    surfaceElevated: Color(0xFFFFFBF5),
    ink: Color(0xFF3A2A20),
    inkSecondary: Color(0xFF52423A),
    inkTertiary: Color(0xFF55483F),
    line: Color(0xFF968573),
    sage: Color(0xFF21583A),
    sageSoft: Color(0xFFE4EFE6),
    onSage: Color(0xFFFFFFFF),
    terracotta: Color(0xFF703420),
    terracottaSoft: Color(0xFFF2D9CB),
    water: Color(0xFF2A4C70),
    waterSoft: Color(0xFFDCE7F3),
    sun: Color(0xFF815F26),
    sunSoft: Color(0xFFF3E3C2),
    rose: Color(0xFFAD3C51),
    roseSoft: Color(0xFFF5DDE0),
    danger: Color(0xFF932C21),
    shadow: Color(0x3D5E2C14),
    brightness: Brightness.light,
  );

  /// Contraste élevé, en sombre.
  static const darkHighContrast = FloraColors(
    canvas: Color(0xFF221A15),
    surface: Color(0xFF2E2219),
    surfaceMuted: Color(0xFF3A2C22),
    surfaceElevated: Color(0xFF443428),
    ink: Color(0xFFF6EFE4),
    inkSecondary: Color(0xFFD2C4B7),
    inkTertiary: Color(0xFFC5BAB0),
    line: Color(0xFF8A7666),
    sage: Color(0xFF9BD7B1),
    sageSoft: Color(0xFF2C3D31),
    onSage: Color(0xFF0B1A10),
    terracotta: Color(0xFFEDB99C),
    terracottaSoft: Color(0xFF4A2E22),
    water: Color(0xFFA7C7EA),
    waterSoft: Color(0xFF2B3644),
    sun: Color(0xFFEAC970),
    sunSoft: Color(0xFF45391F),
    rose: Color(0xFFF2B2BD),
    roseSoft: Color(0xFF4A2C31),
    danger: Color(0xFFEC9990),
    shadow: Color(0x00000000),
    brightness: Brightness.dark,
  );

  /// Ce qu'on pose sur un accent employé comme fond — le libellé de
  /// « Arroser », le chiffre du héros du matin.
  ///
  /// Une seule valeur par thème suffit : les accents sont tous sombres en
  /// clair et tous clairs en sombre, c'est la règle que fait respecter le
  /// contrat ci-dessus. Écrire `Colors.white` en dur, comme avant, donnait
  /// 1,7:1 sur l'ocre du thème sombre.
  Color get onAccent => onSage;

  /// Interpolation utilisée par [ThemeExtension.lerp] lors des changements de thème.
  FloraColors lerp(FloraColors other, double t) => FloraColors(
        canvas: Color.lerp(canvas, other.canvas, t)!,
        surface: Color.lerp(surface, other.surface, t)!,
        surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
        surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
        ink: Color.lerp(ink, other.ink, t)!,
        inkSecondary: Color.lerp(inkSecondary, other.inkSecondary, t)!,
        inkTertiary: Color.lerp(inkTertiary, other.inkTertiary, t)!,
        line: Color.lerp(line, other.line, t)!,
        sage: Color.lerp(sage, other.sage, t)!,
        sageSoft: Color.lerp(sageSoft, other.sageSoft, t)!,
        onSage: Color.lerp(onSage, other.onSage, t)!,
        terracotta: Color.lerp(terracotta, other.terracotta, t)!,
        terracottaSoft: Color.lerp(terracottaSoft, other.terracottaSoft, t)!,
        water: Color.lerp(water, other.water, t)!,
        waterSoft: Color.lerp(waterSoft, other.waterSoft, t)!,
        sun: Color.lerp(sun, other.sun, t)!,
        sunSoft: Color.lerp(sunSoft, other.sunSoft, t)!,
        rose: Color.lerp(rose, other.rose, t)!,
        roseSoft: Color.lerp(roseSoft, other.roseSoft, t)!,
        danger: Color.lerp(danger, other.danger, t)!,
        shadow: Color.lerp(shadow, other.shadow, t)!,
        brightness: t < 0.5 ? brightness : other.brightness,
      );
}
