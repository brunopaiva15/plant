import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:http/http.dart' as http;

import '../config/relay_config.dart';
import 'app_attest.dart';
import 'play_integrity.dart';

/// Le relais n'a pas voulu, ou n'a pas pu, laisser entrer.
class RelayException implements Exception {
  const RelayException(this.code, [this.message]);

  /// `unavailable` quand l'appareil n'a aucun moyen de se présenter ;
  /// `refused` quand le relais a regardé et dit non ; `unreachable` quand il
  /// n'a pas répondu.
  final String code;
  final String? message;

  @override
  String toString() => 'RelayException($code${message == null ? '' : ': $message'})';
}

/// Ce que l'appareil garde d'un lancement à l'autre pour se présenter.
///
/// Sur iPhone, l'identifiant de la clé attestée. Ce n'est pas un secret —
/// c'est le condensé d'une clé publique — mais il doit survivre : Apple
/// refuse d'attester deux fois la même clé, et en refaire une à chaque
/// lancement finirait par buter sur ses limites.
///
/// Sur Android, l'identifiant d'installation : Play Integrity ne rend aucune
/// identité d'appareil, et c'est lui que le relais compte dans ses quotas.
abstract interface class RelayKeyStore {
  String? get keyId;
  Future<void> setKeyId(String? value);

  String? get installId;
  Future<void> setInstallId(String value);
}

/// Un client HTTP qui se présente au relais avant de lui parler.
///
/// Les cinq services qui passaient par une clé d'éditeur passent maintenant
/// par ici : `PlantNetIdentifier`, les quatre appels aux AI Services
/// d'Infomaniak, et Jev. Vu d'eux, rien ne change — ils reçoivent un
/// `http.Client` et postent sur une URL.
///
/// La poignée de main, elle, est ici. Elle se fait une fois par heure, pas à
/// chaque requête : une signature de la Secure Enclave, ou un jeton Play
/// Integrity, coûte un aller-retour, et le relais délivre contre elle un
/// jeton de séance.
///
/// **Ce qui n'est pas rejoué.** Si le relais répond 401 — jeton périmé entre
/// la vérification et l'envoi, secret changé côté serveur, appareil retiré de
/// la base —, le jeton est oublié et la requête échoue. Elle n'est pas
/// renvoyée : une requête `http` est à usage unique, ses photos sont lues
/// depuis le disque au fil de l'envoi, et les remettre en mémoire pour
/// pouvoir les rejouer coûterait une quinzaine de mégaoctets à chaque
/// identification pour un cas qui ne se produit presque jamais — le jeton est
/// renouvelé cinq minutes avant son terme. La tentative suivante refait la
/// poignée de main et passe.
class RelayClient extends http.BaseClient {
  RelayClient({
    required this.store,
    String? baseUrl,
    this.attest = const AppAttest(),
    this.integrity = const PlayIntegrity(),
    this.devToken = RelayConfig.devToken,
    http.Client? inner,
    DateTime Function()? clock,
  })  : baseUrl = baseUrl ?? RelayConfig.baseUrl,
        _inner = inner ?? http.Client(),
        _ownsInner = inner == null,
        _now = clock ?? DateTime.now;

  final String baseUrl;
  final RelayKeyStore store;
  final AppAttest attest;
  final PlayIntegrity integrity;
  final String devToken;

  final http.Client _inner;
  final bool _ownsInner;
  final DateTime Function() _now;

  /// De quoi renouveler avant l'échéance plutôt qu'après : un jeton qui périme
  /// pendant l'envoi d'une photo ferait échouer la requête pour rien.
  static const _margin = Duration(minutes: 5);
  static const _timeout = Duration(seconds: 20);

