import '../models/models.dart';

/// Filtre de la liste de plantes.
class PlantFilter {
  const PlantFilter({
    this.query = '',
    this.locationId,
    this.status = PlantStatus.active,
    this.needsAttention = false,
    this.favoritesOnly = false,
    this.tagId,
    this.sort = PlantSort.name,
  });

  final String query;
  final String? locationId;
  final PlantStatus status;
  final bool needsAttention;
  final bool favoritesOnly;
  final String? tagId;
  final PlantSort sort;

  bool get hasActiveFilters => locationId != null || needsAttention || favoritesOnly || tagId != null;

  PlantFilter copyWith({
    String? query,
    String? Function()? locationId,
    PlantStatus? status,
    bool? needsAttention,
    bool? favoritesOnly,
    String? Function()? tagId,
    PlantSort? sort,
  }) =>
      PlantFilter(
        query: query ?? this.query,
        locationId: locationId != null ? locationId() : this.locationId,
        status: status ?? this.status,
        needsAttention: needsAttention ?? this.needsAttention,
        favoritesOnly: favoritesOnly ?? this.favoritesOnly,
        tagId: tagId != null ? tagId() : this.tagId,
        sort: sort ?? this.sort,
      );

  @override
  bool operator ==(Object other) =>
      other is PlantFilter &&
      other.query == query &&
      other.locationId == locationId &&
      other.status == status &&
      other.needsAttention == needsAttention &&
      other.favoritesOnly == favoritesOnly &&
      other.tagId == tagId &&
      other.sort == sort;

  @override
  int get hashCode => Object.hash(query, locationId, status, needsAttention, favoritesOnly, tagId, sort);
}

enum PlantSort { name, nextCare, recentlyAdded }

/// Données de création d'une plante (3 étapes : photo, nom, emplacement).
class NewPlant {
  const NewPlant({
    required this.name,
    this.speciesName,
    this.locationId,
    this.acquiredAt,
    this.notes,
    this.parentPlantId,
    this.wateringIntervalDays,
    this.fertilizingIntervalDays,
  });

  final String name;
  final String? speciesName;
  final String? locationId;
  final DateTime? acquiredAt;
  final String? notes;
  final String? parentPlantId;
  final int? wateringIntervalDays;
  final int? fertilizingIntervalDays;
}

abstract class PlantRepository {
  Stream<List<PlantSummary>> watchSummaries(PlantFilter filter);
  Stream<PlantSummary?> watchSummary(String id);
  Stream<Plant?> watchPlant(String id);
  Future<Plant?> getPlant(String id);
  Stream<int> watchActiveCount();
  Stream<List<PlantSummary>> watchChildren(String parentId);
  Future<Plant> create(NewPlant data);
  Future<void> update(Plant plant);
  Future<void> setFavorite(String id, bool value);
  Future<void> moveToLocation(List<String> ids, String? locationId);
  Future<void> archive(List<String> ids, {String? reason});
  Future<void> restore(List<String> ids);
  Future<void> deleteForever(String id);
  Stream<List<PlantSummary>> watchArchived();
}

abstract class LocationRepository {
  Stream<List<Location>> watchAll();
  Stream<List<LocationNode>> watchTree();
  Stream<Location?> watch(String id);
  Future<Location> create({required String name, required String icon, String? parentId, String? light, String? orientation, bool isOutdoor = false});
  Future<void> update(Location location);
  Future<void> delete(String id);
  /// Crée les emplacements de départ si aucun n'existe.
  Future<void> ensureDefaults(List<({String name, String icon, bool outdoor})> defaults);
}

/// Données d'une nouvelle action.
class NewAction {
  const NewAction({
    required this.plantId,
    required this.typeKey,
    this.occurredAt,
    this.notes,
    this.metadata = const {},
    this.photoId,
  });

  final String plantId;
  final String typeKey;
  final DateTime? occurredAt;
  final String? notes;
  final Map<String, Object?> metadata;
  final String? photoId;
}

abstract class ActionRepository {
  Stream<List<PlantAction>> watchByPlant(String plantId, {int? limit});
  Stream<List<PlantAction>> watchRecent({int limit = 20});
  Stream<List<PlantAction>> watchBetween(DateTime from, DateTime to);

  /// Enregistre l'action et complète la routine du même type, s'il y en a une.
  Future<PlantAction> log(NewAction data);

  /// Enregistre la même action pour plusieurs plantes (multi-sélection).
  Future<List<PlantAction>> logMany(List<String> plantIds, String typeKey);

