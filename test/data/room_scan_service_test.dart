import 'dart:io';

import 'package:flora/data/services/room_scan_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Le service Dart n'est qu'un traducteur : ce que le canal rend devient un
/// relevé, et ce qu'il ne rend pas ne casse rien — un relevé annulé, un
/// canal absent, une plateforme sans RoomPlan valent la réponse vide.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(ChannelRoomScanService.channelName);
  final calls = <MethodCall>[];
  Future<Object?> Function(MethodCall) handler = (_) async => null;

  setUp(() {
    calls.clear();
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return handler(call);
    });
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test("ce que l'appareil sait faire", () async {
    handler = (_) async => {'lidar': true, 'sections': true, 'structure': false};
    final support = await ChannelRoomScanService(enabled: true).support();
    expect(support.lidar, isTrue);
    expect(support.sections, isTrue);
    expect(support.structure, isFalse);
  });

  test('un relevé abouti rend le chemin et le nord', () async {
    handler = (call) async => {'path': call.arguments['path'], 'northOffsetDeg': 87.5};
    final result = await ChannelRoomScanService(enabled: true).scan(toPath: '/tmp/room.json');
    expect(result?.succeeded, isTrue);
    expect(result?.path, '/tmp/room.json');
    expect(result?.northOffsetDeg, 87.5);
    expect(calls.single.method, 'scan');
    expect(calls.single.arguments, {'path': '/tmp/room.json'});
  });

  test('sans boussole stable, le nord manque et le relevé reste bon', () async {
    handler = (_) async => {'path': '/tmp/room.json'};
    final result = await ChannelRoomScanService(enabled: true).scan(toPath: '/tmp/room.json');
    expect(result?.succeeded, isTrue);
    expect(result?.northOffsetDeg, isNull);
  });

  test('un relevé annulé ne rend rien', () async {
    handler = (_) async => null;
    expect(await ChannelRoomScanService(enabled: true).scan(toPath: '/tmp/room.json'), isNull);
  });

  test('un relevé qui a échoué rend sa raison, sans chemin', () async {
    handler = (_) async => {'error': 'no floor detected'};
    final result = await ChannelRoomScanService(enabled: true).scan(toPath: '/tmp/room.json');
    expect(result?.succeeded, isFalse);
    expect(result?.error, 'no floor detected');
  });

  test('une erreur native vaut la réponse vide', () async {
    handler = (_) async => throw PlatformException(code: 'busy');
    expect(await ChannelRoomScanService(enabled: true).scan(toPath: '/tmp/room.json'), isNull);
    expect((await ChannelRoomScanService(enabled: true).support()).lidar, isFalse);
  });

  test('sans le drapeau, rien ne part au canal', () async {
    handler = (_) async => {'lidar': true};
    final service = ChannelRoomScanService(enabled: false);
    expect(service.isSupported, isFalse);
    expect((await service.support()).lidar, isFalse);
    expect(calls, isEmpty);
  });

  test('sur Android, rien ne part au canal', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final service = ChannelRoomScanService(enabled: true);
    expect(service.isSupported, isFalse);
    expect(await service.scan(toPath: '/tmp/room.json'), isNull);
    expect(calls, isEmpty);
  });

  group('le magasin des fichiers', () {
    late Directory dir;
    late RoomScanStore store;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('rooms');
      store = RoomScanStore(root: dir);
    });

    tearDown(() => dir.delete(recursive: true));

    test('écrit, relit, supprime, et ne se plaint pas de ce qui manque', () async {
      final path = await store.newPath('abc');
      expect(path, endsWith('abc.json'));
      final relative = store.relativeOf(path);
      expect(relative, 'abc.json');
      expect(await store.read(relative), isNull);
      await store.write(relative, {'walls': []});
      expect(await store.read(relative), {'walls': []});
      await store.delete(relative);
      expect(await store.read(relative), isNull);
      await store.delete(relative);
    });

    test('un fichier qui n’est pas du JSON se lit comme absent', () async {
      await File(await store.absolutePath('bad.json')).writeAsString('{not json');
      expect(await store.read('bad.json'), isNull);
    });
  });
}
