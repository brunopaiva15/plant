import 'package:flutter/services.dart';

/// Retours haptiques, utilisés avec modération.
///
/// Vocabulaire volontairement réduit pour rester cohérent dans toute l'app.
abstract final class Haptics {
  /// Changement de sélection (chip, onglet, segment).
  static Future<void> selection() => HapticFeedback.selectionClick();

  /// Tap sur un bouton.
  static Future<void> light() => HapticFeedback.lightImpact();

  /// Action enregistrée (arrosage, création…).
  static Future<void> success() => HapticFeedback.mediumImpact();

  /// Action sensible (archivage, suppression).
  static Future<void> warning() => HapticFeedback.heavyImpact();
}
