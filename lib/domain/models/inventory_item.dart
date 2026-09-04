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
    this.lowThreshold,
    this.locationId,
    this.notes,
    this.photoPath,
    this.thumbPath,
  });

  final String id;
  final String gardenId;
  final InventoryCategory category;
  final String name;
  final double quantity;

  /// `ml`, `cl`, `L`, `g`, `kg`, `cm`, `m` ou vide pour des unités (pièces).
  final String unit;
  final double? lowThreshold;
  final String? locationId;
  final String? notes;
  final String? photoPath;
  final String? thumbPath;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isLow => lowThreshold != null && quantity <= lowThreshold!;

  InventoryItem copyWith({
    InventoryCategory? category,
    String? name,
    double? quantity,
    String? unit,
    double? Function()? lowThreshold,
    String? Function()? locationId,
    String? Function()? notes,
    String? Function()? photoPath,
    String? Function()? thumbPath,
    DateTime? updatedAt,
  }) =>
      InventoryItem(
        id: id,
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
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

/// Unités proposées (métrique). L'impérial est converti à l'affichage plus tard.
const inventoryUnits = ['', 'ml', 'cl', 'L', 'g', 'kg', 'cm', 'm'];
