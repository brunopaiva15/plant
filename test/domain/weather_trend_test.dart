import 'package:flora/domain/weather/weather.dart';
import 'package:flora/domain/weather/weather_trend.dart';
import 'package:flutter_test/flutter_test.dart';

DailyWeather day(int offset, {required double max, double rain = 0}) => DailyWeather(
      date: DateTime(2026, 7, 1).add(Duration(days: offset)),
      temperatureNow: max,
      temperatureMax: max,
      temperatureMin: max - 10,
      precipitationMm: rain,
      precipitationProbability: rain > 0 ? 80 : 0,
      condition: rain > 0 ? WeatherCondition.rain : WeatherCondition.clear,
    );

void main() {
  group('la tendance', () {
    test('moyenne les maxima et cumule la pluie', () {
      final trend = WeatherTrend.of([day(0, max: 20, rain: 1), day(1, max: 30, rain: 3)])!;
      expect(trend.meanMaxC, 25);
      expect(trend.rainMm, 4);
      expect(trend.days, 2);
      expect(trend.rainPerDayMm, 2);
    });

    test('sans jour, rien : hors ligne la saison reprend la main', () {
      expect(WeatherTrend.of(const []), isNull);
    });
  });

  group('le multiplicateur d\'arrosage', () {
    test('une canicule sèche resserre l\'intervalle', () {
      final trend = WeatherTrend.of([for (var i = 0; i < 5; i++) day(i, max: 34)])!;
      expect(trend.kind, WeatherTrendKind.dryHeat);
      expect(trend.wateringFactor, lessThan(0.8));
    });

    test('une semaine pluvieuse l\'espace', () {
      final trend = WeatherTrend.of([for (var i = 0; i < 5; i++) day(i, max: 18, rain: 7)])!;
      expect(trend.kind, WeatherTrendKind.wet);
      expect(trend.wateringFactor, greaterThan(1.2));
    });

    test('le froid l\'espace aussi, l\'évaporation s\'arrêtant presque', () {
      final trend = WeatherTrend.of([for (var i = 0; i < 5; i++) day(i, max: 3)])!;
      expect(trend.kind, WeatherTrendKind.cold);
      expect(trend.wateringFactor, greaterThan(1.3));
    });

    test('une semaine ordinaire ne change rien', () {
      final trend = WeatherTrend.of([for (var i = 0; i < 5; i++) day(i, max: 19, rain: 1)])!;
      expect(trend.kind, WeatherTrendKind.mild);
      expect(trend.wateringFactor, 1.0);
    });

    test('la pluie tempère la chaleur sans l\'annuler', () {
      final hot = WeatherTrend.of([for (var i = 0; i < 5; i++) day(i, max: 30)])!;
      final hotAndWet = WeatherTrend.of([for (var i = 0; i < 5; i++) day(i, max: 30, rain: 4)])!;
      expect(hotAndWet.wateringFactor, greaterThan(hot.wateringFactor));
    });

    test('ne sort jamais de 0,6–1,6 : la météo corrige la fiche, elle ne la remplace pas', () {
      final extreme = WeatherTrend.of([for (var i = 0; i < 5; i++) day(i, max: 45)])!;
      final frozen = WeatherTrend.of([for (var i = 0; i < 5; i++) day(i, max: -5, rain: 20)])!;
      expect(extreme.wateringFactor, greaterThanOrEqualTo(0.6));
      expect(frozen.wateringFactor, lessThanOrEqualTo(1.6));
    });
  });
}
