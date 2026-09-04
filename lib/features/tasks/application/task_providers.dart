import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/components/toast.dart';
import '../../../domain/models/models.dart';
import '../../account/application/membership_providers.dart';
import '../../today/application/reminder_scheduler.dart';

final allTasksProvider = StreamProvider.autoDispose<List<FreeTask>>((ref) => ref.watch(taskRepositoryProvider).watchAll());
final openTasksProvider = StreamProvider.autoDispose<List<FreeTask>>((ref) => ref.watch(taskRepositoryProvider).watchOpen());
final plantTasksProvider = StreamProvider.autoDispose.family<List<FreeTask>, String>((ref, plantId) => ref.watch(taskRepositoryProvider).watchByPlant(plantId));

/// Tâches ouvertes en retard ou dues aujourd'hui (écran Aujourd'hui).
final dueTasksProvider = Provider.autoDispose<List<FreeTask>>((ref) {
  final now = DateTime.now();
  final open = ref.watch(openTasksProvider).value ?? const <FreeTask>[];
  return open.where((t) => switch (t.status(now)) { FreeTaskStatus.overdue || FreeTaskStatus.today => true, _ => false }).toList();
});

/// Cas d'usage tâches : compléter (avec Undo), rouvrir, supprimer (avec Undo).
class TaskActions {
  TaskActions(this._ref);

  final Ref _ref;

  bool _blocked() {
    if (_ref.read(canEditProvider)) return false;
    Haptics.warning();
    return true;
  }

  Future<void> complete(BuildContext context, FreeTask task) async {
    if (_blocked()) return;
    final l10n = context.l10n;
    final previous = await _ref.read(taskRepositoryProvider).complete(task.id);
    Haptics.success();
    final after = await _ref.read(taskRepositoryProvider).get(task.id);
    final message = task.isRecurring && after?.dueAt != null && context.mounted
        ? l10n.taskNextToast(task.title, l10n.dueLabel(after!.dueAt, DateTime.now()).toLowerCase())
        : l10n.taskDoneToast(task.title);
    _ref.read(toastProvider.notifier).show(ToastData(
      message: message,
      emoji: task.isRecurring ? '🔁' : '✓',
      undoLabel: l10n.undo,
      onUndo: () async {
        await _ref.read(taskRepositoryProvider).restore(previous);
        await _ref.read(reminderSchedulerProvider).reschedule();
      },
    ));
    await _ref.read(reminderSchedulerProvider).reschedule();
  }

  Future<void> reopen(FreeTask task) async {
    if (_blocked()) return;
    await _ref.read(taskRepositoryProvider).reopen(task.id);
    Haptics.light();
    await _ref.read(reminderSchedulerProvider).reschedule();
  }

  Future<void> delete(BuildContext context, FreeTask task) async {
    if (_blocked()) return;
    final l10n = context.l10n;
    await _ref.read(taskRepositoryProvider).delete(task.id);
    Haptics.warning();
    _ref.read(toastProvider.notifier).show(ToastData(
      message: l10n.taskDeleted,
      emoji: '🗑️',
      undoLabel: l10n.undo,
      onUndo: () => _ref.read(taskRepositoryProvider).restore(task),
    ));
    await _ref.read(reminderSchedulerProvider).reschedule();
  }
}

final taskActionsProvider = Provider<TaskActions>((ref) => TaskActions(ref));
