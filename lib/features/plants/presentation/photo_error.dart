import 'package:flutter/cupertino.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/l10n/platform_copy.dart';
import '../../../core/system_settings.dart';
import '../../../data/services/photo_storage_service.dart';
import '../../../design_system/design_system.dart';

/// Le toast d'une photo qui n'est pas arrivée, d'où qu'elle vienne.
///
/// Un accès refusé ne se règle pas en réessayant : iOS ne repose jamais la
/// question, Android cesse après le deuxième refus. Le toast dit quoi
/// autoriser et mène aux réglages du système.
/// Toute autre erreur garde le message générique.
ToastData photoErrorToast(AppLocalizations l10n, Object error) {
  if (error is! PhotoAccessDenied) return ToastData(message: l10n.photoError, emoji: '!');
  final settings = SystemSettings.isSupported;
  return ToastData(
    message: error.source == PhotoSource.camera ? l10n.cameraDeniedHint : l10n.photosDeniedHint,
    emoji: '!',
    undoLabel: settings ? l10n.systemSettingsShort : null,
    onUndo: settings ? SystemSettings.open : null,
    actionIcon: CupertinoIcons.gear,
  );
}
