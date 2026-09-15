import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;

import '../../domain/home/home_climate.dart';
import 'channel_home_climate_service.dart';

/// Les capteurs d'Apple Maison, par HomeKit (`ios/Runner/HomeClimateChannel.swift`).
///
/// Tout se passe sur l'appareil : HomeKit ne rend que ce que les accessoires
/// mesurent, et rien n'en sort. Le système demande l'accès à la première
/// lecture, avec le texte de `NSHomeKitUsageDescription`.
class HomeKitClimateService extends ChannelHomeClimateService {
  HomeKitClimateService({super.channel}) : super(channelName: channelName);

  static const channelName = 'ch.vergasta.plant/home_climate';

  @override
  HomeSource get source => HomeSource.apple;

  @override
  bool get isSupported => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
}
