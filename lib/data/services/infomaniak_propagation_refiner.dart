import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/cuttings/propagation_guide.dart';

/// Précise les textes d'un guide de multiplication par les AI Services
/// d'Infomaniak, via leur route compatible OpenAI. Même clé et même produit
/// que le diagnostic et le complément des fiches.
///
/// Seuls le nom scientifique, la méthode et la structure du guide partent.
/// Pas de photo, pas de nom de plante, rien de l'utilisateur.
///
/// Le modèle ne décide de rien : ni du nombre d'étapes, ni de leur ordre, ni
/// des animations. Il reçoit le geste déjà choisi et réécrit les phrases
/// pour l'espèce — où se trouve le nœud, quel milieu convient, combien de
/// temps attendre, à quelle saison, ce qu'il faut éviter. Une réponse qui
/// n'a pas la forme demandée est jetée, et les textes locaux restent.
class InfomaniakPropagationRefiner implements PropagationGuideRefiner {
  InfomaniakPropagationRefiner({required this.apiKey, required this.productId, required this.model, http.Client? client})
      : _client = client ?? http.Client();

  final String apiKey;
  final String productId;
  final String model;
  final http.Client _client;

  /// Au-delà, une étape ne se lit plus d'un coup d'œil sous l'illustration.
  static const int maxStepLength = 320;

  Uri get endpoint => Uri.parse('https://api.infomaniak.com/2/ai/$productId/openai/v1/chat/completions');

  @override
  bool get isConfigured => apiKey.trim().isNotEmpty && productId.trim().isNotEmpty;

  @override
  Future<PropagationRefinement> refine({
    required String scientificName,
    required String language,
    required PropagationGuideKind kind,
    required List<String> stepIds,
  }) async {
    if (!isConfigured) throw const PropagationGuideException('unconfigured');
    final name = scientificName.trim();
    if (name.isEmpty) throw const PropagationGuideException('no_species');
    if (stepIds.isEmpty) throw const PropagationGuideException('no_steps');
    var response = await _post(buildRequest(
        model: model, scientificName: name, language: language, kind: kind, stepIds: stepIds, constrainJson: true));
    // Le format JSON contraint n'est pas garanti par tous les modèles : s'il
    // est refusé, la même demande repart sans lui.
    if (response.statusCode == 400) {
      response = await _post(buildRequest(
          model: model, scientificName: name, language: language, kind: kind, stepIds: stepIds, constrainJson: false));
    }
    if (response.statusCode == 401 || response.statusCode == 403) throw const PropagationGuideException('unauthorized');
    if (response.statusCode == 429) throw const PropagationGuideException('quota');
    if (response.statusCode != 200) throw PropagationGuideException('http ${response.statusCode}');
    // Décodée en UTF-8 quoi qu'en dise l'en-tête : sans charset, `body`
    // lirait du Latin-1 et les accents seraient perdus.
    return parseResponse(utf8.decode(response.bodyBytes), stepIds.length);
  }

  Future<http.Response> _post(Map<String, Object?> body) => _client
      .post(endpoint, headers: {'content-type': 'application/json', 'authorization': 'Bearer ${apiKey.trim()}'}, body: jsonEncode(body))
      .timeout(const Duration(seconds: 45));

  /// Corps de requête, au format OpenAI (exposé pour les tests).
  static Map<String, Object?> buildRequest({
    required String model,
    required String scientificName,
    required String language,
    required PropagationGuideKind kind,
    required List<String> stepIds,
    required bool constrainJson,
  }) =>
      {
        'model': model,
        'max_tokens': 900,
        // Il s'agit de restituer un savoir, pas d'en inventer un.
        'temperature': 0.2,
        if (constrainJson) 'response_format': {'type': 'json_object'},
        'messages': [
          {'role': 'system', 'content': systemPrompt(language)},
          {'role': 'user', 'content': jsonEncode(brief(scientificName: scientificName, kind: kind, stepIds: stepIds))},
        ],
      };

  /// Ce que le modèle reçoit : l'espèce, la méthode, le geste, et les étapes
  /// telles que l'application les montre. Rien de plus, rien à décider.
  static Map<String, Object?> brief({
    required String scientificName,
    required PropagationGuideKind kind,
    required List<String> stepIds,
  }) =>
      {
        'species': scientificName,
        'method': methodName(kind),
        'guideKind': kind.name,
        'steps': stepIds,
      };

