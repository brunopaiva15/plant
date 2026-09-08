import 'dart:convert';
import 'dart:io';

import 'package:flora/data/services/infomaniak_diagnoser.dart';
import 'package:flora/domain/diagnosis/plant_diagnoser.dart';
import 'package:flora/domain/problems/plant_problem.dart';
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

final _ok = jsonEncode({'summary': 'ok', 'urgent': false, 'causes': []});

Future<File> _tmpImage() => File('${Directory.systemTemp.path}/flora-diag-${DateTime.now().microsecondsSinceEpoch}.jpg').writeAsBytes([1, 2, 3]);

InfomaniakDiagnoser _diagnoser(http.Client client) =>
    InfomaniakDiagnoser(apiKey: 'tok', productId: '12345', model: 'mistralai/Mistral-Small-4-119B-2603', client: client);

PlantProblem _probleme(String id, ProblemKind kind, String en, {String fr = 'fr'}) =>
    PlantProblem(id: id, kind: kind, scope: ProblemScope.wide, fr: fr, en: en, it: 'it', de: 'de', hosts: const ['Tracheophyta']);

final _pistes = [
  _probleme('002', ProblemKind.disorder, 'Waterlogging and root oxygen deficiency', fr: 'Excès d\'eau et asphyxie racinaire'),
  _probleme('060', ProblemKind.pest, 'Spider mites', fr: 'Tétranyques'),
  _probleme('126', ProblemKind.disease, 'Powdery mildews', fr: 'Oïdiums'),
];

