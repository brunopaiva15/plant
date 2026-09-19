import 'dart:convert';
import 'dart:io';

import 'package:flora/data/services/infomaniak_identification_arbiter.dart';
import 'package:flora/domain/identification/identification_arbiter.dart';
import 'package:flora/domain/identification/plant_identifier.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Le service annonce son JSON en UTF-8 ; sans cet en-tête, `http.Response`
/// encode le corps en latin1 et refuse le moindre « … ».
http.Response _reponse(String corps, int code) =>
    http.Response(corps, code, headers: const {'content-type': 'application/json; charset=utf-8'});

String _completion(Object content) => jsonEncode({
      'choices': [
        {
          'finish_reason': 'stop',
          'message': {'role': 'assistant', 'content': content},
        }
      ],
    });

String _avis({Object? candidate = 2, Object? plant = true, String trait = 'fenestrations'}) =>
    _completion(jsonEncode({'candidate': candidate, 'plant': plant, 'trait': trait}));

Future<File> _tmpImage() =>
    File('${Directory.systemTemp.path}/flora-arb-${DateTime.now().microsecondsSinceEpoch}.jpg').writeAsBytes([1, 2, 3]);

InfomaniakIdentificationArbiter _arbitre(http.Client client) => InfomaniakIdentificationArbiter(
      apiKey: 'tok',
      productId: '12345',
      model: 'mistralai/Mistral-Small-4-119B-2603',
      client: client,
    );

IdentificationCandidate _c(String name, double score) => IdentificationCandidate(
      scientificName: name,
      score: score,
      source: IdentificationSource.local,
    );

final _candidates = [
  _c('Monstera deliciosa', 0.44),
  _c('Monstera adansonii', 0.39),
  _c('Rhaphidophora tetrasperma', 0.12),
];

const _noms = ['Monstera deliciosa', 'Monstera adansonii', 'Rhaphidophora tetrasperma'];