  /// La méthode telle que la fiche d'entretien la nomme.
  static String methodName(PropagationGuideKind kind) => switch (kind) {
        PropagationGuideKind.stemNodeVine || PropagationGuideKind.stemSoft => 'stemCutting',
        PropagationGuideKind.leafCutting => 'leafCutting',
        PropagationGuideKind.division => 'division',
        PropagationGuideKind.offset => 'offsets',
        PropagationGuideKind.keiki => 'offsets',
        PropagationGuideKind.succulentSegment => 'stemCutting',
      };

  /// Ce que chaque étape montre, en une ligne, pour que le modèle sache
  /// quoi préciser. L'ordre suit [propagationStepIds].
  static const Map<PropagationGuideKind, List<String>> stepBriefs = {
    PropagationGuideKind.stemNodeVine: [
      'identify_node: find a healthy node on a stem, the swelling where a leaf and often an aerial root start',
      'cut_below_node: cut cleanly about a centimetre below that node, so the node stays on the cutting',
      'clear_node: remove the leaves that would sit under water, leaving the node bare',
      'place_in_water: put the cutting in water, node submerged, remaining leaves above the surface',
      'roots_from_node: roots come out of the node itself, not from the base of the stem',
      'pot: once roots are a few centimetres long, pot the cutting without burying the node deep',
    ],
    PropagationGuideKind.stemSoft: [
      'choose_stem: pick a young, firm, non-flowering shoot of the soft-stemmed plant',
      'cut: cut just below a pair of leaves with a clean blade',
      'remove_lower_leaves: strip the lowest leaves so nothing rots below the water line',
      'root: stand the bare stem in water or in a light substrate',
      'roots: fine roots appear along the buried or submerged part of the stem',
      'pot: pot it up early, while the roots are still short',
    ],
    PropagationGuideKind.leafCutting: [
      'choose_leaf: pick a mature, firm, undamaged leaf',
      'cut_leaf: cut the whole leaf off at its base with a clean blade',
      'prepare: cut the leaf into segments if the species allows it, marking the bottom of each so it is never planted upside down',
      'callus: let the cut surfaces dry before planting',
      'substrate: push the bottom of each piece a couple of centimetres into a free-draining substrate',
      'new_growth: roots come first, then a new shoot rises from the substrate beside the leaf',
    ],
    PropagationGuideKind.division: [
      'plant: the clump in its pot, ready to be tipped out',
      'remove_pot: slide the pot off and free the root ball whole',
      'expose_roots: crumble the soil away until the roots show',
      'identify_clusters: find two groups that each have their own shoots and their own roots',
      'separate: pull the groups apart by hand, cutting only if the crowns will not come free',
      'repot: pot each division separately and water it',
    ],
    PropagationGuideKind.offset: [
      'identify_offset: find an offset big enough to live on its own',
      'expose: clear the substrate around its base to see where it joins the mother plant',
      'separate: detach it, keeping its own roots',
      'roots: check that the offset carries roots of its own',
      'pot: pot it in a small pot, in the substrate the species wants',
      'establish: how the offset shows it has taken',
    ],
    PropagationGuideKind.keiki: [
      'identify_keiki: find a young plant growing on a node of the flower spike, with leaves of its own',
      'wait_roots: let its aerial roots lengthen along the spike before thinking of taking it',
      'separate: cut the spike on either side of the keiki, never pull it off the spike',
      'roots: check that the keiki carries its aerial roots, which are what will take in the pot',
      'pot: pot it in a small pot of orchid substrate, the base level with the surface',
      'establish: how the keiki shows it has taken',
    ],
    PropagationGuideKind.succulentSegment: [
      'choose_segment: pick a firm, healthy terminal segment',
      'cut: detach it at the joint, twisting rather than tearing',
      'fresh_cut: what the fresh wound looks like',
      'callus: let the wound dry and form a callus before planting',
      'substrate: set the callused end barely into a very free-draining substrate',
      'roots: roots form first, then a new segment',
    ],
  };

