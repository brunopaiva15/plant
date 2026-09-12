import 'dart:convert';

/// Les six étapes du guide de bouturage, dans l'ordre du geste. Chacune a
/// sa séquence d'images rendue sous Blender (`tool/build_cutting_guide.py`)
/// et son texte générique dans les ARB ; l'IA peut préciser le texte pour
/// une espèce, jamais l'ordre ni le nombre des étapes.
enum CuttingStep { stem, cut, leaves, water, roots, pot }

/// Ce que l'IA dit du bouturage d'une espèce : un texte par étape, et la
/// méthode de multiplication qu'elle lui connaît.
///
/// Les textes génériques valent pour une bouture de tige dans l'eau, la plus
/// courante. Pour une espèce donnée, l'IA les réécrit : où se trouve le
/// nœud, si l'eau ou le substrat convient mieux, combien de temps attendre,
/// à quelle saison. Une réponse vide laisse les textes génériques.
class CuttingGuideRefinement {
  const CuttingGuideRefinement({this.steps = const [], this.method});

  /// Un texte par étape de [CuttingStep], dans l'ordre, ou rien.
  final List<String> steps;

  /// La méthode habituelle pour l'espèce, dans le vocabulaire de la fiche
  /// d'entretien (`stemCutting`, `leafCutting`, `division`…), ou `null`.
  final String? method;

  /// Vrai quand l'IA n'a rien précisé : les textes génériques restent, et
  /// la question ne vaut pas d'être reposée.
  bool get isEmpty => steps.isEmpty;

  /// Le texte de [step], ou `null` si l'IA ne l'a pas précisé.
  String? of(CuttingStep step) => step.index < steps.length ? steps[step.index] : null;

  Map<String, Object?> toJson() => {'s': steps, if (method != null) 'm': method};

  factory CuttingGuideRefinement.fromJson(Map<String, Object?> json) {
    final raw = json['s'];
    final steps = raw is List ? [for (final s in raw) if (s is String) s] : const <String>[];
    return CuttingGuideRefinement(
      steps: steps.length == CuttingStep.values.length ? steps : const [],
      method: json['m'] is String ? json['m'] as String : null,
    );
  }
}

class CuttingGuideException implements Exception {
  const CuttingGuideException(this.message);

  final String message;

  @override
  String toString() => 'CuttingGuideException: $message';
}

/// Précise les étapes du guide pour une espèce.
abstract class CuttingGuideRefiner {
  bool get isConfigured;

  Future<CuttingGuideRefinement> refine({required String scientificName, required String language});
}

class UnconfiguredCuttingGuideRefiner implements CuttingGuideRefiner {
  const UnconfiguredCuttingGuideRefiner();

  @override
  bool get isConfigured => false;

  @override
  Future<CuttingGuideRefinement> refine({required String scientificName, required String language}) =>
      throw const CuttingGuideException('unconfigured');
}

/// Les réponses déjà obtenues, gardées sur l'appareil.
///
/// On bouture souvent la même plante ; sans mémoire, la même question
/// repartirait à chaque bouture pour le même texte. Les réponses vides
/// comptent autant que les autres : une espèce que l'IA ne connaît pas ne
/// vaut pas d'être redemandée.
abstract class CuttingGuideStore {
  CuttingGuideRefinement? read(String scientificName, String language);

  Future<void> write(String scientificName, String language, CuttingGuideRefinement refinement);

  /// Clé de rangement, le nom d'espèce normalisé et la langue.
  static String keyOf(String scientificName, String language) => '$language|${scientificName.trim().toLowerCase()}';

  static String encode(Map<String, CuttingGuideRefinement> entries) =>
      jsonEncode({for (final e in entries.entries) e.key: e.value.toJson()});

  static Map<String, CuttingGuideRefinement> decode(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      final json = jsonDecode(raw);
      if (json is! Map) return {};
      return {
        for (final e in json.entries)
          if (e.value is Map) e.key as String: CuttingGuideRefinement.fromJson(Map<String, Object?>.from(e.value as Map)),
      };
    } on FormatException {
      return {};
    }
  }
}
