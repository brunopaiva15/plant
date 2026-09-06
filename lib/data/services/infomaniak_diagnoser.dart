import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute;
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

import '../../domain/diagnosis/plant_diagnoser.dart';

/// Diagnostic par les AI Services d'Infomaniak (hébergés en Suisse), via
/// leur route compatible OpenAI : un modèle qui voit les images reçoit les
/// photos et rend un JSON — résumé, urgence, causes classées avec des gestes.
///
/// Les photos sont réduites à [maxSide] pixels avant l'envoi : c'est ce
/// que le modèle regarde de toute façon, et la facture se compte en jetons
/// d'image. Rien n'est stocké côté service au-delà de la requête.
class InfomaniakDiagnoser implements PlantDiagnoser {
  InfomaniakDiagnoser({required this.apiKey, required this.productId, required this.model, http.Client? client})
      : _client = client ?? http.Client();

  final String apiKey;
  final String productId;
  final String model;
  final http.Client _client;

  static const maxImages = 3;
  static const maxSide = 1024;

  Uri get endpoint => Uri.parse('https://api.infomaniak.com/2/ai/$productId/openai/v1/chat/completions');

  @override
  bool get isConfigured => apiKey.trim().isNotEmpty && productId.trim().isNotEmpty;

  @override
  Future<Diagnosis> diagnose({required List<File> images, required String language, String? plantName, String? species, String? symptoms}) async {
    if (!isConfigured) throw const DiagnosisException('unconfigured');
    if (images.isEmpty) throw const DiagnosisException('no_images');
    final parts = <Map<String, Object?>>[
      for (final image in images.take(maxImages))
        {
          'type': 'image_url',
          'image_url': {'url': 'data:image/jpeg;base64,${base64Encode(await prepareImage(await image.readAsBytes()))}'},
        },
      {'type': 'text', 'text': userPrompt(language: language, plantName: plantName, species: species, symptoms: symptoms)},
    ];
    // Le format JSON contraint n'est pas garanti par tous les modèles : si
    // le service le refuse, on renvoie la même demande sans lui — la consigne
    // demande déjà du JSON, et le lecteur est tolérant.
    var response = await _post(buildRequest(model: model, parts: parts, language: language, constrainJson: true));
    if (response.statusCode == 400) {
      response = await _post(buildRequest(model: model, parts: parts, language: language, constrainJson: false));
    }
    if (response.statusCode == 401 || response.statusCode == 403) throw const DiagnosisException('unauthorized');
    if (response.statusCode == 429) throw const DiagnosisException('quota');
    if (response.statusCode != 200) throw DiagnosisException('http ${response.statusCode}');
    return parseResponse(response.body);
  }

  Future<http.Response> _post(Map<String, Object?> body) => _client
      .post(endpoint, headers: {'content-type': 'application/json', 'authorization': 'Bearer ${apiKey.trim()}'}, body: jsonEncode(body))
      .timeout(const Duration(minutes: 2));

  /// La photo telle qu'elle part : JPEG, grand côté à [maxSide] au plus.
  /// Une image illisible part telle quelle, le service dira ce qu'il en pense.
  static Future<Uint8List> prepareImage(Uint8List bytes) => compute(_shrink, bytes);

  static Uint8List _shrink(Uint8List bytes) {
    final img.Image? decoded;
    try {
      decoded = img.decodeImage(bytes);
    } on Object {
      // Le décodeur peut lever sur un fichier tronqué : on envoie tel quel.
      return bytes;
    }
    if (decoded == null) return bytes;
    var image = decoded;
    if (image.width > maxSide || image.height > maxSide) {
      image = image.width >= image.height ? img.copyResize(image, width: maxSide) : img.copyResize(image, height: maxSide);
    }
    return Uint8List.fromList(img.encodeJpg(image, quality: 85));
  }

  /// Corps de requête, au format OpenAI (exposé pour les tests).
  static Map<String, Object?> buildRequest({required String model, required List<Map<String, Object?>> parts, required String language, required bool constrainJson}) => {
        'model': model,
        'max_tokens': 1500,
        'temperature': 0.2,
        if (constrainJson) 'response_format': {'type': 'json_object'},
        'messages': [
          {'role': 'system', 'content': systemPrompt(language)},
          {'role': 'user', 'content': parts},
        ],
      };

  static String systemPrompt(String language) =>
      'You help a hobbyist care for a houseplant or garden plant. Look at the photos and describe what you observe, '
      'then list the most plausible causes ranked by likelihood (0 to 1; they need not sum to 1), each with a short explanation '
      'and 1 to 3 concrete, gentle actions the person can take at home. Be honest about uncertainty: these are suggestions, never a diagnosis. '
      'If the plant looks healthy, say so with a single low-likelihood cause at most. Set "urgent" only for pests, rot or rapid decline. '
      'If the photos do not show a plant clearly enough, say so in "summary" and return no cause. '
      'Write every text field in the language with code "$language", in a warm, plain, human tone, without jargon. '
      'Answer with one JSON object only, no markdown, no text around it, with exactly these keys: '
      '"summary" (string), "urgent" (boolean), "causes" (array of objects with "title" (string), "likelihood" (number), '
      '"explanation" (string), "actions" (array of strings)).';

  static String userPrompt({required String language, String? plantName, String? species, String? symptoms}) {
    final parts = <String>[
      if (plantName != null && plantName.isNotEmpty) 'Plant: $plantName.',
      if (species != null && species.isNotEmpty) 'Species: $species.',
      if (symptoms != null && symptoms.trim().isNotEmpty) 'What the owner noticed: ${symptoms.trim()}',
      'What might be wrong, and what can I do?',
    ];
    return parts.join(' ');
  }

  /// Extrait le diagnostic d'une réponse chat completions. Le contenu peut
  /// être une chaîne ou une liste de fragments ; du JSON entouré de
  /// balises Markdown ou d'une phrase est accepté.
  static Diagnosis parseResponse(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final choices = (json['choices'] as List?) ?? const [];
    if (choices.isEmpty) throw const DiagnosisException('empty');
    final choice = choices.first as Map<String, dynamic>;
    if (choice['finish_reason'] == 'content_filter') throw const DiagnosisException('refusal');
    final message = (choice['message'] as Map<String, dynamic>?) ?? const {};
    final content = message['content'];
    final text = switch (content) {
      String s => s,
      List l => l.map((p) => p is Map ? (p['text'] as String? ?? '') : '').join(),
      _ => '',
    };
    final data = _extractJson(text);
    if (data == null) throw const DiagnosisException('empty');
    final causes = ((data['causes'] as List?) ?? const [])
        .whereType<Map>()
        .map((c) => DiagnosisCause(
              title: (c['title'] as String?) ?? '',
              likelihood: ((c['likelihood'] as num?) ?? 0).toDouble().clamp(0, 1),
              explanation: (c['explanation'] as String?) ?? '',
              actions: ((c['actions'] as List?) ?? const []).whereType<String>().toList(),
            ))
        .where((c) => c.title.isNotEmpty)
        .toList()
      ..sort((a, b) => b.likelihood.compareTo(a.likelihood));
    return Diagnosis(summary: (data['summary'] as String?) ?? '', causes: causes, urgent: data['urgent'] == true);
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
