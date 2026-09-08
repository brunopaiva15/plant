import 'dart:convert';

import 'package:flora/data/services/infomaniak_advisor.dart';
import 'package:flora/domain/species/plant_advisor.dart';
import 'package:flora/domain/species/plant_finder.dart';
import 'package:flora/domain/species/species_info.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

String _completion(Object content, {String finish = 'stop'}) => jsonEncode({
      'choices': [
        {
          'finish_reason': finish,
          'message': {'role': 'assistant', 'content': content},
        }
      ],
    });

String _suggestions(List<Map<String, String>> items) => jsonEncode({'suggestions': items});

const _criteria = FinderCriteria(
  spot: FinderSpot.darkRoom,
  effort: FinderEffort.forgiving,
  safeOnly: true,
  categories: {SpeciesCategory.indoor},
  note: 'salle de bain sans fenêtre',
);

InfomaniakAdvisor _advisor(http.Client client) =>
    InfomaniakAdvisor(apiKey: 'tok', productId: '12345', model: 'mistralai/Mistral-Small-4-119B-2603', client: client);

void main() {
  group('la lecture de la réponse', () {
    test('retient nom, nom commun et raison', () {
      final body = _completion(_suggestions([
        {'scientific_name': 'Aspidistra elatior', 'common_name': 'Aspidistra', 'reason': 'Supporte l\'ombre et les oublis.'},
      ]));
      final results = InfomaniakAdvisor.parseResponse(body);
      expect(results, hasLength(1));
      expect(results.first.scientificName, 'Aspidistra elatior');
      expect(results.first.commonName, 'Aspidistra');
      expect(results.first.reason, 'Supporte l\'ombre et les oublis.');
    });

    test('écarte les doublons et les entrées sans nom', () {
      final body = _completion(_suggestions([
        {'scientific_name': 'Aspidistra elatior', 'common_name': '', 'reason': 'a'},
        {'scientific_name': 'aspidistra elatior', 'common_name': 'Aspidistra', 'reason': 'b'},
        {'scientific_name': '  ', 'common_name': 'Rien', 'reason': 'c'},
      ]));
      final results = InfomaniakAdvisor.parseResponse(body);
      expect(results, hasLength(1));
      expect(results.first.commonName, isNull);
    });

    test('ne rend jamais plus que le maximum annoncé', () {
      final body = _completion(_suggestions([
        for (var i = 0; i < 8; i++) {'scientific_name': 'Genus species$i', 'common_name': 'n$i', 'reason': 'r'},
      ]));
      expect(InfomaniakAdvisor.parseResponse(body), hasLength(InfomaniakAdvisor.maxSuggestions));
    });

    test('accepte du JSON entouré de balises Markdown', () {
      final body = _completion('Voici :\n```json\n${_suggestions([
            {'scientific_name': 'Chamaedorea elegans', 'common_name': 'Palmier nain', 'reason': 'r'}
          ])}\n```');
      expect(InfomaniakAdvisor.parseResponse(body).first.scientificName, 'Chamaedorea elegans');
    });

    test('sans JSON lisible, échoue proprement', () {
      expect(() => InfomaniakAdvisor.parseResponse(_completion('Je ne sais pas.')), throwsA(isA<AdvisorException>()));
    });

    test('un filtrage de contenu est signalé comme refus', () {
      expect(() => InfomaniakAdvisor.parseResponse(_completion('', finish: 'content_filter')),
          throwsA(predicate((e) => e is AdvisorException && e.message == 'refusal')));
    });
  });

  group('la requête', () {
    test('porte les critères, la langue et les espèces déjà proposées', () async {
      late http.Request captured;
      final client = MockClient((req) async {
        captured = req;
        return http.Response(_completion(_suggestions([
          {'scientific_name': 'Aspidistra elatior', 'common_name': 'Aspidistra', 'reason': 'r'}
        ])), 200);
      });

      final results = await _advisor(client).suggest(criteria: _criteria, language: 'fr', exclude: ['Zamioculcas zamiifolia']);
      expect(results, hasLength(1));
      expect(captured.url.toString(), 'https://api.infomaniak.com/2/ai/12345/openai/v1/chat/completions');
      expect(captured.headers['authorization'], 'Bearer tok');
      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['response_format'], {'type': 'json_object'});
      final messages = body['messages'] as List;
      expect(messages.first['content'], contains('"fr"'));
      expect(messages.last['content'], contains('dark indoor corner'));
      expect(messages.last['content'], contains('non-toxic'));
      expect(messages.last['content'], contains('salle de bain sans fenêtre'));
      expect(messages.last['content'], contains('Zamioculcas zamiifolia'));
    });

    test('si le format JSON contraint est refusé, renvoie la demande sans lui', () async {
      final bodies = <Map<String, dynamic>>[];
      final client = MockClient((req) async {
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        bodies.add(body);
        return body.containsKey('response_format')
            ? http.Response('{"error":"response_format"}', 400)
            : http.Response(_completion(_suggestions([
                {'scientific_name': 'Hoya carnosa', 'common_name': 'Hoya', 'reason': 'r'}
              ])), 200);
      });
      final results = await _advisor(client).suggest(criteria: _criteria, language: 'de');
      expect(results.first.scientificName, 'Hoya carnosa');
      expect(bodies, hasLength(2));
      expect(bodies.last.containsKey('response_format'), isFalse);
    });

    test('traduit les codes HTTP en erreurs parlantes', () async {
      for (final (code, expected) in [(401, 'unauthorized'), (403, 'unauthorized'), (429, 'quota'), (500, 'http 500')]) {
        final client = MockClient((_) async => http.Response('', code));
        await expectLater(
          _advisor(client).suggest(criteria: _criteria, language: 'fr'),
          throwsA(predicate((e) => e is AdvisorException && e.message == expected)),
        );
      }
    });

    test('sans clé ou sans produit, ne part pas', () {
      expect(InfomaniakAdvisor(apiKey: '', productId: '1', model: 'm').isConfigured, isFalse);
      expect(InfomaniakAdvisor(apiKey: 'k', productId: '', model: 'm').isConfigured, isFalse);
      expect(const UnconfiguredAdvisor().isConfigured, isFalse);
    });
  });
}
