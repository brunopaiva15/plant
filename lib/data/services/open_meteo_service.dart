import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/weather/weather.dart';

/// Open-Meteo : gratuit, sans clé, respectueux de la vie privée (pas de compte).
class OpenMeteoService implements WeatherService {
  OpenMeteoService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<List<WeatherPlace>> searchPlaces(String query, {String? language}) async {
    if (query.trim().length < 2) return const [];
    final uri = Uri.https('geocoding-api.open-meteo.com', '/v1/search', {'name': query.trim(), 'count': '6', 'language': language ?? 'en', 'format': 'json'});
    final res = await _client.get(uri).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) return const [];
    return parsePlaces(res.body);
  }

  @override
  Future<DailyWeather> today(WeatherPlace place) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': place.latitude.toString(),
      'longitude': place.longitude.toString(),
      'current': 'temperature_2m,weather_code',
      'daily': 'temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_probability_max,weather_code',
      'timezone': 'auto',
      'forecast_days': '1',
    });
    final res = await _client.get(uri).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) throw Exception('open-meteo ${res.statusCode}');
    return parseToday(res.body);
  }

  static List<WeatherPlace> parsePlaces(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final results = (json['results'] as List?) ?? const [];
    return [
      for (final r in results.cast<Map<String, dynamic>>())
        WeatherPlace(
          name: [r['name'], r['admin1'], r['country']].whereType<String>().where((s) => s.isNotEmpty).toSet().join(', '),
          latitude: (r['latitude'] as num).toDouble(),
          longitude: (r['longitude'] as num).toDouble(),
        ),
    ];
  }

  static DailyWeather parseToday(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final current = json['current'] as Map<String, dynamic>? ?? const {};
    final daily = json['daily'] as Map<String, dynamic>? ?? const {};
    double first(String key, [double fallback = 0]) => ((daily[key] as List?)?.firstOrNull as num?)?.toDouble() ?? fallback;
    return DailyWeather(
      date: DateTime.tryParse(((daily['time'] as List?)?.firstOrNull as String?) ?? '') ?? DateTime.now(),
      temperatureNow: (current['temperature_2m'] as num?)?.toDouble() ?? first('temperature_2m_max'),
      temperatureMax: first('temperature_2m_max'),
      temperatureMin: first('temperature_2m_min'),
      precipitationMm: first('precipitation_sum'),
      precipitationProbability: first('precipitation_probability_max').round(),
      condition: conditionFromCode((current['weather_code'] as num?)?.toInt() ?? first('weather_code').toInt()),
    );
  }

  /// Codes WMO utilisés par Open-Meteo.
  static WeatherCondition conditionFromCode(int code) => switch (code) {
        0 => WeatherCondition.clear,
        1 || 2 => WeatherCondition.partlyCloudy,
        3 => WeatherCondition.cloudy,
        45 || 48 => WeatherCondition.fog,
        51 || 53 || 55 || 56 || 57 => WeatherCondition.drizzle,
        61 || 63 || 65 || 66 || 67 || 80 || 81 || 82 => WeatherCondition.rain,
        71 || 73 || 75 || 77 || 85 || 86 => WeatherCondition.snow,
        95 || 96 || 99 => WeatherCondition.thunderstorm,
        _ => WeatherCondition.unknown,
      };
}
