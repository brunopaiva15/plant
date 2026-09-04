import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models/models.dart';
import '../../plants/application/plant_providers.dart';
import '../application/task_providers.dart';
import 'task_sheet.dart';

/// Ligne de tâche : rond à cocher, titre, plante · échéance · récurrence.
/// Tap : édition. Le rond : fait (avec Undo) ou rouvrir.
class TaskRow extends ConsumerWidget {
  const TaskRow({super.key, required this.task, this.showPlant = true, this.dense = false});

  final FreeTask task;
  final bool showPlant;
  final bool dense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final now = DateTime.now();
    final status = task.status(now);
    final plant = showPlant && task.plantId != null ? ref.watch(plantSummaryProvider(task.plantId!)).value : null;
    final parts = <String>[
      if (plant != null) plant.plant.name,
      if (task.done && task.doneAt != null)
        l10n.taskDoneOn(Dates.relativeDay(context, task.doneAt!).toLowerCase())
      else if (task.dueAt != null)
        task.allDay ? l10n.dueLabel(task.dueAt, now) : '${l10n.dueLabel(task.dueAt, now)} · ${Dates.time(context, task.dueAt!)}',
      if (task.recurrence != null) l10n.recurrenceLabel(task.recurrence!.unit.key, task.recurrence!.value),
    ];
    final dueColor = switch (status) {
      FreeTaskStatus.overdue => c.terracotta,
      FreeTaskStatus.today => c.water,
      _ => c.inkSecondary,
    };
    return FloraListRow(
      dense: dense,
      leading: _CheckCircle(done: task.done, onTap: () => task.done ? ref.read(taskActionsProvider).reopen(task) : ref.read(taskActionsProvider).complete(context, task)),
      title: task.title,
      subtitle: parts.isEmpty ? null : parts.join(' · '),
      subtitleColor: task.done ? c.inkTertiary : dueColor,
      strikethrough: task.done,
      chevron: false,
      trailing: task.recurrence != null ? Icon(CupertinoIcons.repeat, size: 16, color: c.inkTertiary) : null,
      onTap: () => showTaskSheet(context, existing: task),
    );
  }
}

class _CheckCircle extends StatelessWidget {
  const _CheckCircle({required this.done, required this.onTap});

  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: onTap,
      scale: 0.85,
      child: AnimatedContainer(
        duration: Motion.of(context, Motion.standard),
        curve: Motion.easeOut,
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: done ? c.sage : Colors.transparent,
          border: Border.all(color: done ? c.sage : c.inkTertiary, width: 1.6),
        ),
        child: done ? Icon(CupertinoIcons.checkmark_alt, size: 16, color: c.onSage) : null,
      ),
    );
  }
}
