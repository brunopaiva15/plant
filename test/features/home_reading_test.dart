import 'package:flora/app/providers.dart';
import 'package:flora/data/services/preferences_service.dart';
import 'package:flora/domain/home/home_climate.dart';
import 'package:flora/features/home_climate/application/home_climate_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes/fake_home_climate_service.dart';

/// La mesure de la maison, quand la température et l'humidité ne viennent
/// pas du même capteur.
void main() {
  // La mesure écoute le réveil de l'application : il faut un binding.
  TestWidgetsFlutterBinding.ensureInitialized();
  const thermostat = HomeSensor(id: 'T', name: 'Thermostat', roomName: 'Salon', hasHumidity: false);
  const hygro = HomeSensor(id: 'H', name: 'Hygromètre', roomName: 'Salon', hasTemperature: false);
  final at = DateTime(2026, 9, 12, 10);

  Future<ProviderContainer> container(Map<String, String> prefs, FakeHomeClimateService home) async {
    SharedPreferences.setMockInitialValues(prefs);
    final service = await PreferencesService.load();
    final c = ProviderContainer(overrides: [
      preferencesServiceProvider.overrideWithValue(service),
      homeClimateServiceProvider.overrideWithValue(home),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  test("l'humidité vient du second capteur, la température du premier", () async {
    final home = FakeHomeClimateService(readings: {
      'T': HomeReading(at: at, temperatureC: 21.5),
      'H': HomeReading(at: at, humidity: 44),
    });
    final c = await container({'home_sensor': thermostat.encode(), 'home_humidity_sensor': hygro.encode()}, home);
    final reading = (await c.read(homeReadingProvider.future))!;
    expect(reading.temperatureC, 21.5);
    expect(reading.humidity, 44);
    expect(reading.sensor, thermostat);
    expect(reading.humiditySensor, hygro);
    expect(home.readCalls, 2);
  });

  test("sans second capteur, l'humidité vient du premier s'il la mesure", () async {
    final home = FakeHomeClimateService(reading: HomeReading(at: at, temperatureC: 20, humidity: 55));
    final c = await container({'home_sensor': thermostat.encode()}, home);
    final reading = (await c.read(homeReadingProvider.future))!;
    expect(reading.humidity, 55);
    expect(reading.humiditySensor, isNull);
    expect(home.readCalls, 1);
  });

  test('un hygromètre muet laisse la température seule', () async {
    final home = FakeHomeClimateService(readings: {'T': HomeReading(at: at, temperatureC: 19, humidity: 70), 'H': null});
    final c = await container({'home_sensor': thermostat.encode(), 'home_humidity_sensor': hygro.encode()}, home);
    final reading = (await c.read(homeReadingProvider.future))!;
    expect(reading.temperatureC, 19);
    // Le second capteur a été choisi pour l'humidité : celle du premier n'est pas reprise à sa place.
    expect(reading.humidity, isNull);
    expect(reading.error, isNull);
  });

  test("la raison d'un hygromètre en échec remonte avec la mesure", () async {
    final home = FakeHomeClimateService(readings: {
      'T': HomeReading(at: at, temperatureC: 19),
      'H': HomeReading(at: at, error: 'Accessoire injoignable (4)'),
    });
    final c = await container({'home_sensor': thermostat.encode(), 'home_humidity_sensor': hygro.encode()}, home);
    final reading = (await c.read(homeReadingProvider.future))!;
    expect(reading.temperatureC, 19);
    expect(reading.humidity, isNull);
    expect(reading.error, 'Accessoire injoignable (4)');
    // La raison du capteur de température ne se mêle pas à celle de l'humidité quand sa valeur est là.
    final both = FakeHomeClimateService(readings: {'T': HomeReading(at: at, temperatureC: 19, error: 'lent'), 'H': HomeReading(at: at, humidity: 40)});
    final c2 = await container({'home_sensor': thermostat.encode(), 'home_humidity_sensor': hygro.encode()}, both);
    expect((await c2.read(homeReadingProvider.future))!.error, isNull);
  });

  test("l'humidité vient d'un raccourci : la valeur transmise, avec sa pièce", () async {
    final home = FakeHomeClimateService(readings: {'T': HomeReading(at: at, temperatureC: 21)});
    const shortcut = HomeSensor(id: HomeSensor.shortcutId, name: 'Raccourci');
    final written = DateTime.now().subtract(const Duration(minutes: 5)).millisecondsSinceEpoch;
    final c = await container({
      'home_sensor': thermostat.encode(),
      'home_humidity_sensor': shortcut.encode(),
      'home_shortcut_reading': '|45.0|$written|Salle de jeux',
    }, home);
    final reading = (await c.read(homeReadingProvider.future))!;
    expect(reading.temperatureC, 21);
    expect(reading.humidity, 45);
    expect(reading.error, isNull);
    expect(home.readCalls, 1);
  });

  test('une valeur de raccourci trop vieille ne compte plus, et le dit', () async {
    final old = DateTime.now().subtract(const Duration(hours: 7)).millisecondsSinceEpoch;
    final c = await container({
      'home_sensor': const HomeSensor(id: HomeSensor.shortcutId, name: 'Raccourci').encode(),
      'home_shortcut_reading': '22.5|45|$old|Salon',
    }, FakeHomeClimateService());
    final reading = (await c.read(homeReadingProvider.future))!;
    expect(reading.temperatureC, isNull);
    expect(reading.humidity, isNull);
    expect(reading.error, 'stale');
    expect(decodeShortcutReading('22.5|45|$old|Salon', now: DateTime.fromMillisecondsSinceEpoch(old + 1000))!.humidity, 45);
    expect(decodeShortcutReading('||1'), isNull);
    expect(decodeShortcutReading('x'), isNull);
  });

  test('retirer le capteur de température emporte celui de l’humidité', () async {
    final c = await container({'home_sensor': thermostat.encode(), 'home_humidity_sensor': hygro.encode()}, FakeHomeClimateService());
    await c.read(preferencesProvider.notifier).setHomeSensor(null);
    expect(c.read(preferencesProvider).homeSensor, isNull);
    expect(c.read(preferencesProvider).homeHumiditySensor, isNull);
    expect(await c.read(homeReadingProvider.future), isNull);
  });
}
