import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/l10n/l10n.dart';
import '../../../domain/care/reminder_planner.dart';
import '../../../domain/models/models.dart';

/// Planifie la notification quotidienne à partir des soins dus.
///
/// Appelé au démarrage, après chaque action et après tout changement de
/// réglage. Une seule notification, groupée, utile : « Monstera et Pilea ont
/// probablement besoin d'eau aujourd'hui. »
class ReminderScheduler {
  ReminderScheduler(this._ref);

  final Ref _ref;

  Future<void> reschedule() async {
    final prefs = _ref.read(preferencesProvider);
    final notifications = _ref.read(notificationServiceProvider);
    if (!prefs.notificationsEnabled) {
      await notifications.cancelAll();
      return;
    }
    final now = DateTime.now();
    final fireAt = ReminderPlanner.nextFireTime(
      now,
      hour: prefs.notificationTime.hour,
      minute: prefs.notificationTime.minute,
      quietWeekdays: prefs.quietWeekdays,
    );
    // On évalue les soins qui seront dus au moment de la notification.
    final tasks = await _ref.read(careRepositoryProvider).watchTasks(until: DateTime(fireAt.year, fireAt.month, fireAt.day, 23, 59, 59)).first;
    final digest = ReminderPlanner.digest(tasks, fireAt);
    final lowStock = await _ref.read(inventoryRepositoryProvider).watchLowStock().first;
    // Tâches libres échues au moment de la notification (sans date : ignorées).
    final openTasks = await _ref.read(taskRepositoryProvider).watchOpen().first;
    final dueTasks = openTasks.where((t) => t.dueAt != null && !t.dueAt!.isAfter(fireAt)).toList()
      ..sort((a, b) => a.dueAt!.compareTo(b.dueAt!));
    if (digest.isEmpty && lowStock.isEmpty && dueTasks.isEmpty) {
      await notifications.cancelAll();
      return;
    }
    final l10n = resolveLocalizations(prefs.locale);
    await notifications.scheduleDaily(
      at: fireAt,
      title: l10n.notificationTitle,
      body: buildBody(
        l10n,
        digest,
        lowStockNames: lowStock.map((i) => i.name).toList(),
        taskTitles: dueTasks.map((t) => t.title).toList(),
      ),
      channelName: l10n.notificationChannel,
      payload: '/today',
    );
  }

  /// Texte humain, sans jargon : arrosage d'abord, le reste compté.
  static String buildBody(
    AppLocalizations l10n,
    ReminderDigest digest, {
    List<String> lowStockNames = const [],
    List<String> taskTitles = const [],
  }) {
    final water = digest.byType[CareKind.watering.key] ?? const [];
    final others = digest.byType.entries.where((e) => e.key != CareKind.watering.key).fold(0, (s, e) => s + e.value.length);
    final parts = <String>[];
    if (water.length == 1) parts.add(l10n.notifWaterOne(water.first));
    if (water.length > 1) parts.add(l10n.notifWaterMany(l10n.joinNames(water.take(3).toList())));
    if (others > 0) parts.add(water.isEmpty ? l10n.notifOnlyOther(others) : l10n.notifOther(others));
    if (taskTitles.length == 1) parts.add(l10n.notifTasksOne(taskTitles.first));
    if (taskTitles.length > 1) parts.add(l10n.notifTasksMany(taskTitles.length, l10n.joinNames(taskTitles.take(2).toList())));
    if (lowStockNames.length == 1) parts.add(l10n.notifLowStockOne(lowStockNames.first));
    if (lowStockNames.length > 1) parts.add(l10n.notifLowStockMany(lowStockNames.length));
    return parts.join(' ');
  }
}

final reminderSchedulerProvider = Provider<ReminderScheduler>((ref) => ReminderScheduler(ref));
