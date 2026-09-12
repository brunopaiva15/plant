import 'package:flora/data/services/infomaniak_diagnoser.dart';
import 'package:flora/domain/home/home_climate.dart';
import 'package:flutter_test/flutter_test.dart';

/// La mesure de la maison part avec la question, quand il y en a une.
void main() {
  test('la mesure du capteur est dans la question, avec sa pièce', () {
    final reading = HomeReading(at: DateTime(2026, 9, 12), temperatureC: 21.4, humidity: 38, sensor: const HomeSensor(id: 'A', name: 'Eve', roomName: 'Salon'));
    final prompt = InfomaniakDiagnoser.userPrompt(language: 'fr', plantName: 'Calathea', indoorClimate: reading);
    expect(prompt, contains('Plant: Calathea.'));
    expect(prompt, contains('21.4 °C, 38 % relative humidity'));
    expect(prompt, contains('in the room "Salon"'));
    expect(prompt, contains('dry air, cold or heat'));
  });

  test('sans capteur, ou sans valeur, rien de plus ne part', () {
    expect(InfomaniakDiagnoser.userPrompt(language: 'fr'), isNot(contains('Measured indoors')));
    expect(InfomaniakDiagnoser.climateLine(HomeReading(at: DateTime(2026, 9, 12))), isNull);
    final humidityOnly = HomeReading(at: DateTime(2026, 9, 12), humidity: 70);
    expect(InfomaniakDiagnoser.climateLine(humidityOnly), allOf(contains('70 % relative humidity'), isNot(contains('°C')), isNot(contains('room'))));
  });
}
