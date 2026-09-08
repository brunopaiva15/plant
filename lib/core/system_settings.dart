import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Le raccourci vers la fiche de l'application dans les Réglages du système.
///
/// Une permission refusée ne se redemande pas : iOS ne repose jamais la
/// question deux fois. Sans ce raccourci, l'écran des rappels était une
/// impasse — un interrupteur qui refuse de s'allumer et une phrase qui dit
/// « allez dans les Réglages », sans y mener.
///
/// Android n'ouvre pas sa fiche d'application par une simple URL : là-bas
/// [isSupported] répond faux et l'appelant se contente de la phrase.
abstract final class SystemSettings {
  static bool get isSupported => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// Ouvre les Réglages. Retourne `false` si le système a refusé.
  static Future<bool> open() async {
    if (!isSupported) return false;
    final uri = Uri.parse('app-settings:');
    try {
      return await launchUrl(uri);
    } on Exception {
      return false;
    }
  }
}
