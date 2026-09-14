import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Retours haptiques, utilisés avec modération.
///
/// Vocabulaire volontairement réduit pour rester cohérent dans toute l'app.
///
/// Sur iPhone, les trois retours qui racontent quelque chose — la goutte, le
/// roulement, le coup sourd — sont des motifs Core Haptics joués par
/// `ios/Runner/HapticsChannel.swift` : plusieurs impulsions d'intensité et
/// de netteté réglées, là où `HapticFeedback` n'offre qu'un seul coup. La
/// sélection et le tap restent ceux du système, qui sont déjà les bons.
/// Partout ailleurs, et si le moteur manque (iPad, simulateur, réglage
/// *Vibrations* coupé), le repli est le retour d'avant.
abstract final class Haptics {
  static const String channelName = 'ch.vergasta.plant/haptics';

  static MethodChannel _channel = const MethodChannel(channelName);

  /// `null` tant qu'on ne sait pas si le natif répond ; ensuite, la réponse
  /// est retenue pour ne pas payer un aller-retour à chaque tap.
  static bool? _native;

  /// Les tests remplacent le canal et remettent la découverte à zéro.
  @visibleForTesting
  static void debugUseChannel(MethodChannel? channel) {
    _channel = channel ?? const MethodChannel(channelName);
    _native = null;
  }

  /// Changement de sélection (chip, onglet, segment).
  static Future<void> selection() => HapticFeedback.selectionClick();

  /// Tap sur un bouton.
  static Future<void> light() => HapticFeedback.lightImpact();

  /// Action enregistrée (création, réglage, photo…) : un roulement qui
  /// monte et se pose.
  static Future<void> success() => _play('success', HapticFeedback.mediumImpact);

  /// Arrosage enregistré : deux gouttes légères, puis la goutte qui touche
  /// la terre et s'y étale.
  static Future<void> drop() => _play('drop', HapticFeedback.mediumImpact);

  /// Action sensible (archivage, suppression) : un coup sourd et son écho.
  static Future<void> warning() => _play('warning', HapticFeedback.heavyImpact);

  static Future<void> _play(String pattern, Future<void> Function() fallback) async {
    if (_native == false || kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return fallback();
    bool played;
    try {
      played = await _channel.invokeMethod<bool>('play', pattern) == true;
      // Le natif répond, mais ce matériel n'a pas de moteur : on n'insiste
      // pas, et le repli du système prend le relais pour de bon.
      _native = played;
    } on MissingPluginException {
      _native = false;
      played = false;
    } on PlatformException {
      played = false;
    }
    if (!played) await fallback();
  }
}
