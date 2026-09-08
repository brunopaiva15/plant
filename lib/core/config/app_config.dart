/// Configuration de marque et limites produit.
///
/// Le produit s'appelle « Auxine ». Le code, lui, garde son nom de travail
/// (« Flora » : classes du design system, paquet Dart, schéma des liens) —
/// rien d'autre que [appName] ne porte le nom vu par l'utilisateur.
abstract final class AppConfig {
  static const String appName = 'Auxine';

  /// Noms portés avant « Auxine ». Les sauvegardes faites alors restent
  /// importables : leur manifeste annonce encore l'ancien nom.
  static const List<String> legacyAppNames = ['Flora', 'Auxin'];
  static const String bundleId = 'ch.vergasta.plant';

  /// Schéma des liens encodés dans les QR codes (`flora://plant/<id>`).
  ///
  /// Il garde le nom de travail : les étiquettes déjà imprimées le portent,
  /// et c'est aussi l'URL de redirection déclarée côté Supabase pour la
  /// connexion Google. Rien de tout cela n'est visible dans l'application.
  static const String linkScheme = 'flora';

  /// Achat unique, facultatif, qui ne déverrouille rien : l'application est
  /// entière et gratuite. Voir `SupportService`.
  static const String supportProductId = 'ch.vergasta.plant.support';

  /// Durée pendant laquelle une action peut être annulée.
  static const Duration undoWindow = Duration(seconds: 5);

  /// Fenêtre « à venir » de l'écran Aujourd'hui.
  static const int upcomingDays = 7;

  /// Intervalles par défaut (jours) des routines créées avec une plante.
  static const int defaultWateringInterval = 7;
  static const int defaultFertilizingInterval = 30;
}
