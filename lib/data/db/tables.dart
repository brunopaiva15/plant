import 'package:drift/drift.dart';

/// Schéma local SQLite, miroir du schéma Postgres cible (docs/04-data-model.md).
/// Les noms de data classes sont suffixés `Row` pour ne pas entrer en conflit
/// avec les modèles de domaine.

mixin Timestamps on Table {
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

@DataClassName('GardenRow')
class Gardens extends Table with Timestamps {
  TextColumn get id => text()();
  TextColumn get ownerId => text()();
  TextColumn get name => text()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('LocationRow')
class Locations extends Table with Timestamps {
  TextColumn get id => text()();
  TextColumn get gardenId => text()();
  TextColumn get parentId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get icon => text()();
  TextColumn get light => text().nullable()();
  TextColumn get orientation => text().nullable()();
  BoolColumn get isOutdoor => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PlantRow')
class Plants extends Table with Timestamps {
  TextColumn get id => text()();
  TextColumn get gardenId => text()();
  TextColumn get name => text()();
  TextColumn get speciesName => text().nullable()();
  TextColumn get locationId => text().nullable()();
  TextColumn get primaryPhotoId => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  TextColumn get health => text().withDefault(const Constant('healthy'))();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  DateTimeColumn get acquiredAt => dateTime().nullable()();
  TextColumn get source => text().nullable()();
  RealColumn get price => real().nullable()();
  RealColumn get potSize => real().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get parentPlantId => text().nullable()();
  DateTimeColumn get archivedAt => dateTime().nullable()();
  TextColumn get archiveReason => text().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PlantPhotoRow')
class PlantPhotos extends Table {
  TextColumn get id => text()();
  TextColumn get plantId => text()();
  TextColumn get filePath => text()();
  TextColumn get thumbPath => text()();
  IntColumn get width => integer()();
  IntColumn get height => integer()();
  DateTimeColumn get takenAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ActionTypeRow')
class ActionTypes extends Table {
  TextColumn get key => text()();
  TextColumn get label => text().nullable()();
  TextColumn get emoji => text()();
  BoolColumn get isBuiltin => boolean()();
  BoolColumn get schedulable => boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer()();

  @override
  Set<Column> get primaryKey => {key};
}

@DataClassName('PlantActionRow')
class PlantActions extends Table {
  TextColumn get id => text()();
  TextColumn get plantId => text()();
  TextColumn get typeKey => text()();
  DateTimeColumn get occurredAt => dateTime()();
  TextColumn get notes => text().nullable()();
  TextColumn get metadata => text().withDefault(const Constant('{}'))();
  TextColumn get photoId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('CareScheduleRow')
class CareSchedules extends Table with Timestamps {
  TextColumn get id => text()();
  TextColumn get plantId => text()();
  TextColumn get typeKey => text()();
  TextColumn get strategy => text()();
  IntColumn get intervalDays => integer()();
  TextColumn get seasonalRules => text().nullable()();
  DateTimeColumn get nextDueAt => dateTime().nullable()();
  DateTimeColumn get lastCompletedAt => dateTime().nullable()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TagRow')
class Tags extends Table {
  TextColumn get id => text()();
  TextColumn get gardenId => text()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PlantTagRow')
class PlantTags extends Table {
  TextColumn get plantId => text()();
  TextColumn get tagId => text()();

  @override
  Set<Column> get primaryKey => {plantId, tagId};
}

@DataClassName('MeasurementRow')
class Measurements extends Table {
  TextColumn get id => text()();
  TextColumn get plantId => text()();
  TextColumn get actionId => text().nullable()();
  TextColumn get kind => text()();
  RealColumn get value => real()();
  TextColumn get unit => text()();
  DateTimeColumn get measuredAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// File d'attente de synchronisation (offline-first). Drainée en Phase 2.
@DataClassName('SyncOutboxRow')
class SyncOutbox extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entity => text()();
  TextColumn get entityId => text()();
  TextColumn get op => text()();
  TextColumn get payload => text()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
}

@DataClassName('InventoryItemRow')
class InventoryItems extends Table with Timestamps {
  TextColumn get id => text()();
  TextColumn get gardenId => text()();
  TextColumn get categoryKey => text()();
  TextColumn get name => text()();
  RealColumn get quantity => real().withDefault(const Constant(0))();
  TextColumn get unit => text().withDefault(const Constant(''))();
  RealColumn get lowThreshold => real().nullable()();
  TextColumn get locationId => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get photoPath => text().nullable()();
  TextColumn get thumbPath => text().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
