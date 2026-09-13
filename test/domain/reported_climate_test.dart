import 'package:flora/domain/diagnosis/plant_diagnoser.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ce que la personne tape pour le diagnostic, quand aucun capteur ne le
/// mesure : lu avec indulgence, transmis en Celsius, ignoré hors de toute
/// plage vraisemblable.
void main() {
  test('virgule ou point, espaces autour : la valeur est lue', () {
    final r = ReportedClimate.parse(temperature: ' 21,5 ', humidity: '40');
    expect(r.temperatureC, 21.5);
    expect(r.humidity, 40);
    expect(r.isEmpty, isFalse);
  });

  test('en Fahrenheit, la température est convertie en Celsius', () {
    expect(ReportedClimate.parse(temperature: '68', fahrenheit: true).temperatureC, closeTo(20, 0.01));
  });

  test('vide, rien ; illisible ou hors plage, ignoré', () {
    expect(ReportedClimate.parse().isEmpty, isTrue);
    expect(ReportedClimate.parse(temperature: '', humidity: '  ').isEmpty, isTrue);
    expect(ReportedClimate.parse(temperature: 'chaud', humidity: 'NaN').isEmpty, isTrue);
    expect(ReportedClimate.parse(temperature: '95', humidity: '140').isEmpty, isTrue);
    expect(ReportedClimate.parse(temperature: '-40').isEmpty, isTrue);
    final partial = ReportedClimate.parse(temperature: '-5', humidity: '101');
    expect(partial.temperatureC, -5);
    expect(partial.humidity, isNull);
  });

  test("l'humidité s'arrondit à l'entier", () {
    expect(ReportedClimate.parse(humidity: '55.6').humidity, 56);
  });
}
