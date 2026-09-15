import 'package:flora/data/services/channel_home_climate_service.dart';
import 'package:flora/data/services/home_kit_climate_service.dart';
import 'package:flora/domain/home/home_climate.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Le service Dart n'est qu'un traducteur : ce que le canal rend devient des
/// capteurs et des mesures, et ce qu'il ne rend pas ne casse rien.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(HomeKitClimateService.channelName);
  final calls = <MethodCall>[];

  void answer(Object? Function(MethodCall call) handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return handler(call);
    });
  }

  const salon = HomeSensor(id: 'A', name: 'Eve Room');

  setUp(() {
    calls.clear();
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('liste les capteurs avec leur pièce, marqués Apple Maison', () async {
    answer((call) => [
          {'id': 'A', 'name': 'Eve Room', 'room': 'Salon', 'home': 'Maison', 'temperature': true, 'humidity': true},
          {'id': 'B', 'name': 'Thermostat', 'temperature': true, 'humidity': false},
          {'name': 'sans id'},
        ]);
    final sensors = await HomeKitClimateService().sensors();
    expect(sensors.map((s) => s.id), ['A', 'B']);
    expect(sensors.first.label, 'Salon');
    expect(sensors.first.homeName, 'Maison');
    expect(sensors.map((s) => s.source), everyElement(HomeSource.apple));
    expect(sensors.last.label, 'Thermostat');
    expect(sensors.last.hasHumidity, isFalse);
  });

  test('lit une mesure, et borne l’humidité', () async {
    answer((call) => {'temperature': 21.4, 'humidity': 137.0, 'at': 1000});
    final reading = await HomeKitClimateService().read(salon);
    expect(calls.single.method, 'read');
    expect(calls.single.arguments, {'id': 'A'});
    expect(reading!.temperatureC, 21.4);
    expect(reading.humidity, 100);
    expect(reading.at, DateTime.fromMillisecondsSinceEpoch(1000));
  });

  test("un capteur d'une autre maison ne part pas sur ce canal", () async {
    answer((call) => {'temperature': 21.4, 'at': 1000});
    const google = HomeSensor(id: 'A', name: 'Nest', source: HomeSource.google);
    expect(await HomeKitClimateService().read(google), isNull);
    expect(calls, isEmpty);
  });

  test("une lecture en échec garde la raison, pour l'écran", () async {
    answer((call) => {'at': 1, 'temperature': 25.0, 'error': 'unreachable; Accessoire injoignable (4)'});
    final reading = (await HomeKitClimateService().read(salon))!;
    expect(reading.temperatureC, 25);
    expect(reading.humidity, isNull);
    expect(reading.error, 'unreachable; Accessoire injoignable (4)');
    answer((call) => {'at': 1, 'error': 'timeout'});
    expect((await HomeKitClimateService().read(salon))!.isEmpty, isTrue);
  });

  test('une mesure vide vaut null, un canal absent aussi', () async {
    answer((call) => {'at': 1});
    expect(await HomeKitClimateService().read(salon), isNull);
    answer((call) => throw PlatformException(code: 'boom'));
    expect(await HomeKitClimateService().read(salon), isNull);
    expect(await HomeKitClimateService().sensors(), isEmpty);
    expect(await HomeKitClimateService().access(), HomeAccess.unavailable);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    expect(await HomeKitClimateService().sensors(), isEmpty);
  });

  test("l'accès se traduit mot pour mot", () async {
    answer((call) => 'denied');
    expect(await HomeKitClimateService().access(), HomeAccess.denied);
    expect(ChannelHomeClimateService.parseAccess('authorized'), HomeAccess.authorized);
    expect(ChannelHomeClimateService.parseAccess('notDetermined'), HomeAccess.notDetermined);
    expect(ChannelHomeClimateService.parseAccess('?'), HomeAccess.unavailable);
  });

  test('hors iOS, rien ne part sur le canal', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    answer((call) => [
          {'id': 'A', 'name': 'x'},
        ]);
    final service = HomeKitClimateService();
    expect(service.isSupported, isFalse);
    expect(service.sources, isEmpty);
    expect(service.of(HomeSource.apple), isNull);
    expect(await service.sensors(), isEmpty);
    expect(await service.access(), HomeAccess.unavailable);
    expect(calls, isEmpty);
  });
}
