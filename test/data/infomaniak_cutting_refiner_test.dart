import 'dart:convert';

import 'package:flora/data/services/infomaniak_cutting_refiner.dart';
import 'package:flora/domain/cuttings/cutting_guide.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Le guide de bouturage précisé par l'IA : ce qui part, et ce qu'on garde
/// de ce qui revient. Six phrases exactement, ou rien — le générique vaut
/// mieux qu'un guide à trous.

String _completion(Object content, {String finish = 'stop'}) => jsonEncode({
      'choices': [
        {
          'finish_reason': finish,
          'message': {'role': 'assistant', 'content': content},
        }
      ],
    });

const _six = [
  'Une tige avec une racine aérienne au nœud reprend plus vite.',
  'Coupe nette sous le nœud, lame propre.',
  'Une feuille en haut suffit. Le nœud reste nu.',
  'Dans l\'eau, à la lumière, sans soleil direct.',
  'Racines en trois semaines, eau changée chaque semaine.',
  'En pot dès trois centimètres de racines, dans un terreau aéré.',
];

InfomaniakCuttingRefiner _refiner(http.Client client) =>
    InfomaniakCuttingRefiner(apiKey: 'tok', productId: '12345', model: 'mistralai/Mistral-Small-4-119B-2603', client: client);

void main() {
  group('la requête', () {
    test("n'emporte que le nom scientifique, et demande six étapes dans la langue", () {
      final body = InfomaniakCuttingRefiner.buildRequest(
          model: 'm', scientificName: 'Epipremnum aureum', language: 'fr', constrainJson: true);
      final messages = body['messages'] as List;
      expect((messages.last as Map)['content'], 'Epipremnum aureum');
      final system = (messages.first as Map)['content'] as String;
      expect(system, contains('"fr"'));
      expect(system, contains('exactly six strings'));
      expect(system, contains('no exclamation marks, no semicolons'));
      expect(body['response_format'], {'type': 'json_object'});
      expect(body['temperature'], lessThan(0.5));
    });

    test('sans clé, rien ne part', () {
      final refiner = InfomaniakCuttingRefiner(apiKey: '', productId: '1', model: 'm');
      expect(refiner.isConfigured, isFalse);
      expect(() => refiner.refine(scientificName: 'Monstera deliciosa', language: 'fr'), throwsA(isA<CuttingGuideException>()));
    });
  });

  group('la lecture de la réponse', () {
    test('garde six textes et la méthode', () {
      final r = InfomaniakCuttingRefiner.parseResponse(_completion(jsonEncode({'known': true, 'method': 'water', 'steps': _six})));
      expect(r.isEmpty, isFalse);
      expect(r.steps, _six);
      expect(r.method, 'water');
      expect(r.of(CuttingStep.roots), _six[4]);
    });

    test("une espèce inconnue laisse le générique", () {
      final r = InfomaniakCuttingRefiner.parseResponse(_completion('{"known": false}'));
      expect(r.isEmpty, isTrue);
    });

    test("cinq étapes, ou une vide, c'est rien", () {
      expect(InfomaniakCuttingRefiner.parseResponse(_completion(jsonEncode({'known': true, 'steps': _six.sublist(1)}))).isEmpty, isTrue);
      final trou = [..._six]..[2] = '   ';
      expect(InfomaniakCuttingRefiner.parseResponse(_completion(jsonEncode({'known': true, 'steps': trou}))).isEmpty, isTrue);
      expect(InfomaniakCuttingRefiner.parseResponse(_completion(jsonEncode({'known': true, 'steps': 'non'}))).isEmpty, isTrue);
    });

    test('une méthode hors vocabulaire tombe, les étapes restent', () {
      final r = InfomaniakCuttingRefiner.parseResponse(_completion(jsonEncode({'known': true, 'method': 'magie', 'steps': _six})));
      expect(r.method, isNull);
      expect(r.steps.length, 6);
    });

    test('le ton est tenu : ni exclamation ni point-virgule, une majuscule par phrase, un point pour finir', () {
      expect(InfomaniakCuttingRefiner.sanitize('Coupez  sous le nœud !  bravo !'), 'Coupez sous le nœud. Bravo.');
      expect(InfomaniakCuttingRefiner.sanitize('Sans fin !!!'), 'Sans fin.');
      expect(InfomaniakCuttingRefiner.sanitize('le nœud sous l\'eau ; les feuilles au-dessus'), 'Le nœud sous l\'eau. Les feuilles au-dessus.');
      expect(InfomaniakCuttingRefiner.sanitize('à la lumière. sans soleil direct.'), 'À la lumière. Sans soleil direct.');
      expect(InfomaniakCuttingRefiner.sanitize('Racines en 3 semaines… '), 'Racines en 3 semaines…');
    });

    test('un texte interminable est coupé à une phrase', () {
      final long = '${'Une phrase courte. ' * 30}Fin.';
      final court = InfomaniakCuttingRefiner.sanitize(long);
      expect(court.length, lessThanOrEqualTo(InfomaniakCuttingRefiner.maxStepLength));
      expect(court, endsWith('.'));
    });

    test('un refus du modèle est une erreur, pas un guide vide', () {
      expect(() => InfomaniakCuttingRefiner.parseResponse(_completion('', finish: 'content_filter')), throwsA(isA<CuttingGuideException>()));
    });

    test('du JSON noyé dans du texte est retrouvé', () {
      final r = InfomaniakCuttingRefiner.parseResponse(_completion('Voici :\n```json\n${jsonEncode({'known': true, 'steps': _six})}\n```'));
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
      final r = await _refiner(client).refine(scientificName: 'Epipremnum aureum', language: 'fr');
      expect(appels, 2);
      expect(r.steps, _six);
    });

    test('dit le quota et le refus de clé', () async {
      final quota = MockClient((_) async => http.Response('', 429));
      expect(() => _refiner(quota).refine(scientificName: 'x', language: 'fr'),
          throwsA(predicate((e) => e is CuttingGuideException && e.message == 'quota')));
      final cle = MockClient((_) async => http.Response('', 401));
      expect(() => _refiner(cle).refine(scientificName: 'x', language: 'fr'),
          throwsA(predicate((e) => e is CuttingGuideException && e.message == 'unauthorized')));
    });
  });
}
