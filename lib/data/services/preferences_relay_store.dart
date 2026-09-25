import '../../core/network/relay_client.dart';
import 'preferences_service.dart';

/// L'identifiant de la clé App Attest, et celui de l'installation sur
/// Android, gardés avec les autres réglages.
///
/// Rien à chiffrer ici : le premier est le condensé d'une clé publique, dont
/// la partie privée ne quitte jamais la Secure Enclave ; le second est tiré
/// au sort. Ce qu'on veut, c'est qu'ils survivent au redémarrage — une clé
/// neuve à chaque lancement finirait par buter sur les limites
/// d'attestation d'Apple.
class PreferencesRelayKeyStore implements RelayKeyStore {
  const PreferencesRelayKeyStore(this._prefs);

  final PreferencesService _prefs;

  @override
  String? get keyId => _prefs.appAttestKeyId;

  @override
  Future<void> setKeyId(String? value) => _prefs.setAppAttestKeyId(value);

  @override
  String? get installId => _prefs.relayInstallId;

  @override
  Future<void> setInstallId(String value) => _prefs.setRelayInstallId(value);
}
