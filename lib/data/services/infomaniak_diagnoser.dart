import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute;
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

import '../../core/config/relay_config.dart';
import '../../core/network/network_failure.dart';
import '../../core/utils/search_text.dart';
import '../../domain/diagnosis/diagnosis_observations.dart';
import '../../domain/diagnosis/plant_diagnoser.dart';
import '../../domain/home/home_climate.dart';
import '../../domain/problems/natural_cause.dart';
import '../../domain/problems/plant_problem.dart';

/// Diagnostic par les AI Services d'Infomaniak (hébergés en Suisse), via
/// leur route compatible OpenAI : un modèle qui voit les images reçoit les
/// photos et rend un JSON — résumé, urgence, causes classées avec des gestes.
///
/// Les photos sont réduites à [maxSide] pixels avant l'envoi : la facture se
/// compte en jetons d'image, et une photo de téléphone entière n'en vaut pas
/// le prix. Rien n'est stocké côté service au-delà de la requête.
class InfomaniakDiagnoser implements PlantDiagnoser {
  InfomaniakDiagnoser({
    Uri? endpoint,
    http.Client? client,
    this.retryPause = const Duration(seconds: 2),
  })  : endpoint = endpoint ?? RelayConfig.route('ai'),
        _client = client ?? http.Client();

  /// Le relais, qui tient la clé et choisit le modèle. Les quatre appels aux
  /// AI Services passent par la même route : même amont, même corps.
  final Uri endpoint;
  final http.Client _client;

  /// Ce qu'on laisse passer avant de renvoyer la même demande. Multiplié par
  /// le rang de la tentative : un service saturé ne se désature pas en une
  /// seconde. Les tests le mettent à zéro.
  final Duration retryPause;

  static const maxImages = 3;

  /// Grand côté des photos envoyées, en pixels.
  ///
  /// Mille vingt-quatre suffisaient à voir une feuille jaune ; pas à voir ce
  /// qui distingue les pistes entre elles. Un thrips mesure un millimètre, et
  /// son dégât est un piqueté argenté semé de points noirs : sur un gros plan
  /// de téléphone ramené à mille pixels, il ne reste que quelques pixels
  /// ternes, que le modèle a lus comme du calcaire — et le compte rendu
  /// répondait « feuilles vertes, sans taches » à qui photographiait de près.
  /// Mille cinq cents pixels doublent le nombre de points de l'image et son
  /// poids ; c'est ce que coûte un compte rendu qui nomme le ravageur au lieu
  /// de rester général.
  static const maxSide = 1536;

  /// Ce qu'on attend d'une réponse, et combien de fois on repose la question.
  ///
  /// Une minute suffisait à trois photos réduites, téléversement compris —
  /// les photos partent plus grandes depuis qu'un dégât d'un millimètre doit
  /// y survivre ([maxSide]), et quarante secondes se jouaient alors sur la
  /// qualité du réseau. Le modèle réfléchit avant d'écrire, et cette
  /// réflexion prend le temps qu'elle prend ([_answerTokens]) : une minute
  /// et demie la laisse aller au bout d'une photo difficile. Au-delà, c'est
  /// que la demande s'est perdue, et la reposer vaut mieux que de l'attendre.
  static const _callTimeout = Duration(seconds: 90);
  static const _attempts = 3;

  /// Jetons laissés à la réponse, et ce qu'on redonne quand elle est revenue
  /// coupée au milieu d'une phrase.
  ///
  /// La réflexion du modèle se paie sur ce budget. Qwen 3.5 réfléchit avant
  /// de répondre, et cette réflexion, invisible, compte dans `max_tokens` au
  /// même titre que la réponse. Mille six cents jetons suffisaient à la
  /// réponse — trois cents à cinq cents —, pas toujours à ce qui la précède :
  /// devant une photo difficile, la réflexion mangeait parfois le budget
  /// entier, et le service rendait un contenu vide, arrêté faute de place.
  /// Deux fois de suite sur la même photo, et l'écran disait « L'analyse n'a
  /// pas abouti » à quelqu'un dont le troisième essai, moins long à
  /// réfléchir, passait. C'était la panne intermittente du diagnostic.
  ///
  /// On garde la réflexion — c'est elle qui lit le motif avant de nommer —
  /// et on lui laisse la place. Le plafond ne coûte rien tant qu'il n'est
  /// pas atteint : seuls les jetons écrits se facturent.
  static const _answerTokens = 5000;
  static const _wideTokens = 9000;

  @override
  bool get isConfigured => endpoint.hasAuthority;

