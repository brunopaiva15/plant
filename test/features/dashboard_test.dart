import 'package:flora/domain/models/models.dart';
import 'package:flora/features/dashboard/application/dashboard_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 6, 15, 12);

  Plant plant({
    String id = 'p1',
    String name = 'Monstera',
    String? species,
    PlantHealth health = PlantHealth.healthy,
    bool favorite = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? archivedAt,
  }) =>
      Plant(
        id: id,
        gardenId: 'g1',
        name: name,
        speciesName: species,
        status: archivedAt == null ? PlantStatus.active : PlantStatus.archived,
        health: health,
        isFavorite: favorite,
        archivedAt: archivedAt,
        createdAt: createdAt ?? DateTime(2026),
        updatedAt: updatedAt ?? DateTime(2026),
      );

  PlantSummary summary(Plant p, {DateTime? nextDueAt}) =>
      PlantSummary(plant: p, nextDueAt: nextDueAt, nextDueTypeKey: nextDueAt == null ? null : CareKind.watering.key);

  PlantAction action({String id = 'a1', String typeKey = 'watering', DateTime? at, String plantId = 'p1', String? notes}) =>
      PlantAction(id: id, plantId: plantId, typeKey: typeKey, occurredAt: at ?? now, createdAt: at ?? now, notes: notes);

  GardenStats stats({
    List<PlantSummary> plants = const [],
    List<PlantSummary> archived = const [],
    List<Location> locations = const [],
    List<PlantAction> actions = const [],
    List<InventoryItem> lowStock = const [],
    List<FreeTask> openTasks = const [],
  }) =>
      GardenStats.from(plants: plants, archived: archived, locations: locations, actions: actions, lowStock: lowStock, openTasks: openTasks, now: now);

  group('statistiques', () {
    test('un jardin vide ne compte rien', () {
      final s = stats();
      expect(s.plants, 0);
      expect(s.isEmpty, isTrue);
    });

    test('les espèces sont comptées une seule fois', () {
      final s = stats(plants: [
        summary(plant(id: 'a', species: 'Monstera deliciosa')),
        summary(plant(id: 'b', species: 'Monstera deliciosa')),
        summary(plant(id: 'c', species: 'Ficus lyrata')),
      ]);
      expect(s.species, 2);
      expect(s.plants, 3);
    });

    test('une espèce vide ou en blanc ne compte pas', () {
      final s = stats(plants: [summary(plant(id: 'a', species: '   ')), summary(plant(id: 'b'))]);
      expect(s.species, 0);
    });

    test('seuls les soins du mois en cours sont comptés', () {
      final s = stats(actions: [
        action(id: '1', at: DateTime(2026, 6, 1)),
        action(id: '2', at: DateTime(2026, 6, 15)),
        action(id: '3', at: DateTime(2026, 5, 31, 23, 59)),
      ]);
      expect(s.actionsThisMonth, 2);
      expect(s.wateringsThisMonth, 2);
    });

    test('les arrosages sont distingués des autres soins', () {
      final s = stats(actions: [action(id: '1'), action(id: '2', typeKey: 'fertilizing')]);
      expect(s.actionsThisMonth, 2);
      expect(s.wateringsThisMonth, 1);
    });

    test('« à soigner » ne compte que les échéances passées ou du jour', () {
      final s = stats(plants: [
        summary(plant(id: 'a'), nextDueAt: now.subtract(const Duration(days: 3))),
        summary(plant(id: 'b'), nextDueAt: now.add(const Duration(days: 5))),
        summary(plant(id: 'c')),
      ]);
      expect(s.needingCare, 1);
    });

    test('la doyenne est la plus ancienne acquisition', () {
      final s = stats(plants: [
        summary(plant(id: 'jeune', createdAt: DateTime(2026, 3))),
        summary(plant(id: 'vieille', createdAt: DateTime(2019, 1))),
      ]);
      expect(s.oldest?.plant.id, 'vieille');
    });
  });

  group('avertissements', () {
    test('une plante en bonne santé et à jour ne remonte pas', () {
      expect(computeWarnings([summary(plant())], now), isEmpty);
    });

    test('une plante malade remonte toujours', () {
      final w = computeWarnings([summary(plant(health: PlantHealth.sick))], now);
      expect(w.single.reason, WarningReason.sick);
    });

    test('un retard de moins d\'une semaine ne suffit pas', () {
      final w = computeWarnings([summary(plant(), nextDueAt: now.subtract(const Duration(days: 3)))], now);
      expect(w, isEmpty, reason: 'l\'écran Aujourd\'hui montre déjà ce retard');
    });

    test('un retard d\'une semaine devient un avertissement', () {
      final w = computeWarnings([summary(plant(), nextDueAt: now.subtract(const Duration(days: 8)))], now);
      expect(w.single.reason, WarningReason.overdue);
      expect(w.single.overdueDays, 8);
    });

    test('malade avant à surveiller, puis le plus grand retard', () {
      final w = computeWarnings([
        summary(plant(id: 'retard'), nextDueAt: now.subtract(const Duration(days: 30))),
        summary(plant(id: 'surveiller', health: PlantHealth.watch)),
        summary(plant(id: 'malade', health: PlantHealth.sick)),
      ], now);
      expect(w.map((x) => x.plant.plant.id), ['malade', 'surveiller', 'retard']);
    });
  });

  group('dernières plantes', () {
    test('par ajout, la plus récente d\'abord', () {
      final list = sortRecent([
        summary(plant(id: 'vieux', createdAt: DateTime(2025))),
        summary(plant(id: 'neuf', createdAt: DateTime(2026, 6))),
      ], RecentPlantsMode.added);
      expect(list.first.plant.id, 'neuf');
    });

    test('par modification, l\'ordre peut changer', () {
      final plants = [
        summary(plant(id: 'a', createdAt: DateTime(2026, 6), updatedAt: DateTime(2026, 6))),
        summary(plant(id: 'b', createdAt: DateTime(2025), updatedAt: DateTime(2026, 7))),
      ];
      expect(sortRecent(plants, RecentPlantsMode.added).first.plant.id, 'a');
      expect(sortRecent(plants, RecentPlantsMode.updated).first.plant.id, 'b');
    });

    test('la liste est bornée', () {
      final plants = [for (var i = 0; i < 30; i++) summary(plant(id: '$i'))];
      expect(sortRecent(plants, RecentPlantsMode.added), hasLength(10));
    });
  });

  group('journal d\'activité', () {
    List<ActivityEntry> log({
      List<PlantSummary> plants = const [],
      List<PlantSummary> archived = const [],
      List<PlantAction> actions = const [],
      List<LocationLogEntry> locationLogs = const [],
      List<FreeTask> doneTasks = const [],
    }) =>
        buildActivityLog(plants: plants, archived: archived, actions: actions, locationLogs: locationLogs, doneTasks: doneTasks);

    test('les sources se mêlent, la plus récente d\'abord', () {
      final entries = log(
        plants: [summary(plant(id: 'p1', createdAt: DateTime(2026, 6, 1)))],
        actions: [action(at: DateTime(2026, 6, 10))],
      );
      expect(entries.map((e) => e.kind), [ActivityKind.action, ActivityKind.plantAdded]);
    });

    test('une action porte le nom de sa plante', () {
      final entries = log(plants: [summary(plant(id: 'p1', name: 'Pilea'))], actions: [action(plantId: 'p1')]);
      expect(entries.first.plantName, 'Pilea');
    });

    test('une action orpheline reste lisible', () {
      final entries = log(actions: [action(plantId: 'disparue')]);
      expect(entries, hasLength(1));
      expect(entries.single.plantName, isNull);
    });

    test('une plante archivée donne sa ligne d\'archivage', () {
      final archived = summary(plant(id: 'p1', createdAt: DateTime(2026), archivedAt: DateTime(2026, 6)));
      final entries = log(archived: [archived]);
      expect(entries.map((e) => e.kind), [ActivityKind.plantArchived]);
    });

    test('une tâche terminée sans date est ignorée', () {
      final task = FreeTask(id: 't1', gardenId: 'g1', title: 'Tailler', allDay: true, done: true, createdAt: now, updatedAt: now);
      expect(log(doneTasks: [task]), isEmpty);
    });

    test('les identifiants ne se collisionnent pas entre sources', () {
      final entries = log(plants: [summary(plant(id: 'x'))], actions: [action(id: 'x')]);
      expect(entries.map((e) => e.id).toSet(), hasLength(2));
    });
  });
}
