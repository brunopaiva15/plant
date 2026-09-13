import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/services.dart';

import '../../domain/home/home_climate.dart';

/// Les capteurs d'Apple Maison, par HomeKit (`ios/Runner/HomeClimateChannel.swift`).
///
/// Tout se passe sur l'appareil : HomeKit ne rend que ce que les accessoires
/// mesurent, et rien n'en sort. Le système demande l'accès à la première
/// lecture, avec le texte de `NSHomeKitUsageDescription`.
class HomeKitClimateService implements HomeClimateService {
  HomeKitClimateService({MethodChannel? channel}) : _channel = channel ?? const MethodChannel(channelName);

  static const channelName = 'ch.vergasta.plant/home_climate';

  final MethodChannel _channel;

  @override
  bool get isSupported => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Future<HomeAccess> access() async {
    if (!isSupported) return HomeAccess.unavailable;
    try {
      return parseAccess(await _channel.invokeMethod<String>('access'));
    } on PlatformException {
      return HomeAccess.unavailable;
    } on MissingPluginException {
      return HomeAccess.unavailable;
    }
  }

  @override
  Future<List<HomeSensor>> sensors() async {
    if (!isSupported) return const [];
    try {
      final raw = await _channel.invokeListMethod<Object?>('sensors');
      return parseSensors(raw);
    } on PlatformException {
      return const [];
    } on MissingPluginException {
      return const [];
    }
  }

  @override
  Future<HomeReading?> read(String sensorId) async {
    if (!isSupported) return null;
    try {
      final raw = await _channel.invokeMapMethod<String, Object?>('read', {'id': sensorId});
      return parseReading(raw);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  static HomeAccess parseAccess(String? raw) => switch (raw) {
        'authorized' => HomeAccess.authorized,
        'denied' => HomeAccess.denied,
        'notDetermined' => HomeAccess.notDetermined,
        _ => HomeAccess.unavailable,
      };

  static List<HomeSensor> parseSensors(List<Object?>? raw) => [
        for (final item in raw ?? const [])
          if (item is Map && item['id'] is String && (item['id'] as String).isNotEmpty)
            HomeSensor(
              id: item['id'] as String,
              name: item['name'] is String && (item['name'] as String).isNotEmpty ? item['name'] as String : item['id'] as String,
              roomName: _text(item['room']),
              homeName: _text(item['home']),
              hasTemperature: item['temperature'] == true,
              hasHumidity: item['humidity'] == true,
            ),
      ];

  static HomeReading? parseReading(Map<String, Object?>? raw) {
    if (raw == null) return null;
    final temperature = (raw['temperature'] as num?)?.toDouble();
    final humidity = (raw['humidity'] as num?)?.round();
    final error = _text(raw['error']);
    // Rien lu et rien à expliquer : pas de mesure. Rien lu mais une raison :
    // une mesure vide qui la porte.
    if (temperature == null && humidity == null && error == null) return null;
    final at = raw['at'] is num ? DateTime.fromMillisecondsSinceEpoch((raw['at'] as num).toInt()) : DateTime.now();
    return HomeReading(at: at, temperatureC: temperature, humidity: humidity?.clamp(0, 100), error: error);
  }

  static String? _text(Object? v) => v is String && v.trim().isNotEmpty ? v.trim() : null;
}
