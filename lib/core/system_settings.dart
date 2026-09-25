import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Le raccourci vers la fiche de l'application dans les réglages du système.
///
/// Une permission refusée ne se redemande pas : iOS ne repose jamais la
/// question deux fois, Android cesse après le deuxième refus. Sans ce
/// raccourci, l'écran des rappels était une impasse — un interrupteur qui
/// refuse de s'allumer et une phrase qui dit « allez dans les Réglages »,
/// sans y mener.
///
/// iOS ouvre sa fiche par une URL (`app-settings:`). Android demande une
/// intention, que `url_launcher` ne sait pas construire : elle passe par un
/// canal (`android/.../SystemSettingsChannel.kt`).
abstract final class SystemSettings {
  static const MethodChannel _android = MethodChannel('ch.vergasta.plant/system_settings');

  static bool get isSupported =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android);

  /// Ouvre les réglages. Retourne `false` si le système a refusé.
  static Future<bool> open() async {
    if (!isSupported) return false;
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        return await _android.invokeMethod<bool>('open') ?? false;
      }
      return await launchUrl(Uri.parse('app-settings:'));
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    } on Exception {
      return false;
    }
  }
}
