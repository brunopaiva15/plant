import 'package:flora/domain/models/models.dart';
import 'package:flora/features/archive/application/archive_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  PlantSummary p({
    required String id,
    String name = 'Monstera',
    String? species,
    DateTime? archivedAt,
    DateTime? createdAt,
    String? reason,
  }) =>
      PlantSummary(
        plant: Plant(
          id: id,
          gardenId: 'g1',
          name: name,
          speciesName: species,
          status: PlantStatus.archived,
          health: PlantHealth.healthy,
          isFavorite: false,
          archivedAt: archivedAt,
          archiveReason: reason,
          createdAt: createdAt ?? DateTime(2024),
          updatedAt: DateTime(2026),
        ),
      );

  List<String> ids(List<PlantSummary> list) => list.map((s) => s.plant.id).toList();

  final basil = p(id: 'basilic', name: 'Basilic', species: 'Ocimum basilicum', archivedAt: DateTime(2024, 9, 1), createdAt: DateTime(2024, 5, 1), reason: 'died');
  final fig = p(id: 'figuier', name: 'Figuier', species: 'Ficus carica', archivedAt: DateTime(2026, 3, 4), createdAt: DateTime(2019, 1, 1), reason: 'given');
  final aloe = p(id: 'aloe', name: 'Aloe', archivedAt: DateTime(2025, 7, 12), createdAt: DateTime(2025, 1, 1));
  final all = [basil, fig, aloe];

  group('recherche', () {
    test('sans filtre, tout remonte', () {
      expect(filterArchive(all, const ArchiveFilter()), hasLength(3));
    });

    test('par nom, sans tenir compte de la casse', () {
      expect(ids(filterArchive(all, const ArchiveFilter(query: 'FIGU'))), ['figuier']);
    });

    test('par espèce', () {
      expect(ids(filterArchive(all, const ArchiveFilter(query: 'ocimum'))), ['basilic']);
    });

    test('par raison d\'archivage', () {
      expect(ids(filterArchive(all, const ArchiveFilter(query: 'given'))), ['figuier']);
    });

    test('une recherche vide ou en blanc ne filtre pas', () {
      expect(filterArchive(all, const ArchiveFilter(query: '   ')), hasLength(3));
    });

    test('une recherche sans résultat rend une liste vide', () {
      expect(filterArchive(all, const ArchiveFilter(query: 'cactus')), isEmpty);
    });
  });

  group('année', () {
    test('seules les plantes de l\'année retenue remontent', () {
      expect(ids(filterArchive(all, const ArchiveFilter(year: 2025))), ['aloe']);
    });

    test('une année sans archive rend une liste vide', () {
      expect(filterArchive(all, const ArchiveFilter(year: 2000)), isEmpty);
    });

    test('année et recherche se combinent', () {
      expect(filterArchive(all, const ArchiveFilter(year: 2026, query: 'basilic')), isEmpty);
    });
  });

  group('tri', () {
    test('par archivage, la plus récente d\'abord', () {
      expect(ids(filterArchive(all, const ArchiveFilter())), ['figuier', 'aloe', 'basilic']);
    });

    test('par archivage croissant', () {
      expect(ids(filterArchive(all, const ArchiveFilter(sort: ArchiveSort.archivedAsc))), ['basilic', 'aloe', 'figuier']);
    });

    test('par nom, alphabétique', () {
      expect(ids(filterArchive(all, const ArchiveFilter(sort: ArchiveSort.name))), ['aloe', 'basilic', 'figuier']);
    });

    test('par durée gardée, la plus longue d\'abord', () {
      expect(ids(filterArchive(all, const ArchiveFilter(sort: ArchiveSort.longestKept))).first, 'figuier');
    });

    test('une plante sans date d\'archivage passe en dernier', () {
      final orphan = p(id: 'sans-date');
      final list = filterArchive([orphan, ...all], const ArchiveFilter());
      expect(ids(list).last, 'sans-date');
    });

    test('sans date, le tri croissant la met aussi en dernier', () {
      final orphan = p(id: 'sans-date');
      final list = filterArchive([orphan, ...all], const ArchiveFilter(sort: ArchiveSort.archivedAsc));
      expect(ids(list).last, 'sans-date');
    });
  });

  group('durée gardée', () {
    test('compte de l\'arrivée à l\'archivage', () {
      expect(daysKept(aloe), DateTime(2025, 7, 12).difference(DateTime(2025, 1, 1)).inDays);
    });
  });

  test('« filtre actif » ignore le tri', () {
    expect(const ArchiveFilter(sort: ArchiveSort.name).isFiltering, isFalse);
    expect(const ArchiveFilter(query: 'a').isFiltering, isTrue);
    expect(const ArchiveFilter(year: 2025).isFiltering, isTrue);
  });
}
