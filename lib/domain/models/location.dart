/// Un emplacement (Maison → Salon…). Hiérarchie via [parentId].
class Location {
  const Location({
    required this.id,
    required this.gardenId,
    required this.name,
    required this.icon,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    this.parentId,
    this.light,
    this.orientation,
  });

  final String id;
  final String gardenId;
  final String? parentId;
  final String name;

  /// Emoji d'icône (ex. « 🛋️ »).
  final String icon;
  final String? light;
  final String? orientation;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  Location copyWith({
    String? name,
    String? icon,
    String? Function()? parentId,
    String? Function()? light,
    String? Function()? orientation,
    int? sortOrder,
    DateTime? updatedAt,
  }) =>
      Location(
        id: id,
        gardenId: gardenId,
        name: name ?? this.name,
        icon: icon ?? this.icon,
        parentId: parentId != null ? parentId() : this.parentId,
        light: light != null ? light() : this.light,
        orientation: orientation != null ? orientation() : this.orientation,
        sortOrder: sortOrder ?? this.sortOrder,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

/// Un emplacement avec son nombre de plantes et ses enfants (pour l'arborescence).
class LocationNode {
  const LocationNode({required this.location, required this.plantCount, required this.children});

  final Location location;
  final int plantCount;
  final List<LocationNode> children;

  int get totalPlantCount => plantCount + children.fold(0, (s, c) => s + c.totalPlantCount);
}
