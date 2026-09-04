import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../domain/models/models.dart';
import '../../plants/application/plant_providers.dart';

/// Tris possibles des archives.
enum ArchiveSort { archivedDesc, archivedAsc, name, longestKept }

/// Filtre courant de l'écran Archives.
class ArchiveFilter {
  const ArchiveFilter({this.query = '', this.year, this.sort = ArchiveSort.archivedDesc});

  final String query;

  /// Année d'archivage retenue, `null` = toutes.
  final int? year;
  final ArchiveSort sort;

  ArchiveFilter copyWith({String? query, int? Function()? year, ArchiveSort? sort}) => ArchiveFilter(
        query: query ?? this.query,
        year: year == null ? this.year : year(),
        sort: sort ?? this.sort,
      );

  bool get isFiltering => query.trim().isNotEmpty || year != null;
}

class ArchiveFilterController extends Notifier<ArchiveFilter> {
  @override
  ArchiveFilter build() {
    final saved = ref.read(preferencesServiceProvider).archiveSort;
    return ArchiveFilter(sort: ArchiveSort.values.where((s) => s.name == saved).firstOrNull ?? ArchiveSort.archivedDesc);
  }

  void setQuery(String q) => state = state.copyWith(query: q);
  void setYear(int? year) => state = state.copyWith(year: () => year);

  void setSort(ArchiveSort sort) {
    // Le tri est mémorisé : on le retrouve au lancement suivant.
    ref.read(preferencesServiceProvider).setArchiveSort(sort.name);
    state = state.copyWith(sort: sort);
  }

  void clear() => state = ArchiveFilter(sort: state.sort);
}

final archiveFilterProvider = NotifierProvider<ArchiveFilterController, ArchiveFilter>(ArchiveFilterController.new);

/// Vue carte ou liste, mémorisée elle aussi.
class ArchiveViewController extends Notifier<bool> {
  @override
  bool build() => ref.read(preferencesServiceProvider).archiveGridView;

  void set(bool grid) {
    ref.read(preferencesServiceProvider).setArchiveGridView(grid);
    state = grid;
  }
}

final archiveGridProvider = NotifierProvider<ArchiveViewController, bool>(ArchiveViewController.new);

final filteredArchiveProvider = Provider.autoDispose<List<PlantSummary>>(
  (ref) => filterArchive(ref.watch(archivedPlantsProvider).value ?? const [], ref.watch(archiveFilterProvider)),
);

/// Années où au moins une plante a été archivée, de la plus récente au plus
/// ancienne : ce qui remplit la barre de navigation par année.
final archiveYearsProvider = Provider.autoDispose<List<int>>((ref) {
  final years = (ref.watch(archivedPlantsProvider).value ?? const <PlantSummary>[])
      .map((p) => p.plant.archivedAt?.year)
      .whereType<int>()
      .toSet()
      .toList()
    ..sort((a, b) => b.compareTo(a));
  return years;
});

/// Applique recherche, année et tri. Fonction pure, pour rester testable.
List<PlantSummary> filterArchive(List<PlantSummary> plants, ArchiveFilter filter) {
  final query = filter.query.trim().toLowerCase();
  final list = plants.where((p) {
    if (filter.year != null && p.plant.archivedAt?.year != filter.year) return false;
    if (query.isEmpty) return true;
    final haystack = [p.plant.name, p.plant.speciesName ?? '', p.plant.archiveReason ?? ''].join(' ').toLowerCase();
    return haystack.contains(query);
  }).toList();

  // Une plante sans date d'archivage passe en dernier, dans les deux sens :
  // le signe du tri ne doit pas la remonter en tête.
  int byDate(PlantSummary a, PlantSummary b, {required bool ascending}) {
    final x = a.plant.archivedAt;
    final y = b.plant.archivedAt;
    if (x == null && y == null) return 0;
    if (x == null) return 1;
    if (y == null) return -1;
    return ascending ? x.compareTo(y) : y.compareTo(x);
  }

  list.sort((a, b) => switch (filter.sort) {
        ArchiveSort.archivedDesc => byDate(a, b, ascending: false),
        ArchiveSort.archivedAsc => byDate(a, b, ascending: true),
        ArchiveSort.name => a.plant.name.toLowerCase().compareTo(b.plant.name.toLowerCase()),
        ArchiveSort.longestKept => _kept(b).compareTo(_kept(a)),
      });
  return list;
}

/// Durée passée au jardin, en jours.
int _kept(PlantSummary p) {
  final start = p.plant.acquiredAt ?? p.plant.createdAt;
  final end = p.plant.archivedAt ?? DateTime.now();
  return end.difference(start).inDays;
}

/// Durée de vie au jardin, exposée pour l'affichage.
int daysKept(PlantSummary p) => _kept(p);
