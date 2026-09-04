import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../application/reminder_scheduler.dart';

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
    final granted = await ref.read(notificationServiceProvider).requestPermission();
    if (granted) {
      await ref.read(preferencesProvider.notifier).setNotificationsEnabled(true);
      await ref.read(reminderSchedulerProvider).reschedule();
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
    return AnimatedSize(
      duration: Motion.of(context, Motion.emphasis),
      curve: Motion.emphasized,
      child: !show
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.fromLTRB(Space.page, Space.md, Space.page, 0),
              child: FloraCard(
                color: context.colors.sageSoft,
                padding: const EdgeInsets.all(Space.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('🔔', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: Space.xs),
                        Expanded(child: Text(l10n.notificationAskTitle, style: context.text.title3)),
                      ],
                    ),
                    const SizedBox(height: Space.xs),
                    Text(l10n.notificationAskBody, style: context.text.callout),
                    const SizedBox(height: Space.md),
                    Wrap(
                      spacing: Space.xs,
                      runSpacing: Space.xs,
                      children: [
                        FloraButton(label: l10n.enable, size: FloraButtonSize.small, onPressed: _enable),
                        FloraButton(label: l10n.notNow, size: FloraButtonSize.small, style: FloraButtonStyle.ghost, onPressed: _dismiss),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

final _hasAnyActionProvider = StreamProvider.autoDispose<bool>(
  (ref) => ref.watch(actionRepositoryProvider).watchRecent(limit: 1).map((l) => l.isNotEmpty),
);
