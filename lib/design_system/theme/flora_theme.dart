import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radius.dart';
import '../tokens/typography.dart';

/// Extension de thème exposant les tokens Flora à toute l'arborescence.
class FloraTheme extends ThemeExtension<FloraTheme> {
  const FloraTheme({required this.colors, required this.text});

  final FloraColors colors;
  final FloraTypography text;

  static FloraTheme fromColors(FloraColors colors) => FloraTheme(
        colors: colors,
        text: FloraTypography.forColors(ink: colors.ink, secondary: colors.inkSecondary),
      );

  @override
  FloraTheme copyWith({FloraColors? colors, FloraTypography? text}) =>
      FloraTheme(colors: colors ?? this.colors, text: text ?? this.text);

  @override
  FloraTheme lerp(ThemeExtension<FloraTheme>? other, double t) {
    if (other is! FloraTheme) return this;
    return FloraTheme.fromColors(colors.lerp(other.colors, t));
  }
}

extension FloraThemeContext on BuildContext {
  FloraTheme get flora => Theme.of(this).extension<FloraTheme>()!;
  FloraColors get colors => flora.colors;
  /// La typographie du thème, épaissie si « Texte en gras » est actif.
  ///
  /// Le passage se fait ici, au seul endroit où toute l'application lit ses
  /// styles : les grands titres suivent alors le réglage comme le reste.
  FloraTypography get text => MediaQuery.boldTextOf(this) ? flora.text.bolder : flora.text;
  bool get isIOS => Theme.of(this).platform == TargetPlatform.iOS;
}

/// Construit le [ThemeData] Material 3 aligné sur les tokens Flora.
///
/// [highContrast] sert les thèmes que `MaterialApp` choisit quand
/// « Augmenter le contraste » est actif dans les réglages d'accessibilité.
ThemeData buildFloraTheme(Brightness brightness, {bool highContrast = false}) {
  final dark = brightness == Brightness.dark;
  final c = switch ((dark, highContrast)) {
    (true, true) => FloraColors.darkHighContrast,
    (true, false) => FloraColors.dark,
    (false, true) => FloraColors.lightHighContrast,
    (false, false) => FloraColors.light,
  };
  final ext = FloraTheme.fromColors(c);
  final scheme = ColorScheme(
    brightness: brightness,
    primary: c.sage,
    onPrimary: c.onSage,
    secondary: c.terracotta,
    onSecondary: c.surface,
    error: c.danger,
    onError: c.surface,
    surface: c.canvas,
    onSurface: c.ink,
    surfaceContainerHighest: c.surfaceMuted,
    onSurfaceVariant: c.inkSecondary,
    outline: c.line,
    outlineVariant: c.line,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: c.canvas,
    canvasColor: c.canvas,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    splashColor: Colors.transparent,
    dividerColor: c.line,
    extensions: [ext],
    textTheme: TextTheme(
      displayLarge: ext.text.display,
      headlineLarge: ext.text.title1,
      headlineMedium: ext.text.title2,
      titleMedium: ext.text.title3,
      bodyLarge: ext.text.body,
      bodyMedium: ext.text.callout,
      labelSmall: ext.text.caption,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: c.canvas,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      foregroundColor: c.ink,
      centerTitle: true,
      titleTextStyle: ext.text.title3,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: Radii.sheetTop),
      showDragHandle: false,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: Radii.largeAll),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: c.ink,
      contentTextStyle: ext.text.callout.copyWith(color: c.canvas),
      behavior: SnackBarBehavior.floating,
      shape: const RoundedRectangleBorder(borderRadius: Radii.mediumAll),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
      },
    ),
    cupertinoOverrideTheme: CupertinoThemeData(
      brightness: brightness,
      primaryColor: c.sage,
      scaffoldBackgroundColor: c.canvas,
      barBackgroundColor: c.canvas,
      textTheme: CupertinoTextThemeData(
        primaryColor: c.sage,
        textStyle: ext.text.body,
        actionTextStyle: ext.text.body.copyWith(color: c.sage),
        navTitleTextStyle: ext.text.title3,
        navLargeTitleTextStyle: ext.text.display,
        navActionTextStyle: ext.text.body.copyWith(color: c.sage, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surfaceMuted,
      border: const OutlineInputBorder(borderRadius: Radii.mediumAll, borderSide: BorderSide.none),
      enabledBorder: const OutlineInputBorder(borderRadius: Radii.mediumAll, borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: Radii.mediumAll, borderSide: BorderSide(color: c.sage, width: 1.5)),
      hintStyle: ext.text.body.copyWith(color: c.inkTertiary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStatePropertyAll(c.surface),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? c.sage : c.line,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
  );
}
