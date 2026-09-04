class PlantPhoto {
  const PlantPhoto({
    required this.id,
    required this.plantId,
    required this.filePath,
    required this.thumbPath,
    required this.width,
    required this.height,
    required this.takenAt,
    required this.createdAt,
  });

  final String id;
  final String plantId;

  /// Chemins relatifs au dossier documents de l'application.
  final String filePath;
  final String thumbPath;
  final int width;
  final int height;
  final DateTime takenAt;
  final DateTime createdAt;
}