  /// Supprime l'action (Undo) et restaure l'échéance précédente de la routine.
  Future<void> undo(PlantAction action);
}

abstract class CareRepository {
  Stream<List<CareSchedule>> watchByPlant(String plantId);
  Stream<List<CareSchedule>> watchAllEnabled();
  Stream<List<CareTask>> watchTasks({required DateTime until});
  Stream<List<CareTask>> watchDueTasks(DateTime now);
  Future<CareSchedule> upsert(CareSchedule schedule);
  Future<void> delete(String id);
  Future<void> snooze(String scheduleId, DateTime now, {int days = 1});
}

abstract class PhotoRepository {
  Stream<List<PlantPhoto>> watchByPlant(String plantId);
  Stream<List<PlantPhoto>> watchRecent({int limit = 12});
  Future<PlantPhoto> add({
    required String plantId,
    required String filePath,
    required String thumbPath,
    required int width,
    required int height,
    DateTime? takenAt,
  });
  Future<void> setPrimary(String plantId, String photoId);
  Future<void> delete(String photoId);
}

abstract class ActionTypeRepository {
  Stream<List<ActionType>> watchAll();
  Future<ActionType> createCustom({required String label, required String emoji, bool schedulable = true});
  Future<void> deleteCustom(String key);
}

abstract class TagRepository {
  Stream<List<Tag>> watchAll();
  Stream<List<Tag>> watchForPlant(String plantId);
  Future<Tag> create(String name);
  Future<void> setPlantTags(String plantId, List<String> tagIds);
  Future<void> addTagToPlants(List<String> plantIds, String tagId);
  Future<void> delete(String tagId);
}

abstract class MeasurementRepository {
  Stream<List<MeasurementSeries>> watchSeries(String plantId);
}

abstract class InventoryRepository {
  Stream<List<InventoryItem>> watchAll();
  Stream<List<InventoryItem>> watchLowStock();
  Future<InventoryItem> create({
    required InventoryCategory category,
    required String name,
    required double quantity,
    required String unit,
    double? lowThreshold,
    String? locationId,
    String? notes,
    String? photoPath,
    String? thumbPath,
  });
  Future<void> update(InventoryItem item);
  Future<void> adjustQuantity(String id, double delta);
  Future<void> delete(String id);
}

/// Données d'une nouvelle tâche libre.
class NewTask {
  const NewTask({required this.title, this.description, this.plantId, this.dueAt, this.allDay = true, this.recurrence});

  final String title;
  final String? description;
  final String? plantId;
  final DateTime? dueAt;
  final bool allDay;
  final TaskRecurrence? recurrence;
}

abstract class AttributeRepository {
  /// Attributs d'une plante, dans l'ordre d'affichage.
  Stream<List<PlantAttribute>> watchForPlant(String plantId);

  /// Modèles réutilisables du jardin (actifs d'abord).
  Stream<List<AttributeSchema>> watchSchemas({bool activeOnly = false});

  Future<PlantAttribute> add({required String plantId, required String label, required AttributeType type, String? value});
  Future<void> update(PlantAttribute attribute);
  Future<void> delete(String id);

  /// Applique un modèle (ou un couple libellé / type) à plusieurs plantes.
  Future<void> applyToPlants(List<String> plantIds, {required String label, required AttributeType type, String? value});

  /// Recopie les attributs d'une plante vers une autre (bouturage, clonage).
  Future<void> cloneAttributes({required String fromPlantId, required String toPlantId});

  /// Identifiants des plantes dont un attribut contient [query].
  Future<Set<String>> searchPlantIds(String query);

  Future<AttributeSchema> createSchema({required String label, required AttributeType type});
  Future<void> updateSchema(AttributeSchema schema);
  Future<void> deleteSchema(String id);
}

abstract class TaskRepository {
  /// Toutes les tâches non supprimées (ouvertes d'abord, puis par échéance).
  Stream<List<FreeTask>> watchAll();
  Stream<List<FreeTask>> watchOpen();
  Stream<List<FreeTask>> watchByPlant(String plantId);
  Future<FreeTask?> get(String id);
  Future<FreeTask> create(NewTask data);
  Future<void> update(FreeTask task);

  /// Marque faite. Une tâche récurrente reste ouverte et passe à l'occurrence
  /// suivante ; retourne l'état précédent pour permettre l'annulation.
  Future<FreeTask> complete(String id, {DateTime? now});

  /// Rouvre une tâche terminée.
  Future<void> reopen(String id);

  /// Restaure l'état précédent (Undo de `complete`).
  Future<void> restore(FreeTask previous);
  Future<void> delete(String id);
}
