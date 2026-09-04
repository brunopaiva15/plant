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

  /// Dernier numéro de plante attribué. Ne recule jamais, même après une
  /// suppression définitive : un numéro imprimé reste unique pour toujours.
  IntColumn get plantCounter => integer().withDefault(const Constant(0))();
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

  /// Notes libres de l'emplacement (Markdown).
  TextColumn get notes => text().nullable()();

  /// Photo d'illustration : chemins relatifs, comme pour les plantes.
  TextColumn get photoPath => text().nullable()();
  TextColumn get thumbPath => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PlantRow')
class Plants extends Table with Timestamps {
  TextColumn get id => text()();
  TextColumn get gardenId => text()();

  /// Numéro court et lisible, unique par jardin : « #42 ». Sert aux
  /// étiquettes et à la recherche.
  IntColumn get number => integer().withDefault(const Constant(0))();
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
  TextColumn get userId => text().nullable()();
  TextColumn get label => text().nullable()();

  /// Photo hébergée ailleurs : `filePath` reste vide et l'URL fait foi.
  TextColumn get remoteUrl => text().nullable()();
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
  TextColumn get userId => text().nullable()();
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
  /// Groupe personnalisé. `null` = groupe déduit de [categoryKey] (héritage).
  TextColumn get groupId => text().nullable()();
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

/// Cache local des profils (noms des membres du jardin), alimenté par la synchro.
@DataClassName('ProfileRow')
class Profiles extends Table {
  TextColumn get id => text()();
  TextColumn get displayName => text().withDefault(const Constant(''))();
  TextColumn get email => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Cache local des membres du jardin (rôles), alimenté par la synchro.
@DataClassName('GardenMemberRow')
class GardenMembers extends Table {
  TextColumn get gardenId => text()();
  TextColumn get userId => text()();
  TextColumn get role => text()();

  @override
  Set<Column> get primaryKey => {gardenId, userId};
}

/// Tâches libres (« Nettoyer la serre »), avec ou sans plante, échéance et
/// récurrence facultatives.
@DataClassName('TaskRow')
class Tasks extends Table with Timestamps {
  TextColumn get id => text()();
  TextColumn get gardenId => text()();
  TextColumn get plantId => text().nullable()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get dueAt => dateTime().nullable()();
  BoolColumn get allDay => boolean().withDefault(const Constant(true))();
  IntColumn get recurrenceValue => integer().nullable()();
  TextColumn get recurrenceUnit => text().nullable()();
  BoolColumn get done => boolean().withDefault(const Constant(false))();
  DateTimeColumn get doneAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Attribut personnalisé d'une plante (« Provenance », « Bouturée le »…).
/// La valeur est stockée en texte et interprétée selon [datatype].
@DataClassName('PlantAttributeRow')
class PlantAttributes extends Table with Timestamps {
  TextColumn get id => text()();
  TextColumn get gardenId => text()();
  TextColumn get plantId => text()();
  TextColumn get label => text()();
  TextColumn get datatype => text()();
  TextColumn get value => text().nullable()();
  IntColumn get position => integer().withDefault(const Constant(0))();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Modèle d'attribut réutilisable, proposé sur toutes les plantes du jardin.
@DataClassName('AttributeSchemaRow')
class AttributeSchemas extends Table with Timestamps {
  TextColumn get id => text()();
  TextColumn get gardenId => text()();
  TextColumn get label => text()();
  TextColumn get datatype => text()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  IntColumn get position => integer().withDefault(const Constant(0))();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Pièce jointe d'une plante : facture, fiche du producteur, analyse de sol.
@DataClassName('PlantAttachmentRow')
class PlantAttachments extends Table {
  TextColumn get id => text()();
  TextColumn get gardenId => text()();
  TextColumn get plantId => text()();
  TextColumn get userId => text().nullable()();
  TextColumn get label => text()();
  TextColumn get filePath => text()();
  TextColumn get mimeType => text().nullable()();
  IntColumn get sizeBytes => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Entrée du journal d'un emplacement (« serre rempotée », « store changé »).
@DataClassName('LocationLogRow')
class LocationLogs extends Table with Timestamps {
  TextColumn get id => text()();
  TextColumn get gardenId => text()();
  TextColumn get locationId => text()();
  TextColumn get userId => text().nullable()();
  TextColumn get content => text()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Groupe d'inventaire, librement nommé par l'utilisateur.
@DataClassName('InventoryGroupRow')
class InventoryGroups extends Table with Timestamps {
  TextColumn get id => text()();
  TextColumn get gardenId => text()();
  TextColumn get label => text()();
  TextColumn get emoji => text().withDefault(const Constant('📦'))();
  IntColumn get position => integer().withDefault(const Constant(0))();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Catégorie d'événement du calendrier : « Marché aux plantes », « Taille »…
/// Purement décorative, mais propre au jardin.
@DataClassName('EventCategoryRow')
class EventCategories extends Table with Timestamps {
  TextColumn get id => text()();
  TextColumn get gardenId => text()();
  TextColumn get label => text()();
  TextColumn get emoji => text().withDefault(const Constant('📅'))();

  /// Clé de couleur du jeton de design (`sage`, `water`, `terracotta`…).
  TextColumn get colorKey => text().nullable()();
  IntColumn get position => integer().withDefault(const Constant(0))();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Événement saisi à la main, à côté des échéances de soin projetées.
@DataClassName('CalendarEntryRow')
class CalendarEntries extends Table with Timestamps {
  TextColumn get id => text()();
  TextColumn get gardenId => text()();

  /// Plante concernée, facultative : un événement peut être libre.
  TextColumn get plantId => text().nullable()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get title => text()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get startAt => dateTime()();

  /// Fin facultative. Pour un événement de plusieurs jours, elle porte le
  /// dernier jour ; l'heure est ignorée quand [allDay] est vrai.
  DateTimeColumn get endAt => dateTime().nullable()();
  BoolColumn get allDay => boolean().withDefault(const Constant(true))();

  /// Rappel : minutes avant le début, `null` = pas de notification.
  IntColumn get reminderMinutes => integer().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tags d'un article d'inventaire (réutilise la table `tags`).
@DataClassName('InventoryTagRow')
class InventoryTags extends Table {
  TextColumn get itemId => text()();
  TextColumn get tagId => text()();

  @override
  Set<Column> get primaryKey => {itemId, tagId};
}
