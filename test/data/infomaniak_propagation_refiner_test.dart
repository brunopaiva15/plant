import 'dart:convert';

import 'package:flora/data/services/infomaniak_propagation_refiner.dart';
import 'package:flora/domain/cuttings/propagation_guide.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Le guide de multiplication précisé par l'IA : ce qui part, et ce qu'on
/// garde de ce qui revient.
///
/// Le modèle reçoit un geste déjà choisi et la liste de ses étapes ; il
/// n'écrit que du texte. Un texte par étape, ou rien — le guide local vaut
/// mieux qu'un guide à trous.

String _completion(Object content, {String finish = 'stop'}) => jsonEncode({
      'choices': [
        {
          'finish_reason': finish,
          'message': {'role': 'assistant', 'content': content},
        }
      ],
    });

const _vine = PropagationGuideKind.stemNodeVine;
const _division = PropagationGuideKind.division;
final _vineSteps = propagationStepIds[_vine]!;
final _divisionSteps = propagationStepIds[_division]!;

const _six = [
  'Une tige avec une racine aérienne au nœud reprend plus vite.',
  'Coupe nette sous le nœud, lame propre.',
  'Une feuille en haut suffit. Le nœud reste nu.',
  'Dans l\'eau, à la lumière, sans soleil direct.',
  'Racines en trois semaines, eau changée chaque semaine.',
  'En pot dès trois centimètres de racines, dans un terreau aéré.',
];

InfomaniakPropagationRefiner _refiner(http.Client client) => InfomaniakPropagationRefiner(
    apiKey: 'tok', productId: '12345', model: 'Qwen/Qwen3.5-397B-A17B-FP8', client: client);

