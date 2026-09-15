import 'dart:convert';

/// Archétype de multiplication : le geste, pas la famille botanique.
///
/// Deux plantes de familles éloignées se multiplient du même geste — on
/// coupe un nœud de monstera comme un nœud de philodendron — et deux plantes
/// voisines ne se multiplient pas pareil : on divise un spathiphyllum, on
/// bouture une feuille de sansevieria. C'est le geste qui décide des
/// animations, des étapes et des textes.
///
/// Un archétype de plus, c'est une valeur ici, une liste d'étapes dans
/// `lib/features/cuttings/application/propagation_guides.dart`, et un dossier
/// d'images sous `assets/cutting/`. Rien d'autre ne bouge : voir
/// `docs/12-guides-de-multiplication.md`.
enum PropagationGuideKind {
  /// Bouture de tige à nœud : pothos, monstera, philodendron.
  stemNodeVine,

  /// Bouture de tige tendre : basilic, menthe, coleus.
  stemSoft,

  /// Bouture de feuille : sansevieria, ZZ, bégonia.
  leafCutting,

  /// Division d'une touffe : spathiphyllum, graminées, fougères.
  division,

  /// Séparation d'un rejet : pilea, aloe, chlorophytum.
  offset,

  /// Bouture de segment : cactus et succulentes à segments.
  succulentSegment,
}

/// Les étapes de chaque archétype, dans l'ordre du geste.
///
/// C'est la structure du guide : elle nomme les séquences d'images
/// (`assets/cutting/<archétype>/<étape>.webp`), elle donne leur rang aux
/// textes, et c'est elle qui part vers l'IA pour qu'elle sache quoi
/// préciser. Quatre étapes, six, huit : le nombre appartient au guide.
const propagationStepIds = <PropagationGuideKind, List<String>>{
  PropagationGuideKind.stemNodeVine: [
    'identify_node',
    'cut_below_node',
    'clear_node',
    'place_in_water',
    'roots_from_node',
    'pot',
  ],
  PropagationGuideKind.stemSoft: [
    'choose_stem',
    'cut',
    'remove_lower_leaves',
    'root',
    'roots',
    'pot',
  ],
  PropagationGuideKind.leafCutting: [
    'choose_leaf',
    'cut_leaf',
    'prepare',
    'callus',
    'substrate',
    'new_growth',
  ],
  PropagationGuideKind.division: [
    'plant',
    'remove_pot',
    'expose_roots',
    'identify_clusters',
    'separate',
    'repot',
  ],
  PropagationGuideKind.offset: [
    'identify_offset',
    'expose',
    'separate',
    'roots',
    'pot',
    'establish',
  ],
  PropagationGuideKind.succulentSegment: [
    'choose_segment',
    'cut',
    'fresh_cut',
    'callus',
    'substrate',
    'roots',
  ],
};

/// Ce que l'IA précise du guide d'une espèce : un texte par étape, dans
/// l'ordre du guide choisi.
///
/// Les textes locaux du guide valent pour l'archétype ; ils sont déjà justes.
/// Pour une espèce donnée, l'IA les réécrit : où se trouve exactement le
/// nœud, si l'eau ou le substrat convient mieux, combien de temps attendre,
/// à quelle saison. Elle ne décide ni du nombre d'étapes, ni de leur ordre,
/// ni des animations. Une réponse vide laisse les textes locaux.
class PropagationRefinement {
  const PropagationRefinement({this.steps = const []});

  /// Un texte par étape du guide, dans l'ordre.
  final List<String> steps;

  /// Vrai quand l'IA n'a rien précisé : les textes locaux restent, et la
  /// question ne vaut pas d'être reposée.
  bool get isEmpty => steps.isEmpty;

  /// Le texte de l'étape de rang [index], ou `null` si l'IA ne l'a pas
  /// précisé — un guide à trous se comble par ses textes locaux.
  String? at(int index) => index >= 0 && index < steps.length ? steps[index] : null;

  Map<String, Object?> toJson() => {'s': steps};

  factory PropagationRefinement.fromJson(Map<String, Object?> json) {
    final raw = json['s'];
    if (raw is! List) return const PropagationRefinement();
    final steps = <String>[];
    for (final s in raw) {
      if (s is! String || s.trim().isEmpty) return const PropagationRefinement();
      steps.add(s);
    }
    return PropagationRefinement(steps: steps);
  }
}

class PropagationGuideException implements Exception {
  const PropagationGuideException(this.message);

  final String message;

  @override
  String toString() => 'PropagationGuideException: $message';
}

/// Précise les textes d'un guide pour une espèce.
abstract class PropagationGuideRefiner {
  bool get isConfigured;

  /// [stepIds] donne la structure du guide choisi : le modèle rend un texte
  /// par étape, dans cet ordre, et rien d'autre.
  Future<PropagationRefinement> refine({
    required String scientificName,
    required String language,
    required PropagationGuideKind kind,
    required List<String> stepIds,
  });
}

class UnconfiguredPropagationGuideRefiner implements PropagationGuideRefiner {
  const UnconfiguredPropagationGuideRefiner();

  @override
  bool get isConfigured => false;

  @override
  Future<PropagationRefinement> refine({
    required String scientificName,
    required String language,
    required PropagationGuideKind kind,
    required List<String> stepIds,
  }) =>
      throw const PropagationGuideException('unconfigured');
}

/// Les réponses déjà obtenues, gardées sur l'appareil.
///
/// On multiplie souvent la même plante ; sans mémoire, la même question
/// repartirait à chaque fois pour le même texte. Les réponses vides comptent
/// autant que les autres : une espèce que l'IA ne connaît pas ne vaut pas
/// d'être redemandée.
abstract class PropagationGuideStore {
  PropagationRefinement? read(String scientificName, String language, PropagationGuideKind kind);

  Future<void> write(String scientificName, String language, PropagationGuideKind kind, PropagationRefinement refinement);

  /// Clé de rangement : la langue, le guide, puis l'espèce normalisée. Le
  /// guide en fait partie — le texte d'une division ne vaut rien pour une
  /// bouture de feuille de la même plante.
  static String keyOf(String scientificName, String language, PropagationGuideKind kind) =>
      '$language|${kind.name}|${scientificName.trim().toLowerCase()}';

  static String encode(Map<String, PropagationRefinement> entries) =>
      jsonEncode({for (final e in entries.entries) e.key: e.value.toJson()});

  static Map<String, PropagationRefinement> decode(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      final json = jsonDecode(raw);
      if (json is! Map) return {};
      return {
        for (final e in json.entries)
          if (e.value is Map) e.key as String: PropagationRefinement.fromJson(Map<String, Object?>.from(e.value as Map)),
      };
    } on FormatException {
      return {};
    }
  }
}
