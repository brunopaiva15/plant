enum PlantStatus { active, archived }

enum PlantHealth { healthy, watch, sick }

/// La plante. Seuls `name` et `gardenId` sont obligatoires : l'utilisateur ne
/// remplit jamais un formulaire complet.
class Plant {
  const Plant({
    required this.id,
    required this.gardenId,
    required this.name,
    required this.status,
    required this.health,
    required this.isFavorite,
    required this.createdAt,
    required this.updatedAt,
    this.speciesName,
    this.locationId,
    this.primaryPhotoId,
    this.acquiredAt,
    this.source,
    this.price,
    this.potSize,
    this.notes,
    this.parentPlantId,
    this.archivedAt,
    this.archiveReason,
  });

  final String id;
  final String gardenId;
  final String name;
  final String? speciesName;
  final String? locationId;
  final String? primaryPhotoId;
  final PlantStatus status;
  final PlantHealth health;
  final bool isFavorite;
  final DateTime? acquiredAt;
  final String? source;
  final double? price;
  final double? potSize;
  final String? notes;
  final String? parentPlantId;
  final DateTime? archivedAt;
  final String? archiveReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isArchived => status == PlantStatus.archived;

  Plant copyWith({
    String? name,
    String? Function()? speciesName,
    String? Function()? locationId,
    String? Function()? primaryPhotoId,
    PlantStatus? status,
    PlantHealth? health,
    bool? isFavorite,
    DateTime? Function()? acquiredAt,
    String? Function()? source,
    double? Function()? price,
    double? Function()? potSize,
    String? Function()? notes,
    String? Function()? parentPlantId,
    DateTime? Function()? archivedAt,
    String? Function()? archiveReason,
    DateTime? updatedAt,
  }) =>
      Plant(
        id: id,
        gardenId: gardenId,
        name: name ?? this.name,
        speciesName: speciesName != null ? speciesName() : this.speciesName,
        locationId: locationId != null ? locationId() : this.locationId,
        primaryPhotoId: primaryPhotoId != null ? primaryPhotoId() : this.primaryPhotoId,
        status: status ?? this.status,
        health: health ?? this.health,
        isFavorite: isFavorite ?? this.isFavorite,
        acquiredAt: acquiredAt != null ? acquiredAt() : this.acquiredAt,
        source: source != null ? source() : this.source,
        price: price != null ? price() : this.price,
        potSize: potSize != null ? potSize() : this.potSize,
        notes: notes != null ? notes() : this.notes,
        parentPlantId: parentPlantId != null ? parentPlantId() : this.parentPlantId,
        archivedAt: archivedAt != null ? archivedAt() : this.archivedAt,
        archiveReason: archiveReason != null ? archiveReason() : this.archiveReason,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
