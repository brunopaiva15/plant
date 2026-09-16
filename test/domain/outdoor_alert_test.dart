import 'package:flora/domain/care/care_guide.dart';
import 'package:flora/domain/care/care_profile.dart';
import 'package:flora/domain/weather/outdoor_alert.dart';
import 'package:flora/domain/weather/weather.dart';
import 'package:flutter_test/flutter_test.dart';

final now = DateTime(2026, 3, 10, 8);

DailyWeather day(int offset, {double min = 12, double max = 20}) => DailyWeather(
      date: now.add(Duration(days: offset)),
      temperatureNow: max,
      temperatureMax: max,
      temperatureMin: min,
      precipitationMm: 0,
      precipitationProbability: 0,
      condition: WeatherCondition.clear,
    );

CareProfile profile({int? minTemp, int? idealMax}) => CareProfile(
      wateringSummerDays: 7,
      wateringWinterDays: 12,
      light: LightNeed.someSun,
      humidity: HumidityNeed.average,
      difficulty: CareDifficulty.easy,
      soil: SoilKind.standard,
      damageBelowC: minTemp,
      idealTempMaxC: idealMax,
    );

OutdoorPlant plant(String name, {int? minTemp, int? idealMax}) =>
    OutdoorPlant(name: name, profile: profile(minTemp: minTemp, idealMax: idealMax));

List<OutdoorAlert> alerts(List<DailyWeather> forecast, List<OutdoorPlant> plants) =>
    OutdoorAlertAdvisor.alerts(forecast: forecast, plants: plants, now: now);

void main() {
  group('le gel', () {
    test('prévient quand la nuit descend sous le seuil, pour qui ne tient pas', () {
      final found = alerts([day(0), day(1, min: -3), day(2)], [plant('Citronnier', minTemp: 5), plant('Buis', minTemp: -20)]);
      expect(found, hasLength(1));
      expect(found.single.kind, OutdoorAlertKind.frost);
      expect(found.single.temperatureC, -3);
      expect(found.single.day.day, 11);
      expect(found.single.plantNames, ['Citronnier'], reason: 'le buis tient −20°');
      expect(found.single.daysFrom(now), 1);
    });

    test('se tait quand toutes les plantes tiennent', () {
      expect(alerts([day(0, min: -4)], [plant('Buis', minTemp: -20)]), isEmpty);
    });

    test('retient la nuit la plus froide de la fenêtre, pas la première', () {
      final found = alerts([day(0, min: 1), day(1, min: -6), day(2, min: 0)], [plant('Olivier', minTemp: 5)]);
      expect(found.single.temperatureC, -6);
    });

    test('ne regarde pas au-delà de trois jours', () {
      expect(alerts([day(0), day(1), day(2), day(5, min: -8)], [plant('Olivier', minTemp: 5)]), isEmpty);
    });

    test('sans minimum connu, seul le gel franc concerne la plante', () {
      expect(alerts([day(0, min: 1.5)], [plant('Inconnue')]), isEmpty);
      expect(alerts([day(0, min: -1)], [plant('Inconnue')]), hasLength(1));
    });

    test('un seuil hérité de la famille n\'est pas nommé comme la plante', () {
      final found = alerts([day(0, min: -2)], [
        OutdoorPlant(name: 'Monstera', profile: profile(minTemp: 5), match: CareMatch.family, matchedOn: 'Araceae'),
      ]);
      expect(found.single.plantNames, isEmpty);
      expect(found.single.familyNames, ['Araceae']);
      expect(found.single.plantCount, 1);
    });

    test('les seuils d\'espèce et les familles se mêlent sans se confondre', () {
      final found = alerts([day(0, min: -2)], [
        plant('Citronnier', minTemp: 5),
        OutdoorPlant(name: 'Monstera', profile: profile(minTemp: 5), match: CareMatch.family, matchedOn: 'Araceae'),
        OutdoorPlant(name: 'Ficus', profile: profile(minTemp: 5), match: CareMatch.family, matchedOn: 'Moraceae'),
        OutdoorPlant(name: 'Aloe', profile: profile(minTemp: 5), match: CareMatch.family, matchedOn: 'Araceae'),
      ]);
      expect(found.single.plantNames, ['Citronnier']);
      expect(found.single.familyNames, ['Araceae', 'Moraceae'], reason: 'une famille ne se répète pas');
      expect(found.single.plantCount, 4);
    });

    test('un seuil de catégorie ne nomme personne', () {
      // Une catégorie n'est pas une famille : faute de nom de groupe, l'alerte
      // se tait plutôt que d'inventer un fait d'espèce.
      final found = alerts([day(0, min: -2)], [
        OutdoorPlant(name: 'Inconnue', profile: profile(minTemp: 5), match: CareMatch.category, matchedOn: 'tree'),
      ]);
      expect(found, isEmpty);
    });
  });

  group('la chaleur', () {
    test('prévient au-dessus du seuil, pour qui a une plage idéale plus basse', () {
      final found = alerts([day(0, max: 35)], [plant('Laitue', idealMax: 22), plant('Cactus', idealMax: 40)]);
      expect(found.single.kind, OutdoorAlertKind.heat);
      expect(found.single.temperatureC, 35);
      expect(found.single.plantNames, ['Laitue']);
    });

    test('sous le seuil, rien, même pour une plante fragile', () {
      expect(alerts([day(0, max: 28)], [plant('Laitue', idealMax: 18)]), isEmpty);
    });
  });

  test('les deux avertissements peuvent tomber la même semaine', () {
    final found = alerts([day(0, min: -2, max: 10), day(1, min: 8, max: 34)], [plant('Olivier', minTemp: 5, idealMax: 30)]);
    expect(found.map((a) => a.kind), [OutdoorAlertKind.frost, OutdoorAlertKind.heat]);
  });

  test('quatre noms au plus, mais le compte reste juste', () {
    final many = [for (var i = 0; i < 7; i++) plant('P$i', minTemp: 5)];
    final found = alerts([day(0, min: -2)], many);
    expect(found.single.plantNames, hasLength(OutdoorAlertAdvisor.maxNames));
    expect(found.single.plantCount, 7);
  });

  test('sans plante dehors, rien à dire', () {
    expect(alerts([day(0, min: -10, max: 40)], const []), isEmpty);
  });
}
