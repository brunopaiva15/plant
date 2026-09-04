import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/config/app_config.dart';
import '../../../domain/models/models.dart';
import '../../../domain/repositories/repositories.dart';

/// Filtre courant de l'écran Plantes.
class PlantFilterController extends Notifier<PlantFilter> {
  @override
  PlantFilter build() {
    // Le tri choisi la dernière fois est restauré au lancement.
    final saved = ref.read(preferencesServiceProvider).plantSort;
    return PlantFilter(sort: PlantSort.values.where((s) => s.name == saved).firstOrNull ?? PlantSort.name);
  }

  void setQuery(String q) => state = state.copyWith(query: q);

  void update(PlantFilter Function(PlantFilter) fn) {
    final next = fn(state);
    if (next.sort != state.sort) ref.read(preferencesServiceProvider).setPlantSort(next.sort.name);
    state = next;
  }

  void clear() => state = PlantFilter(query: state.query, sort: state.sort);
}

final plantFilterProvider = NotifierProvider<PlantFilterController, PlantFilter>(PlantFilterController.new);

final plantSummariesProvider = StreamProvider.autoDispose.family<List<PlantSummary>, PlantFilter>(
  (ref, filter) => ref.watch(plantRepositoryProvider).watchSummaries(filter),
);

final filteredPlantsProvider = StreamProvider.autoDispose<List<PlantSummary>>(
  (ref) => ref.watch(plantRepositoryProvider).watchSummaries(ref.watch(plantFilterProvider)),
);

final plantSummaryProvider = StreamProvider.autoDispose.family<PlantSummary?, String>(
  (ref, id) => ref.watch(plantRepositoryProvider).watchSummary(id),
);

final plantActionsProvider = StreamProvider.autoDispose.family<List<PlantAction>, String>(
  (ref, id) => ref.watch(actionRepositoryProvider).watchByPlant(id),
);

final plantPhotosProvider = StreamProvider.autoDispose.family<List<PlantPhoto>, String>(
  (ref, id) => ref.watch(photoRepositoryProvider).watchByPlant(id),
);

final plantSchedulesProvider = StreamProvider.autoDispose.family<List<CareSchedule>, String>(
  (ref, id) => ref.watch(careRepositoryProvider).watchByPlant(id),
);

final plantChildrenProvider = StreamProvider.autoDispose.family<List<PlantSummary>, String>(
  (ref, id) => ref.watch(plantRepositoryProvider).watchChildren(id),
);

final plantTagsProvider = StreamProvider.autoDispose.family<List<Tag>, String>(
  (ref, id) => ref.watch(tagRepositoryProvider).watchForPlant(id),
);

final archivedPlantsProvider = StreamProvider.autoDispose<List<PlantSummary>>(
  (ref) => ref.watch(plantRepositoryProvider).watchArchived(),
);

final recentPhotosProvider = StreamProvider.autoDispose<List<PlantPhoto>>(
  (ref) => ref.watch(photoRepositoryProvider).watchRecent(limit: 12),
);

/// Soins échus (aujourd'hui + retard) et à venir sur [AppConfig.upcomingDays].
final careTasksProvider = StreamProvider.autoDispose<List<CareTask>>((ref) {
  final now = DateTime.now();
  final until = DateTime(now.year, now.month, now.day + AppConfig.upcomingDays, 23, 59, 59);
  return ref.watch(careRepositoryProvider).watchTasks(until: until);
});

/// Sélection multiple sur l'écran Plantes.
class SelectionController extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  bool get active => state.isNotEmpty;
  void toggle(String id) => state = state.contains(id) ? ({...state}..remove(id)) : {...state, id};
  void start(String id) => state = {id};
  void clear() => state = const {};
}

final selectionProvider = NotifierProvider<SelectionController, Set<String>>(SelectionController.new);
