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
])
class FloraDatabase extends _$FloraDatabase {
  FloraDatabase(super.executor);

  @override
  int get schemaVersion => 9;

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
