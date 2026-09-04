import 'dart:convert';
import 'dart:io';

import 'package:flora/data/services/anthropic_diagnoser.dart';
import 'package:flora/domain/diagnosis/plant_diagnoser.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('parses a structured response, sorted by likelihood', () {
    final body = jsonEncode({
      'stop_reason': 'end_turn',
      'content': [
        {
          'type': 'text',
          'text': jsonEncode({
            'summary': 'Feuilles jaunes en bas.',
            'urgent': false,
            'causes': [
              {'title': 'Manque de lumière', 'likelihood': 0.3, 'explanation': '…', 'actions': ['Rapprocher de la fenêtre']},
              {'title': 'Excès d\'eau', 'likelihood': 0.7, 'explanation': '…', 'actions': ['Laisser sécher', 'Vérifier le drainage']},
            ],
          }),
        }
      ],
    });
    final d = AnthropicDiagnoser.parseResponse(body);
    expect(d.summary, 'Feuilles jaunes en bas.');
    expect(d.causes.map((c) => c.title), ['Excès d\'eau', 'Manque de lumière']);
    expect(d.causes.first.actions, hasLength(2));
    expect(d.urgent, isFalse);
  });

  test('a refusal stop reason is surfaced as an exception', () {
    expect(() => AnthropicDiagnoser.parseResponse(jsonEncode({'stop_reason': 'refusal', 'content': []})), throwsA(isA<DiagnosisException>()));
  });

  test('sends the expected request: model, headers, image block, schema and fallbacks', () async {
    late http.Request captured;
    final client = MockClient((req) async {
      captured = req;
      return http.Response(
        jsonEncode({
          'stop_reason': 'end_turn',
          'content': [
            {'type': 'text', 'text': jsonEncode({'summary': 'ok', 'urgent': false, 'causes': []})}
          ],
        }),
        200,
      );
    });
    final tmp = await File('${Directory.systemTemp.path}/flora-diag-${DateTime.now().microsecondsSinceEpoch}.jpg').writeAsBytes([1, 2, 3]);
    final diagnoser = AnthropicDiagnoser('sk-test', client: client);
    final result = await diagnoser.diagnose(images: [tmp], language: 'fr', plantName: 'Monstera', symptoms: 'taches brunes');
    await tmp.delete();

    expect(result.summary, 'ok');
    expect(captured.url.toString(), 'https://api.anthropic.com/v1/messages');
    expect(captured.headers['x-api-key'], 'sk-test');
    expect(captured.headers['anthropic-version'], '2023-06-01');
    expect(captured.headers['anthropic-beta'], 'server-side-fallback-2026-07-01');
    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(body['model'], 'claude-opus-5');
    expect(body['fallbacks'], 'default');
    expect(body.containsKey('thinking'), isFalse);
    expect(body['output_config']['format']['type'], 'json_schema');
    final content = (body['messages'] as List).first['content'] as List;
    expect(content.first['type'], 'image');
    expect(content.first['source']['media_type'], 'image/jpeg');
    expect(content.last['text'], contains('taches brunes'));
    expect(body['system'], contains('"fr"'));
  });

  test('unconfigured key is reported', () {
    expect(AnthropicDiagnoser('').isConfigured, isFalse);
  });
}
