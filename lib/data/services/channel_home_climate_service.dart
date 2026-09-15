import 'package:flutter/services.dart';

import '../../domain/home/home_climate.dart';

/// Un canal natif qui rend des capteurs et des mesures.
///
/// Apple Maison et Google Home tiennent la même conversation — ce que la
/// maison laisse faire, la liste des accessoires qui mesurent la température
/// ou l'humidité, la mesure de l'un d'eux — et parlent le même dictionnaire
/// (`id`, `name`, `room`, `home`, `temperature`, `humidity`, `at`, `error`).
/// Seuls le canal et la plateforme changent ; le reste est ici.
abstract class ChannelHomeClimateService extends SingleHomeClimateService {
  ChannelHomeClimateService({required String channelName, MethodChannel? channel}) : _channel = channel ?? MethodChannel(channelName);

  final MethodChannel _channel;

  @override
  Future<HomeAccess> access() async => parseAccess(await _ask(() => _channel.invokeMethod<String>('access')));

  @override
  Future<List<HomeSensor>> sensors() async => parseSensors(await _ask(() => _channel.invokeListMethod<Object?>('sensors')));

  @override
  Future<HomeReading?> read(HomeSensor sensor) async {
    // Un identifiant n'est unique que chez lui : un capteur d'une autre
    // maison ne se demande pas à celle-ci.
    if (sensor.source != source) return null;
    return parseReading(await _ask(() => _channel.invokeMapMethod<String, Object?>('read', {'id': sensor.id})));
  }

  /// Ferme la session côté natif. Le canal d'une maison qui n'en ouvre pas
  /// répond « pas implémenté », et [_ask] en fait un silence — mais
  /// [canDisconnect] aura déjà retenu l'écran.
  @override
  Future<void> disconnect() async {
    await _ask(() => _channel.invokeMethod<Object?>('disconnect'));
  }

  /// Une question au canal, et rien qui remonte quand elle échoue : un canal
  /// absent — plateforme sans cette maison, SDK non compilé — ou une erreur
  /// native valent la réponse vide, que l'écran sait déjà montrer.
  Future<T?> _ask<T>(Future<T?> Function() body) async {
    if (!isSupported) return null;
    try {
      return await body();
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

  /// Les capteurs du canal, marqués de la maison qui les a donnés : c'est
  /// cette marque qui, plus tard, dira à qui redemander leur mesure.
  List<HomeSensor> parseSensors(List<Object?>? raw) => [
        for (final item in raw ?? const [])
          if (item is Map && item['id'] is String && (item['id'] as String).isNotEmpty)
            HomeSensor(
              id: item['id'] as String,
              name: item['name'] is String && (item['name'] as String).isNotEmpty ? item['name'] as String : item['id'] as String,
              source: source,
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
