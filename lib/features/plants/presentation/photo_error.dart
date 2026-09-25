import 'package:flutter/cupertino.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/system_settings.dart';
import '../../../data/services/photo_storage_service.dart';
import '../../../design_system/design_system.dart';

/// Le toast d'une photo qui n'est pas arrivée, d'où qu'elle vienne.
///
/// Un accès refusé ne se règle pas en réessayant : iOS ne repose jamais la
/// question. Le toast dit quoi autoriser et, sur iOS, mène aux Réglages.
/// Toute autre erreur garde le message générique.
ToastData photoErrorToast(AppLocalizations l10n, Object error) {
  if (error is! PhotoAccessDenied) return ToastData(message: l10n.photoError, emoji: '!');
  final settings = SystemSettings.isSupported;
  return ToastData(
    message: error.source == PhotoSource.camera ? l10n.cameraPermission : l10n.photoLibraryPermission,
    emoji: '!',
    undoLabel: settings ? l10n.settingsShort : null,
    onUndo: settings ? SystemSettings.open : null,
    actionIcon: CupertinoIcons.gear,
  );
}
