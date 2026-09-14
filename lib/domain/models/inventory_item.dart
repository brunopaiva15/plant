/// Catégories d'inventaire intégrées. Simples, avec un emoji chacune.
enum InventoryCategory {
  fertilizer('fertilizer', '🧪'),
  soil('soil', '🪵'),
  substrate('substrate', '🪨'),
  pot('pot', '🪴'),
  tool('tool', '🧰'),
  treatment('treatment', '🧴'),
  seed('seed', '🌰'),
  accessory('accessory', '🧷');

  const InventoryCategory(this.key, this.emoji);

  final String key;
  final String emoji;

  /// Unité par défaut proposée à la création.
  String get defaultUnit => switch (this) {
        fertilizer || treatment => 'ml',
        soil || substrate => 'L',
        pot || tool || seed || accessory => '',
      };

  static InventoryCategory fromKey(String key) => values.firstWhere((c) => c.key == key, orElse: () => InventoryCategory.accessory);
}

/// Forme d'un engrais : ce qu'on tient dans la main au moment de doser.
/// Propre à [InventoryCategory.fertilizer] ; nulle partout ailleurs.
enum FertilizerForm {
  liquid,
  granules,
  sticks,
  solublePowder,
  foliar,
  other;

  /// Depuis la valeur stockée ; `null` pour une valeur inconnue plutôt
  /// qu'une erreur — une version plus récente peut en connaître d'autres.
  static FertilizerForm? parse(String? raw) => raw == null ? null : values.asNameMap()[raw];
}

/// Origine d'un engrais : d'où viennent ses éléments.
enum FertilizerOrigin {
  mineral,
  organic,
  organomineral;

  static FertilizerOrigin? parse(String? raw) => raw == null ? null : values.asNameMap()[raw];
}

class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.gardenId,
    required this.category,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.createdAt,
    required this.updatedAt,
    this.groupId,
    this.tags = const [],
    this.lowThreshold,
    this.locationId,
    this.notes,
    this.photoPath,
    this.thumbPath,
    this.fertilizerForm,
    this.fertilizerOrigin,
    this.nitrogen,
    this.phosphorus,
    this.potassium,
  });

  final String id;
  final String gardenId;
  final InventoryCategory category;

  /// Groupe personnalisé. `null` : le groupe vient de [category].
  final String? groupId;

  /// Noms des tags, pour l'affichage et le filtrage.
  final List<String> tags;
  final String name;
  final double quantity;

  /// `ml`, `cl`, `L`, `g`, `kg`, `cm`, `m` ou vide pour des unités (pièces).
  final String unit;
  final double? lowThreshold;
  final String? locationId;
  final String? notes;
  final String? photoPath;
  final String? thumbPath;

  /// Caractérisation d'un engrais. Ces cinq champs ne valent que pour
  /// [InventoryCategory.fertilizer] : le dépôt les efface dès que l'article
  /// change de catégorie, pour qu'un pot ne traîne jamais un NPK.
  final FertilizerForm? fertilizerForm;
  final FertilizerOrigin? fertilizerOrigin;

  /// Azote, phosphore et potassium, en pourcentage de la masse. Chacun
  /// facultatif : un engrais peut n'annoncer qu'un seul élément.
  final double? nitrogen;
  final double? phosphorus;
  final double? potassium;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isLow => lowThreshold != null && quantity <= lowThreshold!;

  /// « 7-3-5 », l'ordre que tous les sacs impriment. Un élément non renseigné
  /// s'écrit « – » : absent n'est pas zéro. `null` quand aucun des trois
  /// n'est connu, pour que l'affichage saute simplement la mention.
  String? get npk {
    if (nitrogen == null && phosphorus == null && potassium == null) return null;
    String part(double? v) => v == null ? '–' : (v == v.roundToDouble() ? v.toInt().toString() : v.toString());
    return '${part(nitrogen)}-${part(phosphorus)}-${part(potassium)}';
  }

  InventoryItem copyWith({
    InventoryCategory? category,
    String? Function()? groupId,
    List<String>? tags,
    String? name,
    double? quantity,
    String? unit,
    double? Function()? lowThreshold,
    String? Function()? locationId,
    String? Function()? notes,
    String? Function()? photoPath,
    String? Function()? thumbPath,
    FertilizerForm? Function()? fertilizerForm,
    FertilizerOrigin? Function()? fertilizerOrigin,
    double? Function()? nitrogen,
    double? Function()? phosphorus,
    double? Function()? potassium,
    DateTime? updatedAt,
  }) =>
      InventoryItem(
        id: id,
        groupId: groupId != null ? groupId() : this.groupId,
        tags: tags ?? this.tags,
        gardenId: gardenId,
        category: category ?? this.category,
        name: name ?? this.name,
        quantity: quantity ?? this.quantity,
        unit: unit ?? this.unit,
        lowThreshold: lowThreshold != null ? lowThreshold() : this.lowThreshold,
        locationId: locationId != null ? locationId() : this.locationId,
        notes: notes != null ? notes() : this.notes,
        photoPath: photoPath != null ? photoPath() : this.photoPath,
        thumbPath: thumbPath != null ? thumbPath() : this.thumbPath,
        fertilizerForm: fertilizerForm != null ? fertilizerForm() : this.fertilizerForm,
        fertilizerOrigin: fertilizerOrigin != null ? fertilizerOrigin() : this.fertilizerOrigin,
        nitrogen: nitrogen != null ? nitrogen() : this.nitrogen,
        phosphorus: phosphorus != null ? phosphorus() : this.phosphorus,
        potassium: potassium != null ? potassium() : this.potassium,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

/// Unités proposées (métrique). L'impérial est converti à l'affichage plus tard.
const inventoryUnits = ['', 'ml', 'cl', 'L', 'g', 'kg', 'cm', 'm'];

/// Groupe d'inventaire nommé par l'utilisateur.
class InventoryGroup {
  const InventoryGroup({
    required this.id,
    required this.gardenId,
    required this.label,
    required this.emoji,
    required this.position,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String gardenId;
  final String label;
  final String emoji;
  final int position;
  final DateTime createdAt;
  final DateTime updatedAt;

  InventoryGroup copyWith({String? label, String? emoji, int? position, DateTime? updatedAt}) => InventoryGroup(
        id: id,
        gardenId: gardenId,
        label: label ?? this.label,
        emoji: emoji ?? this.emoji,
        position: position ?? this.position,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
