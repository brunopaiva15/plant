import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/weather/region_climate.dart';
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
  Future<List<DailyWeather>> forecast(WeatherPlace place, {int days = 5, int pastDays = 0}) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': place.latitude.toString(),
      'longitude': place.longitude.toString(),
      'current': 'temperature_2m,weather_code',
      'daily': 'temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_probability_max,'
          'weather_code,wind_speed_10m_max,relative_humidity_2m_mean',
      'timezone': 'auto',
      'forecast_days': days.clamp(1, 16).toString(),
      if (pastDays > 0) 'past_days': pastDays.clamp(1, 92).toString(),
    });
    final res = await _client.get(uri).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) throw Exception('open-meteo ${res.statusCode}');
    return parseForecast(res.body);
  }

  /// Les extrêmes des trois dernières années révolues, par l'API d'archives
  /// — gratuite et sans clé comme les prévisions. Trois ans lissent l'hiver
  /// doux comme la vague de froid ; la série s'arrête à la fin de l'année
  /// dernière, une année en cours n'ayant pas encore eu son hiver.
  static const int climateYears = 3;

  @override
  Future<RegionClimate?> climate(WeatherPlace place) async {
    final lastYear = DateTime.now().year - 1;
    final uri = Uri.https('archive-api.open-meteo.com', '/v1/archive', {
      'latitude': place.latitude.toString(),
      'longitude': place.longitude.toString(),
      'start_date': '${lastYear - climateYears + 1}-01-01',
      'end_date': '$lastYear-12-31',
      'daily': 'temperature_2m_max,temperature_2m_min',
      'timezone': 'auto',
    });
    final res = await _client.get(uri).timeout(const Duration(seconds: 30));
    if (res.statusCode != 200) throw Exception('open-meteo ${res.statusCode}');
    return parseClimate(res.body);
  }

  /// La nuit la plus froide et le jour le plus chaud de chaque année de la
  /// série, moyennés. Une année à trous — l'archive en a près des pôles —
  /// compte comme les autres : son extrême reste l'extrême observé.
  static RegionClimate? parseClimate(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final daily = json['daily'] as Map<String, dynamic>? ?? const {};
    final times = (daily['time'] as List?) ?? const [];
    final mins = (daily['temperature_2m_min'] as List?) ?? const [];
    final maxs = (daily['temperature_2m_max'] as List?) ?? const [];
    final byYear = <int, ({double low, double high})>{};
    for (var i = 0; i < times.length; i++) {
      final year = DateTime.tryParse(times[i] as String? ?? '')?.year;
      if (year == null) continue;
      final low = i < mins.length ? (mins[i] as num?)?.toDouble() : null;
      final high = i < maxs.length ? (maxs[i] as num?)?.toDouble() : null;
      if (low == null && high == null) continue;
      final seen = byYear[year];
      byYear[year] = (
        low: seen == null ? (low ?? high!) : (low == null ? seen.low : (low < seen.low ? low : seen.low)),
        high: seen == null ? (high ?? low!) : (high == null ? seen.high : (high > seen.high ? high : seen.high)),
      );
    }
    return RegionClimate.fromYearlyExtremes(byYear);
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

  /// Une entrée par jour. La température « maintenant » n'existe que pour
  /// aujourd'hui : les autres jours prennent leur maximum.
  ///
  /// Avec des jours passés, aujourd'hui n'est plus la première ligne — d'où
  /// la recherche de sa date plutôt qu'un indice zéro qui daterait le temps
  /// présent d'avant-hier.
  static List<DailyWeather> parseForecast(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final current = json['current'] as Map<String, dynamic>? ?? const {};
    final daily = json['daily'] as Map<String, dynamic>? ?? const {};
    final times = (daily['time'] as List?) ?? const [];
    double at(String key, int i, [double fallback = 0]) {
      final list = daily[key] as List?;
      if (list == null || i >= list.length) return fallback;
      return (list[i] as num?)?.toDouble() ?? fallback;
    }

    if (times.isEmpty) {
      // Réponse sans bloc journalier : on retourne au moins le temps présent.
      return [
        DailyWeather(
          date: DateTime.now(),
          temperatureNow: (current['temperature_2m'] as num?)?.toDouble() ?? 0,
          temperatureMax: 0,
          temperatureMin: 0,
          precipitationMm: 0,
          precipitationProbability: 0,
          condition: conditionFromCode((current['weather_code'] as num?)?.toInt() ?? -1),
        ),
      ];
    }

    final dates = [for (var i = 0; i < times.length; i++) DateTime.tryParse(times[i] as String? ?? '')];
    final now = DateTime.now();
    // Aucune ligne datée d'aujourd'hui — une série d'archives, un fuseau qui
    // a basculé : le temps présent revient à la première, comme avant les
    // jours passés. Les prévisions en contiennent toujours une.
    final today = dates.indexWhere((d) => d != null && d.year == now.year && d.month == now.month && d.day == now.day);
    final currentAt = today >= 0 ? today : 0;

    return [
      for (var i = 0; i < times.length; i++)
        DailyWeather(
          date: dates[i] ?? DateTime.now().add(Duration(days: i)),
          temperatureNow: i == currentAt ? (current['temperature_2m'] as num?)?.toDouble() ?? at('temperature_2m_max', i) : at('temperature_2m_max', i),
          temperatureMax: at('temperature_2m_max', i),
          temperatureMin: at('temperature_2m_min', i),
          precipitationMm: at('precipitation_sum', i),
          precipitationProbability: at('precipitation_probability_max', i).round(),
          condition: conditionFromCode(
            i == currentAt ? (current['weather_code'] as num?)?.toInt() ?? at('weather_code', i, -1).toInt() : at('weather_code', i, -1).toInt(),
          ),
          windKph: at('wind_speed_10m_max', i),
          humidity: at('relative_humidity_2m_mean', i).round(),
        ),
    ];
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
