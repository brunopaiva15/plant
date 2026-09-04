import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/care/care_engine.dart';
import '../../../domain/models/models.dart';
import '../../plants/application/plant_providers.dart';
import '../../plants/presentation/create_plant_flow.dart';
import '../../tasks/application/task_providers.dart';
import '../../tasks/presentation/task_row.dart';
import '../../weather/presentation/weather_widgets.dart';
import '../application/completed_tasks.dart';
import 'care_task_card.dart';
import 'notification_prompt.dart';

/// Écran principal : « Qu'est-ce que je dois faire aujourd'hui ? »
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final prefs = ref.watch(preferencesProvider);
    final tasks = ref.watch(careTasksProvider);
    final plantCount = ref.watch(activePlantCountProvider).value ?? 0;
    final now = DateTime.now();
    final greeting = prefs.displayName.isEmpty ? l10n.greetingAnonymous : l10n.greeting(prefs.displayName);

    final live = tasks.value ?? const <CareTask>[];
    final lingering = ref.watch(completedTasksProvider);
    // Les tâches qui viennent d'être complétées restent affichées un instant,
    // à leur place d'origine, en état « ✓ Fait ».
    final liveIds = live.map((t) => t.schedule.id).toSet();
    final all = [
      ...live,
      for (final l in lingering.values)
        if (!liveIds.contains(l.task.schedule.id)) l.task,
    ];
    DueStatus statusOf(CareTask t) => t.status(now);
    final overdue = all.where((t) => statusOf(t) == DueStatus.overdue).toList();
    final today = all.where((t) => statusOf(t) == DueStatus.today).toList();
    final upcoming = all.where((t) => statusOf(t) == DueStatus.upcoming).toList();
    final dueTasks = ref.watch(dueTasksProvider);
    final dueCount = live.where((t) => statusOf(t) != DueStatus.upcoming).length + dueTasks.length;

    return LargeTitlePage(
      title: greeting,
      leading: FloraIconButton(
        icon: CupertinoIcons.chart_bar,
        semanticLabel: l10n.dashboardTitle,
        filled: false,
        onPressed: () => context.push(Routes.dashboard),
      ),
      trailing: FloraIconButton(
        icon: CupertinoIcons.plus,
        semanticLabel: l10n.addPlant,
        onPressed: () => startCreatePlantFlow(context, ref),
      ),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [Text(Dates.longDate(context, now), style: context.text.callout), const WeatherLine()],
                  ),
                ),
                if (plantCount > 0)
                  AnimatedSwitcher(
                    duration: Motion.of(context, Motion.standard),
                    child: Text(l10n.careCount(dueCount), key: ValueKey(dueCount), style: context.text.caption.copyWith(fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: WeatherAdviceCard()),
        const SliverToBoxAdapter(child: NotificationPrompt()),
        if (plantCount == 0 && tasks.hasValue)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: EmptyState(
                emoji: '🌱',
                title: l10n.emptyGardenTitle,
                subtitle: l10n.onboardingSubtitle,
                actionLabel: l10n.addFirstPlant,
                onAction: () => startCreatePlantFlow(context, ref),
              ),
            ),
          )
        else ...[
          if (dueCount == 0 && tasks.hasValue)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(Space.page, Space.md, Space.page, 0),
                child: FloraCard(
                  padding: const EdgeInsets.all(Space.lg),
                  child: Row(
                    children: [
                      const EmojiTile(emoji: '🌿', size: 48),
                      const SizedBox(width: Space.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.allDoneTitle, style: context.text.title3),
                            const SizedBox(height: 2),
                            Text(l10n.allDoneSubtitle, style: context.text.callout),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (dueTasks.isNotEmpty) _FreeTaskSection(tasks: dueTasks),
          if (overdue.isNotEmpty) _TaskSection(title: l10n.sectionOverdue, tasks: overdue),
          if (today.isNotEmpty) _TaskSection(title: l10n.sectionToday, tasks: today),
          if (upcoming.isNotEmpty) _TaskSection(title: l10n.sectionUpcoming, tasks: upcoming, compact: true),
          const _GardenSummary(),
          const _RecentPhotos(),
        ],
      ],
    );
  }
}

