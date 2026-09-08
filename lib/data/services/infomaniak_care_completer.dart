import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/care/care_completion.dart';
import '../../domain/care/care_profile.dart';

/// Complète une fiche d'entretien par les AI Services d'Infomaniak, via leur
/// route compatible OpenAI. Même clé et même produit que le diagnostic.
///
/// Seul le nom scientifique part. Pas de photo, pas de nom de plante, rien de
/// l'utilisateur. La réponse est une poignée de chiffres et de mots d'un
/// vocabulaire fermé, ce qui laisse peu de place a l'invention et permet de
/// jeter tout ce qui n'entre pas dedans.
class InfomaniakCareCompleter implements CareCompleter {
  InfomaniakCareCompleter({required this.apiKey, required this.productId, required this.model, http.Client? client})
      : _client = client ?? http.Client();

  final String apiKey;
  final String productId;
  final String model;
  final http.Client _client;

  Uri get endpoint => Uri.parse('https://api.infomaniak.com/2/ai/$productId/openai/v1/chat/completions');

  @override
  bool get isConfigured => apiKey.trim().isNotEmpty && productId.trim().isNotEmpty;

  @override
  Future<CareCompletion> complete({required String scientificName, required String language}) async {
    if (!isConfigured) throw const CareCompletionException('unconfigured');
    final name = scientificName.trim();
    if (name.isEmpty) throw const CareCompletionException('no_species');
    var response = await _post(buildRequest(model: model, scientificName: name, language: language, constrainJson: true));
    if (response.statusCode == 400) {
      response = await _post(buildRequest(model: model, scientificName: name, language: language, constrainJson: false));
    }
    if (response.statusCode == 401 || response.statusCode == 403) throw const CareCompletionException('unauthorized');
    if (response.statusCode == 429) throw const CareCompletionException('quota');
    if (response.statusCode != 200) throw CareCompletionException('http ${response.statusCode}');
    return parseResponse(response.body);
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
        'max_tokens': 500,
        // Il s'agit de restituer un savoir, pas d'en inventer un.
        'temperature': 0.0,
        if (constrainJson) 'response_format': {'type': 'json_object'},
        'messages': [
          {'role': 'system', 'content': systemPrompt(language)},
          {'role': 'user', 'content': scientificName},
        ],
      };

  static String systemPrompt(String language) =>
      'You are given the accepted scientific name of a plant. Return what is well established about growing it indoors or in a garden. '
      'Omit any field you are not confident about, and never guess: a missing field is a good answer, a plausible invention is not. '
      'If you do not know the species, return {"known": false} and nothing else. '
      'Never return anything about toxicity, safety for pets or children, or edibility. '
      'Use only these words. light: shade, lowLight, indirect, brightIndirect, someSun, fullSun. '
      'humidity: low, average, high. soil: standard, draining, cactus, orchid, acidic, rich, aquatic. '
      'difficulty: easy, medium, demanding. '
      'propagation: stemCutting, leafCutting, division, offsets, layering, seed, water, tuber. '
      'issues: overwatering, underwatering, rootRot, spiderMites, mealybugs, scale, aphids, fungusGnats, whitefly, slugs, '
      'powderyMildew, leafSpot, blight, sunburn, dryTips, leafDrop, etiolation, chlorosis, blossomEndRot. '
      'Watering days are the usual number of days between two waterings, in full growth and in winter rest. '
      'Set "no_fertilizer" to true only for species that are not fertilized at all. '
      'Answer with one JSON object only, no markdown, no text around it, with any of these keys: '
      '"known" (boolean), "watering_summer_days", "watering_winter_days", "light", "humidity", "soil", '
      '"fertilizing_days", "no_fertilizer", "repot_every_months", "min_temp_c", "ideal_temp_min_c", '
      '"ideal_temp_max_c", "difficulty", "propagation" (array), "issues" (array). '
      'The language "$language" is irrelevant here, every value is a number or one of the words above.';

  /// Lit la reponse et n'en garde que ce qui tient debout : les mots du
  /// vocabulaire, et les nombres dans des bornes plausibles. Le reste tombe.
  static CareCompletion parseResponse(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final choices = (json['choices'] as List?) ?? const [];
    if (choices.isEmpty) throw const CareCompletionException('empty');
    final choice = choices.first as Map<String, dynamic>;
    if (choice['finish_reason'] == 'content_filter') throw const CareCompletionException('refusal');
    final message = (choice['message'] as Map<String, dynamic>?) ?? const {};
    final content = message['content'];
    final text = switch (content) {
      String s => s,
      List l => l.map((p) => p is Map ? (p['text'] as String? ?? '') : '').join(),
      _ => '',
    };
    final data = _extractJson(text);
    if (data == null) throw const CareCompletionException('empty');
    if (data['known'] == false) return const CareCompletion();

    int? borne(Object? raw, int min, int max) {
      final v = raw is num ? raw.round() : null;
      return v == null || v < min || v > max ? null : v;
    }

    T? mot<T extends Enum>(List<T> values, Object? raw) {
      for (final v in values) {
        if (v.name == raw) return v;
      }
      return null;
    }

    List<T> mots<T extends Enum>(List<T> values, Object? raw) {
      final out = <T>[];
      for (final name in (raw as List?) ?? const []) {
        final v = mot(values, name);
        if (v != null && !out.contains(v)) out.add(v);
      }
      return out;
    }

    final ete = borne(data['watering_summer_days'], 1, 120);
    final hiver = borne(data['watering_winter_days'], 1, 180);
    var ideMin = borne(data['ideal_temp_min_c'], -5, 35);
    var ideMax = borne(data['ideal_temp_max_c'], 5, 45);
    // Une plage à l'envers ne veut rien dire : les deux bornes tombent.
    if (ideMin != null && ideMax != null && ideMin >= ideMax) {
      ideMin = null;
      ideMax = null;
    }
    return CareCompletion(
      wateringSummerDays: ete,
      // Une plante ne boit pas plus souvent au repos qu'en pleine croissance.
      wateringWinterDays: hiver == null || (ete != null && hiver < ete) ? null : hiver,
      light: mot(LightNeed.values, data['light']),
      humidity: mot(HumidityNeed.values, data['humidity']),
      soil: mot(SoilKind.values, data['soil']),
      fertilizingDays: borne(data['fertilizing_days'], 7, 180),
      noFertilizer: data['no_fertilizer'] == true,
      repotEveryMonths: borne(data['repot_every_months'], 6, 120),
      minTempC: borne(data['min_temp_c'], -30, 25),
      idealTempMinC: ideMin,
      idealTempMaxC: ideMax,
      difficulty: mot(CareDifficulty.values, data['difficulty']),
      propagation: mots(Propagation.values, data['propagation']),
      issues: mots(CommonIssue.values, data['issues']),
    );
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
