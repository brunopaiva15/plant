import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute;
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

import '../../core/utils/search_text.dart';
import '../../domain/diagnosis/plant_diagnoser.dart';
import '../../domain/problems/plant_problem.dart';

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
  Future<Diagnosis> diagnose({
    required List<File> images,
    required String language,
    String? plantName,
    String? species,
    String? symptoms,
    List<PlantProblem> candidates = const [],
    Set<String> frequentIds = const {},
  }) async {
    if (!isConfigured) throw const DiagnosisException('unconfigured');
    if (images.isEmpty) throw const DiagnosisException('no_images');
    final parts = <Map<String, Object?>>[
      for (final image in images.take(maxImages))
        {
          'type': 'image_url',
          'image_url': {'url': 'data:image/jpeg;base64,${base64Encode(await prepareImage(await image.readAsBytes()))}'},
        },
      {
        'type': 'text',
        'text': userPrompt(
          language: language,
          plantName: plantName,
          species: species,
          symptoms: symptoms,
          candidates: candidates,
          frequentIds: frequentIds,
        ),
      },
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
    // Un numéro qu'on n'a pas soumis ne vaut rien : soit le modèle l'a
    // inventé, soit il désigne un problème qu'on a écarté pour cette plante.
    final diagnosis = parseResponse(
      response.body,
      allowed: {for (final p in candidates) p.id},
      byName: namesOf(candidates, language),
    );
    return _numberLeftovers(diagnosis, candidates, language);
  }

  /// Deuxième passe, pour les pistes revenues sans numéro.
  ///
  /// Demander en un seul jet d'observer, d'expliquer, de conseiller *et* de
  /// rattacher à une liste, c'est demander quatre choses à la fois, et la
  /// quatrième est celle qu'on lâche. En pratique le modèle écrivait
  /// « Blessure mécanique ou coupure récente » sans voir que la liste
  /// contenait « Blessures mécaniques ».
  ///
  /// Ici il n'y a plus qu'une question, fermée : lequel de ces numéros, ou
  /// aucun. Pas de photo, donc quelques centimes de jetons et une seconde,
  /// et seulement s'il reste des pistes à rattacher.
  ///
  /// C'est un bonus, jamais un motif d'échec : la moindre difficulté rend le
  /// diagnostic de la première passe tel quel.
  Future<Diagnosis> _numberLeftovers(Diagnosis diagnosis, List<PlantProblem> candidates, String language) async {
    if (candidates.isEmpty) return diagnosis;
    final orphelines = [
      for (final (i, c) in diagnosis.causes.indexed)
        if (c.problemId == null) i,
    ];
    if (orphelines.isEmpty) return diagnosis;
    try {
      final body = buildMappingRequest(
        model: model,
        candidates: candidates,
        causes: [for (final i in orphelines) diagnosis.causes[i]],
        language: language,
      );
      var response = await _post(body, timeout: const Duration(seconds: 30));
      if (response.statusCode == 400) {
        response = await _post({...body}..remove('response_format'), timeout: const Duration(seconds: 30));
      }
      if (response.statusCode != 200) return diagnosis;
      final trouves = parseMapping(response.body, allowed: {for (final p in candidates) p.id});
      if (trouves.isEmpty) return diagnosis;
      final causes = [...diagnosis.causes];
      for (final e in trouves.entries) {
        if (e.key < 0 || e.key >= orphelines.length) continue;
        final at = orphelines[e.key];
        final c = causes[at];
        causes[at] = DiagnosisCause(
          title: c.title,
          likelihood: c.likelihood,
          explanation: c.explanation,
          actions: c.actions,
          problemId: e.value,
        );
      }
      return Diagnosis(summary: diagnosis.summary, causes: causes, urgent: diagnosis.urgent);
    } on Object {
      return diagnosis;
    }
  }

  /// Corps de la deuxième passe (exposé pour les tests).
  static Map<String, Object?> buildMappingRequest({
    required String model,
    required List<PlantProblem> candidates,
    required List<DiagnosisCause> causes,
    required String language,
  }) =>
      {
        'model': model,
        'max_tokens': 300,
        // Un rattachement, pas une création.
        'temperature': 0.0,
        'response_format': {'type': 'json_object'},
        'messages': [
          {
            'role': 'system',
            'content': 'You match short descriptions of plant problems to a numbered list. '
                'For each numbered cause below, answer with the number of the listed problem it describes, or null when none of them does. '
                'Do not rename anything, do not explain, do not use a number that is not on the list. '
                'A cause worded loosely still matches when it is the same problem: "a knock or a recent cut" is mechanical injury. '
                'Two causes may match the same listed problem, and none of them has to match. '
                'Answer with one JSON object only, no markdown: {"matches": [{"cause": 0, "problem": "001"}, {"cause": 1, "problem": null}]}.',
          },
          {
            'role': 'user',
            'content': [
              'Listed problems: ${candidates.map((p) => '${p.id} ${p.nameIn(language)}').join('; ')}.',
              'Causes:',
              for (final (i, c) in causes.indexed) '$i. ${c.title}${c.explanation.isEmpty ? '' : ' — ${c.explanation}'}',
            ].join('\n'),
          },
        ],
      };

  /// Lit la réponse de la deuxième passe : le rang de la piste, son numéro.
  static Map<int, String> parseMapping(String body, {required Set<String> allowed}) {
    final text = _contentOf(body);
    final data = _extractJson(text);
    final matches = (data?['matches'] as List?) ?? const [];
    final out = <int, String>{};
    for (final m in matches.whereType<Map>()) {
      final at = m['cause'];
      final rang = at is num ? at.toInt() : int.tryParse('$at');
      final id = _problemId(m['problem'], allowed);
      if (rang != null && id != null) out[rang] = id;
    }
    return out;
  }

  Future<http.Response> _post(Map<String, Object?> body, {Duration timeout = const Duration(minutes: 2)}) => _client
      .post(endpoint, headers: {'content-type': 'application/json', 'authorization': 'Bearer ${apiKey.trim()}'}, body: jsonEncode(body))
      .timeout(timeout);

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
      'then list the most plausible causes, most plausible first, each with a short explanation '
      'and 1 to 3 concrete, gentle actions the person can take at home. Be honest about uncertainty: these are suggestions, never a diagnosis. '
      'Rate each cause with "likelihood", one of exactly these three words: "likely", "possible", "unlikely". '
      'Do not use numbers or percentages: you cannot measure this from a photo, and a figure would suggest a precision you do not have. '
      'Use "likely" sparingly, for what the photos really show; at most two causes may be "likely". '
      'If the plant looks healthy, say so with a single "unlikely" cause at most. Set "urgent" only for pests, rot or rapid decline. '
      'If the photos do not show a plant clearly enough, say so in "summary" and return no cause. '
      'The message lists known problems for this plant, each as a three-digit number and a name. Read that list before you name anything. '
      'For every cause, decide "problem" first, before writing its title: the number of the listed problem it is, or null when it is none of them. '
      'Always include the key, never write a number that is not on the list, and when a listed problem fits, use its number even if you would '
      'have worded the name differently. '
      'One cause is one listed problem. When two listed problems both fit what you see, give them as two causes, each with its own number, '
      'instead of merging them into a single title of the form "A or B": they call for different actions, and the reader has to choose anyway. '
      'The list is a shortlist, not a closed set: a cause outside it takes "problem": null, and that is a perfectly good answer. '
      'Write every text field in the language with code "$language", in a warm, plain, human tone, without jargon. '
      'Answer with one JSON object only, no markdown, no text around it, with exactly these keys: '
      '"summary" (string), "urgent" (boolean), "causes" (array of objects with "problem" (string or null), "title" (string), '
      '"likelihood" (string), "explanation" (string), "actions" (array of strings)).';

  static String userPrompt({
    required String language,
    String? plantName,
    String? species,
    String? symptoms,
    List<PlantProblem> candidates = const [],
    Set<String> frequentIds = const {},
  }) {
    final parts = <String>[
      if (plantName != null && plantName.isNotEmpty) 'Plant: $plantName.',
      if (species != null && species.isNotEmpty) 'Species: $species.',
      // La base locale, réduite à ce qui peut concerner cette plante. Elle
      // donne au modèle un vocabulaire au lieu de le laisser improviser un
      // nom à chaque analyse, et c'est ce nom-là que l'application affichera.
      ...shortlist(candidates, frequentIds, language),
      if (symptoms != null && symptoms.trim().isNotEmpty) 'What the owner noticed: ${symptoms.trim()}',
      'What might be wrong, and what can I do?',
    ];
    return parts.join(' ');
  }

  /// Les noms des pistes soumises, normalisés, pour le filet de rattrapage.
  ///
  /// Un nom qui se normalise comme un autre est écarté des deux côtés : mieux
  /// vaut ne rien rattraper que de trancher au hasard entre deux pistes.
  static Map<String, String> namesOf(List<PlantProblem> candidates, String language) {
    final vus = <String, String?>{};
    for (final p in candidates) {
      final clef = normaliseName(p.nameIn(language));
      if (clef.isEmpty) continue;
      vus[clef] = vus.containsKey(clef) ? null : p.id;
    }
    return {
      for (final e in vus.entries)
        if (e.value != null) e.key: e.value!,
    };
  }

  /// Casse, accents et ponctuation retirés. Sert des deux côtés de la
  /// comparaison, jamais à l'affichage.
  static String normaliseName(String raw) => foldSpeciesName(raw).replaceAll(RegExp('[^a-z0-9]+'), '');

  /// La liste de pistes telle qu'elle part, groupée par nature.
  ///
  /// Les troubles d'abord : ce sont les plus fréquents sur une plante de
  /// balcon ou de salon, et ceux qu'un modèle a le plus tendance à oublier au
  /// profit d'un ravageur spectaculaire.
  ///
  /// Les noms partent dans la langue de la réponse, pas en anglais. Le modèle
  /// doit écrire son titre dans cette langue : lui donner la liste dans une
  /// autre l'obligeait à traduire, et une traduction libre ne retombe pas sur
  /// le nom de la base.
  static List<String> shortlist(List<PlantProblem> candidates, Set<String> frequentIds, String language) {
    if (candidates.isEmpty) return const [];
    String? group(String label, ProblemKind kind) {
      final of = candidates.where((p) => p.kind == kind);
      if (of.isEmpty) return null;
      return '$label: ${of.map((p) => '${p.id} ${p.nameIn(language)}').join('; ')}.';
    }

    final frequent = candidates.where((p) => frequentIds.contains(p.id)).map((p) => p.id).toList();
    return [
      'Known problems for this kind of plant, as "number name".',
      ?group('Disorders', ProblemKind.disorder),
      ?group('Pests', ProblemKind.pest),
      ?group('Diseases', ProblemKind.disease),
      ?group('Other', ProblemKind.condition),
      // Ce que le catalogue de soins signale pour l'espèce : un a priori de
      // plus, jamais une réponse.
      if (frequent.isNotEmpty)
        'Known to be especially common on this species: ${frequent.join(', ')}. '
            'Weigh them a little more, but only if the photos fit.',
    ];
  }

  /// Extrait le diagnostic d'une réponse chat completions. Le contenu peut
  /// être une chaîne ou une liste de fragments ; du JSON entouré de
  /// balises Markdown ou d'une phrase est accepté.
  ///
  /// [allowed] borne les numéros acceptés à ceux qu'on a soumis. `null`
  /// laisse passer n'importe quel numéro à trois chiffres, ce qui n'a de sens
  /// que hors appel réel. [byName] rattrape les pistes nommées sans numéro.
  static Diagnosis parseResponse(String body, {Set<String>? allowed, Map<String, String> byName = const {}}) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final choices = (json['choices'] as List?) ?? const [];
    if (choices.isEmpty) throw const DiagnosisException('empty');
    final choice = choices.first as Map<String, dynamic>;
    if (choice['finish_reason'] == 'content_filter') throw const DiagnosisException('refusal');
    final message = (choice['message'] as Map<String, dynamic>?) ?? const {};
    final data = _extractJson(_textOf(message['content']));
    if (data == null) throw const DiagnosisException('empty');
    final causes = ((data['causes'] as List?) ?? const [])
        .whereType<Map>()
        .map((c) => DiagnosisCause(
              title: (c['title'] as String?) ?? '',
              likelihood: Likelihood.parse(c['likelihood']),
              explanation: (c['explanation'] as String?) ?? '',
              actions: ((c['actions'] as List?) ?? const []).whereType<String>().toList(),
              problemId: _problemId(c['problem'], allowed) ?? _problemByName(c['title'], byName),
            ))
        // Une cause sans titre reste lisible si elle porte un numéro : la
        // base lui en donnera un, dans la bonne langue.
        .where((c) => c.title.isNotEmpty || c.problemId != null)
        .toList();
    // Trois crans laissent beaucoup d'ex æquo. Le rang d'arrivée les
    // départage, car le service a déjà classé ses pistes de la plus à la
    // moins plausible ; un tri sans cela les rebattrait sans raison.
    final classees = causes.indexed.toList()
      ..sort((a, b) {
        final cran = a.$2.likelihood.index.compareTo(b.$2.likelihood.index);
        return cran != 0 ? cran : a.$1.compareTo(b.$1);
      });
    return Diagnosis(
      summary: (data['summary'] as String?) ?? '',
      causes: [for (final (_, c) in classees) c],
      urgent: data['urgent'] == true,
    );
  }

  /// Le texte d'une réponse, sans juger de sa validité : chaîne vide quand
  /// il n'y en a pas. La première passe, elle, distingue une réponse vide
  /// d'un refus et lève ; la seconde n'a qu'à renoncer.
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
    return _textOf((first['message'] as Map<String, dynamic>?)?['content']);
  }

  /// Le contenu peut être une chaîne ou une liste de fragments.
  static String _textOf(Object? content) => switch (content) {
        String s => s,
        List l => l.map((p) => p is Map ? (p['text'] as String? ?? '') : '').join(),
        _ => '',
      };

  /// Le numéro rendu, s'il est bien formé et s'il faisait partie de la liste
  /// soumise. Un modèle qui écrit « 60 » ou « id 060 » veut dire 060.
  static String? _problemId(Object? raw, Set<String>? allowed) {
    final digits = RegExp(r'\d+').firstMatch(switch (raw) { num n => '$n', String t => t, _ => '' })?.group(0);
    if (digits == null || digits.length > 3) return null;
    final id = digits.padLeft(3, '0');
    if (id == '000') return null;
    return allowed == null || allowed.contains(id) ? id : null;
  }

  /// Dernier recours : le service a écrit le nom exact d'une piste soumise
  /// sans en donner le numéro.
  ///
  /// La comparaison est stricte — accents, casse et ponctuation mis à part,
  /// le titre doit être ce nom et rien d'autre. Un rapprochement approximatif
  /// poserait un mauvais nom sur une carte, ce qui est pire que pas de nom.
  static String? _problemByName(Object? raw, Map<String, String> byName) {
    if (byName.isEmpty || raw is! String) return null;
    return byName[normaliseName(raw)];
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