/// Tâches libres en retard ou dues aujourd'hui.
class _FreeTaskSection extends StatelessWidget {
  const _FreeTaskSection({required this.tasks});

  final List<FreeTask> tasks;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: SectionHeader(title: l10n.tasksTodayTitle, actionLabel: l10n.seeAll, onAction: () => context.go(Routes.garden)),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: Space.page),
          sliver: SliverToBoxAdapter(
            child: FloraGroup(children: [for (final t in tasks) TaskRow(key: ValueKey(t.id), task: t)]),
          ),
        ),
      ],
    );
  }
}

class _TaskSection extends StatelessWidget {
  const _TaskSection({required this.title, required this.tasks, this.compact = false});

  final String title;
  final List<CareTask> tasks;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(child: SectionHeader(title: title)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: Space.page),
          sliver: SliverList.separated(
            itemCount: tasks.length,
            separatorBuilder: (_, _) => const SizedBox(height: Space.sm),
            itemBuilder: (context, i) => CareTaskCard(
              key: ValueKey(tasks[i].schedule.id),
              task: tasks[i],
              compact: compact,
              onOpen: () => context.push(Routes.plant(tasks[i].plantId)),
            ),
          ),
        ),
      ],
    );
  }
}

/// « Votre jardin · 24 plantes » + emplacements avec leur nombre de plantes.
class _GardenSummary extends ConsumerWidget {
  const _GardenSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final tree = ref.watch(locationTreeProvider).value ?? const [];
    final count = ref.watch(activePlantCountProvider).value ?? 0;
    final flat = <LocationNode>[];
    void walk(List<LocationNode> nodes) {
      for (final n in nodes) {
        if (n.totalPlantCount > 0) flat.add(n);
        walk(n.children);
      }
    }

    walk(tree);
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: l10n.yourGarden, actionLabel: l10n.seeAll, onAction: () => context.go(Routes.garden)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.page),
            child: Text(l10n.plantCount(count), style: context.text.callout),
          ),
          if (flat.isNotEmpty) ...[
            const SizedBox(height: Space.sm),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: Space.page),
                itemCount: flat.length,
                separatorBuilder: (_, _) => const SizedBox(width: Space.xs),
                itemBuilder: (context, i) {
                  final n = flat[i];
                  return Pressable(
                    onTap: () => context.push(Routes.location(n.location.id)),
                    scale: 0.95,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: Space.md),
                      decoration: BoxDecoration(color: context.colors.surface, borderRadius: Radii.fullAll, border: Border.all(color: context.colors.line)),
                      child: Row(
                        children: [
                          Text(n.location.icon, style: const TextStyle(fontSize: 15)),
                          const SizedBox(width: 6),
                          Text(n.location.name, style: context.text.callout.copyWith(color: context.colors.ink, fontWeight: FontWeight.w500)),
                          const SizedBox(width: 6),
                          Text('${n.totalPlantCount}', style: context.text.caption),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RecentPhotos extends ConsumerWidget {
  const _RecentPhotos();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photos = ref.watch(recentPhotosProvider).value ?? const [];
    if (photos.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: context.l10n.recentPhotos),
          SizedBox(
            height: 128,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: Space.page),
              itemCount: photos.length,
              separatorBuilder: (_, _) => const SizedBox(width: Space.xs),
              itemBuilder: (context, i) => Pressable(
                onTap: () => context.push(Routes.plantGallery(photos[i].plantId)),
                scale: 0.96,
                child: ClipRRect(
                  borderRadius: Radii.mediumAll,
                  child: SizedBox(width: 100, height: 128, child: PlantImage(relativePath: photos[i].thumbPath, cacheWidth: 300)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
