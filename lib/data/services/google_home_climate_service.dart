import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;

import '../../core/config/app_config.dart';
import '../../domain/home/home_climate.dart';
import 'channel_home_climate_service.dart';

/// Les capteurs de Google Home, par les Home APIs
/// (`ios/Runner/GoogleHomeChannel.swift`,
/// `android/app/src/googleHome/kotlin/.../GoogleHomeChannel.kt`).
///
/// Même conversation qu'Apple Maison, sur un autre canal : la liste des
/// appareils qui mesurent la température ou l'humidité, et la mesure de l'un
/// d'eux. Aucune commande n'est envoyée, aucun autre appareil n'est lu.
///
/// À la différence de HomeKit, les Home APIs ne sont pas dans le système :
/// leur SDK se télécharge depuis la console Google Home et se compile dans
/// l'application. Tant qu'il n'y est pas, le canal n'existe pas et
/// [AppConfig.googleHomeEnabled] laisse la maison hors de l'écran — voir
/// `docs/05-technical-architecture.md`.
class GoogleHomeClimateService extends ChannelHomeClimateService {
  GoogleHomeClimateService({super.channel, bool? enabled})
      : _enabled = enabled ?? AppConfig.googleHomeEnabled,
        super(channelName: channelName);

  static const channelName = 'ch.vergasta.plant/google_home_climate';

  /// Livré, ou non. [AppConfig.googleHomeEnabled] par défaut ; les tests
  /// l'ouvrent pour éprouver le canal sans attendre le SDK.
  final bool _enabled;

  @override
  HomeSource get source => HomeSource.google;

  /// Les plateformes où Google Home existe : iPhone, iPad et Android. Le
  /// web, non. C'est la question posée par la ligne « Bientôt » de l'écran
  /// des capteurs, qui n'a rien à annoncer ailleurs.
  static bool get isPossible => !kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android);

  /// La plateforme, et le drapeau, qui tranche tant que le SDK n'est pas
  /// livré.
  @override
  bool get isSupported => _enabled && isPossible;
}
