import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../app/sync_coordinator.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/care/care_engine.dart';
import '../../../domain/models/models.dart';
import '../../../domain/sync/sync_state.dart';
import '../../account/application/membership_providers.dart';
import '../../dashboard/application/dashboard_providers.dart';
import '../../dashboard/presentation/activity_log_screen.dart';
import '../../home_climate/application/home_climate_providers.dart';
import '../../home_climate/presentation/home_climate_widgets.dart';
import '../../plants/application/plant_providers.dart';
import '../../plants/presentation/create_plant_flow.dart';
import '../../tasks/application/task_providers.dart';
import '../../tasks/presentation/task_row.dart';
import '../../weather/application/weather_providers.dart';
import '../../weather/presentation/weather_widgets.dart';
import '../application/completed_tasks.dart';
import 'care_task_card.dart';
import 'notification_prompt.dart';
import 'today_notice.dart';
import 'upcoming_section.dart';

/// L'heure à partir de laquelle on dit « Bonsoir » : celle de l'appareil,
/// donc celle que la personne a sous les yeux.
const int _eveningHour = 18;

/// « Bonjour Paul » le jour, « Bonsoir Paul » le soir, et sans le nom tant
/// qu'on n'en a pas.
String _greeting(AppLocalizations l10n, String name, DateTime now) {
  final evening = now.hour >= _eveningHour;
  if (name.isEmpty) return evening ? l10n.greetingEveningAnonymous : l10n.greetingAnonymous;
  return evening ? l10n.greetingEvening(name) : l10n.greeting(name);
}

/// Écran principal : « Qu'est-ce que je dois faire aujourd'hui ? »
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final prefs = ref.watch(preferencesProvider);
    final tasks = ref.watch(careTasksProvider);
    final plantCount = ref.watch(activePlantCountProvider).value ?? 0;
    final sync = ref.watch(syncCoordinatorProvider);
    final user = ref.watch(currentUserProvider).value;
    final now = DateTime.now();
    final greeting = _greeting(l10n, prefs.displayName, now);

    // À la première synchronisation d'un compte ou juste après avoir basculé
    // sur un jardin partagé, la base locale peut être vide quelques instants.
    // Ne pas faire passer cet état transitoire pour un jardin réellement vide.
    final isInitialSync = user != null &&
        !user.isLocal &&
        plantCount == 0 &&
        sync.lastSyncedAt == null &&
        (sync.status == SyncStatus.idle || sync.status == SyncStatus.syncing);

    final live = tasks.value ?? const <CareTask>[];
    final lingering = ref.watch(completedTasksProvider);
    // Les tâches qui viennent d'être complétées restent affichées un instant,
    // **à leur place d'origine**, en état « ✓ Fait », puis s'en vont.
    //
    // C'est la version d'avant qui prime, et non celle de la base : un soin
    // enregistré repousse l'échéance à la seconde même. Sans cela la pièce
    // changeait de section — de « En retard » à « À venir » — avant d'avoir pu
    // montrer quoi que ce soit.
    //
    // Et comme l'échéance décide aussi du rang, on range sur celle qu'on
    // affiche : une tuile arrosée garde sa case le temps de le dire, au lieu
    // de filer en fin de grille pendant qu'une autre prend sa place. Le tri
    // est **stable** — beaucoup de soins tombent le même jour, et un ordre qui
    // se rejoue à chaque image serait pire que le saut qu'on répare.
    final liveIds = live.map((t) => t.schedule.id).toSet();
    final all = [
      for (final t in live) lingering[t.schedule.id]?.task ?? t,
      for (final l in lingering.values)
        if (!liveIds.contains(l.task.schedule.id)) l.task,
    ];
    mergeSort(all, compare: (a, b) => switch ((a.dueAt, b.dueAt)) {
      (null, null) => 0,
      (null, _) => 1,
      (_, null) => -1,
      (final x?, final y?) => x.compareTo(y),
    });
    DueStatus statusOf(CareTask t) => t.status(now);
    final overdue = all.where((t) => statusOf(t) == DueStatus.overdue).toList();
    final today = all.where((t) => statusOf(t) == DueStatus.today).toList();
    final upcoming = all.where((t) => statusOf(t) == DueStatus.upcoming).toList();
    final dueTasks = ref.watch(dueTasksProvider);
    final dueCount = live.where((t) => statusOf(t) != DueStatus.upcoming).length + dueTasks.length;

    return LargeTitlePage(
      title: greeting,
      // Replié, le salut ne dit plus où l'on est : c'est le nom de
      // l'application qui reste dans la barre.
      collapsedTitle: l10n.appName,
      leading: FloraIconButton(
        icon: CupertinoIcons.chart_bar,
        semanticLabel: l10n.dashboardTitle,
        filled: false,
        onPressed: () => context.push(Routes.dashboard),
      ),
      trailing: !ref.watch(canEditProvider)
          ? null
          : FloraIconButton(
              icon: CupertinoIcons.plus,
              semanticLabel: l10n.addPlant,
              onPressed: () => startCreatePlantFlow(context, ref),
            ),
      slivers: [
        // Le jour, et ce qu'il fait : la date, puis le temps dehors et l'air
        // de la maison sur une même rangée de pilules.
        const SliverToBoxAdapter(child: _DayHeader()),
        // La carte du jour : la seule pièce de terre cuite pleine de l'écran,
        // celle qui compte. Elle s'efface quand tout est fait.
        if (plantCount > 0 && dueCount > 0)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Space.page, Space.sm, Space.page, 0),
              child: _DueHero(count: dueCount),
            ),
          ),
        // Le gel et la canicule d'abord : ils ont une échéance, la pluie non.
        const SliverToBoxAdapter(child: OutdoorAlertCard()),
        const SliverToBoxAdapter(child: WeatherAdviceCard()),
        const SliverToBoxAdapter(child: HomeClimateAdviceCard()),
        const SliverToBoxAdapter(child: NotificationPrompt()),
        if (isInitialSync)
          SliverCentered(
            child: Semantics(
              label: l10n.syncSyncing,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CupertinoActivityIndicator(radius: 14),
                  const SizedBox(height: Space.sm),
                  Text(l10n.syncSyncing, style: context.text.title3),
                ],
              ),
            ),
          )
        else if (plantCount == 0 && tasks.hasValue)
          SliverCentered(
            child: EmptyState(
              emoji: '🌱',
              title: l10n.emptyGardenTitle,
              subtitle: l10n.emptyGardenSubtitle,
              actionLabel: l10n.addFirstPlant,
              onAction: () => startCreatePlantFlow(context, ref),
            ),
          )
        else ...[
          if (dueCount == 0 && tasks.hasValue)
            SliverToBoxAdapter(
              child: TodayNoticeSlot(child: TodayNotice(emoji: '🌿', title: l10n.allDoneTitle, body: l10n.allDoneSubtitle)),
            ),
          if (dueTasks.isNotEmpty) _FreeTaskSection(tasks: dueTasks),
          if (overdue.isNotEmpty) _TaskSection(title: l10n.sectionOverdue, tasks: overdue),
          if (today.isNotEmpty) _TaskSection(title: l10n.sectionToday, tasks: today),
          if (upcoming.isNotEmpty) UpcomingSection(tasks: upcoming),
          const _GardenSummary(),
          const _RecentPhotos(),
          const _RecentActivity(),
        ],
      ],
    );
  }
}

