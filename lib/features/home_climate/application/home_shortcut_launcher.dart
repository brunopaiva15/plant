import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';

/// Le raccourci « Climat Auxine », depuis l'application.
///
/// iOS ne laisse aucune app créer une automatisation ni lire un HomePod.
/// Il laisse deux gestes : ouvrir un raccourci partagé pour l'ajouter d'un
/// tap, et lancer un raccourci par son nom avec un retour vers l'app
/// (x-callback-url). Le retour arrive en `auxine://home-climate/updated`
/// ou `…/failed`, que `openFloraLink` traite.
abstract final class HomeShortcut {
  /// Le raccourci partagé est-il disponible ? Sans lien iCloud dans la
  /// configuration, il reste à construire à la main.
  static bool get canAdd => AppConfig.homeShortcutUrl.isNotEmpty;

  static Uri get addUri => Uri.parse(AppConfig.homeShortcutUrl);

  static Uri get runUri => Uri(
        scheme: 'shortcuts',
        host: 'x-callback-url',
        path: '/run-shortcut',
        queryParameters: {
          'name': AppConfig.homeShortcutName,
          'x-success': '${AppConfig.linkScheme}://home-climate/updated',
          'x-error': '${AppConfig.linkScheme}://home-climate/failed',
          'x-cancel': '${AppConfig.linkScheme}://home-climate/failed',
        },
      );

  static Future<bool> add() => launchUrl(addUri, mode: LaunchMode.externalApplication);

  /// Lance le raccourci ; `false` si Raccourcis n'a pas pu être ouvert.
  static Future<bool> run() => launchUrl(runUri, mode: LaunchMode.externalApplication);

  static Future<bool> openShortcuts() => launchUrl(Uri.parse('shortcuts://'), mode: LaunchMode.externalApplication);
}
