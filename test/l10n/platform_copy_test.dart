import 'package:flora/core/l10n/platform_copy.dart';
import 'package:flora/l10n/generated/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Une consigne qui envoie vers « Réglages » sur un Android, où l'écran
/// s'appelle « Paramètres », ne mène nulle part.
void main() {
  Future<AppLocalizations> fr() => AppLocalizations.delegate.load(const Locale('fr'));

  String on(TargetPlatform platform, String Function(AppLocalizations l10n) text, AppLocalizations l10n) {
    debugDefaultTargetPlatformOverride = platform;
    try {
      return text(l10n);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  }

  test('iPhone : les Réglages', () async {
    final l10n = await fr();
    expect(on(TargetPlatform.iOS, (l) => l.openSystemSettings, l10n), contains('Réglages'));
    expect(on(TargetPlatform.iOS, (l) => l.cameraDeniedHint, l10n), contains('Réglages'));
    expect(on(TargetPlatform.iOS, (l) => l.systemSettingsShort, l10n), 'Réglages');
  });

  test('Android : les Paramètres, jamais les Réglages', () async {
    final l10n = await fr();
    final texts = [
      on(TargetPlatform.android, (l) => l.openSystemSettings, l10n),
      on(TargetPlatform.android, (l) => l.notificationsDeniedHint, l10n),
      on(TargetPlatform.android, (l) => l.cameraDeniedHint, l10n),
      on(TargetPlatform.android, (l) => l.photosDeniedHint, l10n),
      on(TargetPlatform.android, (l) => l.systemSettingsShort, l10n),
    ];
    for (final text in texts) {
      expect(text, contains('Paramètres'));
      expect(text, isNot(contains('Réglages')));
    }
  });
}
