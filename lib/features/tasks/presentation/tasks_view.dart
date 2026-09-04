import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models/models.dart';
import '../application/task_providers.dart';
import 'task_row.dart';
import 'task_sheet.dart';

enum TaskFilter { open, overdue, done }

class TaskFilterController extends Notifier<TaskFilter> {
  @override
  TaskFilter build() => TaskFilter.open;
  void set(TaskFilter f) => state = f;
}

final taskFilterProvider = NotifierProvider<TaskFilterController, TaskFilter>(TaskFilterController.new);

/// Onglet « Tâches » du Jardin : filtres, sections par échéance.
class TasksSlivers extends ConsumerWidget {
  const TasksSlivers({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final filter = ref.watch(taskFilterProvider);
    final all = ref.watch(allTasksProvider);
    final tasks = all.value ?? const <FreeTask>[];
    final now = DateTime.now();
    final open = tasks.where((t) => !t.done).toList();
    final done = tasks.where((t) => t.done).toList()..sort((a, b) => (b.doneAt ?? b.updatedAt).compareTo(a.doneAt ?? a.updatedAt));
    final overdue = open.where((t) => t.status(now) == FreeTaskStatus.overdue).toList();
    final today = open.where((t) => t.status(now) == FreeTaskStatus.today).toList();
    final upcoming = open.where((t) => t.status(now) == FreeTaskStatus.upcoming).toList();
    final noDate = open.where((t) => t.status(now) == FreeTaskStatus.noDate).toList();

    final sections = switch (filter) {
      TaskFilter.open => [
          (l10n.taskSectionOverdue, overdue),
          (l10n.taskSectionToday, today),
          (l10n.taskSectionUpcoming, upcoming),
          (l10n.taskSectionNoDate, noDate),
        ],
      TaskFilter.overdue => [(l10n.taskSectionOverdue, overdue)],
      TaskFilter.done => [(l10n.taskFilterDone, done)],
    }
        .where((s) => s.$2.isNotEmpty)
        .toList();

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: Space.page),
              children: [
                _FilterChip(label: l10n.taskFilterOpen, count: open.length, filter: TaskFilter.open),
                const SizedBox(width: Space.xs),
                _FilterChip(label: l10n.taskFilterOverdue, count: overdue.length, filter: TaskFilter.overdue),
                const SizedBox(width: Space.xs),
                _FilterChip(label: l10n.taskFilterDone, count: done.length, filter: TaskFilter.done),
              ],
            ),
          ),
        ),
        if (all.hasValue && sections.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: filter == TaskFilter.done
                  ? EmptyState(emoji: '☑️', title: l10n.noDoneTasks, compact: true)
                  : EmptyState(emoji: '📝', title: l10n.noTasksTitle, subtitle: l10n.noTasksSubtitle, actionLabel: l10n.newTask, onAction: () => showTaskSheet(context)),
            ),
          )
        else
          for (final (title, list) in sections)
            SliverMainAxisGroup(
              slivers: [
                SliverToBoxAdapter(child: SectionHeader(title: title)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: Space.page),
                  sliver: SliverToBoxAdapter(child: FloraGroup(children: [for (final t in list) TaskRow(key: ValueKey(t.id), task: t)])),
                ),
              ],
            ),
      ],
    );
  }
}

class _FilterChip extends ConsumerWidget {
  const _FilterChip({required this.label, required this.count, required this.filter});

  final String label;
  final int count;
  final TaskFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(taskFilterProvider) == filter;
    return FloraChip(label: count == 0 ? label : '$label · $count', selected: selected, onTap: () => ref.read(taskFilterProvider.notifier).set(filter));
  }
}
