import '../care/care_profile.dart';
import '../problems/plant_problem.dart';

enum PlantStatus { active, archived }

/// État de santé, avec l'icône qui le dit d'un coup d'œil. Le nom (`healthy`,
/// `watch`, `sick`) est ce qui est stocké et synchronisé : il ne bouge pas.
enum PlantHealth {
  healthy('💚'),
  watch('👀'),
  sick('🤒');

  const PlantHealth(this.emoji);

  final String emoji;
}

/// Ce qui ne va pas, quand la plante n'est pas en forme. Facultatif : « à
/// surveiller » sans dire pourquoi reste permis. Le nom est stocké tel quel.
///
/// Chaque entrée pointe vers la base des deux cents problèmes, quand celle-ci
/// dit la même chose : c'est de là que vient son illustration d'argile, et
/// c'est ce qui fait que « Manque d'eau » se lit pareil ici, sur la fiche de
/// soin et dans un diagnostic. Les deux familles — ravageurs, maladies — ne
/// désignent aucune entrée en particulier ; elles portent le symbole de leur
/// famille, qui est exactement ce qu'elles disent.
enum HealthIssue {
  overwatering(kind: ProblemKind.disorder, problemId: '002'),
  underwatering(kind: ProblemKind.disorder, problemId: '001'),
  pests(kind: ProblemKind.pest),
  disease(kind: ProblemKind.disease),
  rootRot(kind: ProblemKind.disease, problemId: '172'),
  transplantShock(kind: ProblemKind.disorder, problemId: '007'),
  deficiency(kind: ProblemKind.disorder, problemId: '025'),
  sunburn(kind: ProblemKind.disorder, problemId: '009'),
  frost(kind: ProblemKind.disorder, problemId: '012');

  const HealthIssue({required this.kind, this.problemId});

  /// La famille dont relève ce problème, et le symbole qui la représente
  /// quand aucune entrée précise n'est désignée.
  final ProblemKind kind;

  /// L'entrée de la base qui dit la même chose, s'il y en a une.
  final String? problemId;

  /// Depuis la valeur stockée ; `null` pour une valeur inconnue plutôt
  /// qu'une erreur — une version plus récente peut en connaître d'autres.
  static HealthIssue? parse(String? raw) => raw == null ? null : values.asNameMap()[raw];
}

/// Cycle de vie : une plante annuelle ne reviendra pas, une vivace si.
enum Lifespan {
  annual,
  biennial,
  perennial;

  static Lifespan? parse(String? raw) => raw == null ? null : values.asNameMap()[raw];
}

/// Résistance au gel.
enum Hardiness {
  hardy,
  tender;

  static Hardiness? parse(String? raw) => raw == null ? null : values.asNameMap()[raw];
}

/// La plante. Seuls `name` et `gardenId` sont obligatoires : l'utilisateur ne
/// remplit jamais un formulaire complet.
class Plant {
  const Plant({
    required this.id,
    required this.gardenId,
    required this.name,
    this.number = 0,
    required this.status,
    required this.health,
    required this.isFavorite,
    required this.createdAt,
    required this.updatedAt,
    this.healthIssue,
    this.speciesName,
    this.locationId,
    this.primaryPhotoId,
    this.light,
    this.humidity,
    this.lifespan,
    this.hardiness,
    this.cuttingMonth,
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

  /// Numéro court et lisible, unique par jardin : « #42 ».
  final int number;
  final String name;
  final String? speciesName;
  final String? locationId;
  final String? primaryPhotoId;
  final PlantStatus status;
  final PlantHealth health;

  /// Précision sur l'état, quand il n'est pas « en forme ».
  final HealthIssue? healthIssue;
  final bool isFavorite;

  /// Besoins propres à cette plante, quand ils diffèrent de ce que dit la
  /// fiche de l'espèce — ou que l'espèce n'en a pas. La lumière prime sur
  /// celle de l'emplacement dans les conseils d'arrosage.
  final LightNeed? light;
  final HumidityNeed? humidity;
  final Lifespan? lifespan;
  final Hardiness? hardiness;

  /// Mois (1–12) où la bouturer.
  final int? cuttingMonth;
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
    HealthIssue? Function()? healthIssue,
    bool? isFavorite,
    LightNeed? Function()? light,
    HumidityNeed? Function()? humidity,
    Lifespan? Function()? lifespan,
    Hardiness? Function()? hardiness,
    int? Function()? cuttingMonth,
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
        number: number,
        name: name ?? this.name,
        speciesName: speciesName != null ? speciesName() : this.speciesName,
        locationId: locationId != null ? locationId() : this.locationId,
        primaryPhotoId: primaryPhotoId != null ? primaryPhotoId() : this.primaryPhotoId,
        status: status ?? this.status,
        health: health ?? this.health,
        healthIssue: healthIssue != null ? healthIssue() : this.healthIssue,
        isFavorite: isFavorite ?? this.isFavorite,
        light: light != null ? light() : this.light,
        humidity: humidity != null ? humidity() : this.humidity,
        lifespan: lifespan != null ? lifespan() : this.lifespan,
        hardiness: hardiness != null ? hardiness() : this.hardiness,
        cuttingMonth: cuttingMonth != null ? cuttingMonth() : this.cuttingMonth,
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