void main() {
  group('la question posée', () {
    test('numérote les candidates et ne donne aucun score', () {
      final prompt = InfomaniakIdentificationArbiter.userPrompt(_noms);
      expect(prompt, contains('1. Monstera deliciosa'));
      expect(prompt, contains('2. Monstera adansonii'));
      // Les scores ancreraient la réponse sur l'ordre qu'on fait arbitrer.
      expect(prompt, isNot(contains('0.44')));
      expect(prompt, isNot(contains('44')));
    });

    test('la consigne ferme l\'ensemble', () {
      final consigne = InfomaniakIdentificationArbiter.systemPrompt('fr');
      expect(consigne, contains('the list is closed'));
      expect(consigne, contains('"candidate"'));
      // La langue du caractère décisif est celle de l'application.
      expect(consigne, contains('"fr"'));
    });

    test('le corps demande du JSON, sans température ni bavardage', () {
      final body = InfomaniakIdentificationArbiter.buildRequest(
        model: 'm',
        parts: const [],
        language: 'fr',
        constrainJson: true,
      );
      expect(body['model'], 'm');
      expect(body['temperature'], 0.0);
      expect(body['response_format'], {'type': 'json_object'});
      expect(body['max_tokens'], 200);
    });

    test('et sans `response_format` quand le service l\'a refusé', () {
      final body = InfomaniakIdentificationArbiter.buildRequest(
        model: 'm',
        parts: const [],
        language: 'fr',
        constrainJson: false,
      );
      expect(body.containsKey('response_format'), isFalse);
    });
  });

  group('la lecture de la réponse', () {
    test('un numéro désigne le nom soumis à ce rang', () {
      final avis = InfomaniakIdentificationArbiter.parseResponse(_avis(candidate: 2), names: _noms);
      expect(avis?.outcome, ArbitrationOutcome.picked);
      expect(avis?.scientificName, 'Monstera adansonii');
      expect(avis?.trait, 'fenestrations');
    });

    test('zéro veut dire « aucune de ces candidates »', () {
      final avis = InfomaniakIdentificationArbiter.parseResponse(_avis(candidate: 0, trait: ''), names: _noms);
      expect(avis?.outcome, ArbitrationOutcome.none);
      expect(avis?.scientificName, isNull);
    });

    test('un numéro hors liste vaut zéro, jamais un nom inventé', () {
      final avis = InfomaniakIdentificationArbiter.parseResponse(_avis(candidate: 9), names: _noms);
      expect(avis?.outcome, ArbitrationOutcome.none);
    });

    test('« ce n\'est pas une plante » passe avant le numéro', () {
      final avis = InfomaniakIdentificationArbiter.parseResponse(
        _avis(candidate: 1, plant: false),
        names: _noms,
      );
      expect(avis?.outcome, ArbitrationOutcome.notPlant);
    });

    test('un numéro écrit en toutes lettres du JSON se lit quand même', () {
      final avis = InfomaniakIdentificationArbiter.parseResponse(_avis(candidate: '2'), names: _noms);
      expect(avis?.scientificName, 'Monstera adansonii');
    });

    test('du JSON emballé dans du Markdown se lit aussi', () {
      final body = _completion('```json\n{"candidate": 3, "plant": true, "trait": "feuille percée"}\n```');
      final avis = InfomaniakIdentificationArbiter.parseResponse(body, names: _noms);
      expect(avis?.scientificName, 'Rhaphidophora tetrasperma');
      expect(avis?.trait, 'feuille percée');
    });

    test('une réponse illisible ne rend aucun avis', () {
      expect(InfomaniakIdentificationArbiter.parseResponse(_completion('je ne sais pas'), names: _noms), isNull);
      expect(InfomaniakIdentificationArbiter.parseResponse('pas du JSON', names: _noms), isNull);
      expect(
        InfomaniakIdentificationArbiter.parseResponse(_completion(jsonEncode({'trait': 'x'})), names: _noms),
        isNull,
      );
    });

    test('un caractère décisif bavard ne s\'affiche pas', () {
      // La ligne n'a de place que pour un caractère ; une phrase entière
      // trahit une consigne mal suivie, et le nom reste utile sans elle.
      final long = 'La plante présente des feuilles fenestrées typiques ainsi qu\'un port grimpant et des racines aériennes visibles';
      final avis = InfomaniakIdentificationArbiter.parseResponse(_avis(trait: long), names: _noms);
      expect(avis?.outcome, ArbitrationOutcome.picked);
      expect(avis?.trait, isNull);
    });
  });

  group('l\'appel', () {
    test('envoie la photo et les noms, et rend la candidate désignée', () async {
      Map<String, Object?>? envoye;
      final client = MockClient((r) async {
        envoye = jsonDecode(r.body) as Map<String, Object?>;
        return _reponse(_avis(candidate: 2), 200);
      });
      final tmp = await _tmpImage();
      final avis = await _arbitre(client).arbitrate(images: [tmp], candidates: _candidates, language: 'fr');
      expect(avis?.scientificName, 'Monstera adansonii');

      final parts = ((envoye!['messages'] as List).last as Map)['content'] as List;
      expect(parts.first, containsPair('type', 'image_url'));
      expect(((parts.first as Map)['image_url'] as Map)['url'], startsWith('data:image/jpeg;base64,'));
      expect((parts.last as Map)['text'], contains('2. Monstera adansonii'));
      await tmp.delete();
    });

    test('ne soumet que cinq noms au plus', () async {
      String? texte;
      final client = MockClient((r) async {
        final parts = ((jsonDecode(r.body) as Map)['messages'] as List).last as Map;
        texte = ((parts['content'] as List).last as Map)['text'] as String;
        return _reponse(_avis(candidate: 1), 200);
      });
      final tmp = await _tmpImage();
      await _arbitre(client).arbitrate(
        images: [tmp],
        candidates: [for (var i = 0; i < 8; i++) _c('Espece numero$i', 0.2)],
        language: 'fr',
      );
      expect(texte, contains('5. Espece numero4'));
      expect(texte, isNot(contains('6.')));
      await tmp.delete();
    });

    test('redemande sans `response_format` quand le service le refuse', () async {
      final corps = <Map<String, Object?>>[];
      final client = MockClient((r) async {
        corps.add(jsonDecode(r.body) as Map<String, Object?>);
        return corps.length == 1 ? _reponse('{"error":"unsupported"}', 400) : _reponse(_avis(candidate: 1), 200);
      });
      final tmp = await _tmpImage();
      final avis = await _arbitre(client).arbitrate(images: [tmp], candidates: _candidates, language: 'fr');
      expect(avis?.scientificName, 'Monstera deliciosa');
      expect(corps.first.containsKey('response_format'), isTrue);
      expect(corps.last.containsKey('response_format'), isFalse);
      await tmp.delete();
    });

    test('un quota ou une panne ne rendent aucun avis, et ne lèvent pas', () async {
      for (final code in [401, 429, 500]) {
        final client = MockClient((r) async => _reponse('{"error":"non"}', code));
        final tmp = await _tmpImage();
        expect(
          await _arbitre(client).arbitrate(images: [tmp], candidates: _candidates, language: 'fr'),
          isNull,
          reason: 'HTTP $code',
        );
        await tmp.delete();
      }
    });

    test('une panne réseau non plus', () async {
      final client = MockClient((r) async => throw const SocketException('coupé'));
      final tmp = await _tmpImage();
      expect(await _arbitre(client).arbitrate(images: [tmp], candidates: _candidates, language: 'fr'), isNull);
      await tmp.delete();
    });

    test('rien ne part sans clé, sans photo, ni sur une seule candidate', () async {
      var appels = 0;
      final client = MockClient((r) async {
        appels++;
        return _reponse(_avis(), 200);
      });
      final tmp = await _tmpImage();
      final sansCle = InfomaniakIdentificationArbiter(apiKey: '', productId: '', model: 'm', client: client);
      expect(sansCle.isConfigured, isFalse);
      expect(await sansCle.arbitrate(images: [tmp], candidates: _candidates, language: 'fr'), isNull);
      expect(await _arbitre(client).arbitrate(images: const [], candidates: _candidates, language: 'fr'), isNull);
      expect(
        await _arbitre(client).arbitrate(images: [tmp], candidates: [_candidates.first], language: 'fr'),
        isNull,
      );
      expect(appels, 0);
      await tmp.delete();
    });
  });
}
