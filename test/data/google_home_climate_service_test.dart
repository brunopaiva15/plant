import 'package:flora/data/services/google_home_climate_service.dart';
import 'package:flora/domain/home/home_climate.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Google Home parle le même dictionnaire qu'Apple Maison, sur un autre
/// canal : les capteurs qu'il rend portent sa marque, et sa mesure se lit
/// comme l'autre. Sur Android comme sur iPhone.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(GoogleHomeClimateService.channelName);
  final calls = <MethodCall>[];

  void answer(Object? Function(MethodCall call) handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return handler(call);
    });
  }

  const nest = HomeSensor(id: 'N1', name: 'Nest', source: HomeSource.google);

  setUp(() {
    calls.clear();
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('liste les appareils, marqués Google Home', () async {
    answer((call) => [
          {'id': 'N1', 'name': 'Nest Thermostat', 'room': 'Salon', 'home': 'Chez moi', 'temperature': true, 'humidity': true},
          {'id': 'N2', 'name': 'Capteur', 'temperature': true, 'humidity': false},
        ]);
    final sensors = await GoogleHomeClimateService(enabled: true).sensors();
    expect(sensors.map((s) => s.id), ['N1', 'N2']);
    expect(sensors.map((s) => s.source), everyElement(HomeSource.google));
    expect(sensors.first.label, 'Salon');
    expect(sensors.first.homeName, 'Chez moi');
    expect(sensors.last.hasHumidity, isFalse);
  });

  test('lit une mesure, et la marque du capteur suffit à la router', () async {
    answer((call) => {'temperature': 20.5, 'humidity': 44.0, 'at': 2000});
    final service = GoogleHomeClimateService(enabled: true);
    final reading = await service.read(nest);
    expect(calls.single.arguments, {'id': 'N1'});
    expect(reading!.temperatureC, 20.5);
    expect(reading.humidity, 44);
    calls.clear();
    // Un capteur d'Apple Maison n'a rien à faire ici.
    expect(await service.read(const HomeSensor(id: 'N1', name: 'Eve')), isNull);
    expect(calls, isEmpty);
  });

  test('sur iPhone aussi, et jamais sur le web', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(GoogleHomeClimateService(enabled: true).isSupported, isTrue);
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    expect(GoogleHomeClimateService(enabled: true).isSupported, isFalse);
  });

  test("tant que le SDK n'est pas livré, la maison n'existe pas", () async {
    answer((call) => [
          {'id': 'N1', 'name': 'Nest', 'temperature': true},
        ]);
    final service = GoogleHomeClimateService(enabled: false);
    expect(service.isSupported, isFalse);
    expect(service.sources, isEmpty);
    expect(service.of(HomeSource.google), isNull);
    expect(await service.sensors(), isEmpty);
    expect(await service.access(), HomeAccess.unavailable);
    expect(calls, isEmpty);
  });

  test('un canal absent vaut une maison vide', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    final service = GoogleHomeClimateService(enabled: true);
    expect(await service.sensors(), isEmpty);
    expect(await service.access(), HomeAccess.unavailable);
    expect(await service.read(nest), isNull);
  });
}
