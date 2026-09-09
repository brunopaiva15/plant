import 'plant_diagnoser.dart';

/// Une photo soumise à l'analyse, gardée avec le compte rendu.
///
/// Les chemins sont relatifs au dossier des photos, comme partout ailleurs.
class DiagnosisPhoto {
  const DiagnosisPhoto({required this.filePath, required this.thumbPath});

  final String filePath;
  final String thumbPath;

  Map<String, Object?> toJson() => {'file': filePath, 'thumb': thumbPath};

  /// `null` si l'entrée ne nomme aucun fichier : une vignette sans original
  /// se relit, un enregistrement vide non.
  static DiagnosisPhoto? fromJson(Map<String, Object?> json) {
    final file = json['file'];
    if (file is! String || file.isEmpty) return null;
    final thumb = json['thumb'];
    return DiagnosisPhoto(filePath: file, thumbPath: thumb is String && thumb.isNotEmpty ? thumb : file);
  }
}

/// Le compte rendu complet d'une analyse, tel qu'il est gardé dans le journal.
///
/// L'entrée du journal reste une note lisible telle quelle — résumé et trois
/// pistes en texte —, mais elle porte en plus tout ce que l'analyse a rendu :
/// chaque piste avec son explication et ses gestes, l'urgence, les symptômes
/// signalés, les photos regardées. C'est ce qui permet de rouvrir un
/// diagnostic des mois plus tard au lieu d'en relire l'aperçu.
///
/// Les numéros de la base ([DiagnosisCause.problemId]) sont conservés : à la
/// réouverture, les noms des pistes sont redonnés par la base, dans la langue
/// de l'application du moment et non dans celle du jour de l'analyse.
class DiagnosisRecord {
  /// [symptoms] est ramené à `null` quand il ne dit rien : un champ laissé
  /// vide n'est pas un symptôme signalé, et le compte rendu n'a pas à lui
  /// donner un titre.
  DiagnosisRecord({required this.diagnosis, String? symptoms, this.photos = const []})
      : symptoms = symptoms != null && symptoms.trim().isNotEmpty ? symptoms.trim() : null;

  /// Clé sous laquelle le compte rendu vit dans `PlantAction.metadata`. Les
  /// métadonnées partent en synchronisation et en sauvegarde avec la ligne :
  /// le compte rendu suit le journal sans table de plus.
  static const metadataKey = 'diagnosis';

  final Diagnosis diagnosis;

  /// Ce que l'utilisateur avait décrit avant l'analyse, s'il a écrit quelque
  /// chose.
  final String? symptoms;

  /// Les photos analysées. Elles restent sur l'appareil qui a fait l'analyse
  /// (voir `DiagnosisPhotoStrip`).
  final List<DiagnosisPhoto> photos;

  Map<String, Object?> toJson() => {
        'version': 1,
        ...diagnosis.toJson(),
        if (symptoms != null && symptoms!.isNotEmpty) 'symptoms': symptoms,
        if (photos.isNotEmpty) 'photos': [for (final p in photos) p.toJson()],
      };

  /// Le compte rendu porté par une entrée du journal, ou `null` pour une
  /// entrée ordinaire — c'est-à-dire l'immense majorité d'entre elles.
  static DiagnosisRecord? fromMetadata(Map<String, Object?> metadata) {
    final raw = metadata[metadataKey];
    if (raw is! Map) return null;
    final json = raw.cast<String, Object?>();
    final diagnosis = Diagnosis.fromJson(json);
    // Une analyse sans rien à dire n'est pas un compte rendu : la note seule
    // fera mieux l'affaire.
    if (diagnosis.summary.isEmpty && diagnosis.causes.isEmpty) return null;
    return DiagnosisRecord(
      diagnosis: diagnosis,
      symptoms: json['symptoms'] is String ? json['symptoms'] as String : null,
      photos: [
        for (final p in json['photos'] is List ? json['photos'] as List : const [])
          if (p is Map) ?DiagnosisPhoto.fromJson(p.cast<String, Object?>()),
      ],
    );
  }
}
