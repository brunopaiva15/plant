import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/species/plant_advisor.dart';
import '../../domain/species/plant_finder.dart';

/// Propositions d'espèces par les AI Services d'Infomaniak, via leur route
/// compatible OpenAI. Même clé et même produit que le diagnostic.
///
/// Requête de texte seul, donc quelques centaines de jetons : c'est le second
/// tour, quand le catalogue intégré n'a rien de convaincant, et il n'a lieu
/// que si l'utilisateur le demande.
class InfomaniakAdvisor implements PlantAdvisor {
  InfomaniakAdvisor({required this.apiKey, required this.productId, required this.model, http.Client? client})
      : _client = client ?? http.Client();

  final String apiKey;
  final String productId;
  final String model;
  final http.Client _client;

  static const maxSuggestions = 3;

  Uri get endpoint => Uri.parse('https://api.infomaniak.com/2/ai/$productId/openai/v1/chat/completions');

  @override
  bool get isConfigured => apiKey.trim().isNotEmpty && productId.trim().isNotEmpty;

  @override
  Future<List<AdvisorSuggestion>> suggest({required FinderCriteria criteria, required String language, List<String> exclude = const []}) async {
    if (!isConfigured) throw const AdvisorException('unconfigured');
    var response = await _post(buildRequest(model: model, criteria: criteria, language: language, exclude: exclude, constrainJson: true));
    // Le format JSON contraint n'est pas garanti par tous les modèles : s'il
    // est refusé, la même demande repart sans lui — la consigne le réclame
    // déjà et le lecteur est tolérant.
    if (response.statusCode == 400) {
      response = await _post(buildRequest(model: model, criteria: criteria, language: language, exclude: exclude, constrainJson: false));
    }
    if (response.statusCode == 401 || response.statusCode == 403) throw const AdvisorException('unauthorized');
    if (response.statusCode == 429) throw const AdvisorException('quota');
    if (response.statusCode != 200) throw AdvisorException('http ${response.statusCode}');
    return parseResponse(response.body);
  }

  Future<http.Response> _post(Map<String, Object?> body) => _client
      .post(endpoint, headers: {'content-type': 'application/json', 'authorization': 'Bearer ${apiKey.trim()}'}, body: jsonEncode(body))
      .timeout(const Duration(seconds: 60));

  /// Corps de requête, au format OpenAI (exposé pour les tests).
  static Map<String, Object?> buildRequest({
    required String model,
    required FinderCriteria criteria,
    required String language,
    required List<String> exclude,
    required bool constrainJson,
  }) =>
      {
        'model': model,
        'max_tokens': 700,
        'temperature': 0.4,
        if (constrainJson) 'response_format': {'type': 'json_object'},
        'messages': [
          {'role': 'system', 'content': systemPrompt(language)},
          {'role': 'user', 'content': userPrompt(criteria: criteria, exclude: exclude)},
        ],
      };

  static String systemPrompt(String language) =>
      'You help a hobbyist choose a plant to buy, from what they say about the spot and about themselves. '
      'Suggest at most $maxSuggestions species that are widely sold, giving the accepted scientific name for each. '
      'Never invent a species. If the person mentions pets or children, suggest only species known to be non-toxic when chewed, '
      'and if you are not certain a species is safe, leave it out. '
      'Give one short reason per species, at most 20 words, saying what makes it fit this person and this spot. '
      'Write the "common_name" and "reason" fields in the language with code "$language", in a warm, plain tone. '
      'Answer with one JSON object only, no markdown, no text around it, with exactly this key: '
      '"suggestions" (array of objects with "scientific_name" (string), "common_name" (string), "reason" (string)).';

  static String userPrompt({required FinderCriteria criteria, required List<String> exclude}) {
    final described = criteria.describe();
    return [
      if (described.isEmpty) 'They have not said much: suggest easy, widely sold plants.' else described,
      if (exclude.isNotEmpty) 'Already suggested, do not repeat: ${exclude.join(', ')}.',
      'Which plants would suit them?',
    ].join(' ');
  }

  /// Extrait les propositions d'une réponse chat completions. Le contenu peut
  /// être une chaîne ou une liste de fragments ; du JSON entouré de balises
  /// Markdown ou d'une phrase est accepté.
  static List<AdvisorSuggestion> parseResponse(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final choices = (json['choices'] as List?) ?? const [];
    if (choices.isEmpty) throw const AdvisorException('empty');
    final choice = choices.first as Map<String, dynamic>;
    if (choice['finish_reason'] == 'content_filter') throw const AdvisorException('refusal');
    final message = (choice['message'] as Map<String, dynamic>?) ?? const {};
    final content = message['content'];
    final text = switch (content) {
      String s => s,
      List l => l.map((p) => p is Map ? (p['text'] as String? ?? '') : '').join(),
      _ => '',
    };
    final data = _extractJson(text);
    if (data == null) throw const AdvisorException('empty');
    final seen = <String>{};
    return ((data['suggestions'] as List?) ?? const [])
        .whereType<Map>()
        .map((s) => AdvisorSuggestion(
              scientificName: ((s['scientific_name'] as String?) ?? '').trim(),
              commonName: (s['common_name'] as String?)?.trim().nullIfEmpty,
              reason: ((s['reason'] as String?) ?? '').trim(),
            ))
        .where((s) => s.scientificName.isNotEmpty && seen.add(s.scientificName.toLowerCase()))
        .take(maxSuggestions)
        .toList();
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

extension on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}
