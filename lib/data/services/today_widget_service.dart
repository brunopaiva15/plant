import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Ce que le widget de l'écran d'accueil lit, pour la partie Dart
/// (`ios/Runner/TodayWidgetChannel.swift`).
///
/// Une seule méthode : déposer l'instantané du jour, en JSON, dans le
/// conteneur partagé de l'App Group, et demander au système de redessiner
/// les widgets. Le widget ne calcule rien : il montre ce qu'on lui a écrit.
/// Muet hors iOS.
class TodayWidgetService {
  TodayWidgetService({MethodChannel? channel}) : _channel = channel ?? const MethodChannel(channelName);

  static const String channelName = 'ch.vergasta.plant/widgets';

  final MethodChannel _channel;

  Future<void> publish(String json) async {
    try {
      await _channel.invokeMethod<void>('publish', json);
    } on MissingPluginException {
      // Pas de widget sur cette plateforme.
    } on PlatformException catch (e) {
      debugPrint('widget: publish failed: ${e.message}');
    }
  }
}
