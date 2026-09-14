import 'package:flora/data/services/open_meteo_service.dart';
import 'package:flora/domain/models/models.dart';
import 'package:flora/domain/weather/weather.dart';
import 'package:flora/domain/weather/weather_advisor.dart';
import 'package:flutter_test/flutter_test.dart';

CareTask task(String name, String type, {String? locationId, String? locationName}) {
  final now = DateTime(2026, 9, 4);
  return CareTask(
    summary: PlantSummary(
      plant: Plant(id: name, gardenId: 'g', name: name, locationId: locationId, status: PlantStatus.active, health: PlantHealth.healthy, isFavorite: false, createdAt: now, updatedAt: now),
      locationName: locationName,
    ),
    schedule: CareSchedule(id: '$name-$type', plantId: name, typeKey: type, strategy: CareStrategy.fixed, intervalDays: 7, enabled: true, nextDueAt: now, createdAt: now, updatedAt: now),
  );
}

void main() {
  test('parses Open-Meteo forecast into today weather', () {
    const body = '''{"current":{"temperature_2m":21.4,"weather_code":61},
      "daily":{"time":["2026-09-04"],"temperature_2m_max":[24.1],"temperature_2m_min":[15.2],"precipitation_sum":[6.5],"precipitation_probability_max":[85],"weather_code":[61]}}''';
    final w = OpenMeteoService.parseForecast(body).first;
    expect(w.temperatureNow, 21.4);
    expect(w.precipitationMm, 6.5);
    expect(w.precipitationProbability, 85);
    expect(w.condition, WeatherCondition.rain);
    expect(w.rainExpected, isTrue);
  });

  test('parses geocoding results with a readable name', () {
    const body = '{"results":[{"name":"Lausanne","latitude":46.5,"longitude":6.6,"admin1":"Vaud","country":"Suisse"}]}';
    final places = OpenMeteoService.parsePlaces(body);
    expect(places.single.name, 'Lausanne, Vaud, Suisse');
    expect(places.single.latitude, 46.5);
  });

  group('le conseil de la pluie', () {
    final rainy = DailyWeather(
        date: DateTime(2026, 9, 4), temperatureNow: 20, temperatureMax: 22, temperatureMin: 14, precipitationMm: 8, precipitationProbability: 90, condition: WeatherCondition.rain);
    final dry = DailyWeather(
        date: DateTime(2026, 9, 4), temperatureNow: 28, temperatureMax: 30, temperatureMin: 18, precipitationMm: 0, precipitationProbability: 10, condition: WeatherCondition.clear);
    final tasks = [
      task('Olivier', 'watering', locationId: 'balcon', locationName: 'Balcon'),
      task('Basilic', 'watering', locationId: 'balcon', locationName: 'Balcon'),
      task('Monstera', 'watering', locationId: 'salon', locationName: 'Salon'),
      task('Rosier', 'fertilizing', locationId: 'balcon', locationName: 'Balcon'),
    ];

    test('ne vise que les arrosages du dehors, et seulement s\'il pleut', () {
      final advice = WeatherAdvisor.advise(weather: rainy, dueTasks: tasks, outdoorLocationIds: {'balcon'});
      expect(advice.tasks.map((t) => t.summary.plant.name), ['Olivier', 'Basilic']);
      expect(advice.locationNames, ['Balcon']);
      expect(advice.kind, RainAdviceKind.expected);
      expect(WeatherAdvisor.advise(weather: dry, dueTasks: tasks, outdoorLocationIds: {'balcon'}).isEmpty, isTrue);
    });

    test('la pluie tombée vaut un arrosage, celle qu\'on annonce un report', () {
      final fallen = WeatherAdvisor.advise(weather: dry, dueTasks: tasks, outdoorLocationIds: {'balcon'}, rainFallenMm: 9);
      expect(fallen.kind, RainAdviceKind.fallen);
      expect(fallen.rainMm, 9);
      expect(fallen.tasks, hasLength(2));
    });

    test('une averse trop courte ne vaut pas un arrosage', () {
      final advice = WeatherAdvisor.advise(weather: dry, dueTasks: tasks, outdoorLocationIds: {'balcon'}, rainFallenMm: 2);
      expect(advice.isEmpty, isTrue, reason: 'sous 5 mm, et sans pluie annoncée, il n\'y a rien à dire');
    });

    test('tombée ou annoncée le même jour, c\'est la pluie tombée qui compte', () {
      final advice = WeatherAdvisor.advise(weather: rainy, dueTasks: tasks, outdoorLocationIds: {'balcon'}, rainFallenMm: 9);
      expect(advice.kind, RainAdviceKind.fallen);
    });

    test('le cumul tombé ignore les jours à venir', () {
      DailyWeather at(int offset, double mm) => DailyWeather(
          date: DateTime(2026, 9, 4).add(Duration(days: offset)),
          temperatureNow: 18,
          temperatureMax: 20,
          temperatureMin: 12,
          precipitationMm: mm,
          precipitationProbability: 60,
          condition: WeatherCondition.rain);
      final window = [at(-2, 3), at(-1, 2), at(0, 1.5), at(1, 40)];
      expect(WeatherAdvisor.rainFallen(window, DateTime(2026, 9, 4, 9)), 6.5);
    });
  });

  group('prévisions Open-Meteo', () {
    const body = '''
{
  "current": {"temperature_2m": 21.4, "weather_code": 61},
  "daily": {
    "time": ["2026-09-04", "2026-09-05", "2026-09-06"],
    "temperature_2m_max": [24.0, 26.5, 19.0],
    "temperature_2m_min": [14.0, 15.5, 12.0],
    "precipitation_sum": [8.2, 0.0, 1.5],
    "precipitation_probability_max": [90, 5, 40],
    "weather_code": [61, 0, 3],
    "wind_speed_10m_max": [18.0, 9.0, 25.0],
    "relative_humidity_2m_mean": [82, 55, 70]
  }
}''';

    test('un jour par entrée de la liste', () {
      final days = OpenMeteoService.parseForecast(body);
      expect(days, hasLength(3));
      expect(days.map((d) => d.date.day), [4, 5, 6]);
    });

    test('le premier jour porte la température du moment', () {
      final days = OpenMeteoService.parseForecast(body);
      expect(days.first.temperatureNow, 21.4);
      expect(days[1].temperatureNow, 26.5, reason: 'les jours suivants prennent leur maximum');
    });

    test('vent et humidité sont lus quand ils existent', () {
      final day = OpenMeteoService.parseForecast(body).first;
      expect(day.windKph, 18.0);
      expect(day.humidity, 82);
    });

    test('le premier jour porte sa propre pluie', () {
      expect(OpenMeteoService.parseForecast(body).first.precipitationMm, 8.2);
    });

    test('une réponse sans bloc journalier ne jette pas', () {
      final days = OpenMeteoService.parseForecast('{"current": {"temperature_2m": 12.0, "weather_code": 0}}');
      expect(days, hasLength(1));
      expect(days.single.temperatureNow, 12.0);
      expect(days.single.condition, WeatherCondition.clear);
    });

    test('une journée plus courte que les autres ne fait pas planter', () {
      const partial = '''
{"daily": {"time": ["2026-09-04", "2026-09-05"], "temperature_2m_max": [24.0]}}''';
      final days = OpenMeteoService.parseForecast(partial);
      expect(days, hasLength(2));
      expect(days[1].temperatureMax, 0, reason: 'valeur manquante = zéro, pas une exception');
    });
  });

  group('les archives climatiques', () {
    test('retiennent l\'extrême de chaque année, puis les moyennent', () {
      const body = '''
{"daily": {
  "time": ["2023-01-05", "2023-07-20", "2024-01-08", "2024-08-01", "2025-02-01", "2025-07-15"],
  "temperature_2m_min": [-10.0, 14.0, -6.0, 16.0, -8.0, 15.0],
  "temperature_2m_max": [2.0, 34.0, 4.0, 30.0, 3.0, 32.0]
}}''';
      final climate = OpenMeteoService.parseClimate(body)!;
      expect(climate.years, 3);
      expect(climate.winterLowC, -8);
      expect(climate.summerHighC, 32);
    });

    test('une archive vide ne donne pas de climat', () {
      expect(OpenMeteoService.parseClimate('{"daily": {"time": []}}'), isNull);
    });
  });

  group('les jours passés', () {
    test('le temps présent se pose sur aujourd\'hui, pas sur la première ligne', () {
      final today = DateTime.now();
      String iso(int offset) {
        final d = today.add(Duration(days: offset));
        return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      }

      final body = '''
{"current": {"temperature_2m": 21.4, "weather_code": 0},
 "daily": {
   "time": ["${iso(-2)}", "${iso(-1)}", "${iso(0)}", "${iso(1)}"],
   "temperature_2m_max": [10.0, 11.0, 12.0, 13.0],
   "temperature_2m_min": [1.0, 2.0, 3.0, 4.0],
   "precipitation_sum": [5.0, 0.0, 1.0, 0.0],
   "precipitation_probability_max": [90, 0, 20, 0],
   "weather_code": [61, 0, 3, 0]
 }}''';
      final days = OpenMeteoService.parseForecast(body);
      expect(days, hasLength(4));
      expect(days[2].temperatureNow, 21.4, reason: 'la ligne datée d\'aujourd\'hui');
      expect(days[0].temperatureNow, 10.0, reason: 'les autres prennent leur maximum');
    });
  });
}
