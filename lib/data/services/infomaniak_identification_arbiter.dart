import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../domain/identification/identification_arbiter.dart';
import '../../domain/identification/plant_identifier.dart';
import 'model_image.dart';

/// Départage les candidates d'Iris par les AI Services d'Infomaniak
/// (hébergés en Suisse), sur leur route compatible OpenAI — la même clé, le
/// même produit et le même modèle que le diagnostic.
///
/// **La question est fermée.** On soumet la photo et les noms qu'Iris a
/// proposés, numérotés, et on demande un numéro : celui qui correspond, ou
/// zéro. Un modèle généraliste à qui l'on demande « quelle est cette
/// plante ? » rend un binôme plausible et inventé, hors du catalogue, donc
/// sans fiche d'entretien ni vignette — et l'ensemble ouvert est le travail
/// de Pl@ntNet. Un numéro, lui, ne peut désigner qu'une candidate d'Iris.
///
/// **Les scores ne partent pas.** Donner « 44 % / 39 % » ancrerait la réponse
/// sur l'ordre d'Iris, et un avis qui recopie l'avis qu'on arbitre ne sert à
/// rien (c'est la remarque du § « Jev ne doit pas remplacer Iris » de
/// docs/16). Ce qu'on achète ici, c'est un deuxième regard sur la **photo**.
///
/// Rien n'est stocké côté service au-delà de la requête.
class InfomaniakIdentificationArbiter implements IdentificationArbiter {
  InfomaniakIdentificationArbiter({
    required this.apiKey,
    required this.productId,
    required this.model,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String apiKey;
  final String productId;
  final String model;
  final http.Client _client;

  /// Deux photos au plus : c'est le maximum que les écrans d'identification
  /// proposent, et chaque image se paie.
  static const maxImages = 2;

  /// Le grand côté envoyé. Le diagnostic monte à 1 024 px parce qu'il cherche
  /// une tache sur une feuille ; ici il s'agit d'une forme, d'un port et d'une
  /// marge de feuille, que 768 px donnent déjà — pour un peu plus de la moitié
  /// du coût en jetons d'image.
  static const maxSide = 768;

  /// Cinq noms au plus : c'est ce que les écrans affichent, et une liste plus
  /// longue dilue la question au lieu de l'affiner.
  static const maxCandidates = 5;

  /// Quelqu'un attend devant l'écran. Passé ce délai, la liste d'Iris est
  /// rendue telle quelle : un arbitrage est un bonus, jamais une attente.
  static const timeout = Duration(seconds: 8);

  Uri get endpoint => Uri.parse('https://api.infomaniak.com/2/ai/$productId/openai/v1/chat/completions');

  @override
  bool get isConfigured => apiKey.trim().isNotEmpty && productId.trim().isNotEmpty;

  @override
  Future<Arbitration?> arbitrate({
    required List<File> images,
    required List<IdentificationCandidate> candidates,
    required String language,
  }) async {
    if (!isConfigured || images.isEmpty) return null;
    final names = [for (final c in candidates.take(maxCandidates)) c.scientificName];
    if (names.length < 2) return null;
    try {
      final parts = <Map<String, Object?>>[
        for (final image in images.take(maxImages))
          {
            'type': 'image_url',
            'image_url': {
              'url': 'data:image/jpeg;base64,${base64Encode(await shrinkForModel(await image.readAsBytes(), maxSide: maxSide))}',
            },
          },
        {'type': 'text', 'text': userPrompt(names)},
      ];
      // Le format JSON contraint n'est pas garanti par tous les modèles : si
      // le service le refuse, la même demande repart sans lui — la consigne
      // demande déjà du JSON, et le lecteur est tolérant.
      var response = await _post(buildRequest(model: model, parts: parts, language: language, constrainJson: true));
      if (response.statusCode == 400) {
        response = await _post(buildRequest(model: model, parts: parts, language: language, constrainJson: false));
      }
      if (response.statusCode != 200) return null;
      return parseResponse(response.body, names: names);
    } on Object {
      // Réseau coupé, délai dépassé, fichier illisible : la liste d'Iris
      // reste ce qu'elle était. Un arbitrage manqué ne se voit pas.
      return null;
    }
  }

  Future<http.Response> _post(Map<String, Object?> body) => _client
      .post(endpoint, headers: {'content-type': 'application/json', 'authorization': 'Bearer ${apiKey.trim()}'}, body: jsonEncode(body))
      .timeout(timeout);

  /// Corps de requête, au format OpenAI (exposé pour les tests).
  static Map<String, Object?> buildRequest({
    required String model,
    required List<Map<String, Object?>> parts,
    required String language,
    required bool constrainJson,
  }) =>
      {
        'model': model,
        // Un numéro et une poignée de mots. Large parce qu'un modèle
        // bavard écrit sa phrase avant son JSON, pas parce qu'on en veut.
        'max_tokens': 200,
        // Un arbitrage, pas une invention.
        'temperature': 0.0,
        if (constrainJson) 'response_format': {'type': 'json_object'},
        'messages': [
          {'role': 'system', 'content': systemPrompt(language)},
          {'role': 'user', 'content': parts},
        ],
      };

  static String systemPrompt(String language) =>
      'You are shown one or two photos of the same plant, and a numbered shortlist of candidate species. '
      'Your only task is to say which numbered candidate the photos show, or 0 when none of them does. '
      'Never name a species that is not on the list, and never add one: the list is closed. '
      'Judge from what the photos actually show — leaf shape, size and margin, venation, fenestration, variegation, succulence, petiole, '
      'stem, habit, spines, flowers, fruit — and not from what is common or likely. '
      'Answer 0 whenever the photos do not let you tell one candidate from another, or when the plant is none of them: '
      '0 is a useful answer, and a wrong name is worse than no name. '
      'Answer with one JSON object only, no markdown, with exactly these keys: '
      '"candidate" (integer: the number of the candidate, or 0), '
      '"plant" (boolean: false only when the photos show no plant at all), '
      '"trait" (string: the single visible feature that decided it, at most ten words, in the language with code "$language", '
      'empty when "candidate" is 0).';

  static String userPrompt(List<String> names) => [
        'Candidates:',
        for (final (i, name) in names.indexed) '${i + 1}. $name',
        'Which candidate do the photos show?',
      ].join('\n');

  /// Lit la réponse : un numéro de la liste soumise, ou rien.
  ///
  /// Tout ce qui n'est pas un numéro soumis vaut zéro — un modèle qui répond
  /// « 7 » sur cinq candidates, ou qui écrit un nom au lieu d'un numéro, n'a
  /// pas répondu à la question posée. Et une réponse illisible rend `null` :
  /// pas d'avis, plutôt qu'un avis inventé.
  static Arbitration? parseResponse(String body, {required List<String> names}) {
    final data = _extractJson(_contentOf(body));
    if (data == null) return null;
    if (data['plant'] == false) return const Arbitration(outcome: ArbitrationOutcome.notPlant);
    final raw = data['candidate'];
    final number = switch (raw) {
      num n => n.toInt(),
      String s => int.tryParse(RegExp(r'\d+').firstMatch(s)?.group(0) ?? ''),
      _ => null,
    };
    if (number == null) return null;
    if (number < 1 || number > names.length) return const Arbitration.none();
    return Arbitration(
      outcome: ArbitrationOutcome.picked,
      scientificName: names[number - 1],
      trait: _trait(data['trait']),
    );
  }

  /// Le caractère décisif, tel qu'il s'affichera : une poignée de mots, ou
  /// rien. Un modèle qui écrit un paragraphe n'a pas nommé un caractère, et
  /// la ligne n'a de place que pour un.
  static String? _trait(Object? raw) {
    if (raw is! String) return null;
    final text = raw.trim();
    if (text.isEmpty || text.length > 80) return null;
    // Une phrase entière trahit une consigne mal suivie ; un caractère
    // botanique tient en quelques mots.
    if (text.split(RegExp(r'\s+')).length > 12) return null;
    return text;
  }

  static String _contentOf(String body) {
    final Object? json;
    try {
      json = jsonDecode(body);
    } on FormatException {
      return '';
    }
    if (json is! Map<String, dynamic>) return '';
    final choices = (json['choices'] as List?) ?? const [];
    if (choices.isEmpty) return '';
    final first = choices.first;
    if (first is! Map<String, dynamic>) return '';
    return switch ((first['message'] as Map<String, dynamic>?)?['content']) {
      String s => s,
      List l => l.map((p) => p is Map ? (p['text'] as String? ?? '') : '').join(),
      _ => '',
    };
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
