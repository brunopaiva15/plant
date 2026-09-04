/// Entrée du journal d'un emplacement.
class LocationLogEntry {
  const LocationLogEntry({
    required this.id,
    required this.gardenId,
    required this.locationId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.userId,
  });

  final String id;
  final String gardenId;
  final String locationId;
  final String? userId;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
}
