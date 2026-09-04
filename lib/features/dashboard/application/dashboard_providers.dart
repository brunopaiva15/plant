import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../domain/care/care_engine.dart';
import '../../../domain/models/models.dart';
import '../../../domain/repositories/repositories.dart';
import '../../plants/application/plant_providers.dart';
import '../../tasks/application/task_providers.dart';

/// Chiffres du jardin, calculés à partir des flux déjà en mémoire.
class GardenStats {
  const GardenStats({
    required this.plants,
    required this.archived,
    required this.species,
    required this.locations,
    required this.favorites,
    required this.needingCare,
    required this.openTasks,
    required this.lowStock,
    required this.actionsThisMonth,
    required this.wateringsThisMonth,
    required this.oldest,
  });

  final int plants;
  final int archived;
  final int species;
  final int locations;
  final int favorites;
  final int needingCare;
  final int openTasks;
  final int lowStock;
  final int actionsThisMonth;
  final int wateringsThisMonth;

  /// Plante présente depuis le plus longtemps, s'il y en a une.
  final PlantSummary? oldest;

  bool get isEmpty => plants == 0 && archived == 0;

  /// Calcule les chiffres à partir des listes déjà chargées.
  static GardenStats from({
    required List<PlantSummary> plants,
    required List<PlantSummary> archived,
    required List<Location> locations,
    required List<PlantAction> actions,
    required List<InventoryItem> lowStock,
    required List<FreeTask> openTasks,
    required DateTime now,
  }) {
    final monthStart = DateTime(now.year, now.month);
    final thisMonth = actions.where((a) => !a.occurredAt.isBefore(monthStart)).toList();
    final species = plants.map((p) => p.plant.speciesName).whereType<String>().map((s) => s.trim()).where((s) => s.isNotEmpty).toSet();
    return GardenStats(
      plants: plants.length,
      archived: archived.length,
      species: species.length,
      locations: locations.length,
      favorites: plants.where((p) => p.plant.isFavorite).length,
      needingCare: plants.where((p) => p.nextDueAt != null && p.dueStatus(now) != DueStatus.upcoming).length,
      openTasks: openTasks.length,
      lowStock: lowStock.length,
      actionsThisMonth: thisMonth.length,
      wateringsThisMonth: thisMonth.where((a) => a.typeKey == CareKind.watering.key).length,
      oldest: _oldest(plants),
    );
  }
}

/// Toutes les plantes actives, sans filtre : socle des statistiques.
final _allPlantsProvider = StreamProvider.autoDispose<List<PlantSummary>>(
  (ref) => ref.watch(plantRepositoryProvider).watchSummaries(const PlantFilter()),
);

final _recentActionsProvider = StreamProvider.autoDispose<List<PlantAction>>(
  (ref) => ref.watch(actionRepositoryProvider).watchRecent(limit: 200),
);

final _inventoryLowProvider = StreamProvider.autoDispose<List<InventoryItem>>(
  (ref) => ref.watch(inventoryRepositoryProvider).watchLowStock(),
);

final _locationLogsProvider = StreamProvider.autoDispose<List<LocationLogEntry>>(
  (ref) => ref.watch(locationRepositoryProvider).watchRecentLog(limit: 50),
);

final _doneTasksProvider = StreamProvider.autoDispose<List<FreeTask>>(
  (ref) => ref.watch(taskRepositoryProvider).watchDone(limit: 50),
);

final gardenStatsProvider = Provider.autoDispose<GardenStats>((ref) => GardenStats.from(
      plants: ref.watch(_allPlantsProvider).value ?? const [],
      archived: ref.watch(archivedPlantsProvider).value ?? const [],
      locations: ref.watch(locationsProvider).value ?? const [],
      actions: ref.watch(_recentActionsProvider).value ?? const [],
      lowStock: ref.watch(_inventoryLowProvider).value ?? const [],
      openTasks: ref.watch(openTasksProvider).value ?? const [],
      now: DateTime.now(),
    ));

PlantSummary? _oldest(List<PlantSummary> plants) {
  PlantSummary? best;
  for (final p in plants) {
    final date = p.plant.acquiredAt ?? p.plant.createdAt;
    final bestDate = best == null ? null : (best.plant.acquiredAt ?? best.plant.createdAt);
    if (bestDate == null || date.isBefore(bestDate)) best = p;
  }
  return best;
}

/// Une plante qui demande de l'attention, et pourquoi.
class PlantWarning {
  const PlantWarning({required this.plant, required this.reason, this.overdueDays = 0});

  final PlantSummary plant;
  final WarningReason reason;
  final int overdueDays;
}

enum WarningReason { sick, watch, overdue }

final plantWarningsProvider = Provider.autoDispose<List<PlantWarning>>(
    (ref) => computeWarnings(ref.watch(_allPlantsProvider).value ?? const [], DateTime.now()));

