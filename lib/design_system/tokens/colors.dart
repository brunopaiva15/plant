import 'package:flutter/material.dart';

/// Palette Flora : un vert franc en tête d'écran, une feuille crème dessous,
/// une encre presque noire, et trois couleurs vives pour ce qui compte
/// aujourd'hui — l'orange de la terre cuite, le jaune du soleil, le bleu de
/// l'eau.
///
/// ## Deux familles d'accents
///
/// - Les **accents de texte** (`sage`, `terracotta`, `water`, `sun`, `rose`,
///   `danger`) écrivent sur la feuille et sur leur pastel : l'échéance d'une
///   pastille, le nom d'un soin. Ils sont sombres en clair, clairs en sombre.
/// - Les **accents vifs** (`brand`, `terracottaPop`, `sunPop`, `waterPop`)
///   sont des fonds pleins : la tête verte d'un écran, le bouton « Arroser »,
///   la carte du prochain soin. Ils gardent leur éclat dans les deux thèmes ;
///   le blanc va sur `brand`, l'encre [onPop] sur les trois autres.
///
/// ## Le contrat de contraste
///
/// `colors_contrast_test.dart` le vérifie :
///
/// - encre, encre secondaire et encre tertiaire : **≥ 4.5:1** sur `canvas`,
///   `surface` et `surfaceMuted` — l'encre tertiaire porte les libellés des
///   champs, elle ne peut pas se contenter d'un gris décoratif ;
/// - `sage`, `terracotta`, `water`, `danger` : **≥ 4.5:1** sur ces fonds et
///   sur leur pastel — ils portent du texte de 13 pt ;
/// - `sun` et `rose` ne servent que d'icônes : **≥ 3:1** suffit ;
/// - tout accent de texte employé comme fond porte [onAccent], **≥ 4.5:1** ;
/// - [onBrand] sur `brand` et [onPop] sur les accents vifs : **≥ 4.5:1**.
///
/// Les séparateurs (`line`) restent volontairement ténus — ils ne portent
/// aucune information — et ne se renforcent qu'en contraste élevé.
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
    required this.brand,
    required this.onBrand,
    required this.terracottaPop,
    required this.sunPop,
    required this.waterPop,
    required this.onPop,
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

  /// Le vert des têtes d'écran, sous du blanc.
  final Color brand;
  final Color onBrand;

  /// Les accents vifs, des fonds pleins sous l'encre [onPop].
  final Color terracottaPop;
  final Color sunPop;
  final Color waterPop;
  final Color onPop;
  final Color shadow;
  final Brightness brightness;

  bool get isDark => brightness == Brightness.dark;

  static const light = FloraColors(
    canvas: Color(0xFFFFFBF4),
    surface: Color(0xFFF4ECE0),
    surfaceMuted: Color(0xFFEDE3D4),
    surfaceElevated: Color(0xFFFFFFFF),
    ink: Color(0xFF1C1712),
    inkSecondary: Color(0xFF66594D),
    inkTertiary: Color(0xFF66594D),
    line: Color(0xFFE8DDCC),
    sage: Color(0xFF2A7447),
    sageSoft: Color(0xFFDDF0E2),
    onSage: Color(0xFFFFFFFF),
    terracotta: Color(0xFF9A3E1A),
    terracottaSoft: Color(0xFFFFE0D2),
    water: Color(0xFF1B5E96),
    waterSoft: Color(0xFFD9EEFF),
    sun: Color(0xFF7A5F00),
    sunSoft: Color(0xFFFFF4B8),
    rose: Color(0xFFB83A55),
    roseSoft: Color(0xFFFFDDE4),
    danger: Color(0xFFB8321F),
    brand: Color(0xFF358354),
    onBrand: Color(0xFFFFFFFF),
    terracottaPop: Color(0xFFFF7B45),
    sunPop: Color(0xFFFFE14D),
    waterPop: Color(0xFF5DB7FF),
    onPop: Color(0xFF1C1712),
    shadow: Color(0x1F3A2A1A),
    brightness: Brightness.light,
  );

  /// Sombre : la feuille passe au brun de nuit, les accents de texte
  /// s'éclaircissent ; la tête verte et les accents vifs, eux, ne bougent pas.
  static const dark = FloraColors(
    canvas: Color(0xFF17130F),
    surface: Color(0xFF261F19),
    surfaceMuted: Color(0xFF31281F),
    surfaceElevated: Color(0xFF3A3027),
    ink: Color(0xFFF6EFE4),
    inkSecondary: Color(0xFFBCAC9C),
    inkTertiary: Color(0xFFAE9E8F),
    line: Color(0xFF3A3027),
    sage: Color(0xFF74CF95),
    sageSoft: Color(0xFF1F3527),
    onSage: Color(0xFF17130F),
    terracotta: Color(0xFFFF9A6E),
    terracottaSoft: Color(0xFF45251A),
    water: Color(0xFF8CCBFF),
    waterSoft: Color(0xFF1B3247),
    sun: Color(0xFFFFD84D),
    sunSoft: Color(0xFF3D3414),
    rose: Color(0xFFF58CA0),
    roseSoft: Color(0xFF45222B),
    danger: Color(0xFFFF8373),
    brand: Color(0xFF358354),
    onBrand: Color(0xFFFFFFFF),
    terracottaPop: Color(0xFFFF7B45),
    sunPop: Color(0xFFFFE14D),
    waterPop: Color(0xFF5DB7FF),
    onPop: Color(0xFF1C1712),
    shadow: Color(0x00000000),
    brightness: Brightness.dark,
  );

  /// Contraste élevé (« Augmenter le contraste » dans Réglages > Accessibilité).
  ///
  /// Mêmes fonds, mêmes teintes : seule la clarté des encres et des accents
  /// bouge. Le texte vise AAA (≥ 7:1), les icônes 4.5:1, et les séparateurs
  /// deviennent enfin visibles — c'est la première chose que ce réglage est
  /// censé rendre.
  static const lightHighContrast = FloraColors(
    canvas: Color(0xFFFFFBF4),
    surface: Color(0xFFF4ECE0),
    surfaceMuted: Color(0xFFEDE3D4),
    surfaceElevated: Color(0xFFFFFFFF),
    ink: Color(0xFF120E0A),
    inkSecondary: Color(0xFF43392F),
    inkTertiary: Color(0xFF43392F),
    line: Color(0xFF94836F),
    sage: Color(0xFF1D5634),
    sageSoft: Color(0xFFDDF0E2),
    onSage: Color(0xFFFFFFFF),
    terracotta: Color(0xFF6E2A0F),
    terracottaSoft: Color(0xFFFFE0D2),
    water: Color(0xFF12436C),
    waterSoft: Color(0xFFD9EEFF),
    sun: Color(0xFF5E4900),
    sunSoft: Color(0xFFFFF4B8),
    rose: Color(0xFF8E2A40),
    roseSoft: Color(0xFFFFDDE4),
    danger: Color(0xFF86220F),
    brand: Color(0xFF1F5E38),
    onBrand: Color(0xFFFFFFFF),
    terracottaPop: Color(0xFFFF8A5A),
    sunPop: Color(0xFFFFE14D),
    waterPop: Color(0xFF70C0FF),
    onPop: Color(0xFF120E0A),
    shadow: Color(0x333A2A1A),
    brightness: Brightness.light,
  );

  /// Contraste élevé, en sombre.
  static const darkHighContrast = FloraColors(
    canvas: Color(0xFF17130F),
    surface: Color(0xFF261F19),
    surfaceMuted: Color(0xFF31281F),
    surfaceElevated: Color(0xFF3A3027),
    ink: Color(0xFFFFFFFF),
    inkSecondary: Color(0xFFDCD0C4),
    inkTertiary: Color(0xFFD2C6BA),
    line: Color(0xFF8A7866),
    sage: Color(0xFFA6E6BC),
    sageSoft: Color(0xFF1F3527),
    onSage: Color(0xFF17130F),
    terracotta: Color(0xFFFFBFA2),
    terracottaSoft: Color(0xFF45251A),
    water: Color(0xFFB8DEFF),
    waterSoft: Color(0xFF1B3247),
    sun: Color(0xFFFFE68A),
    sunSoft: Color(0xFF3D3414),
    rose: Color(0xFFFFB8C5),
    roseSoft: Color(0xFF45222B),
    danger: Color(0xFFFFB0A6),
    brand: Color(0xFF1F5E38),
    onBrand: Color(0xFFFFFFFF),
    terracottaPop: Color(0xFFFF8A5A),
    sunPop: Color(0xFFFFE14D),
    waterPop: Color(0xFF70C0FF),
    onPop: Color(0xFF120E0A),
    shadow: Color(0x00000000),
    brightness: Brightness.dark,
  );

  /// Ce qu'on pose sur un accent employé comme fond — le libellé de
  /// « Arroser », le chiffre du héros du matin.
  ///
  /// Une seule valeur par thème suffit : les accents de texte sont tous
  /// sombres en clair et tous clairs en sombre, c'est la règle que fait
  /// respecter le contrat ci-dessus. Écrire `Colors.white` en dur donnait
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
        brand: Color.lerp(brand, other.brand, t)!,
        onBrand: Color.lerp(onBrand, other.onBrand, t)!,
        terracottaPop: Color.lerp(terracottaPop, other.terracottaPop, t)!,
        sunPop: Color.lerp(sunPop, other.sunPop, t)!,
        waterPop: Color.lerp(waterPop, other.waterPop, t)!,
        onPop: Color.lerp(onPop, other.onPop, t)!,
        shadow: Color.lerp(shadow, other.shadow, t)!,
        brightness: t < 0.5 ? brightness : other.brightness,
      );
}

/// Ce qu'on pose **sur une image** : les commandes du viseur de l'étape photo
/// — la galerie dans un coin du cadre, la croix d'une vue de plus.
///
/// Elles sont hors du contrat des palettes, comme la marque d'Iris, et pour la
/// même raison : ce qu'elles ont dessous n'est pas un fond du thème, c'est un
/// cadrage. Leur pastille est donc blanche des deux côtés — et l'encre qui va
/// dessus doit l'être aussi. Prendre `ink`, comme avant, la faisait tourner au
/// crème en thème sombre : l'icône s'effaçait dans sa pastille, à 1,2:1.
abstract final class OnMedia {
  /// La pastille : du blanc presque plein, pour tenir aussi bien sur un
  /// cadrage clair que sur un cadrage sombre.
  static const Color tile = Color(0xD9FFFFFF);

  /// Ce qu'on dessine dessus : l'encre du thème clair, figée. 12:1 sur la
  /// pastille au pire du fondu, dans les quatre palettes.
  static const Color ink = Color(0xFF1C1712);
}
