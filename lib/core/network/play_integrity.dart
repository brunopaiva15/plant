import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/services.dart';

import '../config/relay_config.dart';

/// Play Integrity, vu de Dart : le pendant Android d'App Attest.
///
/// L'application demande au Play Store de l'appareil un jeton chiffré, qui
/// scelle un condensé qu'elle choisit — ici, celui du défi du relais et de
/// l'identifiant d'installation. Seul Google sait ouvrir ce jeton ; le relais
/// le lui fait déchiffrer et y lit que c'est bien Auxine, distribué par
/// Google Play, sur un Android certifié. Rien de plus : ni qui tient
/// l'appareil, ni ce qu'il contient.
///
/// Le canal est dans `android/app/src/main/kotlin/.../PlayIntegrityChannel.kt`.
/// Ailleurs — iOS, le web, les tests — [isSupported] rend `false`.
class PlayIntegrityException implements Exception {
  const PlayIntegrityException(this.code, [this.message]);

  /// Le code d'erreur de Google Play (`-3` pour le réseau, `-8` pour trop de
  /// demandes…), ou `unsupported` là où le mécanisme n'existe pas.
  final String code;
  final String? message;

  @override
  String toString() => 'PlayIntegrityException($code${message == null ? '' : ': $message'})';
}

class PlayIntegrity {
  const PlayIntegrity({
    this.channel = const MethodChannel('ch.vergasta.plant/play_integrity'),
    this.cloudProjectNumber = RelayConfig.playCloudProjectNumber,
  });

  final MethodChannel channel;

  /// Le projet Google Cloud lié à l'application dans la console Play. Zéro
  /// tant qu'il n'est pas renseigné : Android passe alors par le
  /// laissez-passer de développement, comme avant.
  final int cloudProjectNumber;

  Future<bool> get isSupported async => !kIsWeb && defaultTargetPlatform == TargetPlatform.android && cloudProjectNumber > 0;

  /// Un jeton qui scelle [requestHash]. Le premier appel prépare le
  /// fournisseur de jetons du Play Store, ce qui prend une ou deux secondes ;
  /// les suivants sont rapides.
  Future<String> token(String requestHash) async {
    try {
      final value = await channel.invokeMethod<String>('token', {
        'cloudProjectNumber': cloudProjectNumber,
        'requestHash': requestHash,
      });
      if (value == null || value.isEmpty) throw const PlayIntegrityException('failed', 'réponse vide');
      return value;
    } on MissingPluginException {
      throw const PlayIntegrityException('unsupported');
    } on PlatformException catch (e) {
      throw PlayIntegrityException(e.code, e.message);
    }
  }
}
