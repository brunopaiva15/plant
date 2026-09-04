import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/care/reminder_planner.dart';
import '../../today/application/reminder_scheduler.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final prefs = ref.watch(preferencesProvider);
    final ctrl = ref.read(preferencesProvider.notifier);
    final scheduler = ref.read(reminderSchedulerProvider);
    final weekdays = [for (var d = 1; d <= 7; d++) DateTime(2026, 9, 6 + d)]; // 2026-09-07 est un lundi.
    final preview = ReminderScheduler.buildBody(l10n, const ReminderDigest(byType: {'watering': ['Monstera', 'Pilea'], 'fertilizing': ['Ficus']}, totalPlants: 3));

    Future<void> toggle(bool v) async {
      if (v) {
        final granted = await ref.read(notificationServiceProvider).requestPermission();
        if (!granted) {
          ref.read(toastProvider.notifier).show(ToastData(message: l10n.notificationPermissionDenied, emoji: '!'));
          return;
        }
      }
      await ctrl.setNotificationsEnabled(v);
      await scheduler.reschedule();
    }

    return FloraPage(
      title: l10n.notifications,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FloraGroup(
            footer: l10n.notificationHint,
            children: [
              FloraListRow(leading: const Text('🔔', style: TextStyle(fontSize: 18)), title: l10n.enableNotifications, trailing: AdaptiveSwitch(value: prefs.notificationsEnabled, onChanged: toggle)),
              FloraListRow(
                leading: const Text('🕘', style: TextStyle(fontSize: 18)),
                title: l10n.notificationTime,
                trailing: Text(
                  MaterialLocalizations.of(context).formatTimeOfDay(prefs.notificationTime, alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context)),
                  style: context.text.callout.copyWith(color: c.sage, fontWeight: FontWeight.w600),
                ),
                chevron: false,
                onTap: () async {
                  final t = await showAdaptiveTimePicker(context, initial: prefs.notificationTime, doneLabel: l10n.done);
                  if (t == null) return;
                  await ctrl.setNotificationTime(t);
                  await scheduler.reschedule();
                },
              ),
            ],
          ),
          const SizedBox(height: Space.xl),
          Padding(padding: const EdgeInsets.only(left: Space.md, bottom: Space.xs), child: Text(l10n.quietDays.toUpperCase(), style: context.text.caption.copyWith(letterSpacing: 0.4))),
          Row(
            children: [
              for (final d in weekdays)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Pressable(
                      onTap: () async {
                        final set = {...prefs.quietWeekdays};
                        set.contains(d.weekday) ? set.remove(d.weekday) : set.add(d.weekday);
                        await ctrl.setQuietWeekdays(set);
                        await scheduler.reschedule();
                      },
                      scale: 0.9,
                      child: AnimatedContainer(
                        duration: Motion.of(context, Motion.standard),
                        height: 44,
                        decoration: BoxDecoration(
                          color: prefs.quietWeekdays.contains(d.weekday) ? c.ink : c.surface,
                          borderRadius: Radii.mediumAll,
                          border: Border.all(color: c.line),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          Dates.weekdayShort(context, d).replaceAll('.', ''),
                          style: context.text.caption.copyWith(color: prefs.quietWeekdays.contains(d.weekday) ? c.canvas : c.ink, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: Space.xl),
          Padding(padding: const EdgeInsets.only(left: Space.md, bottom: Space.xs), child: Text(l10n.notificationPreview.toUpperCase(), style: context.text.caption.copyWith(letterSpacing: 0.4))),
          FloraCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const EmojiTile(emoji: '🌿', size: 36),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [Text(l10n.notificationTitle, style: context.text.title3), const SizedBox(height: 2), Text(preview, style: context.text.callout)],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
