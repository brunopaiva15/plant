import '../../core/network/relay_client.dart';
import 'preferences_service.dart';

/// L'identifiant de la clé App Attest, gardé avec les autres réglages.
///
/// Rien à chiffrer ici : c'est le condensé d'une clé publique, et la partie
/// privée ne quitte jamais la Secure Enclave. Ce qu'on veut, c'est qu'il
/// survive au redémarrage — une clé neuve à chaque lancement finirait par
/// buter sur les limites d'attestation d'Apple.
class PreferencesRelayKeyStore implements RelayKeyStore {
  const PreferencesRelayKeyStore(this._prefs);

  final PreferencesService _prefs;

  @override
  String? get keyId => _prefs.appAttestKeyId;

  @override
  Future<void> setKeyId(String? value) => _prefs.setAppAttestKeyId(value);
}
