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
}
