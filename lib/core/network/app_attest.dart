import 'package:flutter/services.dart';

/// App Attest, vu de Dart.
///
/// La Secure Enclave d'un appareil Apple fabrique une paire de clés dont la
/// partie privée ne sort jamais, et Apple signe une attestation disant que
/// cette clé est née là, dans cette application-ci. Le relais qui vérifie
/// cette chaîne sait donc qu'il parle au vrai Auxine, sur un vrai iPhone —
/// et rien de plus : ni qui le tient, ni ce qu'il contient.
///
/// Le canal est dans `ios/Runner/AppAttestChannel.swift`. Ailleurs —
/// sur le simulateur, qui n'a pas d'enclave, et sur Android, qui se présente
/// par Play Integrity (`play_integrity.dart`) — [isSupported] rend `false`.
class AppAttestException implements Exception {
  const AppAttestException(this.code, [this.message]);

  /// `invalid_key` quand Apple ne reconnaît plus la clé — elle se refait ;
  /// `server_unavailable` quand c'est Apple qui ne répond pas — on retente
  /// plus tard ; `unsupported` là où le mécanisme n'existe pas.
  final String code;
  final String? message;

  @override
  String toString() => 'AppAttestException($code${message == null ? '' : ': $message'})';
}

class AppAttest {
  const AppAttest([this.channel = const MethodChannel('ch.vergasta.plant/app_attest')]);

  final MethodChannel channel;

  Future<bool> get isSupported async {
    try {
      return await channel.invokeMethod<bool>('isSupported') ?? false;
    } on MissingPluginException {
      // Le canal n'existe pas : ce n'est pas un appareil Apple.
      return false;
    } on PlatformException {
      return false;
    }
  }

  /// Une clé neuve dans l'enclave. Son identifiant est le condensé de sa
  /// partie publique : il se garde, elle ne se refait pas à chaque lancement.
  Future<String> generateKey() => _call<String>('generateKey');

  /// L'attestation d'une clé neuve, à ne demander qu'une fois par clé : Apple
  /// refuse d'attester deux fois la même.
  Future<Uint8List> attest(String keyId, String challenge) =>
      _call<Uint8List>('attest', {'keyId': keyId, 'challenge': challenge});

  /// La signature d'un défi par une clé déjà attestée.
  Future<Uint8List> assertion(String keyId, String challenge) =>
      _call<Uint8List>('assert', {'keyId': keyId, 'challenge': challenge});

  Future<T> _call<T>(String method, [Map<String, Object?>? arguments]) async {
    try {
      final value = await channel.invokeMethod<T>(method, arguments);
      if (value == null) throw const AppAttestException('failed', 'réponse vide');
      return value;
    } on MissingPluginException {
      throw const AppAttestException('unsupported');
    } on PlatformException catch (e) {
      throw AppAttestException(e.code, e.message);
    }
  }
}
