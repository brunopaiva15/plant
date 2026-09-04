import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../domain/diagnosis/plant_diagnoser.dart';

/// Diagnostic par l'API Claude (Messages API, HTTP brut : pas de SDK Dart officiel).
///
/// - Modèle `claude-opus-5`, réflexion adaptative (par défaut), sortie
///   structurée (`output_config.format`, JSON Schema) pour un résultat fiable.
/// - `fallbacks: "default"` : si les classificateurs de sécurité déclinent, la
///   requête est rejouée côté serveur sur le modèle de repli recommandé.
/// - Le `stop_reason` est vérifié avant de lire le contenu.
class AnthropicDiagnoser implements PlantDiagnoser {
  AnthropicDiagnoser(this.apiKey, {http.Client? client, this.model = defaultModel}) : _client = client ?? http.Client();

  final String apiKey;
  final String model;
  final http.Client _client;

  static const defaultModel = 'claude-opus-5';
  static const _endpoint = 'https://api.anthropic.com/v1/messages';
  static const maxImages = 3;

  @override
  bool get isConfigured => apiKey.trim().isNotEmpty;

  @override
  Future<Diagnosis> diagnose({required List<File> images, required String language, String? plantName, String? species, String? symptoms}) async {
    if (!isConfigured) throw const DiagnosisException('unconfigured');
    if (images.isEmpty) throw const DiagnosisException('no_images');
    final content = <Map<String, Object?>>[
      for (final image in images.take(maxImages))
        {
          'type': 'image',
          'source': {'type': 'base64', 'media_type': 'image/jpeg', 'data': base64Encode(await image.readAsBytes())},
        },
      {'type': 'text', 'text': userPrompt(language: language, plantName: plantName, species: species, symptoms: symptoms)},
    ];
    final body = buildRequest(model: model, content: content, language: language);
    final response = await _client
        .post(
          Uri.parse(_endpoint),
          headers: {
            'content-type': 'application/json',
            'x-api-key': apiKey.trim(),
            'anthropic-version': '2023-06-01',
            'anthropic-beta': 'server-side-fallback-2026-07-01',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(minutes: 3));
    if (response.statusCode == 401 || response.statusCode == 403) throw const DiagnosisException('unauthorized');
    if (response.statusCode != 200) throw DiagnosisException('http ${response.statusCode}');
    return parseResponse(response.body);
  }

  /// Corps de requête (exposé pour les tests).
  static Map<String, Object?> buildRequest({required String model, required List<Map<String, Object?>> content, required String language}) => {
        'model': model,
        'max_tokens': 8000,
        'fallbacks': 'default',
        'system': systemPrompt(language),
        'output_config': {
          'format': {'type': 'json_schema', 'schema': responseSchema},
        },
        'messages': [
          {'role': 'user', 'content': content},
        ],
      };

  static const Map<String, Object?> responseSchema = {
    'type': 'object',
    'additionalProperties': false,
    'required': ['summary', 'urgent', 'causes'],
    'properties': {
      'summary': {'type': 'string'},
      'urgent': {'type': 'boolean'},
      'causes': {
        'type': 'array',
        'items': {
          'type': 'object',
          'additionalProperties': false,
          'required': ['title', 'likelihood', 'explanation', 'actions'],
          'properties': {
            'title': {'type': 'string'},
            'likelihood': {'type': 'number'},
            'explanation': {'type': 'string'},
            'actions': {'type': 'array', 'items': {'type': 'string'}},
          },
        },
      },
    },
  };

  static String systemPrompt(String language) =>
      'You help a hobbyist care for a houseplant or garden plant. Look at the photos and describe what you observe, '
      'then list the most plausible causes ranked by likelihood (0 to 1; they need not sum to 1), each with a short explanation '
      'and 1 to 3 concrete, gentle actions the person can take at home. Be honest about uncertainty: these are suggestions, never a diagnosis. '
      'If the plant looks healthy, say so with a single low-likelihood cause at most. Set "urgent" only for pests, rot or rapid decline. '
      'Write every text field in the language with code "$language", in a warm, plain, human tone, without jargon.';

  static String userPrompt({required String language, String? plantName, String? species, String? symptoms}) {
    final parts = <String>[
      if (plantName != null && plantName.isNotEmpty) 'Plant: $plantName.',
      if (species != null && species.isNotEmpty) 'Species: $species.',
      if (symptoms != null && symptoms.trim().isNotEmpty) 'What the owner noticed: ${symptoms.trim()}',
      'What might be wrong, and what can I do?',
    ];
    return parts.join(' ');
  }

  /// Extrait le diagnostic de la réponse Messages API.
  static Diagnosis parseResponse(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    if (json['stop_reason'] == 'refusal') throw const DiagnosisException('refusal');
    final blocks = (json['content'] as List? ?? const []).cast<Map<String, dynamic>>();
    final text = blocks.where((b) => b['type'] == 'text').map((b) => b['text'] as String? ?? '').join();
    if (text.trim().isEmpty) throw const DiagnosisException('empty');
    final data = jsonDecode(text) as Map<String, dynamic>;
    final causes = ((data['causes'] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map((c) => DiagnosisCause(
              title: (c['title'] as String?) ?? '',
              likelihood: ((c['likelihood'] as num?) ?? 0).toDouble().clamp(0, 1),
              explanation: (c['explanation'] as String?) ?? '',
              actions: ((c['actions'] as List?) ?? const []).cast<String>(),
            ))
        .toList()
      ..sort((a, b) => b.likelihood.compareTo(a.likelihood));
    return Diagnosis(summary: (data['summary'] as String?) ?? '', causes: causes, urgent: data['urgent'] == true);
  }
}