void main() {
  group('la requête', () {
    test("emporte l'espèce, la méthode, le geste et ses étapes, et rien d'autre", () {
      final body = InfomaniakPropagationRefiner.buildRequest(
          model: 'm', scientificName: 'Epipremnum aureum', language: 'fr', kind: _vine, stepIds: _vineSteps, constrainJson: true);
      final messages = body['messages'] as List;
      final brief = jsonDecode((messages.last as Map)['content'] as String) as Map<String, dynamic>;
      expect(brief, {
        'species': 'Epipremnum aureum',
        'method': 'stemCutting',
        'guideKind': 'stemNodeVine',
        'steps': _vineSteps,
      });
      final system = (messages.first as Map)['content'] as String;
      expect(system, contains('"fr"'));
      expect(system, contains('The steps are fixed'));
      expect(system, contains('no exclamation marks, no semicolons'));
      expect(body['response_format'], {'type': 'json_object'});
      expect(body['temperature'], lessThan(0.5));
    });

    test('une division dit la division, pas la bouture', () {
      final body = InfomaniakPropagationRefiner.buildRequest(
          model: 'm', scientificName: 'Spathiphyllum wallisii', language: 'en', kind: _division, stepIds: _divisionSteps, constrainJson: false);
      final brief = jsonDecode(((body['messages'] as List).last as Map)['content'] as String) as Map<String, dynamic>;
      expect(brief['method'], 'division');
      expect(brief['guideKind'], 'division');
      expect(body.containsKey('response_format'), isFalse);
    });

    test('chaque archétype est décrit au modèle, étape par étape', () {
      for (final kind in PropagationGuideKind.values) {
        final briefs = InfomaniakPropagationRefiner.stepBriefs[kind];
        expect(briefs, isNotNull, reason: '${kind.name} : le modèle ne sait pas ce qu\'il précise');
        expect(briefs, hasLength(propagationStepIds[kind]!.length));
        for (final (i, id) in propagationStepIds[kind]!.indexed) {
          expect(briefs![i], startsWith('$id:'), reason: '${kind.name} : les descriptions ne suivent plus les étapes');
        }
      }
    });

    test('sans clé, rien ne part', () {
      final refiner = InfomaniakPropagationRefiner(apiKey: '', productId: '1', model: 'm');
      expect(refiner.isConfigured, isFalse);
      expect(() => refiner.refine(scientificName: 'Monstera deliciosa', language: 'fr', kind: _vine, stepIds: _vineSteps),
          throwsA(isA<PropagationGuideException>()));
    });
  });

  group('la lecture de la réponse', () {
    test('garde un texte par étape', () {
      final r = InfomaniakPropagationRefiner.parseResponse(_completion(jsonEncode({'known': true, 'steps': _six})), 6);
      expect(r.isEmpty, isFalse);
      expect(r.steps, _six);
      expect(r.at(4), _six[4]);
      expect(r.at(6), isNull);
    });

    test('une espèce inconnue laisse le guide local', () {
      expect(InfomaniakPropagationRefiner.parseResponse(_completion('{"known": false}'), 6).isEmpty, isTrue);
    });

    test("un compte qui ne tombe pas juste, ou une étape vide, c'est rien", () {
      expect(InfomaniakPropagationRefiner.parseResponse(_completion(jsonEncode({'known': true, 'steps': _six.sublist(1)})), 6).isEmpty, isTrue);
      expect(InfomaniakPropagationRefiner.parseResponse(_completion(jsonEncode({'known': true, 'steps': _six})), 5).isEmpty, isTrue);
      final trou = [..._six]..[2] = '   ';
      expect(InfomaniakPropagationRefiner.parseResponse(_completion(jsonEncode({'known': true, 'steps': trou})), 6).isEmpty, isTrue);
      expect(InfomaniakPropagationRefiner.parseResponse(_completion(jsonEncode({'known': true, 'steps': 'non'})), 6).isEmpty, isTrue);
    });

    test('le ton est tenu : ni exclamation ni point-virgule, une majuscule par phrase, un point pour finir', () {
      expect(InfomaniakPropagationRefiner.sanitize('Coupez  sous le nœud !  bravo !'), 'Coupez sous le nœud. Bravo.');
      expect(InfomaniakPropagationRefiner.sanitize('Sans fin !!!'), 'Sans fin.');
      expect(InfomaniakPropagationRefiner.sanitize('le nœud sous l\'eau ; les feuilles au-dessus'),
          'Le nœud sous l\'eau. Les feuilles au-dessus.');
      expect(InfomaniakPropagationRefiner.sanitize('à la lumière. sans soleil direct.'), 'À la lumière. Sans soleil direct.');
      expect(InfomaniakPropagationRefiner.sanitize('Racines en 3 semaines… '), 'Racines en 3 semaines…');
    });

    test('un texte interminable est coupé à une phrase', () {
      final long = '${'Une phrase courte. ' * 30}Fin.';
      final court = InfomaniakPropagationRefiner.sanitize(long);
      expect(court.length, lessThanOrEqualTo(InfomaniakPropagationRefiner.maxStepLength));
      expect(court, endsWith('.'));
    });

    test('un refus du modèle est une erreur, pas un guide vide', () {
      expect(() => InfomaniakPropagationRefiner.parseResponse(_completion('', finish: 'content_filter'), 6),
          throwsA(isA<PropagationGuideException>()));
    });

    test('du JSON noyé dans du texte est retrouvé', () {
      final r = InfomaniakPropagationRefiner.parseResponse(
          _completion('Voici :\n```json\n${jsonEncode({'known': true, 'steps': _six})}\n```'), 6);
      expect(r.steps, _six);
    });
  });

  group('le service', () {
    test('repart sans format contraint quand il est refusé', () async {
      var appels = 0;
      final client = MockClient((request) async {
        appels++;
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        if (body.containsKey('response_format')) return http.Response('bad request', 400);
        return http.Response.bytes(utf8.encode(_completion(jsonEncode({'known': true, 'steps': _six}))), 200);
      });
      final r = await _refiner(client).refine(scientificName: 'Epipremnum aureum', language: 'fr', kind: _vine, stepIds: _vineSteps);
      expect(appels, 2);
      expect(r.steps, _six);
    });

    test('dit le quota et le refus de clé', () async {
      final quota = MockClient((_) async => http.Response('', 429));
      expect(() => _refiner(quota).refine(scientificName: 'x', language: 'fr', kind: _vine, stepIds: _vineSteps),
          throwsA(predicate((e) => e is PropagationGuideException && e.message == 'quota')));
      final cle = MockClient((_) async => http.Response('', 401));
      expect(() => _refiner(cle).refine(scientificName: 'x', language: 'fr', kind: _vine, stepIds: _vineSteps),
          throwsA(predicate((e) => e is PropagationGuideException && e.message == 'unauthorized')));
    });
  });
}
