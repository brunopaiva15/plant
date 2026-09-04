import 'package:flutter/material.dart';

/// Hiérarchie typographique. Police système (SF Pro sur iOS, Roboto sur Android).
///
/// Sept styles seulement : trop de tailles nuit à la cohérence.
class FloraTypography {
  const FloraTypography._(this._ink, this._secondary);

  final Color _ink;
  final Color _secondary;

  factory FloraTypography.forColors({required Color ink, required Color secondary}) =>
      FloraTypography._(ink, secondary);

  TextStyle get display => TextStyle(
        fontSize: 34,
        height: 1.15,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: _ink,
      );

  TextStyle get title1 => TextStyle(
        fontSize: 28,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: _ink,
      );

  TextStyle get title2 => TextStyle(
        fontSize: 22,
        height: 1.25,
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