  @override
  Future<Diagnosis> diagnose({
    required List<File> images,
    required String language,
    String? plantName,
    String? species,
    String? symptoms,
    List<PlantProblem> candidates = const [],
    List<NaturalCause> naturalCauses = const [],
    Set<String> frequentIds = const {},
    HomeReading? indoorClimate,
    ReportedClimate? reportedClimate,
    DiagnosisObservations? observations,
    List<DiagnosisAnswer> answers = const [],
    bool? indoors,
    DateTime? date,
    double? latitude,
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
          naturalCauses: naturalCauses,
          frequentIds: frequentIds,
          indoorClimate: indoorClimate,
          reportedClimate: reportedClimate,
          observations: observations,
          answers: answers,
          indoors: indoors,
          date: date,
          latitude: latitude,
        ),
      },
    ];
    Future<http.Response> ask({required bool constrainJson, int maxTokens = _answerTokens}) =>
        _send(buildRequest(parts: parts, language: language, constrainJson: constrainJson, maxTokens: maxTokens));

    // Le format JSON contraint n'est pas garanti par tous les modèles : si
    // le service le refuse, on renvoie la même demande sans lui — la consigne
    // demande déjà du JSON, et le lecteur est tolérant.
    var constrainJson = true;
    var response = await ask(constrainJson: constrainJson);
    if (response.statusCode == 400) {
      constrainJson = false;
      response = await ask(constrainJson: constrainJson);
    }
    _check(response);
    // Un numéro qu'on n'a pas soumis ne vaut rien : soit le modèle l'a
    // inventé, soit il désigne un problème qu'on a écarté pour cette plante.
    Diagnosis? diagnosis;
    try {
      diagnosis = _read(response, candidates, naturalCauses, language);
    } on DiagnosisException catch (e) {
      // Un refus de contenu ne se rejoue pas ; une réponse illisible, si.
      if (e.message != 'empty') rethrow;
    }
    if (diagnosis == null) {
      // Illisible veut presque toujours dire coupée : la réponse s'est
      // arrêtée au milieu d'une phrase faute de jetons, et le lecteur n'a
      // même pas pu la réparer. La même demande repart une fois, avec de
      // quoi finir. C'est ce cas-là qui affichait « Analyse impossible » à
      // quelqu'un dont le réseau allait très bien.
      final second = await ask(constrainJson: constrainJson, maxTokens: _wideTokens);
      _check(second);
      try {
        diagnosis = _read(second, candidates, naturalCauses, language);
      } on DiagnosisException catch (e) {
        throw DiagnosisException(e.message == 'empty' ? 'unreadable' : e.message);
      }
    }
    final complete = diagnosis.causes.isNotEmpty
        ? diagnosis
        : await _causesFromWords(
            diagnosis,
            language: language,
            plantName: plantName,
            species: species,
            symptoms: symptoms,
            candidates: candidates,
            naturalCauses: naturalCauses,
            frequentIds: frequentIds,
            observations: observations,
            answers: answers,
          );
    return _numberLeftovers(complete, candidates, language);
  }

  /// Passe de repli : un compte rendu revenu sans aucune piste.
  ///
  /// La consigne en demande toujours une. Un modèle qui ne reconnaît rien sur
  /// la photo retombe pourtant sur « rien à signaler », voire sur « ce que
  /// vous décrivez n'est pas sur l'image » — alors que le symptôme, lui, a
  /// bien été vu sur la plante. Un compte rendu sans piste ne sert personne.
  ///
  /// On redemande donc sans les photos, puisqu'elles n'ont rien donné : il
  /// reste l'espèce, ce que la personne a décrit et la liste des problèmes
  /// connus. Quelques centimes de jetons, et seulement dans ce cas-là.
  ///
  /// Comme la deuxième passe, c'est un bonus : la moindre difficulté rend le
  /// compte rendu de la première passe tel quel.
  Future<Diagnosis> _causesFromWords(
    Diagnosis diagnosis, {
    required String language,
    String? plantName,
    String? species,
    String? symptoms,
    required List<PlantProblem> candidates,
    required List<NaturalCause> naturalCauses,
    required Set<String> frequentIds,
    DiagnosisObservations? observations,
    List<DiagnosisAnswer> answers = const [],
  }) async {
    try {
      final body = buildFallbackRequest(
        language: language,
        plantName: plantName,
        species: species,
        symptoms: symptoms,
        candidates: candidates,
        naturalCauses: naturalCauses,
        frequentIds: frequentIds,
        observations: observations,
        answers: answers,
      );
      var response = await _post(body, timeout: const Duration(seconds: 60));
      if (response.statusCode == 400) {
        response = await _post({...body}..remove('response_format'), timeout: const Duration(seconds: 60));
      }
      if (response.statusCode != 200) return diagnosis;
      final repli = parseResponse(
        response.body,
        allowed: {for (final p in candidates) p.id},
        allowedNatural: {for (final n in naturalCauses) n.id},
        byName: namesOf(candidates, language, naturalCauses: naturalCauses),
      );
      if (repli.causes.isEmpty) return diagnosis;
      // Le résumé reste celui de la première passe : c'est elle qui a vu les
      // photos. Le repli n'apporte que les pistes.
      return Diagnosis(
        summary: diagnosis.summary.isEmpty ? repli.summary : diagnosis.summary,
        causes: repli.causes,
        urgent: diagnosis.urgent || repli.urgent,
        // La vue à demander est celle de la passe qui a vu les photos ; le
        // repli, lui, n'en a regardé aucune.
        suggestedView: diagnosis.suggestedView,
        // Les questions aussi : celles du repli portent sur une analyse
        // faite sans les photos.
        questions: diagnosis.questions,
      );
    } on Object {
      return diagnosis;
    }
  }

  /// Corps de la passe de repli (exposé pour les tests).
  static Map<String, Object?> buildFallbackRequest({
    required String language,
    String? plantName,
    String? species,
    String? symptoms,
    List<PlantProblem> candidates = const [],
    List<NaturalCause> naturalCauses = const [],
    Set<String> frequentIds = const {},
    DiagnosisObservations? observations,
    List<DiagnosisAnswer> answers = const [],
  }) =>
      {
        // Le modèle réfléchit avant d'écrire, et sa réflexion se paie sur
        // ce budget ([_answerTokens]) : neuf cents jetons n'y suffisaient pas.
        'max_tokens': 3000,
        'temperature': 0.2,
        'response_format': {'type': 'json_object'},
        'messages': [
          {'role': 'system', 'content': systemPrompt(language)},
          {
            'role': 'user',
            'content': [
              'The photos gave nothing to go on, so judge from what is written below and do not mention them at all.',
              userPrompt(
                language: language,
                plantName: plantName,
                species: species,
                symptoms: symptoms,
                candidates: candidates,
                naturalCauses: naturalCauses,
                frequentIds: frequentIds,
                observations: observations,
                answers: answers,
              ),
              'Give the one or two most plausible causes, as "possible" or "unlikely".',
            ].join(' '),
          },
        ],
      };

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
        // Une piste naturelle n'a rien à chercher dans la base des
        // problèmes : lui en coller un serait la renier.
        if (c.problemId == null && !c.natural) i,
    ];
    if (orphelines.isEmpty) return diagnosis;
    try {
      final body = buildMappingRequest(
        candidates: candidates,
        causes: [for (final i in orphelines) diagnosis.causes[i]],
        language: language,
      );
      var response = await _post(body, timeout: const Duration(seconds: 60));
      if (response.statusCode == 400) {
        response = await _post({...body}..remove('response_format'), timeout: const Duration(seconds: 60));
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
      return Diagnosis(
        summary: diagnosis.summary,
        causes: causes,
        urgent: diagnosis.urgent,
        suggestedView: diagnosis.suggestedView,
        questions: diagnosis.questions,
      );
    } on Object {
      return diagnosis;
    }
  }

  /// Corps de la deuxième passe (exposé pour les tests).
  static Map<String, Object?> buildMappingRequest({
    required List<PlantProblem> candidates,
    required List<DiagnosisCause> causes,
    required String language,
  }) =>
      {
        // Trois cents jetons suffisaient à la réponse, pas à la réflexion
        // qui la précède ([_answerTokens]) : la passe échouait en silence.
        'max_tokens': 1500,
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

  /// La même demande, jusqu'à [attempts] fois.
  ///
  /// Un service d'IA n'est pas une base de données : il coupe, il sature, il
  /// met une minute puis rend 503. Aucun de ces trois-là ne dit quoi que ce
  /// soit sur la plante, et l'écran affichait pourtant « Analyse impossible »
  /// alors qu'un simple renvoi de la même question aboutit presque toujours.
  ///
  /// Ne repartent que les échecs qui ne tranchent rien : réseau coupé, délai
  /// dépassé, 408, 429, 5xx. Un 400, un 401 ou un refus de contenu, eux, se
  /// corrigent et ne se rejouent pas.
  Future<http.Response> _send(Map<String, Object?> body, {Duration timeout = _callTimeout, int attempts = _attempts}) async {
    for (var attempt = 1;; attempt++) {
      final http.Response response;
      try {
        response = await _post(body, timeout: timeout);
      } on Object catch (e) {
        if (!isNetworkFailure(e)) rethrow;
        // Un réseau qui lâche n'est pas un incident de l'application : il se
        // dit à l'écran, il ne se rapporte pas comme un plantage.
        if (attempt >= attempts) throw const DiagnosisException('network');
        await Future<void>.delayed(retryPause * attempt);
        continue;
      }
      if (attempt >= attempts || !_worthAnotherTry(response.statusCode)) return response;
      await Future<void>.delayed(retryPause * attempt);
    }
  }

  /// Les codes qui ne disent rien de la demande : le service est occupé,
  /// pas fâché.
  static bool _worthAnotherTry(int code) => code == 408 || code == 429 || code >= 500;

  /// Ce que vaut un code de retour, une fois les renvois épuisés. Chaque
  /// famille a sa phrase à l'écran : une clé refusée ne se réessaie pas, un
  /// service saturé si.
  static void _check(http.Response response) {
    final code = response.statusCode;
    if (code == 200) return;
    if (code == 401 || code == 403) throw const DiagnosisException('unauthorized');
    if (code == 429) throw const DiagnosisException('quota');
    if (code == 408 || code >= 500) throw const DiagnosisException('busy');
    throw DiagnosisException('http $code');
  }

  /// Le compte rendu d'une réponse, borné à ce qu'on a soumis.
  Diagnosis _read(http.Response response, List<PlantProblem> candidates, List<NaturalCause> naturalCauses, String language) =>
      parseResponse(
        response.body,
        allowed: {for (final p in candidates) p.id},
        allowedNatural: {for (final n in naturalCauses) n.id},
        byName: namesOf(candidates, language, naturalCauses: naturalCauses),
      );

  Future<http.Response> _post(Map<String, Object?> body, {Duration timeout = const Duration(minutes: 2)}) => _client
      .post(endpoint, headers: const {'content-type': 'application/json'}, body: jsonEncode(body))
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
  static Map<String, Object?> buildRequest({
    required List<Map<String, Object?>> parts,
    required String language,
    required bool constrainJson,
    int maxTokens = _answerTokens,
  }) =>
      {
        'max_tokens': maxTokens,
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
      // Ce que la personne est allée vérifier de sa main — la terre au doigt,
      // les racines hors du pot, les insectes sous les feuilles — n'est pas
      // une impression : c'est un constat, et aucune photo ne le montre. La
      // consigne le rangeait pourtant sous la règle des symptômes racontés,
      // qui interdit « probable » à tout ce que l'image ne montre pas : une
      // terre détrempée et des racines brunes ne pouvaient alors jamais mener
      // à une pourriture probable, et la personne lisait un compte rendu où
      // ce qu'elle était allée voir ne pesait rien.
      'The message may also carry what the owner checked by hand: the soil a couple of centimetres down, the roots out of the pot, the light '
      'the plant gets, insects on it or in the soil. These are observations of the plant itself, as solid as the photos and about things no '
      'photo shows. Weigh them exactly like the photos: a cause they support may be "likely", and a cause they contradict is dropped rather '
      'than listed. '
      // Le cas qui a fait tout revoir : « insectes sur la plante » coché, deux
      // photos de thrips, et un compte rendu de phénomènes normaux. Ce que la
      // personne a vu de ses yeux ne se discute pas parce que l'image de son
      // téléphone ne le montre pas — un thrips mesure un millimètre.
      'When the owner checked that insects are on the plant or in the soil, they have seen them and the photos may well not: most are one or '
      'two millimetres across. Give a pest among the causes, first and "likely" unless the damage plainly names another one, and never answer '
      'with normal phenomena alone. When the owner checked that no insect was found on a close look, weigh pests down instead. '
      // Ce qui sépare réellement deux pistes n'est pas la couleur mais le
      // motif : quelles feuilles, quelle zone de la feuille, sec ou mou, net
      // ou diffus. Sans cette consigne, le modèle nomme la couleur qu'il voit
      // et range derrière elle les trois causes les plus courantes.
      'Read the pattern before you name anything: which leaves are affected — the oldest, the newest, all of them —, whether the damage '
      'sits at the edge, at the tip, between the veins or all over, whether it is dry or soft, sharply outlined or diffuse, and whether it '
      'spreads. The pattern separates what the colour alone confuses: a yellowing that starts on the oldest leaves is not the one that '
      'starts on the newest. '
      // Un ravageur ne se voit pas, ses dégâts si. Le modèle rendait « feuilles
      // vertes et brillantes, sans taches » sur un gros plan de Monstera
      // piqueté d'argenté, et rangeait les points noirs du frass avec le
      // calcaire : les deux sont blanchâtres de loin. Les signatures se
      // nomment, sinon elles ne se cherchent pas — et c'est la différence
      // entre un compte rendu général et un compte rendu qui sert.
      'The photos may be at different scales: read each one at its own scale, and a close-up at the scale of a few millimetres. Never settle '
      'for what the wide shot says about a leaf the close-up shows. Before calling a leaf clean, look over its surface: stippling, fine '
      'speckling, webbing, a sticky film, minute black dots or specks that look like dirt are what a pest leaves, and none of them survives '
      'being looked at from a distance. '
      'What that damage says: silvery or bronzed stippling, often along the midrib and the veins, carrying minute black dots of frass, is '
      'thrips — not limescale, which is a chalky white deposit left in the dried rings of water drops, sits on top of the leaf, wipes off and '
      'leaves green tissue under it. Very fine pale speckling with thin webbing is spider mites; white cottony tufts in the leaf axils are '
      'mealybugs; brown limpet-like bumps with a sticky film or black sooty mould are scale insects; small dark flies around the soil are '
      'fungus gnats. Name the pest the damage points to, not "a pest". '
      'Say in "summary" what you actually see — where it is, what it looks like — before any conclusion. '
      'When what the owner checked by hand is what settles the answer, say that in "summary" too: a summary that describes only the photos '
      'hides what the answer was really based on. '
      'Weigh the species, the light, the soil, the season and the room given in the message against every cause, and drop a cause one of '
      'them rules out instead of listing it anyway. '
      'Always give at least one cause, whatever the photos show: "causes" is never empty. '
      // La moitié de ce qui inquiète est normal, et la consigne n'ouvrait
      // aucune porte à cette réponse-là : il ne restait qu'à ranger du
      // nectar extrafloral parmi les ravageurs. Une piste naturelle est une
      // piste comme les autres, avec sa vraisemblance et ses gestes — le
      // geste pouvant être de ne rien faire.
      'Not everything a plant does is a problem. Clear sticky drops of extrafloral nectar, water beads at the leaf tips in the morning, an old '
      'lower leaf going yellow, variegation, aerial roots: these worry the owner and nothing is wrong. The message lists such normal phenomena '
      'under numbers starting with "N". When one of them explains what is seen, give it as a cause like any other, with its number in "problem" '
      'and "natural": true, and weigh it against the problems instead of naming a problem by default. '
      'A natural phenomenon may be "likely" when the photos really show it, it is never "urgent", and it is never a disorder, a pest or a '
      'disease. '
      // Une feuille basse qui jaunit de vieillesse et, sous elle, « laisser
      // sécher le substrat entre deux arrosages » : le geste traitait l'excès
      // d'eau, c'est-à-dire une autre piste, sous une cause qui ne demandait
      // rien. La personne lit les gestes, pas le rang des pistes.
      'Its actions follow from it being normal — leave it be, take the spent leaf off, wipe the deposit away — and never treat a problem that '
      'is not there. This holds for every cause, normal or not: an action belongs under the cause it acts on, and an action that treats '
      'another cause is misplaced — put it under that one, or leave it out. '
      'Set "natural": false on every other cause — a cause that carries a three-digit number is a problem, never a normal phenomenon. '
      'Every other cause is a problem of the plant — a disorder, a pest, a disease, a care mistake. The photo is never a cause: never write that the '
      'reported symptom is missing from it, that it is unclear, or that another photo is needed, neither as a title, nor as an explanation, '
      'nor as an action, nor in "summary". Describe what the photos do show, never what they fail to show. '
      'When the photos do not show what the owner describes, work from the description, the species and the season: the owner has the plant in '
      'front of them, and what they report happened even if the frame missed it. Such causes are "possible" or "unlikely", never "likely" — '
      'unless what the owner checked by hand supports them, which is an observation and not a report. '
      'If the plant looks healthy on the photos, say so in "summary" and still give the one or two most plausible causes of what the owner '
      'reports, as "unlikely" — unless a normal phenomenon explains what is reported, or a hand check points to a cause the leaves do not '
      'show yet, either of which may be "likely". '
      'Set "urgent" only for pests, rot or rapid decline. '
      'The message lists known problems for this plant, each as a three-digit number and a name, and the normal phenomena as "N" numbers. '
      'Read both lists before you name anything. '
      'For every cause, decide "problem" first, before writing its title: the number of the listed problem or normal phenomenon it is, or null '
      'when it is neither. '
      'Always include the key, never write a number that is not on the list, and when a listed problem fits, use its number even if you would '
      'have worded the name differently. '
      'One cause is one listed problem. When two listed problems both fit what you see, give them as two causes, each with its own number, '
      'instead of merging them into a single title of the form "A or B": they call for different actions, and the reader has to choose anyway. '
      'The list is a shortlist, not a closed set: a cause outside it takes "problem": null, and that is a perfectly good answer. '
      // La seule place où une photo manquante a le droit d'exister. Le reste
      // de la consigne l'interdit partout ailleurs, et c'est l'application,
      // pas le compte rendu, qui décide d'en demander une (docs/16).
      'Add a "view" key next to "summary": the single extra photo that would most change what you can tell, one of exactly '
      '"leaf_closeup", "leaf_underside", "whole_plant", "stem_base", "soil_roots", or null when the photos already show what is needed. '
      'This key is the only place a missing view may be named: never in "summary", never in a title, an explanation or an action. '
      'It is a suggestion to the application, not a refusal to answer — the causes are given in full either way. '
      'When a pest is in play and the photos do not settle which one, "view" is "leaf_underside": that is where thrips, mites and scale sit. '
      // Le service n'avait aucun moyen de demander. Une photo ne dit ni depuis
      // quand, ni ce qui a changé dans la pièce, ni ce qui a déjà été tenté :
      // il répondait donc avec ce qu'il avait, et le compte rendu restait
      // général faute d'une question à trois mots.
      'Add a "questions" key next to "summary": up to three short questions to the owner, each one line, or an empty array. Ask only what '
      'would change which cause comes first — when it started and how fast it spread, what changed around the plant, when it was last watered, '
      'fed or repotted, what has already been tried, whether other plants show the same. Never ask what the message already answers, never ask '
      'for a photo — that is "view" — and never ask more than three. '
      'Ask nothing when one cause is already settled, and nothing when the answer would not change the order: an empty array is the ordinary '
      'answer. The causes are given in full either way: questions refine an answer, they never replace one. '
      'Write every text field in the language with code "$language", in a warm, plain, human tone, without jargon. '
      'Keep every explanation to two sentences at most and every action to one line, so the answer ends before it runs out of room. '
      'Answer with one JSON object only, no markdown, no text around it, with exactly these keys: '
      '"summary" (string), "urgent" (boolean), "view" (string or null), "questions" (array of strings, possibly empty), '
      '"causes" (array of objects with "problem" (string or null), '
      '"natural" (boolean), "title" (string), "likelihood" (string), "explanation" (string), "actions" (array of strings)).';

  static String userPrompt({
    required String language,
    String? plantName,
    String? species,
    String? symptoms,
    List<PlantProblem> candidates = const [],
    List<NaturalCause> naturalCauses = const [],
    Set<String> frequentIds = const {},
    HomeReading? indoorClimate,
    ReportedClimate? reportedClimate,
    DiagnosisObservations? observations,
    List<DiagnosisAnswer> answers = const [],
    bool? indoors,
    DateTime? date,
    double? latitude,
  }) {
    final parts = <String>[
      if (plantName != null && plantName.isNotEmpty) 'Plant: $plantName.',
      if (species != null && species.isNotEmpty) 'Species: $species.',
      // Où la plante vit et quel jour on est. Une cochenille de salon en
      // février et une brûlure de balcon en juillet ne se confondent pas, et
      // rien sur la photo ne dit laquelle des deux on regarde.
      ?placeLine(indoors: indoors, date: date, latitude: latitude),
      // Ce que le capteur de la maison mesure, quand il y en a un, et ce que
      // la personne a donné à sa place : une donnée de plus pour départager
      // un air sec d'un manque d'eau, jamais une réponse.
      ?climateLine(indoorClimate, reported: reportedClimate),
      // La base locale, réduite à ce qui peut concerner cette plante. Elle
      // donne au modèle un vocabulaire au lieu de le laisser improviser un
      // nom à chaque analyse, et c'est ce nom-là que l'application affichera.
      ...shortlist(candidates, frequentIds, language),
      // Ce que la plante fait normalement, à côté de ce qui lui arrive. Sans
      // cette liste, une goutte de nectar sous un philodendron n'avait que
      // des ravageurs pour s'expliquer.
      ...naturalShortlist(naturalCauses, language),
      // Ce que la personne décrit a été vu sur la plante, pas sur la photo :
      // le cadrage rate souvent la feuille dont elle parle, et le modèle
      // répondait alors que le symptôme n'était pas visible au lieu de
      // chercher une cause.
      if (symptoms != null && symptoms.trim().isNotEmpty)
        'What the owner noticed, on the plant itself, true whether or not the photos show it: ${symptoms.trim()}',
      // Ce que la personne est allée vérifier de sa main. Une terre au doigt
      // et des racines sorties du pot valent mieux qu'une photo : la consigne
      // le dit, sans quoi le modèle conseillait de vérifier ce qui venait de
      // l'être.
      ?observationsLine(observations),
      // Ce que le service avait demandé au tour précédent. Il ne voit pas
      // ses propres questions revenir : elles lui sont rendues avec les
      // réponses, sans quoi une réponse seule ne veut rien dire.
      ?answersLine(answers),
      'What might be wrong, and what can I do?',
    ];
    return parts.join(' ');
  }

  /// Où vit la plante et à quelle saison, ou `null` quand on n'en sait rien.
  ///
  /// La latitude ne part pas telle quelle : seul son signe compte ici, pour
  /// que « septembre » veuille dire l'automne ou le printemps selon
  /// l'hémisphère. Le lieu de la personne n'a pas à sortir de l'appareil
  /// pour qu'une saison soit juste.
  static String? placeLine({bool? indoors, DateTime? date, double? latitude}) {
    String two(int n) => n.toString().padLeft(2, '0');
    final facts = <String>[
      if (indoors == true) 'The plant lives indoors, in a home.',
      if (indoors == false) 'The plant lives outdoors.',
      if (date != null)
        'Today is ${date.year}-${two(date.month)}-${two(date.day)}'
            '${latitude == null ? '' : ', in the ${latitude >= 0 ? 'northern' : 'southern'} hemisphere'}.',
    ];
    if (facts.isEmpty) return null;
    return '${facts.join(' ')} Weigh the season and the setting: they rule some causes out and make others ordinary.';
  }

  /// La phrase qui décrit le climat, mesuré par le capteur ou donné par la
  /// personne, ou `null` s'il n'y a rien à dire. Le modèle sait d'où vient
  /// chaque valeur : une mesure et une estimation ne pèsent pas pareil.
  static String? climateLine(HomeReading? reading, {ReportedClimate? reported}) {
    final measured = reading == null || reading.isEmpty ? null : _facts(reading.temperatureC, reading.humidity);
    final given = reported == null || reported.isEmpty ? null : _facts(reported.temperatureC, reported.humidity);
    if (measured == null && given == null) return null;
    final room = reading?.sensor?.roomName;
    return [
      if (measured != null) 'Measured indoors right now by a home sensor${room == null || room.isEmpty ? '' : ' in the room "$room"'}: $measured.',
      if (given != null) 'Given by the owner for where the plant lives: $given.',
      'Take these conditions into account when weighing dry air, cold or heat as causes.',
    ].join(' ');
  }

  static String _facts(double? temperatureC, int? humidity) => [
        if (temperatureC != null) '${temperatureC.toStringAsFixed(1)} °C',
        if (humidity != null) '$humidity % relative humidity',
      ].join(', ');

  /// Ce que la personne a vérifié de sa main, ou `null` si elle n'a rien
  /// coché : la terre au doigt, les racines hors du pot, la lumière reçue,
  /// les insectes trouvés.
  ///
  /// Ce sont des constats, pas des impressions, et la photo n'en montre
  /// aucun : la consigne le dit au modèle, faute de quoi il conseillait de
  /// vérifier ce qui venait de l'être. « Aucun insecte » en est un aussi :
  /// une case laissée vide ne dit rien, une case cochée sur « aucun vu » pèse
  /// contre les ravageurs.
  static String? observationsLine(DiagnosisObservations? o) {
    if (o == null || o.isEmpty) return null;
    final facts = [
      switch (o.soil) {
        SoilState.dry => 'the soil is dry a couple of centimetres down',
        SoilState.moist => 'the soil is still damp a couple of centimetres down',
        SoilState.soggy => 'the soil is soaked and stays that way',
        null => null,
      },
      switch (o.roots) {
        RootState.firm => 'the roots were taken out of the pot and looked at: firm and pale',
        RootState.soft => 'the roots were taken out of the pot and looked at: brown, soft or smelling',
        RootState.crowded => 'the roots were taken out of the pot and looked at: coiled, filling the whole pot',
        null => null,
      },
      switch (o.light) {
        LightExposure.direct => 'the plant gets direct sun for part of the day',
        LightExposure.bright => 'the plant gets bright light, without direct sun',
        LightExposure.dim => 'the plant gets little light',
        null => null,
      },
      switch (o.bugs) {
        BugSighting.none => 'no insect was found on a close look, undersides of the leaves included',
        BugSighting.onPlant => 'insects are visible on the plant',
        BugSighting.inSoil => 'insects are visible in the soil',
        null => null,
      },
    ].whereType<String>().join('; ');
    return 'Checked by the owner, by hand, on the plant itself: $facts. '
        'These were verified, not guessed, and no photo shows them: weigh every cause for and against them, '
        'as heavily as what the photos show, say so in the summary when they are what settles it, '
        'and never give as an action something that has already been checked here.';
  }

  /// Ce que le service avait demandé et ce qu'on lui a répondu, ou `null`
  /// quand il n'avait rien demandé.
  ///
  /// Une analyse ne se recolle pas à la précédente : elle se refait en
  /// entier, photos comprises, avec ces réponses en plus. Elles valent ce que
  /// vaut une observation — la personne a la plante devant elle —, et le
  /// service n'a plus à reposer la même question.
  static String? answersLine(List<DiagnosisAnswer> answers) {
    final pairs = [
      for (final a in answers)
        if (a.question.trim().isNotEmpty && a.answer.trim().isNotEmpty) '"${a.question.trim()}" — ${a.answer.trim()}',
    ];
    if (pairs.isEmpty) return null;
    return 'Asked of the owner, and answered: ${pairs.join('; ')}. '
        'These answers are about the plant in front of them: take them as given, weigh them like the photos, and do not ask any of these '
        'again.';
  }

  /// Les noms des pistes soumises, normalisés, pour le filet de rattrapage.
  ///
  /// Un nom qui se normalise comme un autre est écarté des deux côtés : mieux
  /// vaut ne rien rattraper que de trancher au hasard entre deux pistes.
  static Map<String, String> namesOf(List<PlantProblem> candidates, String language, {List<NaturalCause> naturalCauses = const []}) {
    final vus = <String, String?>{};
    void retenir(String id, String name) {
      final clef = normaliseName(name);
      if (clef.isEmpty) return;
      vus[clef] = vus.containsKey(clef) ? null : id;
    }

    for (final p in candidates) {
      retenir(p.id, p.nameIn(language));
    }
    // Les deux bases ensemble : un nom qui les désigne toutes les deux ne
    // rattrape rien, et c'est ce qu'on veut.
    for (final n in naturalCauses) {
      retenir(n.id, n.nameIn(language));
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

  /// Les phénomènes naturels tels qu'ils partent : une liste à part, dite
  /// pour ce qu'elle est.
  ///
  /// Elle vient après celle des problèmes, et le modèle a besoin d'entendre
  /// qu'elle n'en est pas la suite : ce sont les réponses possibles quand
  /// rien ne va mal, pas un dernier groupe de troubles.
  static List<String> naturalShortlist(List<NaturalCause> naturalCauses, String language) {
    if (naturalCauses.isEmpty) return const [];
    return [
      'Normal on this kind of plant, not problems, as "number name": '
          '${naturalCauses.map((n) => '${n.id} ${n.nameIn(language)}').join('; ')}.',
      'Any of these explains what is seen without anything being wrong; give it as a cause with "natural": true.',
    ];
  }

  /// Extrait le diagnostic d'une réponse chat completions. Le contenu peut
  /// être une chaîne ou une liste de fragments ; du JSON entouré de
  /// balises Markdown ou d'une phrase est accepté.
  ///
  /// [allowed] borne les numéros acceptés à ceux qu'on a soumis. `null`
  /// laisse passer n'importe quel numéro à trois chiffres, ce qui n'a de sens
  /// que hors appel réel. [allowedNatural] fait la même chose pour les
  /// numéros des phénomènes naturels. [byName] rattrape les pistes nommées
  /// sans numéro, des deux bases.
  static Diagnosis parseResponse(
    String body, {
    Set<String>? allowed,
    Set<String>? allowedNatural,
    Map<String, String> byName = const {},
  }) {
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
        .map((c) => _cause(c, allowed: allowed, allowedNatural: allowedNatural, byName: byName))
        // Une cause sans titre reste lisible si elle porte un numéro : la
        // base lui en donnera un, dans la bonne langue.
        .where((c) => c.title.isNotEmpty || c.problemId != null || c.naturalId != null)
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
      // Un compte rendu dont aucune piste n'est un problème n'a rien à
      // traiter rapidement : la carte rouge le démentirait. La consigne le
      // dit déjà au modèle ; ici on ne le lui demande pas deux fois.
      urgent: data['urgent'] == true && !(causes.isNotEmpty && causes.every((c) => c.natural)),
      // Ce que le service aurait voulu voir de plus. L'application en fera
      // une proposition de photo ou rien du tout ; le compte rendu, lui, n'en
      // parle jamais.
      suggestedView: DiagnosisView.parse(data['view']),
      // Ce qu'il aurait voulu savoir de plus : trois questions au plus, et
      // rien de ce que la question portait déjà.
      questions: Diagnosis.readQuestions(data['questions']),
    );
  }

  /// Une piste telle que le service l'a écrite, rattachée à la base quand
  /// elle s'y retrouve : le numéro d'un problème, celui d'un phénomène
  /// naturel, ou rien.
  ///
  /// Les deux numéros s'excluent : `060` est un ravageur, `N01` du nectar,
  /// et un modèle qui écrirait les deux aurait de toute façon tranché en
  /// écrivant le premier.
  static DiagnosisCause _cause(
    Map<Object?, Object?> raw, {
    Set<String>? allowed,
    Set<String>? allowedNatural,
    Map<String, String> byName = const {},
  }) {
    var naturalId = _naturalId(raw['problem'], allowedNatural);
    var problemId = naturalId == null ? _problemId(raw['problem'], allowed) : null;
    if (naturalId == null && problemId == null) {
      // Dernier recours : le nom exact d'une entrée soumise, sans son
      // numéro. La forme du numéro dit de quelle base il vient.
      final trouve = _problemByName(raw['title'], byName);
      if (trouve != null && trouve.startsWith('N')) {
        naturalId = trouve;
      } else {
        problemId = trouve;
      }
    }
    return DiagnosisCause(
      title: (raw['title'] as String?) ?? '',
      likelihood: Likelihood.parse(raw['likelihood']),
      explanation: (raw['explanation'] as String?) ?? '',
      actions: ((raw['actions'] as List?) ?? const []).whereType<String>().toList(),
      problemId: problemId,
      naturalId: naturalId,
      // Le numéro tranche : ce que la base range parmi les problèmes n'est
      // pas un phénomène naturel, quoi que dise la clé du même nom.
      natural: naturalId != null || (problemId == null && raw['natural'] == true),
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
    // « N01 » n'est pas le problème 001 : les chiffres seuls ne disent pas
    // de quelle base ils viennent.
    if (raw is String && _naturalShape.hasMatch(raw)) return null;
    final digits = RegExp(r'\d+').firstMatch(switch (raw) { num n => '$n', String t => t, _ => '' })?.group(0);
    if (digits == null || digits.length > 3) return null;
    final id = digits.padLeft(3, '0');
    if (id == '000') return null;
    return allowed == null || allowed.contains(id) ? id : null;
  }

  /// Le numéro d'un phénomène naturel rendu, s'il est bien formé et s'il
  /// faisait partie de ceux qu'on a soumis. « N1 », « n01 » et « N01 »
  /// disent la même chose.
  static String? _naturalId(Object? raw, Set<String>? allowed) {
    if (raw is! String) return null;
    final chiffres = _naturalShape.firstMatch(raw)?.group(1);
    if (chiffres == null) return null;
    final id = 'N${chiffres.padLeft(2, '0')}';
    return allowed == null || allowed.contains(id) ? id : null;
  }

  /// La forme d'un numéro de phénomène naturel, telle qu'elle se lit dans
  /// une réponse : un N en tête, puis des chiffres. Ce qui suit ne compte
  /// pas — un modèle recopie parfois « N01 Nectar extrafloral » en entier.
  static final RegExp _naturalShape = RegExp(r'^\s*n[\s.:-]*0*(\d{1,2})\b', caseSensitive: false);

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

  static Map<String, dynamic>? _extractJson(String raw) {
    final text = withoutThinking(raw);
    final start = text.indexOf('{');
    if (start < 0) return null;
    final end = text.lastIndexOf('}');
    if (end > start) {
      try {
        final decoded = jsonDecode(text.substring(start, end + 1));
        if (decoded is Map<String, dynamic>) return decoded;
      } on FormatException {
        // Tronqué, ou du texte après l'accolade : la réparation s'en occupe.
      }
    }
    return _repairJson(text.substring(start));
  }

  /// Le texte d'une réponse sans la réflexion que le modèle y aurait
  /// laissée.
  ///
  /// Le service rend en général la réflexion à part ; il arrive qu'elle
  /// vienne dans le contenu même, entre balises `<think>` — ou après une
  /// ouverture que son gabarit avait déjà écrite, auquel cas il n'en reste
  /// que la fermeture. Le lecteur y trouvait des accolades
  /// avant le JSON, un brouillon de réponse le plus souvent, et prenait le
  /// brouillon pour la réponse. Une réflexion ouverte et jamais close ne
  /// laisse rien à lire : la réponse n'avait pas commencé, et l'appelant la
  /// redemande.
  static String withoutThinking(String text) {
    var out = text.replaceAll(_thinkBlock, '');
    final close = out.lastIndexOf(_thinkClose);
    if (close >= 0) out = out.substring(close + _thinkClose.length);
    final open = out.indexOf(_thinkOpen);
    return open < 0 ? out : out.substring(0, open);
  }

  static const _thinkOpen = '<think>';
  static const _thinkClose = '</think>';
  static final RegExp _thinkBlock = RegExp('$_thinkOpen.*?$_thinkClose', dotAll: true);

  /// Un objet JSON refermé à la main, quand la réponse s'est arrêtée en
  /// chemin.
  ///
  /// Une réponse coupée faute de jetons est la panne la plus fréquente de
  /// l'analyse, et la plus injuste : trois pistes complètes étaient là, la
  /// quatrième s'est arrêtée au milieu d'un mot, et tout était jeté. On
  /// revient donc au dernier endroit où le texte se tenait encore — une
  /// virgule, une accolade, un crochet, une chaîne close — et on referme ce
  /// qui restait ouvert.
  ///
  /// Réparer ne devine rien : on ne garde que ce qui a été écrit, jamais un
  /// champ reconstitué. Une réponse qu'aucune coupure ne sauve rend `null`,
  /// et l'appelant la redemandera.
  static Map<String, dynamic>? _repairJson(String text) {
    final ouverts = <String>[];
    // Les endroits où couper, du plus tardif au plus ancien : la position et
    // ce qui restait ouvert à cet instant.
    final reprises = <(int, List<String>)>[];
    var dansChaine = false;
    var echappe = false;
    for (var i = 0; i < text.length; i++) {
      final ch = text[i];
      if (dansChaine) {
        if (echappe) {
          echappe = false;
        } else if (ch == '\\') {
          echappe = true;
        } else if (ch == '"') {
          dansChaine = false;
          reprises.add((i + 1, [...ouverts]));
        }
        continue;
      }
      switch (ch) {
        case '"':
          dansChaine = true;
        case '{':
          ouverts.add('}');
        case '[':
          ouverts.add(']');
        case '}' || ']':
          if (ouverts.isEmpty) return null;
          ouverts.removeLast();
          reprises.add((i + 1, [...ouverts]));
        case ',':
          // On coupe avant la virgule : ce qui la suit est justement ce qui
          // n'a pas été écrit en entier.
          reprises.add((i, [...ouverts]));
      }
    }
    for (final (fin, restants) in reprises.reversed.take(_repairTries)) {
      try {
        final decoded = jsonDecode(text.substring(0, fin) + restants.reversed.join());
        if (decoded is Map<String, dynamic> && decoded.isNotEmpty) return _withoutCutCause(decoded);
      } on FormatException {
        // Cette coupure-là tombait sur une clé sans sa valeur : on remonte
        // à la précédente.
      }
    }
    return null;
  }

  /// La dernière piste d'une réponse réparée, quand la coupure l'a prise en
  /// cours d'écriture.
  ///
  /// Refermer les accolades sauve ce qui était écrit ; ce qui l'était à
  /// moitié n'est pas sauvé pour autant. Une piste dont il ne reste ni
  /// explication ni geste n'a rien à dire de plus qu'un titre — une carte
  /// vide sous deux cartes pleines. Elle part, et seules les pistes écrites
  /// en entier restent.
  static Map<String, dynamic> _withoutCutCause(Map<String, dynamic> data) {
    final causes = data['causes'];
    if (causes is! List || causes.isEmpty) return data;
    final last = causes.last;
    if (last is! Map) return data;
    final explication = last['explanation'];
    final gestes = last['actions'];
    final rien = (explication is! String || explication.trim().isEmpty) && (gestes is! List || gestes.isEmpty);
    if (rien) causes.removeLast();
    return data;
  }

  /// Combien de coupures on essaie avant de renoncer. Au-delà, ce n'est plus
  /// une réponse tronquée mais une réponse qui n'en était pas une.
  static const _repairTries = 12;
}
