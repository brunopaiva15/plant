import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/models/models.dart';
import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [
  Gardens,
  Locations,
  Plants,
  PlantPhotos,
  ActionTypes,
  PlantActions,
  CareSchedules,
  Tags,
  PlantTags,
  Measurements,
  SyncOutbox,
  InventoryItems,
  Profiles,
  GardenMembers,
  Tasks,
  PlantAttributes,
  AttributeSchemas,
  PlantAttachments,
  LocationLogs,
  InventoryGroups,
  InventoryTags,
  EventCategories,
  CalendarEntries,
  RoomScans,
  RoomMarkers,
])
class FloraDatabase extends _$FloraDatabase {
  FloraDatabase(super.executor);

  @override
  int get schemaVersion => 13;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _createIndexes();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(inventoryItems);
          }
          if (from < 3) {
            await m.addColumn(locations, locations.isOutdoor);
          }
          if (from < 4) {
            await m.addColumn(plantActions, plantActions.userId);
            await m.addColumn(plantPhotos, plantPhotos.userId);
            await m.createTable(profiles);
            await m.createTable(gardenMembers);
          }
          if (from < 5) {
            await m.createTable(tasks);
          }
          if (from < 6) {
            await m.createTable(plantAttributes);
            await m.createTable(attributeSchemas);
          }
          if (from < 7) {
            await m.createTable(plantAttachments);
            await m.addColumn(plantPhotos, plantPhotos.label);
            await m.addColumn(plantPhotos, plantPhotos.remoteUrl);
          }
          if (from < 8) {
            await m.createTable(locationLogs);
            await m.addColumn(gardens, gardens.plantCounter);
            await m.addColumn(locations, locations.notes);
            await m.addColumn(locations, locations.photoPath);
            await m.addColumn(locations, locations.thumbPath);
            await m.addColumn(plants, plants.number);
            await _numberExistingPlants();
            await customStatement('UPDATE gardens SET plant_counter = (SELECT COALESCE(MAX(number), 0) FROM plants WHERE plants.garden_id = gardens.id)');
          }
          if (from < 9) {
            await m.createTable(inventoryGroups);
            await m.createTable(inventoryTags);
            await m.addColumn(inventoryItems, inventoryItems.groupId);
          }
          if (from < 10) {
            await m.createTable(eventCategories);
            await m.createTable(calendarEntries);
          }
          if (from < 11) {
            await m.addColumn(plants, plants.healthIssue);
            await m.addColumn(plants, plants.light);
            await m.addColumn(plants, plants.humidity);
            await m.addColumn(plants, plants.lifespan);
            await m.addColumn(plants, plants.hardiness);
            await m.addColumn(plants, plants.cuttingMonth);
          }
          if (from < 12) {
            await m.addColumn(inventoryItems, inventoryItems.fertilizerForm);
            await m.addColumn(inventoryItems, inventoryItems.fertilizerOrigin);
            await m.addColumn(inventoryItems, inventoryItems.nitrogen);
            await m.addColumn(inventoryItems, inventoryItems.phosphorus);
            await m.addColumn(inventoryItems, inventoryItems.potassium);
          }
          if (from < 13) {
            await m.createTable(roomScans);
            await m.createTable(roomMarkers);
          }
          await _createIndexes();
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          await _seedActionTypes();
        },
      );

  Future<void> _createIndexes() async {
    await customStatement('CREATE INDEX IF NOT EXISTS idx_plants_status ON plants(status, deleted_at)');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_plants_location ON plants(location_id)');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_actions_plant ON plant_actions(plant_id, occurred_at)');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_schedules_due ON care_schedules(enabled, next_due_at)');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_schedules_plant ON care_schedules(plant_id, type_key)');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_photos_plant ON plant_photos(plant_id, taken_at)');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_measurements_plant ON measurements(plant_id, kind, measured_at)');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_inventory_category ON inventory_items(garden_id, category_key)');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_tasks_open ON tasks(garden_id, done, due_at)');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_tasks_plant ON tasks(plant_id)');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_plant_attributes_plant ON plant_attributes(plant_id)');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_attachments_plant ON plant_attachments(plant_id)');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_location_logs_location ON location_logs(location_id, created_at)');
    await customStatement('CREATE UNIQUE INDEX IF NOT EXISTS idx_plants_number ON plants(garden_id, number) WHERE number > 0');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_inventory_group ON inventory_items(group_id)');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_inventory_tags_item ON inventory_tags(item_id)');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_room_markers_scan ON room_markers(scan_id)');
  }

  /// Attribue un numéro aux plantes créées avant la v8, par ordre de création.
  Future<void> _numberExistingPlants() async {
    await customStatement('''
      UPDATE plants SET number = (
        SELECT COUNT(*) FROM plants AS earlier
        WHERE earlier.garden_id = plants.garden_id AND earlier.created_at <= plants.created_at
      ) WHERE number = 0
    ''');
  }

  /// Les types intégrés existent toujours en base pour rester triables avec
  /// les types personnalisés.
  Future<void> _seedActionTypes() async {
    await batch((b) {
      for (final (i, kind) in CareKind.values.indexed) {
        b.insert(
          actionTypes,
          ActionTypesCompanion.insert(
            key: kind.key,
            emoji: kind.emoji,
            isBuiltin: true,
            schedulable: Value(kind.isSchedulable),
            sortOrder: i,
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
  }

  /// Efface tout ce qu'un jardin laisse sur l'appareil : ses lignes, et les
  /// envois qui les attendaient.
  ///
  /// Sert à la suppression d'un jardin. La file de synchronisation se vide sur
  /// le seul identifiant : les UUID sont uniques d'une table à l'autre, et une
  /// ligne qui n'existe plus n'a rien à pousser — sans cela, la synchronisation
  /// suivante irait supprimer là-bas, une par une, des lignes déjà parties avec
  /// leur jardin.
  Future<void> purgeGarden(String gardenId) async {
    await transaction(() async {
      final plantIds = (await (select(plants)..where((r) => r.gardenId.equals(gardenId))).get()).map((r) => r.id).toList();
      final itemIds = (await (select(inventoryItems)..where((r) => r.gardenId.equals(gardenId))).get()).map((r) => r.id).toList();
      final ids = <String>{
        gardenId,
        ...plantIds,
        ...itemIds,
        for (final r in await (select(locations)..where((x) => x.gardenId.equals(gardenId))).get()) r.id,
        for (final r in await (select(tags)..where((x) => x.gardenId.equals(gardenId))).get()) r.id,
        for (final r in await (select(inventoryGroups)..where((x) => x.gardenId.equals(gardenId))).get()) r.id,
        for (final r in await (select(tasks)..where((x) => x.gardenId.equals(gardenId))).get()) r.id,
        for (final r in await (select(plantAttributes)..where((x) => x.gardenId.equals(gardenId))).get()) r.id,
        for (final r in await (select(attributeSchemas)..where((x) => x.gardenId.equals(gardenId))).get()) r.id,
        for (final r in await (select(plantAttachments)..where((x) => x.gardenId.equals(gardenId))).get()) r.id,
        for (final r in await (select(locationLogs)..where((x) => x.gardenId.equals(gardenId))).get()) r.id,
        for (final r in await (select(eventCategories)..where((x) => x.gardenId.equals(gardenId))).get()) r.id,
        for (final r in await (select(calendarEntries)..where((x) => x.gardenId.equals(gardenId))).get()) r.id,
        // Les filles d'une plante ou d'un article ne portent pas le jardin :
        // elles se relèvent sur leur parent.
        for (final r in await (select(plantPhotos)..where((x) => x.plantId.isIn(plantIds))).get()) r.id,
        for (final r in await (select(plantActions)..where((x) => x.plantId.isIn(plantIds))).get()) r.id,
        for (final r in await (select(careSchedules)..where((x) => x.plantId.isIn(plantIds))).get()) r.id,
        for (final r in await (select(measurements)..where((x) => x.plantId.isIn(plantIds))).get()) r.id,
        // Les tables d'association s'identifient par leurs deux clés.
        for (final r in await (select(plantTags)..where((x) => x.plantId.isIn(plantIds))).get()) '${r.plantId}/${r.tagId}',
        for (final r in await (select(inventoryTags)..where((x) => x.itemId.isIn(itemIds))).get()) '${r.itemId}/${r.tagId}',
      };
      await (delete(plantTags)..where((x) => x.plantId.isIn(plantIds))).go();
      await (delete(plantPhotos)..where((x) => x.plantId.isIn(plantIds))).go();
      await (delete(plantActions)..where((x) => x.plantId.isIn(plantIds))).go();
      await (delete(careSchedules)..where((x) => x.plantId.isIn(plantIds))).go();
      await (delete(measurements)..where((x) => x.plantId.isIn(plantIds))).go();
      await (delete(inventoryTags)..where((x) => x.itemId.isIn(itemIds))).go();
      await (delete(plants)..where((x) => x.gardenId.equals(gardenId))).go();
      await (delete(locations)..where((x) => x.gardenId.equals(gardenId))).go();
      await (delete(tags)..where((x) => x.gardenId.equals(gardenId))).go();
      await (delete(inventoryItems)..where((x) => x.gardenId.equals(gardenId))).go();
      await (delete(inventoryGroups)..where((x) => x.gardenId.equals(gardenId))).go();
      await (delete(tasks)..where((x) => x.gardenId.equals(gardenId))).go();
      await (delete(plantAttributes)..where((x) => x.gardenId.equals(gardenId))).go();
      await (delete(attributeSchemas)..where((x) => x.gardenId.equals(gardenId))).go();
      await (delete(plantAttachments)..where((x) => x.gardenId.equals(gardenId))).go();
      await (delete(locationLogs)..where((x) => x.gardenId.equals(gardenId))).go();
      await (delete(eventCategories)..where((x) => x.gardenId.equals(gardenId))).go();
      await (delete(calendarEntries)..where((x) => x.gardenId.equals(gardenId))).go();
      await (delete(gardenMembers)..where((x) => x.gardenId.equals(gardenId))).go();
      await (delete(gardens)..where((x) => x.id.equals(gardenId))).go();
      await (delete(syncOutbox)..where((o) => o.entityId.isIn(ids.toList()))).go();
    });
  }

  /// Enregistre une écriture dans l'outbox de synchronisation.
  Future<void> enqueueSync(String entity, String entityId, String op, Map<String, Object?> payload) =>
      into(syncOutbox).insert(SyncOutboxCompanion.insert(
        entity: entity,
        entityId: entityId,
        op: op,
        payload: jsonEncode(payload),
        createdAt: DateTime.now(),
      ));
}
