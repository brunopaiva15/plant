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
    this.userId,
    this.label,
    this.remoteUrl,
  });

  final String id;
  final String plantId;

  /// Auteur (compte), `null` pour le compte local.
  final String? userId;

  /// Chemins relatifs au dossier documents de l'application.
  final String filePath;
  final String thumbPath;
  final int width;
  final int height;
  final DateTime takenAt;
  final DateTime createdAt;

  /// Titre libre donné par l'utilisateur (« Avant rempotage »).
  final String? label;

  /// Photo hébergée ailleurs : rien n'est stocké sur l'appareil.
  final String? remoteUrl;

  bool get isRemote => remoteUrl != null && remoteUrl!.isNotEmpty;

  PlantPhoto copyWith({String? Function()? label}) => PlantPhoto(
        id: id,
        plantId: plantId,
        userId: userId,
        filePath: filePath,
        thumbPath: thumbPath,
        width: width,
        height: height,
        takenAt: takenAt,
        createdAt: createdAt,
        label: label != null ? label() : this.label,
        remoteUrl: remoteUrl,
      );
}
