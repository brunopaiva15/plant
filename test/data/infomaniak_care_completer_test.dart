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
);

InfomaniakCareCompleter _completer(http.Client client) =>
    InfomaniakCareCompleter(endpoint: Uri.parse('https://relais.test/ai'), client: client);

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
        'water': 'sensitive',
        'fertilizing_days': 45,
        'repot_every_months': 24,
        'pot': 'snug',
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
      expect(c.water, WaterTolerance.sensitive);
      expect(c.repotEveryMonths, 24);
      expect(c.pot, PotPreference.snug);
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
        'water': 'eau de source',
        'difficulty': 'moyen',
        'pot': 'grand',
        'watering_summer_days': 0,
        'fertilizing_days': 3,
        'repot_every_months': 600,
        'min_temp_c': -80,
        'propagation': ['bouture', 'stemCutting'],
      }));
      final c = InfomaniakCareCompleter.parseResponse(body);
      expect(c.light, isNull);
      expect(c.soil, isNull);
      expect(c.water, isNull);
      expect(c.difficulty, isNull);
      expect(c.pot, isNull);
      expect(c.wateringSummerDays, isNull);
      expect(c.fertilizingDays, isNull);
      expect(c.repotEveryMonths, isNull);
      expect(c.damageBelowC, isNull);
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

    test('l\'eau du catalogue tient tant que l\'IA ne dit rien', () {
      // Le profil générique suppose une plante qui boit l'eau du robinet ;
      // c'est le trou que l'IA peut combler pour une espèce inconnue.
      expect(const CareCompletion().applyTo(_generique).water, WaterTolerance.tolerant);
      expect(const CareCompletion(water: WaterTolerance.strict).applyTo(_generique).water, WaterTolerance.strict);
    });

    test('la floraison et le repos restent au catalogue', () {
      // Une date de floraison inventée se vérifie six mois trop tard, et un
      // bulbe rangé au froid sur un mauvais conseil ne repart pas.
      const curated = CareProfile(
        wateringSummerDays: 7,
        wateringWinterDays: 14,
        light: LightNeed.indirect,
        humidity: HumidityNeed.average,
        difficulty: CareDifficulty.easy,
        soil: SoilKind.standard,
        bloom: Bloom(window: MonthWindow(2, 4)),
        dormancy: DormantRest(window: MonthWindow(6, 9)),
      );
      final p = const CareCompletion(light: LightNeed.fullSun).applyTo(curated);
      expect(p.bloom, same(curated.bloom));
      expect(p.dormancy, same(curated.dormancy));
    });

    test('un autre besoin en humidité emporte la plage en pourcentage', () {
      // Garder « 60 à 80 % » sous « air sec accepté » afficherait deux
      // choses contraires sur la même carte.
      const curated = CareProfile(
        wateringSummerDays: 7,
        wateringWinterDays: 14,
        light: LightNeed.indirect,
        humidity: HumidityNeed.high,
        humidityIdealMin: 65,
        humidityIdealMax: 85,
        difficulty: CareDifficulty.easy,
        soil: SoilKind.standard,
      );
      expect(const CareCompletion(humidity: HumidityNeed.low).applyTo(curated).humidityRange, (30, 50));
      expect(const CareCompletion(light: LightNeed.shade).applyTo(curated).humidityRange, (65, 85));
    });

    test('« pas d\'engrais » n\'est pas « je ne sais pas »', () {
      expect(const CareCompletion(noFertilizer: true).applyTo(_generique).fertilizingDays, isNull);
      expect(const CareCompletion().applyTo(_generique).fertilizingDays, 30);
    });

    test('l\'air qui bouge reste à la fiche : l\'IA ne se prononce pas', () {
      const curated = CareProfile(
        wateringSummerDays: 7,
        wateringWinterDays: 14,
        light: LightNeed.indirect,
        humidity: HumidityNeed.high,
        difficulty: CareDifficulty.demanding,
        soil: SoilKind.standard,
        airflow: AirflowPreference.sheltered,
      );
      expect(const CareCompletion(light: LightNeed.fullSun).applyTo(curated).airflow, AirflowPreference.sheltered);
      expect(const CareCompletion().applyTo(_generique).airflow, isNull,
          reason: 'non renseigné ne devient jamais un avis');
    });
  });

  group('le cache', () {
    test('fait l\'aller-retour, y compris une réponse vide', () {
      const c = CareCompletion(wateringSummerDays: 9, water: WaterTolerance.strict, difficulty: CareDifficulty.demanding, issues: [CommonIssue.spiderMites]);
      final entries = {
        CareCompletionStore.keyOf('Ficus lyrata', 'fr'): c,
        CareCompletionStore.keyOf('Inconnue quelconque', 'fr'): const CareCompletion(),
      };
      final relu = CareCompletionStore.decode(CareCompletionStore.encode(entries));
      expect(relu[CareCompletionStore.keyOf('ficus LYRATA', 'fr')]?.wateringSummerDays, 9);
      expect(relu[CareCompletionStore.keyOf('Ficus lyrata', 'fr')]?.issues, [CommonIssue.spiderMites]);
      expect(relu[CareCompletionStore.keyOf('Ficus lyrata', 'fr')]?.water, WaterTolerance.strict);
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
      expect(messages.first['content'], contains('water: tolerant, sensitive, strict'), reason: 'vocabulaire fermé');
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

    test('sans relais, ne part pas', () {
      expect(InfomaniakCareCompleter(endpoint: Uri.parse('')).isConfigured, isFalse);
      expect(const UnconfiguredCareCompleter().isConfigured, isFalse);
    });
  });
}