  static String systemPrompt(String language) =>
      'You are given a JSON object: the accepted scientific name of a plant, the propagation method a person is about to use, '
      'the illustrated guide they are following, and the exact list of steps that guide shows, in order. '
      'The steps are fixed. You do not choose the method, the number of steps, their order, or what is illustrated. '
      'Here is what each step of each guide shows: '
      '${[
        for (final e in stepBriefs.entries) '${e.key.name} -> ${e.value.join(' | ')}'
      ].join('; ')}. '
      'Write one short text per step of the given guide, in the given order, for this exact species. '
      'Keep what is generic when it applies, and replace it with what is specific and well established: where the node or the '
      'joint is and what it looks like, whether an aerial root helps, whether water or a substrate roots it better, how long it '
      'takes, the best season, the temperature it wants, what to avoid with this species. '
      'Stay inside the step you are writing: never describe a gesture the step does not show. '
      'Never invent: if you do not know the species, return {"known": false} and nothing else. '
      'Never mention toxicity or safety. '
      'Tone: plain, factual, short, at most 35 words per step, in the indicative, no exclamation marks, no semicolons, no greetings, '
      'no reassurance, no praise, no "probably". Full sentences, each starting with a capital letter and ending with a period. '
      'Write every step in the language with code "$language". '
      'Answer with one JSON object only, no markdown, no text around it, with exactly these keys: '
      '"known" (boolean), "steps" (array of strings, exactly one per step given, in the same order).';

  /// Lit la réponse et n'en garde que ce qui tient debout : un texte par
  /// étape, ni vide ni interminable, débarrassé de ce que le ton interdit.
  static PropagationRefinement parseResponse(String body, int stepCount) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final choices = (json['choices'] as List?) ?? const [];
    if (choices.isEmpty) throw const PropagationGuideException('empty');
    final choice = choices.first as Map<String, dynamic>;
    if (choice['finish_reason'] == 'content_filter') throw const PropagationGuideException('refusal');
    final message = (choice['message'] as Map<String, dynamic>?) ?? const {};
    final content = message['content'];
    final text = switch (content) {
      String s => s,
      List l => l.map((p) => p is Map ? (p['text'] as String? ?? '') : '').join(),
      _ => '',
    };
    final data = _extractJson(text);
    if (data == null) throw const PropagationGuideException('empty');
    if (data['known'] == false) return const PropagationRefinement();

    final raw = data['steps'];
    // Un guide à trous vaut moins que le guide local : ou bien le compte y
    // est, ou bien on garde les textes d'origine.
    if (raw is! List || raw.length != stepCount) return const PropagationRefinement();
    final steps = <String>[];
    for (final s in raw) {
      if (s is! String) return const PropagationRefinement();
      final clean = sanitize(s);
      if (clean.isEmpty) return const PropagationRefinement();
      steps.add(clean);
    }
    return PropagationRefinement(steps: steps);
  }

  /// Ce que le ton de l'application exige, appliqué à un texte qui vient
  /// d'ailleurs : pas de point d'exclamation ni de point-virgule, des
  /// phrases qui commencent par une majuscule et finissent par un point, pas
  /// d'espaces en trop, une longueur qui tient sous l'illustration.
  static String sanitize(String text) {
    var s = text.replaceAll(RegExp(r'\s*[!;]+'), '.').replaceAll(RegExp(r'\s+'), ' ').trim();
    s = s.replaceAll(RegExp(r'\.(\s*\.)+'), '.');
    if (s.isEmpty) return s;
    if (s.length > maxStepLength) {
      final cut = s.lastIndexOf('. ', maxStepLength);
      s = cut > maxStepLength ~/ 2 ? s.substring(0, cut + 1) : '${s.substring(0, maxStepLength - 1).trimRight()}.';
    }
    if (!RegExp(r'[.?…]$').hasMatch(s)) s = '$s.';
    // Une majuscule ouvre chaque phrase : la première, et celles qui suivent
    // un point ou un point d'interrogation.
    return s.replaceAllMapped(RegExp(r'(^|[.?]\s+)(\p{Ll})', unicode: true), (m) => '${m[1]}${m[2]!.toUpperCase()}');
  }

  static Map<String, dynamic>? _extractJson(String text) {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start < 0 || end <= start) return null;
    try {
      final decoded = jsonDecode(text.substring(start, end + 1));
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }
}
