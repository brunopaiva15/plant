/// Météo du jour, simplifiée à ce qui compte pour des plantes.
class DailyWeather {
  const DailyWeather({
    required this.date,
    required this.temperatureNow,
    required this.temperatureMax,
    required this.temperatureMin,
    required this.precipitationMm,
    required this.precipitationProbability,
    required this.condition,
    this.windKph = 0,
    this.humidity = 0,
  });

  final DateTime date;
  final double temperatureNow;
  final double temperatureMax;
  final double temperatureMin;

  /// Cumul de précipitations prévu sur la journée (mm).
  final double precipitationMm;

  /// Probabilité maximale de précipitations (0–100).
  final int precipitationProbability;
  final WeatherCondition condition;

  /// Vent maximal prévu (km/h) et humidité relative moyenne (%). À zéro
  /// quand le service ne les fournit pas.
  final double windKph;
  final int humidity;

  /// Pluie suffisante pour dispenser d'arroser les plantes dehors.
  bool get rainExpected => precipitationMm >= 3 || precipitationProbability >= 70;
}

enum WeatherCondition { clear, partlyCloudy, cloudy, fog, drizzle, rain, snow, thunderstorm, unknown }

/// Un lieu choisi par l'utilisateur pour la météo.
class WeatherPlace {
  const WeatherPlace({required this.name, required this.latitude, required this.longitude});

  final String name;
  final double latitude;
  final double longitude;
}

abstract class WeatherService {
  Future<List<WeatherPlace>> searchPlaces(String query, {String? language});
  Future<DailyWeather> today(WeatherPlace place);

  /// Prévisions jour par jour, aujourd'hui compris.
  Future<List<DailyWeather>> forecast(WeatherPlace place, {int days = 5});
}
