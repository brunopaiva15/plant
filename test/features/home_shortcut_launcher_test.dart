import 'package:flora/core/config/app_config.dart';
import 'package:flora/features/home_climate/application/home_shortcut_launcher.dart';
import 'package:flutter_test/flutter_test.dart';

/// Le lancement du raccourci passe par x-callback-url, avec un retour vers
/// l'application dans les deux issues.
void main() {
  test("l'URL de lancement nomme le raccourci et prévoit le retour", () {
    final uri = HomeShortcut.runUri;
    expect(uri.scheme, 'shortcuts');
    expect(uri.host, 'x-callback-url');
    expect(uri.path, '/run-shortcut');
    expect(uri.queryParameters['name'], AppConfig.homeShortcutName);
    expect(uri.queryParameters['x-success'], 'auxine://home-climate/updated');
    expect(uri.queryParameters['x-error'], 'auxine://home-climate/failed');
    expect(uri.queryParameters['x-cancel'], 'auxine://home-climate/failed');
  });

  test('sans lien partagé configuré, rien à ajouter', () {
    expect(HomeShortcut.canAdd, AppConfig.homeShortcutUrl.isNotEmpty);
  });
}
