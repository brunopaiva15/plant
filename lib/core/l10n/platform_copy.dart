import 'package:flutter/foundation.dart';

import '../../l10n/generated/app_localizations.dart';

/// Les textes qui nomment le système : l'app des réglages s'appelle
/// « Réglages » sur iPhone et « Paramètres » sur Android, et une consigne qui
/// envoie vers un écran au mauvais nom ne mène nulle part. En anglais, en
/// allemand et en italien les deux se disent pareil — sauf les
/// « Mitteilungen » d'iOS, qu'Android appelle « Benachrichtigungen ».
extension PlatformCopy on AppLocalizations {
  bool get _android => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  String get systemSettingsShort => _android ? settingsShortAndroid : settingsShort;

  String get openSystemSettings => _android ? openSettingsAndroid : openSettings;

  String get notificationsDeniedHint => _android ? notificationPermissionDeniedAndroid : notificationPermissionDenied;

  String get cameraDeniedHint => _android ? cameraPermissionAndroid : cameraPermission;

  String get photosDeniedHint => _android ? photoLibraryPermissionAndroid : photoLibraryPermission;
}