/// Plantes malades, à surveiller, ou dont un soin traîne. Les plus urgentes
/// d'abord : malade, puis à surveiller, puis le retard le plus long.
List<PlantWarning> computeWarnings(List<PlantSummary> plants, DateTime now) {
  final warnings = <PlantWarning>[];
  for (final p in plants) {
    final overdue = p.nextDueAt != null && p.dueStatus(now) == DueStatus.overdue ? now.difference(p.nextDueAt!).inDays : 0;
    final reason = switch (p.plant.health) {
      PlantHealth.sick => WarningReason.sick,
      PlantHealth.watch => WarningReason.watch,
      // Un soin en retard ne devient un avertissement qu'au-delà d'une
      // semaine : au-dessous, l'écran Aujourd'hui suffit.
      PlantHealth.healthy when overdue >= 7 => WarningReason.overdue,
      PlantHealth.healthy => null,
    };
    if (reason == null) continue;
    warnings.add(PlantWarning(plant: p, reason: reason, overdueDays: overdue));
  }
  warnings.sort((a, b) {
    final byReason = a.reason.index.compareTo(b.reason.index);
    return byReason != 0 ? byReason : b.overdueDays.compareTo(a.overdueDays);
  });
  return warnings;
}

/// Ce que le carrousel « dernières plantes » affiche.
enum RecentPlantsMode { added, updated }

class RecentPlantsController extends Notifier<RecentPlantsMode> {
  @override
  RecentPlantsMode build() {
    final saved = ref.read(preferencesServiceProvider).recentPlantsMode;
    return RecentPlantsMode.values.where((m) => m.name == saved).firstOrNull ?? RecentPlantsMode.added;
  }

  void set(RecentPlantsMode mode) {
    ref.read(preferencesServiceProvider).setRecentPlantsMode(mode.name);
    state = mode;
  }
}

final recentPlantsModeProvider = NotifierProvider<RecentPlantsController, RecentPlantsMode>(RecentPlantsController.new);

final recentPlantsProvider = Provider.autoDispose<List<PlantSummary>>(
    (ref) => sortRecent(ref.watch(_allPlantsProvider).value ?? const [], ref.watch(recentPlantsModeProvider)));

/// Les plus récentes d'abord, au plus [limit].
List<PlantSummary> sortRecent(List<PlantSummary> plants, RecentPlantsMode mode, {int limit = 10}) {
  final sorted = [...plants]..sort((a, b) => switch (mode) {
        RecentPlantsMode.added => b.plant.createdAt.compareTo(a.plant.createdAt),
        RecentPlantsMode.updated => b.plant.updatedAt.compareTo(a.plant.updatedAt),
      });
  return sorted.take(limit).toList();
}

/// Journal global : soins, arrivées, archivages, notes d'emplacement et
/// tâches terminées, mêlés dans l'ordre chronologique inverse.
final activityLogProvider = Provider.autoDispose<List<ActivityEntry>>((ref) => buildActivityLog(
      plants: ref.watch(_allPlantsProvider).value ?? const [],
      archived: ref.watch(archivedPlantsProvider).value ?? const [],
      actions: ref.watch(_recentActionsProvider).value ?? const [],
      locationLogs: ref.watch(_locationLogsProvider).value ?? const [],
      doneTasks: ref.watch(_doneTasksProvider).value ?? const [],
    ));

/// Assemble le journal : soins, arrivées, archivages, notes d'emplacement et
/// tâches terminées, du plus récent au plus ancien.
List<ActivityEntry> buildActivityLog({
  required List<PlantSummary> plants,
  required List<PlantSummary> archived,
  required List<PlantAction> actions,
  required List<LocationLogEntry> locationLogs,
  required List<FreeTask> doneTasks,
}) {
  final byId = {for (final p in [...plants, ...archived]) p.plant.id: p};
  return <ActivityEntry>[
    for (final a in actions)
      ActivityEntry(
        id: 'action:${a.id}',
        at: a.occurredAt,
        kind: ActivityKind.action,
        plantId: a.plantId,
        plantName: byId[a.plantId]?.plant.name,
        thumbPath: byId[a.plantId]?.thumbPath,
        typeKey: a.typeKey,
        text: a.notes,
      ),
    for (final p in plants)
      ActivityEntry(
        id: 'added:${p.plant.id}',
        at: p.plant.createdAt,
        kind: ActivityKind.plantAdded,
        plantId: p.plant.id,
        plantName: p.plant.name,
        thumbPath: p.thumbPath,
      ),
    for (final p in archived)
      if (p.plant.archivedAt case final at?)
        ActivityEntry(
          id: 'archived:${p.plant.id}',
          at: at,
          kind: ActivityKind.plantArchived,
          plantId: p.plant.id,
          plantName: p.plant.name,
          thumbPath: p.thumbPath,
          text: p.plant.archiveReason,
        ),
    for (final e in locationLogs) ActivityEntry(id: 'log:${e.id}', at: e.createdAt, kind: ActivityKind.locationNote, text: e.content),
    for (final t in doneTasks)
      if (t.doneAt case final at?) ActivityEntry(id: 'task:${t.id}', at: at, kind: ActivityKind.taskDone, plantId: t.plantId, text: t.title),
  ]..sort((a, b) => b.at.compareTo(a.at));
}
