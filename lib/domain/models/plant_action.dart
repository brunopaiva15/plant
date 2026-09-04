/// Une action enregistrée dans l'historique d'une plante (append-only).
class PlantAction {
  const PlantAction({
    required this.id,
    required this.plantId,
    required this.typeKey,
    required this.occurredAt,
    required this.createdAt,
    this.notes,
    this.metadata = const {},
    this.photoId,
  });

  final String id;
  final String plantId;

  /// Clé du type ([CareKind.key] ou `custom:…`).
  final String typeKey;
  final DateTime occurredAt;
  final String? notes;

  /// Données libres : quantité, unité, mesure…
  final Map<String, Object?> metadata;
  final String? photoId;
  final DateTime createdAt;
}
