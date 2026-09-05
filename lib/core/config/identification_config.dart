/// Clé du service d'identification Pl@ntNet, fournie au build :
/// `flutter build --dart-define=PLANTNET_API_KEY=…`
///
/// La clé appartient à l'éditeur, pas à l'utilisateur : l'identification en
/// ligne fait partie de l'application, personne n'a à créer de compte chez un
/// tiers pour s'en servir.
///
/// Une clé compilée dans un binaire mobile est extractible par qui démonte le
/// paquet — c'est vrai de toutes les applications qui en embarquent une. Le
/// quota journalier et le modèle embarqué, qui absorbe la majorité des
/// demandes, limitent ce que cela coûterait. Le jour où l'usage le justifie,
/// la parade est un relais côté serveur qui garde la clé et signe les
/// requêtes ; `PlantNetIdentifier` n'aurait alors qu'à changer d'URL.
abstract final class IdentificationConfig {
  static const String plantNetApiKey = String.fromEnvironment('PLANTNET_API_KEY');

  static bool get isConfigured => plantNetApiKey.isNotEmpty;
}
