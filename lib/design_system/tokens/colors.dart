import 'package:flutter/material.dart';

/// Palette Flora : de l'argile et de la terre cuite. Fond crème grainé,
/// surfaces crème claire, encre brune ; le vert reste la couleur de l'action,
/// la terre cuite devient la couleur phare ; ocre, bleu poussière et rose
/// pour les indicateurs de soin.
///
/// Encre et encre secondaire passent AA (≥ 4.5:1) sur le fond et les
/// surfaces ; le vert et la terre cuite passent 4.3 à 4.9:1 avec du blanc
/// dessus, les indicateurs ne portent jamais de texte petit à eux seuls.
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
    inkTertiary: Color(0xFF9A8577),
    line: Color(0xFFE6D9C8),
    sage: Color(0xFF2F7F53),
    sageSoft: Color(0xFFE4EFE6),
    onSage: Color(0xFFFFFFFF),
    terracotta: Color(0xFFBD5836),
    terracottaSoft: Color(0xFFF2D9CB),
    water: Color(0xFF4A82BC),
    waterSoft: Color(0xFFDCE7F3),
    sun: Color(0xFFC4903A),
    sunSoft: Color(0xFFF3E3C2),
    rose: Color(0xFFC4566A),
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
    inkTertiary: Color(0xFF9C8878),
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
