import 'dart:convert';
import 'dart:io';

import 'package:flora/data/services/infomaniak_diagnoser.dart';
import 'package:flora/domain/diagnosis/plant_diagnoser.dart';
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

void main() {
  group('la lecture de la réponse', () {
    test('trie les causes par vraisemblance', () {
      final body = _completion(jsonEncode({
        'summary': 'Feuilles jaunes en bas.',
        'urgent': false,
        'causes': [
          {'title': 'Manque de lumière', 'likelihood': 0.3, 'explanation': '…', 'actions': ['Rapprocher de la fenêtre']},
          {'title': "Excès d'eau", 'likelihood': 0.7, 'explanation': '…', 'actions': ['Laisser sécher', 'Vérifier le drainage']},
        ],
      }));
      final d = InfomaniakDiagnoser.parseResponse(body);
      expect(d.summary, 'Feuilles jaunes en bas.');
      expect(d.causes.map((c) => c.title), ["Excès d'eau", 'Manque de lumière']);
      expect(d.causes.first.actions, hasLength(2));
      expect(d.urgent, isFalse);
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
