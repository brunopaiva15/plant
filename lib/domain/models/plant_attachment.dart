import '../../core/utils/file_kinds.dart';

/// Document rattaché à une plante : facture, fiche du producteur, analyse de
/// sol. Le fichier est copié dans le dossier de l'application.
class PlantAttachment {
  const PlantAttachment({
    required this.id,
    required this.gardenId,
    required this.plantId,
    required this.label,
    required this.filePath,
    required this.createdAt,
    required this.updatedAt,
    this.userId,
    this.mimeType,
    this.sizeBytes,
  });

  final String id;
  final String gardenId;
  final String plantId;
  final String? userId;
  final String label;

  /// Chemin relatif au dossier documents de l'application.
  final String filePath;
  final String? mimeType;
  final int? sizeBytes;
  final DateTime createdAt;
  final DateTime updatedAt;

  FileKind get kind => FileKinds.of(filePath, mimeType);

  PlantAttachment copyWith({String? label, DateTime? updatedAt}) => PlantAttachment(
        id: id,
        gardenId: gardenId,
        plantId: plantId,
        userId: userId,
        label: label ?? this.label,
        filePath: filePath,
        mimeType: mimeType,
        sizeBytes: sizeBytes,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
