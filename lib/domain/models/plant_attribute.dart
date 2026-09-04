/// Type d'un attribut personnalisé. La valeur est stockée en texte et
/// interprétée à la lecture, comme dans HortusFox.
enum AttributeType {
  boolean('bool'),
  integer('int'),
  decimal('double'),
  text('string'),
  date('datetime');

  const AttributeType(this.key);

  final String key;

  static AttributeType fromKey(String? key) => values.where((t) => t.key == key).firstOrNull ?? AttributeType.text;
}

/// Champ libre ajouté à une plante : « Provenance = Marché de Vevey »,
/// « Bouturée le = 12/04/2026 », « Hauteur du pot = 18 ».
class PlantAttribute {
  const PlantAttribute({
    required this.id,
    required this.gardenId,
    required this.plantId,
    required this.label,
    required this.type,
    required this.position,
    required this.createdAt,
    required this.updatedAt,
    this.value,
  });

  final String id;
  final String gardenId;
  final String plantId;
  final String label;
  final AttributeType type;

  /// Représentation textuelle brute ; utilisez les accesseurs typés.
  final String? value;
  final int position;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isEmpty => value == null || value!.trim().isEmpty;

  bool? get asBool => switch (value?.trim().toLowerCase()) {
        '1' || 'true' || 'yes' || 'oui' => true,
        '0' || 'false' || 'no' || 'non' => false,
        _ => null,
      };

  int? get asInt => value == null ? null : int.tryParse(value!.trim());

  double? get asDouble => value == null ? null : double.tryParse(value!.trim().replaceAll(',', '.'));

  DateTime? get asDate => value == null ? null : DateTime.tryParse(value!.trim());

  /// Encode une valeur typée vers son stockage texte.
  static String? encode(AttributeType type, Object? raw) {
    if (raw == null) return null;
    return switch (type) {
      AttributeType.boolean => (raw as bool) ? 'true' : 'false',
      AttributeType.date => (raw as DateTime).toIso8601String(),
      _ => raw.toString().trim(),
    };
  }

  PlantAttribute copyWith({
    String? label,
    AttributeType? type,
    String? Function()? value,
    int? position,
    DateTime? updatedAt,
  }) =>
      PlantAttribute(
        id: id,
        gardenId: gardenId,
        plantId: plantId,
        label: label ?? this.label,
        type: type ?? this.type,
        value: value != null ? value() : this.value,
        position: position ?? this.position,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

/// Modèle d'attribut réutilisable sur toutes les plantes du jardin.
class AttributeSchema {
  const AttributeSchema({
    required this.id,
    required this.gardenId,
    required this.label,
    required this.type,
    required this.active,
    required this.position,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String gardenId;
  final String label;
  final AttributeType type;
  final bool active;
  final int position;
  final DateTime createdAt;
  final DateTime updatedAt;

  AttributeSchema copyWith({String? label, AttributeType? type, bool? active, int? position, DateTime? updatedAt}) => AttributeSchema(
        id: id,
        gardenId: gardenId,
        label: label ?? this.label,
        type: type ?? this.type,
        active: active ?? this.active,
        position: position ?? this.position,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
