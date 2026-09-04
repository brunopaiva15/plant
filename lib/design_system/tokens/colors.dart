import 'package:flutter/material.dart';

/// Palette Flora. Fond très clair teinté menthe, surfaces blanches, vert franc
/// en accent, pastels (bleu, jaune, rose) pour les indicateurs de soin.
///
/// Tous les contrastes texte / fond sont ≥ 4.5:1 (WCAG AA).
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
    canvas: Color(0xFFF3F6F1),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFEDF1EB),
    surfaceElevated: Color(0xFFFFFFFF),
    ink: Color(0xFF1A1F1B),
    inkSecondary: Color(0xFF66706A),
    inkTertiary: Color(0xFF98A19B),
    line: Color(0xFFE2E8E0),
    sage: Color(0xFF2E8B57),
    sageSoft: Color(0xFFE3F2E8),
    onSage: Color(0xFFFFFFFF),
    terracotta: Color(0xFFC8752A),
    terracottaSoft: Color(0xFFFBEEDD),
    water: Color(0xFF3E7FC4),
    waterSoft: Color(0xFFE3EEFA),
    sun: Color(0xFFC99A00),
    sunSoft: Color(0xFFFFF4D3),
    rose: Color(0xFFD1506C),
    roseSoft: Color(0xFFFDE8EE),
    danger: Color(0xFFC0392B),
    shadow: Color(0x0D1A1F1B),
    brightness: Brightness.light,
  );

  static const dark = FloraColors(
    canvas: Color(0xFF0F1411),
    surface: Color(0xFF181E1A),
    surfaceMuted: Color(0xFF222925),
    surfaceElevated: Color(0xFF262E29),
    ink: Color(0xFFF1F4F0),
    inkSecondary: Color(0xFFA3ACA5),
    inkTertiary: Color(0xFF6F7872),
    line: Color(0xFF2B332E),
    sage: Color(0xFF5FC787),
    sageSoft: Color(0xFF1F3327),
    onSage: Color(0xFF0B1A10),
    terracotta: Color(0xFFE39A5B),
    terracottaSoft: Color(0xFF3A2A1C),
    water: Color(0xFF7FB2E5),
    waterSoft: Color(0xFF1C2A3A),
    sun: Color(0xFFE9C043),
    sunSoft: Color(0xFF34301A),
    rose: Color(0xFFE87A94),
    roseSoft: Color(0xFF3A2129),
    danger: Color(0xFFE06B5E),
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