void main() {
  group('la lecture de la réponse', () {
    test('trie les causes par vraisemblance', () {
      final body = _completion(jsonEncode({
        'summary': 'Feuilles jaunes en bas.',
        'urgent': false,
        'causes': [
          {'title': 'Manque de lumière', 'likelihood': 'possible', 'explanation': '…', 'actions': ['Rapprocher de la fenêtre']},
          {'title': "Excès d'eau", 'likelihood': 'likely', 'explanation': '…', 'actions': ['Laisser sécher', 'Vérifier le drainage']},
        ],
      }));
      final d = InfomaniakDiagnoser.parseResponse(body);
      expect(d.summary, 'Feuilles jaunes en bas.');
      expect(d.causes.map((c) => c.title), ["Excès d'eau", 'Manque de lumière']);
      expect(d.causes.first.likelihood, Likelihood.likely);
      expect(d.causes.first.actions, hasLength(2));
      expect(d.urgent, isFalse);
    });

    test('à vraisemblance égale, l\'ordre du service est conservé', () {
      final body = _completion(jsonEncode({
        'summary': '…',
        'causes': [
          {'title': 'Araignées rouges', 'likelihood': 'possible'},
          {'title': 'Air trop sec', 'likelihood': 'possible'},
          {'title': 'Pourriture', 'likelihood': 'unlikely'},
          {'title': 'Excès d\'eau', 'likelihood': 'likely'},
        ],
      }));
      final d = InfomaniakDiagnoser.parseResponse(body);
      expect(d.causes.map((c) => c.title), ['Excès d\'eau', 'Araignées rouges', 'Air trop sec', 'Pourriture']);
    });

    test('un mot inconnu ou absent vaut « possible »', () {
      final body = _completion(jsonEncode({
        'summary': '…',
        'causes': [
          {'title': 'Sans étiquette'},
          {'title': 'Étiquette fantaisiste', 'likelihood': 'très probable'},
        ],
      }));
      final d = InfomaniakDiagnoser.parseResponse(body);
      expect(d.causes.map((c) => c.likelihood), everyElement(Likelihood.possible));
    });

    test('le numéro de la base est retenu, quelle que soit sa forme', () {
      final body = _completion(jsonEncode({
        'summary': '…',
        'causes': [
          {'title': 'Excès d\'eau', 'problem': '002'},
          {'title': 'Tétranyques', 'problem': 60},
          {'title': 'Oïdium', 'problem': 'id 126'},
          {'title': 'Autre chose'},
          {'title': 'Numéro fantaisiste', 'problem': '9999'},
        ],
      }));
      final d = InfomaniakDiagnoser.parseResponse(body, allowed: const {'002', '060', '126'});
      expect(d.causes.map((c) => c.problemId), ['002', '060', '126', null, null]);
    });

    group('le filet de rattrapage par le nom', () {
      final noms = InfomaniakDiagnoser.namesOf([
        _probleme('027', ProblemKind.disorder, 'Magnesium deficiency', fr: 'Carence en magnésium'),
        _probleme('035', ProblemKind.disorder, 'Household-product phytotoxicity', fr: 'Phytotoxicité des produits ménagers'),
      ], 'fr');

      test('un nom exact rattrape un numéro oublié', () {
        // Le cas vu en vrai : le service décrit exactement une piste de la
        // liste, avec ses mots à elle, et n'en donne pas le numéro.
        final body = _completion(jsonEncode({
          'summary': '…',
          'causes': [
            {'title': 'Phytotoxicité des produits ménagers', 'likelihood': 'possible'},
          ],
        }));
        expect(InfomaniakDiagnoser.parseResponse(body, allowed: const {'027', '035'}, byName: noms).causes.single.problemId, '035');
      });

      test('la casse, les accents et la ponctuation ne comptent pas', () {
        final body = _completion(jsonEncode({
          'summary': '…',
          'causes': [
            {'title': 'CARENCE EN MAGNESIUM.'},
          ],
        }));
        expect(InfomaniakDiagnoser.parseResponse(body, allowed: const {'027'}, byName: noms).causes.single.problemId, '027');
      });

      test('un titre approchant ne rattrape rien', () {
        // « Sécheresse passagère ou coup de soleil léger » recouvre deux
        // pistes sans être ni l'une ni l'autre. Poser un nom de travers sur
        // une carte serait pire que de n'en poser aucun.
        final body = _completion(jsonEncode({
          'summary': '…',
          'causes': [
            {'title': 'Légère carence en magnésium'},
            {'title': 'Brûlure chimique légère'},
          ],
        }));
        final d = InfomaniakDiagnoser.parseResponse(body, allowed: const {'027', '035'}, byName: noms);
        expect(d.causes.map((c) => c.problemId), [null, null]);
      });

      test('un numéro explicite prime sur le nom', () {
        final body = _completion(jsonEncode({
          'summary': '…',
          'causes': [
            {'title': 'Carence en magnésium', 'problem': '035'},
          ],
        }));
        expect(InfomaniakDiagnoser.parseResponse(body, allowed: const {'027', '035'}, byName: noms).causes.single.problemId, '035');
      });

      test('deux pistes de même nom normalisé sont écartées des deux côtés', () {
        final ambigus = InfomaniakDiagnoser.namesOf([
          _probleme('001', ProblemKind.disorder, 'Water deficit', fr: 'Manque d\'eau'),
          _probleme('014', ProblemKind.disorder, 'Wind desiccation', fr: 'Manque d\'eau !'),
        ], 'fr');
        expect(ambigus, isEmpty, reason: 'trancher au hasard serait pire que ne rien faire');
      });

      test('sans liste soumise, le filet reste inerte', () {
        final body = _completion(jsonEncode({
          'summary': '…',
          'causes': [
            {'title': 'Carence en magnésium'},
          ],
        }));
        expect(InfomaniakDiagnoser.parseResponse(body).causes.single.problemId, isNull);
      });
    });

    test('une cause sans titre survit si elle porte un numéro', () {
      final body = _completion(jsonEncode({
        'summary': '…',
        'causes': [
          {'problem': '002'},
          {'explanation': 'sans rien pour la nommer'},
        ],
      }));
      final d = InfomaniakDiagnoser.parseResponse(body, allowed: const {'002'});
      expect(d.causes.map((c) => c.problemId), ['002']);
    });

    test('un modèle qui répond encore en chiffres est rangé dans un cran', () {
      final body = _completion(jsonEncode({
        'summary': '…',
        'causes': [
          {'title': 'Haute', 'likelihood': 0.8},
          {'title': 'Moyenne', 'likelihood': 0.4},
          {'title': 'Basse', 'likelihood': 0.1},
        ],
      }));
      final d = InfomaniakDiagnoser.parseResponse(body);
      expect(d.causes.map((c) => c.likelihood), [Likelihood.likely, Likelihood.possible, Likelihood.unlikely]);
    });

    test('accepte du JSON entouré de balises Markdown', () {
      final body = _completion('Voici :\n```json\n${jsonEncode({'summary': 'Cochenilles.', 'urgent': true, 'causes': []})}\n```');
      final d = InfomaniakDiagnoser.parseResponse(body);
      expect(d.summary, 'Cochenilles.');
      expect(d.urgent, isTrue);
    });

    test('accepte un contenu en fragments', () {
      final body = _completion([
        {'type': 'text', 'text': _ok}
      ]);
      expect(InfomaniakDiagnoser.parseResponse(body).summary, 'ok');
    });

    test('sans JSON lisible, échoue proprement', () {
      expect(() => InfomaniakDiagnoser.parseResponse(_completion('Je ne vois pas de plante.')), throwsA(isA<DiagnosisException>()));
    });

    test('un filtrage de contenu est signalé comme refus', () {
      expect(() => InfomaniakDiagnoser.parseResponse(_completion('', finish: 'content_filter')),
          throwsA(predicate((e) => e is DiagnosisException && e.message == 'refusal')));
    });
  });

  group('la requête', () {
    test('vise le produit, porte le jeton, envoie la photo en data URL et demande du JSON', () async {
      late http.Request captured;
      final client = MockClient((req) async {
        captured = req;
        return http.Response(_completion(_ok), 200);
      });
      final tmp = await _tmpImage();
      final result = await _diagnoser(client).diagnose(images: [tmp], language: 'fr', plantName: 'Monstera', symptoms: 'taches brunes');
      await tmp.delete();

      expect(result.summary, 'ok');
      expect(captured.url.toString(), 'https://api.infomaniak.com/2/ai/12345/openai/v1/chat/completions');
      expect(captured.headers['authorization'], 'Bearer tok');
      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['model'], 'mistralai/Mistral-Small-4-119B-2603');
      expect(body['response_format'], {'type': 'json_object'});
      final messages = body['messages'] as List;
      expect(messages.first['role'], 'system');
      expect(messages.first['content'], contains('"fr"'));
      final parts = messages.last['content'] as List;
      expect(parts.first['type'], 'image_url');
      expect(parts.first['image_url']['url'], startsWith('data:image/jpeg;base64,'));
      expect(parts.last['text'], contains('Monstera'));
      expect(parts.last['text'], contains('taches brunes'));
      expect(messages.first['content'], contains('"likely", "possible", "unlikely"'));
    });

    test('la consigne impose le numéro et interdit de fondre deux pistes', () async {
      final consigne = InfomaniakDiagnoser.systemPrompt('fr');
      expect(consigne, contains('decide "problem" first'));
      expect(consigne, contains('Always include the key'));
      expect(consigne, contains('give them as two causes'));
      // Le numéro se décide avant le titre : l'ordre des clés compte pour un
      // modèle qui écrit de gauche à droite.
      expect(consigne.indexOf('"problem" (string or null)'), lessThan(consigne.indexOf('"title" (string)')));
    });

    test('la base locale part comme liste de pistes, groupée par nature', () async {
      late http.Request captured;
      final client = MockClient((req) async {
        captured = req;
        return http.Response(_completion(_ok), 200);
      });
      final tmp = await _tmpImage();
      await _diagnoser(client).diagnose(
        images: [tmp],
        language: 'fr',
        species: 'Monstera deliciosa',
        candidates: _pistes,
        frequentIds: const {'060'},
      );
      await tmp.delete();
      final parts = ((jsonDecode(captured.body) as Map<String, dynamic>)['messages'] as List).last['content'] as List;
      final text = parts.last['text'] as String;
      // Les noms partent dans la langue de la réponse : c'est celle dans
      // laquelle le modèle écrira son titre.
      expect(text, contains('Disorders: 002 Excès d\'eau et asphyxie racinaire.'));
      expect(text, contains('Pests: 060 Tétranyques.'));
      expect(text, contains('Diseases: 126 Oïdiums.'));
      expect(text, contains('especially common on this species: 060'));
      // Une liste de pistes, pas une liste de réponses.
      expect(text, isNot(contains('Other:')));
    });

    test('sans base chargée, la demande part comme avant', () async {
      late http.Request captured;
      final client = MockClient((req) async {
        captured = req;
        return http.Response(_completion(_ok), 200);
      });
      final tmp = await _tmpImage();
      await _diagnoser(client).diagnose(images: [tmp], language: 'fr', species: 'Inconnue quelconque');
      await tmp.delete();
      final parts = ((jsonDecode(captured.body) as Map<String, dynamic>)['messages'] as List).last['content'] as List;
      expect(parts.last['text'], isNot(contains('Known problems')));
    });

    test('en allemand, la liste part en allemand', () async {
      late http.Request captured;
      final client = MockClient((req) async {
        captured = req;
        return http.Response(_completion(_ok), 200);
      });
      final tmp = await _tmpImage();
      await _diagnoser(client).diagnose(
        images: [tmp],
        language: 'de',
        candidates: [_probleme('060', ProblemKind.pest, 'Spider mites', fr: 'Tétranyques')],
      );
      await tmp.delete();
      final parts = ((jsonDecode(captured.body) as Map<String, dynamic>)['messages'] as List).last['content'] as List;
      expect(parts.last['text'], contains('060 de'), reason: 'le nom allemand du gabarit');
    });

    test('un numéro qu\'on n\'a pas soumis est écarté', () async {
      final client = MockClient((_) async => http.Response(
            _completion(jsonEncode({
              'summary': '…',
              'causes': [
                {'title': 'Tétranyques', 'problem': '060'},
                {'title': 'Feu bactérien', 'problem': '182'},
              ],
            })),
            200,
          ));
      final tmp = await _tmpImage();
      final d = await _diagnoser(client).diagnose(images: [tmp], language: 'fr', candidates: _pistes);
      await tmp.delete();
      expect(d.causes.map((c) => c.problemId), ['060', null]);
    });

    test('si le format JSON contraint est refusé, renvoie la demande sans lui', () async {
      final bodies = <Map<String, dynamic>>[];
      final client = MockClient((req) async {
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        bodies.add(body);
        return body.containsKey('response_format') ? http.Response('{"error":"response_format"}', 400) : http.Response(_completion(_ok), 200);
      });
      final tmp = await _tmpImage();
      final result = await _diagnoser(client).diagnose(images: [tmp], language: 'de');
      await tmp.delete();
      expect(result.summary, 'ok');
      expect(bodies, hasLength(2));
      expect(bodies.last.containsKey('response_format'), isFalse);
    });

    test('traduit les codes HTTP en erreurs parlantes', () async {
      for (final (code, expected) in [(401, 'unauthorized'), (403, 'unauthorized'), (429, 'quota'), (500, 'http 500')]) {
        final client = MockClient((_) async => http.Response('', code));
        final tmp = await _tmpImage();
        await expectLater(
          _diagnoser(client).diagnose(images: [tmp], language: 'fr'),
          throwsA(predicate((e) => e is DiagnosisException && e.message == expected)),
        );
        await tmp.delete();
      }
    });

    test('sans clé ou sans produit, ne part pas', () {
      expect(InfomaniakDiagnoser(apiKey: '', productId: '1', model: 'm').isConfigured, isFalse);
      expect(InfomaniakDiagnoser(apiKey: 'k', productId: '', model: 'm').isConfigured, isFalse);
    });
  });
}
