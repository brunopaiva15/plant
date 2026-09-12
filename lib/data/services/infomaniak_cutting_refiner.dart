import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/care/care_profile.dart';
import '../../domain/cuttings/cutting_guide.dart';

/// Précise les étapes du guide de bouturage par les AI Services d'Infomaniak,
/// via leur route compatible OpenAI. Même clé et même produit que le
/// diagnostic et le complément des fiches.
///
/// Seul le nom scientifique de la plante mère part. Pas de photo, pas de nom
/// de plante, rien de l'utilisateur. La réponse est six phrases courtes,
/// une par étape ; tout ce qui n'a pas cette forme est jeté, et les textes
/// génériques restent.
class InfomaniakCuttingRefiner implements CuttingGuideRefiner {
  InfomaniakCuttingRefiner({required this.apiKey, required this.productId, required this.model, http.Client? client})
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
  Future<CuttingGuideRefinement> refine({required String scientificName, required String language}) async {
    if (!isConfigured) throw const CuttingGuideException('unconfigured');
    final name = scientificName.trim();
    if (name.isEmpty) throw const CuttingGuideException('no_species');
    var response = await _post(buildRequest(model: model, scientificName: name, language: language, constrainJson: true));
    // Le format JSON contraint n'est pas garanti par tous les modèles : s'il
    // est refusé, la même demande repart sans lui.
    if (response.statusCode == 400) {
      response = await _post(buildRequest(model: model, scientificName: name, language: language, constrainJson: false));
    }
    if (response.statusCode == 401 || response.statusCode == 403) throw const CuttingGuideException('unauthorized');
    if (response.statusCode == 429) throw const CuttingGuideException('quota');
    if (response.statusCode != 200) throw CuttingGuideException('http ${response.statusCode}');
    // Décodée en UTF-8 quoi qu'en dise l'en-tête : sans charset, `body`
    // lirait du Latin-1 et les accents des six phrases seraient perdus.
    return parseResponse(utf8.decode(response.bodyBytes));
  }

  Future<http.Response> _post(Map<String, Object?> body) => _client
      .post(endpoint, headers: {'content-type': 'application/json', 'authorization': 'Bearer ${apiKey.trim()}'}, body: jsonEncode(body))
      .timeout(const Duration(seconds: 45));

  /// Corps de requête, au format OpenAI (exposé pour les tests).
  static Map<String, Object?> buildRequest({
    required String model,
    required String scientificName,
    required String language,
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
          {'role': 'user', 'content': scientificName},
        ],
      };

  /// Les six étapes telles que l'application les montre, données au modèle
  /// pour qu'il les précise sans en changer l'ordre ni le nombre.
  static const List<String> genericSteps = [
    'stem: choose a healthy stem with at least one node (the swelling where leaves attach) and two or three leaves above it',
    'cut: with a clean blade, cut cleanly just below the node, leaving about a centimetre of stem under it',
    'leaves: remove the lower leaves so the node is bare; keep two or three leaves at the top',
    'water: place the cutting in a glass of room-temperature water, node submerged, leaves above; bright light, no direct sun',
    'roots: change the water every week; the first roots appear after two to six weeks',
    'pot: once the roots are a few centimetres long, pot the cutting in a light potting mix and water it',
  ];

  static String systemPrompt(String language) =>
      'You are given the accepted scientific name of a houseplant or garden plant. A person is about to take a cutting of it '
      'and follows a six-step illustrated guide. The six steps, in order, with their generic text: '
      '${[for (final (i, s) in genericSteps.indexed) '${i + 1}. $s'].join('; ')}. '
      'Rewrite the six texts for this exact species. Keep what is generic when it applies to the species, and replace it with what '
      'is specific and well established: where the node is and what it looks like, whether an aerial root helps, whether it roots '
      'better in water or in a substrate, how long rooting takes, the best season, the temperature, what to avoid. '
      'If the species is not propagated by stem cutting, say so in step 1 and adapt the following steps to its usual method '
      '(leaf cutting, division, offsets, layering, seed) while keeping exactly six steps in the same order of ideas. '
      'Never invent: if you do not know the species, return {"known": false} and nothing else. '
      'Never mention toxicity or safety. '
      'Tone: plain, factual, short, at most 35 words per step, in the indicative, no exclamation marks, no greetings, no reassurance, '
      'no praise, no "probably". Write every step in the language with code "$language". '
      'Answer with one JSON object only, no markdown, no text around it, with exactly these keys: '
      '"known" (boolean), "method" (one of stemCutting, leafCutting, division, offsets, layering, seed, water, tuber), '
      '"steps" (array of exactly six strings, in order).';

  /// Lit la réponse et n'en garde que ce qui tient debout : six textes, ni
  /// vides ni interminables, débarrassés de ce que le ton interdit.
  static CuttingGuideRefinement parseResponse(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final choices = (json['choices'] as List?) ?? const [];
    if (choices.isEmpty) throw const CuttingGuideException('empty');
    final choice = choices.first as Map<String, dynamic>;
    if (choice['finish_reason'] == 'content_filter') throw const CuttingGuideException('refusal');
    final message = (choice['message'] as Map<String, dynamic>?) ?? const {};
    final content = message['content'];
    final text = switch (content) {
      String s => s,
      List l => l.map((p) => p is Map ? (p['text'] as String? ?? '') : '').join(),
      _ => '',
    };
    final data = _extractJson(text);
    if (data == null) throw const CuttingGuideException('empty');
    if (data['known'] == false) return const CuttingGuideRefinement();

    final raw = data['steps'];
    if (raw is! List || raw.length != CuttingStep.values.length) return const CuttingGuideRefinement();
    final steps = <String>[];
    for (final s in raw) {
      if (s is! String) return const CuttingGuideRefinement();
      final clean = sanitize(s);
      if (clean.isEmpty) return const CuttingGuideRefinement();
      steps.add(clean);
    }
    String? method;
    for (final p in Propagation.values) {
      if (p.name == data['method']) method = p.name;
    }
    return CuttingGuideRefinement(steps: steps, method: method);
  }

  /// Ce que le ton de l'application exige, appliqué à un texte qui vient
  /// d'ailleurs : pas de point d'exclamation, pas d'espaces en trop, une
  /// longueur qui tient sous l'illustration.
  static String sanitize(String text) {
    var s = text.replaceAll(RegExp(r'\s*!+'), '.').replaceAll(RegExp(r'\s+'), ' ').trim();
    s = s.replaceAll(RegExp(r'\.{2,}'), '.');
    if (s.length > maxStepLength) {
      final cut = s.lastIndexOf('. ', maxStepLength);
      s = cut > maxStepLength ~/ 2 ? s.substring(0, cut + 1) : '${s.substring(0, maxStepLength - 1).trimRight()}.';
    }
    return s;
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
