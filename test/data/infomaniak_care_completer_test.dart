import 'dart:convert';

import 'package:flora/data/services/infomaniak_care_completer.dart';
import 'package:flora/domain/care/care_completion.dart';
import 'package:flora/domain/care/care_profile.dart';
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

const _generique = CareProfile(
  wateringSummerDays: 7,
  wateringWinterDays: 14,
  light: LightNeed.indirect,
  humidity: HumidityNeed.average,
  difficulty: CareDifficulty.medium,
  soil: SoilKind.standard,
  fertilizingDays: 30,
  toxicity: Toxicity.unknown,
);

InfomaniakCareCompleter _completer(http.Client client) =>
    InfomaniakCareCompleter(apiKey: 'tok', productId: '12345', model: 'mistralai/Mistral-Small-4-119B-2603', client: client);

void main() {
  group('la lecture de la réponse', () {
    test('retient les chiffres et les mots du vocabulaire', () {
      final body = _completion(jsonEncode({
        'known': true,
        'watering_summer_days': 10,
        'watering_winter_days': 21,
        'light': 'brightIndirect',
        'humidity': 'high',
        'soil': 'draining',
        'fertilizing_days': 45,
        'repot_every_months': 24,
        'min_temp_c': 10,
        'ideal_temp_min_c': 18,
        'ideal_temp_max_c': 26,
        'difficulty': 'easy',
        'propagation': ['stemCutting', 'water'],
        'issues': ['overwatering'],
      }));
      final c = InfomaniakCareCompleter.parseResponse(body);
      expect(c.wateringSummerDays, 10);
      expect(c.wateringWinterDays, 21);
      expect(c.light, LightNeed.brightIndirect);
      expect(c.soil, SoilKind.draining);
      expect(c.repotEveryMonths, 24);
      expect(c.propagation, [Propagation.stemCutting, Propagation.water]);
      expect(c.issues, [CommonIssue.overwatering]);
      expect(c.isEmpty, isFalse);
    });

    test('espèce inconnue, rien à dire', () {
      final c = InfomaniakCareCompleter.parseResponse(_completion(jsonEncode({'known': false})));
      expect(c.isEmpty, isTrue);
    });

    test('écarte les mots hors vocabulaire et les nombres invraisemblables', () {
      final body = _completion(jsonEncode({
        'light': 'plein cagnard',
        'soil': 'terreau',
        'difficulty': 'moyen',
        'watering_summer_days': 0,
        'fertilizing_days': 3,
        'repot_every_months': 600,
        'min_temp_c': -80,
        'propagation': ['bouture', 'stemCutting'],
      }));
      final c = InfomaniakCareCompleter.parseResponse(body);
      expect(c.light, isNull);
      expect(c.soil, isNull);
      expect(c.difficulty, isNull);
      expect(c.wateringSummerDays, isNull);
      expect(c.fertilizingDays, isNull);
      expect(c.repotEveryMonths, isNull);
      expect(c.minTempC, isNull);
      expect(c.propagation, [Propagation.stemCutting]);
    });

    test('une plante ne boit pas plus souvent au repos qu\'en croissance', () {
      final body = _completion(jsonEncode({'watering_summer_days': 14, 'watering_winter_days': 7}));
      final c = InfomaniakCareCompleter.parseResponse(body);
      expect(c.wateringSummerDays, 14);
      expect(c.wateringWinterDays, isNull);
    });

    test('accepte du JSON entouré de balises Markdown', () {
      final body = _completion('Voici :\n```json\n${jsonEncode({'light': 'shade'})}\n```');
      expect(InfomaniakCareCompleter.parseResponse(body).light, LightNeed.shade);
    });

    test('sans JSON lisible, échoue proprement', () {
      expect(() => InfomaniakCareCompleter.parseResponse(_completion('Je ne sais pas.')), throwsA(isA<CareCompletionException>()));
    });
  });

  group('ce qui est reposé sur la fiche', () {
    test('remplace ce qui est su, laisse le reste', () {
      const c = CareCompletion(wateringSummerDays: 10, light: LightNeed.fullSun, repotEveryMonths: 36);
      final p = c.applyTo(_generique);
      expect(p.wateringSummerDays, 10);
      expect(p.wateringWinterDays, _generique.wateringWinterDays, reason: 'non dit, donc inchangé');
      expect(p.light, LightNeed.fullSun);
      expect(p.soil, _generique.soil);
      expect(p.repotEveryMonths, 36);
    });

    test('la toxicité ne vient jamais de l\'IA', () {
      const c = CareCompletion(light: LightNeed.fullSun);
      expect(c.applyTo(_generique).toxicity, Toxicity.unknown);
      const curated = CareProfile(
        wateringSummerDays: 7,
        wateringWinterDays: 14,
        light: LightNeed.indirect,
        humidity: HumidityNeed.average,
        difficulty: CareDifficulty.easy,
        soil: SoilKind.standard,
        toxicity: Toxicity.toxic,
      );
      expect(c.applyTo(curated).toxicity, Toxicity.toxic);
    });

    test('« pas d\'engrais » n\'est pas « je ne sais pas »', () {
      expect(const CareCompletion(noFertilizer: true).applyTo(_generique).fertilizingDays, isNull);
      expect(const CareCompletion().applyTo(_generique).fertilizingDays, 30);
    });
  });

  group('le cache', () {
    test('fait l\'aller-retour, y compris une réponse vide', () {
      const c = CareCompletion(wateringSummerDays: 9, difficulty: CareDifficulty.demanding, issues: [CommonIssue.spiderMites]);
      final entries = {
        CareCompletionStore.keyOf('Ficus lyrata', 'fr'): c,
        CareCompletionStore.keyOf('Inconnue quelconque', 'fr'): const CareCompletion(),
      };
      final relu = CareCompletionStore.decode(CareCompletionStore.encode(entries));
      expect(relu[CareCompletionStore.keyOf('ficus LYRATA', 'fr')]?.wateringSummerDays, 9);
      expect(relu[CareCompletionStore.keyOf('Ficus lyrata', 'fr')]?.issues, [CommonIssue.spiderMites]);
      expect(relu[CareCompletionStore.keyOf('Inconnue quelconque', 'fr')]?.isEmpty, isTrue);
    });

    test('un cache illisible ne casse rien', () {
      expect(CareCompletionStore.decode('pas du json'), isEmpty);
      expect(CareCompletionStore.decode(null), isEmpty);
    });
  });

  group('la requête', () {
    test('n\'envoie que le nom scientifique, et interdit la toxicité', () async {
      late http.Request captured;
      final client = MockClient((req) async {
        captured = req;
        return http.Response(_completion(jsonEncode({'light': 'shade'})), 200);
      });
      await _completer(client).complete(scientificName: 'Aechmea fasciata', language: 'fr');
      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      final messages = body['messages'] as List;
      expect(messages.last['content'], 'Aechmea fasciata');
      expect(messages.first['content'], contains('toxicity'));
      expect(body['temperature'], 0.0);
      expect(jsonEncode(body), isNot(contains('Monstera')), reason: 'rien de la plante de l\'utilisateur');
    });

    test('traduit les codes HTTP en erreurs parlantes', () async {
      for (final (code, expected) in [(401, 'unauthorized'), (429, 'quota'), (500, 'http 500')]) {
        final client = MockClient((_) async => http.Response('', code));
        await expectLater(
          _completer(client).complete(scientificName: 'Aechmea fasciata', language: 'fr'),
          throwsA(predicate((e) => e is CareCompletionException && e.message == expected)),
        );
      }
    });

    test('sans clé, ne part pas', () {
      expect(InfomaniakCareCompleter(apiKey: '', productId: '1', model: 'm').isConfigured, isFalse);
      expect(const UnconfiguredCareCompleter().isConfigured, isFalse);
    });
  });
}