/// La date, et dessous le temps qu'il fait et l'air de la maison, chacun
/// sur sa pilule. Une seule rangée : les deux lectures se tiennent côte à
/// côte, et il n'y a rien quand il n'y a rien à lire.
class _DayHeader extends ConsumerWidget {
  const _DayHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weather = ref.watch(todayWeatherProvider);
    final hasOutdoor = ref.watch(outdoorLocationIdsProvider).isNotEmpty;
    final reading = ref.watch(homeReadingProvider).value;
    final pills = <Widget>[
      if (weather != null && hasOutdoor) WeatherPill(weather: weather),
      if (reading != null && !reading.isEmpty) HomeClimatePill(reading: reading),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.xs),
          child: Text(Dates.longDate(context, DateTime.now()), style: context.text.callout),
        ),
        if (pills.isNotEmpty) _PillStrip(children: pills),
      ],
    );
  }
}

/// Une rangée de pilules qui déborde à droite plutôt que de se couper :
/// les lectures du jour, les emplacements du jardin.
class _PillStrip extends StatelessWidget {
  const _PillStrip({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: Space.page),
      child: Row(
        children: [
          for (final (i, child) in children.indexed) ...[
            if (i > 0) const SizedBox(width: Space.xs),
            child,
          ],
        ],
      ),
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
  const _TaskSection({required this.title, required this.tasks});

  final String title;
  final List<CareTask> tasks;

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
            // La clé porte sur l'entrée : une carte déjà posée ne rejoue rien
            // quand la liste se réordonne sous elle.
            itemBuilder: (context, i) => Appear(
              key: ValueKey(tasks[i].schedule.id),
              rank: i,
              child: CareTaskCard(
                task: tasks[i],
                onOpen: () => context.push(Routes.plant(tasks[i].plantId)),
              ),
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
            _PillStrip(
              children: [
                for (final n in flat)
                  FloraPill(
                    emoji: n.location.icon,
                    label: n.location.name,
                    detail: '${n.totalPlantCount}',
                    onTap: () => context.push(Routes.location(n.location.id)),
                  ),
              ],
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
                  child: SizedBox(width: 100, height: 128, child: PlantImage(relativePath: photos[i].thumbPath, remoteUrl: photos[i].remoteUrl, cacheWidth: 300)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Les dernières entrées du journal, et le chemin vers tout le reste. Le
/// journal se cherche depuis l'écran du matin, pas depuis les réglages.
class _RecentActivity extends ConsumerWidget {
  const _RecentActivity();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final entries = ref.watch(activityLogProvider);
    if (entries.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: l10n.activityLogTitle, actionLabel: l10n.seeAll, onAction: () => context.push(Routes.activityLog)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.page),
            child: FloraGroup(children: [for (final e in entries.take(4)) ActivityRow(entry: e)]),
          ),
          const SizedBox(height: Space.lg),
        ],
      ),
    );
  }
}

/// « 3 soins » en grand, sur la terre cuite : le chiffre du matin.
class _DueHero extends StatelessWidget {
  const _DueHero({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    // La chaîne pluralisée porte le nombre ; on le met à part, en grand.
    final label = l10n.careCount(count).replaceFirst(RegExp(r'^\d+\s*'), '');
    final fg = c.onAccent;
    return ClayBox(
      color: c.terracotta,
      shape: const ClayShape.rounded(28),
      depth: ClayDepth.deep,
      padding: const EdgeInsets.fromLTRB(Space.lg, Space.md, Space.lg, Space.md),
      child: Row(
        children: [
          Text('$count', style: context.text.display.copyWith(fontSize: 52, height: 1, color: fg)),
          const SizedBox(width: Space.md),
          Expanded(child: Text(label, style: context.text.title3.copyWith(color: fg, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}