  String? _token;
  DateTime? _expiry;
  Future<String>? _pending;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    request.headers['authorization'] = 'Bearer ${await _authorize()}';
    final response = await _inner.send(request);
    if (response.statusCode == 401) _forget();
    return response;
  }

  @override
  void close() {
    if (_ownsInner) _inner.close();
  }

  void _forget() {
    _token = null;
    _expiry = null;
  }

  /// Un jeton valable, et une seule poignée de main à la fois : cinq écrans
  /// qui se réveillent ensemble ne doivent pas en déclencher cinq.
  Future<String> _authorize() {
    final token = _token;
    final expiry = _expiry;
    if (token != null && expiry != null && expiry.isAfter(_now().add(_margin))) {
      return Future.value(token);
    }
    return _pending ??= _handshake().whenComplete(() => _pending = null);
  }

  Future<String> _handshake() async {
    if (baseUrl.isEmpty) throw const RelayException('unavailable', 'relais non configuré');
    if (await attest.isSupported) return _byAttestation();
    if (await integrity.isSupported) {
      try {
        return await _byIntegrity();
      } on RelayException catch (e) {
        // Un binaire que Google Play n'a pas distribué — `flutter run`, un
        // APK installé à la main — est refusé par le relais ; un émulateur
        // sans Play Store ne peut pas même demander de jeton. S'il porte le
        // laissez-passer, c'est une construction de développement : elle
        // passe par là. Sinon l'échec remonte tel quel, comme un relais
        // injoignable, que le laissez-passer n'atteindrait pas mieux.
        if (devToken.isEmpty || e.code == 'unreachable') rethrow;
      }
    }
    if (devToken.isNotEmpty) return _byDevToken();
    // Ni attestation ni laissez-passer : un simulateur lancé sans
    // `RELAY_DEV_TOKEN`, ou une construction Android sans projet Play
    // Integrity. Les fonctions qui dépendent du relais se taisent, le reste
    // de l'application marche.
    throw const RelayException('unavailable', 'aucun moyen de se présenter');
  }

  /// Le condensé que Play Integrity scelle dans son jeton : le défi, qui dit
  /// que le jeton est frais, et l'installation, qui dit à qui il appartient.
  /// Le relais le recalcule à l'identique (`integrity.ts`).
  @visibleForTesting
  static String integrityHash(String challenge, String installId) =>
      sha256.convert(utf8.encode('$challenge.$installId')).toString();

  Future<String> _byIntegrity() async {
    final installId = await _installId();
    final challenge = await _challenge();
    final String token;
    try {
      token = await integrity.token(integrityHash(challenge, installId));
    } on PlayIntegrityException catch (e) {
      // Pas de Play Store, pas de réseau, trop de demandes : l'appareil ne
      // peut pas se présenter maintenant. Rien de refusé, rien à oublier.
      throw RelayException('unavailable', 'Play Integrity : ${e.code}');
    }
    return _keep(await _post('attest/integrity', {
      'installId': installId,
      'challenge': challenge,
      'token': token,
    }));
  }

  /// Tiré une fois au sort, puis gardé : 32 octets en base64url, sans
  /// remplissage. Il n'identifie personne — une réinstallation en tire un
  /// neuf.
  Future<String> _installId() async {
    final known = store.installId;
    if (known != null && known.isNotEmpty) return known;
    final random = Random.secure();
    final value = base64Url.encode(List<int>.generate(32, (_) => random.nextInt(256))).replaceAll('=', '');
    await store.setInstallId(value);
    return value;
  }

  Future<String> _byAttestation() async {
    final known = store.keyId;
    if (known != null) {
      try {
        final challenge = await _challenge();
        final assertion = await attest.assertion(known, challenge);
        return _keep(await _post('attest/session', {
          'keyId': known,
          'challenge': challenge,
          'assertion': base64Encode(assertion),
        }));
      } on RelayException catch (e) {
        // Le relais ne connaît plus cet appareil : sa base a été remise à
        // zéro, ou l'appareil en a été retiré. La clé, elle, est encore dans
        // l'enclave — mais Apple refuse d'attester deux fois la même, il en
        // faut donc une neuve.
        if (e.code != 'unknown_device') rethrow;
        await store.setKeyId(null);
      } on AppAttestException catch (e) {
        // Apple ne reconnaît plus la clé : même issue, on en refait une.
        if (e.code != 'invalid_key') rethrow;
        await store.setKeyId(null);
      }
    }

    final keyId = await attest.generateKey();
    final challenge = await _challenge();
    final attestation = await attest.attest(keyId, challenge);
    final token = _keep(await _post('attest/register', {
      'keyId': keyId,
      'challenge': challenge,
      'attestation': base64Encode(attestation),
    }));
    // Gardé après coup : un identifiant écrit puis refusé laisserait
    // l'appareil à retenter indéfiniment une attestation qui ne passe pas.
    await store.setKeyId(keyId);
    return token;
  }

  Future<String> _byDevToken() async => _keep(await _post('attest/dev', {'token': devToken}));

  Future<String> _challenge() async {
    final challenge = (await _post('attest/challenge', const {}))['challenge'];
    if (challenge is! String || challenge.isEmpty) throw const RelayException('refused', 'défi illisible');
    return challenge;
  }

  String _keep(Map<String, dynamic> body) {
    final token = body['token'];
    final seconds = body['expiresIn'];
    if (token is! String || token.isEmpty) throw const RelayException('refused', 'jeton illisible');
    _token = token;
    _expiry = _now().add(Duration(seconds: seconds is int && seconds > 0 ? seconds : 3600));
    return token;
  }

  /// Les échanges de la poignée de main passent par le client intérieur, et
  /// non par celui-ci : `send` demanderait un jeton, qui demanderait une
  /// poignée de main, qui demanderait un jeton.
  Future<Map<String, dynamic>> _post(String route, Map<String, Object?> payload) async {
    final http.Response response;
    try {
      response = await _inner
          .post(
            Uri.parse('$baseUrl/$route'),
            headers: const {'content-type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(_timeout);
    } on Object {
      throw const RelayException('unreachable', 'le relais ne répond pas');
    }

    // Un appareil que le relais ne connaît plus, et lui seul : ailleurs, un
    // 404 est une route absente, donc un relais mal déployé.
    if (response.statusCode == 404 && route == 'attest/session') {
      throw const RelayException('unknown_device');
    }
    if (response.statusCode != 200) throw RelayException('refused', 'relais HTTP ${response.statusCode}');

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) throw const RelayException('refused', 'réponse inattendue');
    return decoded;
  }
}
