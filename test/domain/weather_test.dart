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
    final w = OpenMeteoService.parseToday(body);
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

  test('advisor only targets outdoor watering tasks when rain is expected', () {
    final rainy = DailyWeather(date: DateTime(2026, 9, 4), temperatureNow: 20, temperatureMax: 22, temperatureMin: 14, precipitationMm: 8, precipitationProbability: 90, condition: WeatherCondition.rain);
    final tasks = [
      task('Olivier', 'watering', locationId: 'balcon', locationName: 'Balcon'),
      task('Basilic', 'watering', locationId: 'balcon', locationName: 'Balcon'),
      task('Monstera', 'watering', locationId: 'salon', locationName: 'Salon'),
      task('Rosier', 'fertilizing', locationId: 'balcon', locationName: 'Balcon'),
    ];
    final advice = WeatherAdvisor.advise(weather: rainy, dueTasks: tasks, outdoorLocationIds: {'balcon'});
    expect(advice.skipWateringTasks.map((t) => t.summary.plant.name), ['Olivier', 'Basilic']);
    expect(advice.locationNames, ['Balcon']);

    final dry = DailyWeather(date: DateTime(2026, 9, 4), temperatureNow: 28, temperatureMax: 30, temperatureMin: 18, precipitationMm: 0, precipitationProbability: 10, condition: WeatherCondition.clear);
    expect(WeatherAdvisor.advise(weather: dry, dueTasks: tasks, outdoorLocationIds: {'balcon'}).isEmpty, isTrue);
  });
}
