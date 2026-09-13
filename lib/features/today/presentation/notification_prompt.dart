import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/system_settings.dart';
import '../../../design_system/design_system.dart';
import '../application/reminder_scheduler.dart';
import 'today_notice.dart';

/// Proposition contextuelle d'activer les rappels : n'apparaît qu'une fois,
/// après qu'au moins une action a été enregistrée, jamais au lancement.
class NotificationPrompt extends ConsumerStatefulWidget {
  const NotificationPrompt({super.key});

  @override
  ConsumerState<NotificationPrompt> createState() => _NotificationPromptState();
}

class _NotificationPromptState extends ConsumerState<NotificationPrompt> {
  bool _hidden = false;

  Future<void> _dismiss() async {
    await ref.read(preferencesServiceProvider).setNotificationPromptShown();
    if (mounted) setState(() => _hidden = true);
  }

  Future<void> _enable() async {
    final l10n = context.l10n;
    final granted = await ref.read(notificationServiceProvider).requestPermission();
    if (granted) {
      await ref.read(preferencesProvider.notifier).setNotificationsEnabled(true);
      await ref.read(reminderSchedulerProvider).reschedule();
    } else if (mounted && SystemSettings.isSupported) {
      // Refus définitif : on propose le seul chemin qui reste.
      final go = await showAdaptiveConfirm(
        context,
        title: l10n.notificationAskTitle,
        message: l10n.notificationPermissionDenied,
        confirmLabel: l10n.openSettings,
        cancelLabel: l10n.later,
      );
      if (go) await SystemSettings.open();
    }
    await _dismiss();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final service = ref.watch(preferencesServiceProvider);
    final prefs = ref.watch(preferencesProvider);
    final hasActions = ref.watch(_hasAnyActionProvider).value ?? false;
    final show = !_hidden && !service.notificationPromptShown && !prefs.notificationsEnabled && hasActions;
    return TodayNoticeSlot(
      visible: show,
      child: !show
          ? const SizedBox.shrink()
          : TodayNotice(
              emoji: '🔔',
              color: context.colors.sageSoft,
              title: l10n.notificationAskTitle,
              body: l10n.notificationAskBody,
              actions: [
                FloraButton(label: l10n.enable, size: FloraButtonSize.small, onPressed: _enable),
                FloraButton(label: l10n.notNow, size: FloraButtonSize.small, style: FloraButtonStyle.ghost, onPressed: _dismiss),
              ],
            ),
    );
  }
}

final _hasAnyActionProvider = StreamProvider.autoDispose<bool>(
  (ref) => ref.watch(actionRepositoryProvider).watchRecent(limit: 1).map((l) => l.isNotEmpty),
);
