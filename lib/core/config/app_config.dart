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

  /// Nom du modèle de reconnaissance embarqué, tel que l'utilisateur le voit.
  ///
  /// Le numéro de version ne s'écrit pas ici : le modèle l'annonce lui-même
  /// dans `assets/model/model.json`, et [modelDisplayName] le colle au nom —
  /// « Iris 6 ». Un modèle réentraîné change donc de numéro sans qu'on touche
  /// au code, et l'écran ne peut pas afficher un numéro qui ment.
  static const String modelName = 'Iris';

  /// « Iris 6 » quand le modèle a annoncé sa version, « Iris » tout court
  /// tant qu'il n'a rien dit — pas encore chargé, ou métadonnées absentes.
  static String modelDisplayName([String? version]) =>
      version == null || version.isEmpty ? modelName : '$modelName $version';

  /// Éditeur, tel qu'il apparaît au pied des réglages.
  static const String publisher = 'Vergasta Digital';
  static const String privacyUrl = 'https://vergasta.ch/privacy';

  /// Version et numéro de compilation, recopiés de `pubspec.yaml`.
  ///
  /// Recopiés, donc susceptibles de dériver — c'était déjà arrivé, l'écran
  /// annonçait 0.1.0 pour une application en 1.0.0. Un test les compare
  /// désormais au pubspec et échoue si les deux divergent.
  static const String version = '1.0.0';
  static const int build = 1;

  /// Schéma des liens encodés dans les QR codes (`flora://plant/<id>`).
  ///
  /// Il garde le nom de travail : les étiquettes déjà imprimées le portent,
  /// et c'est aussi l'URL de redirection déclarée côté Supabase pour la
  /// connexion Google. Rien de tout cela n'est visible dans l'application.
  static const String linkScheme = 'flora';

  /// Fournisseurs tiers proposés sur l'écran Compte, en plus de l'e-mail par
  /// code. Apple est livré (natif, iPhone et iPad, entitlement
  /// `com.apple.developer.applesignin` dans `ios/Runner/Runner.entitlements`).
  /// Google ne l'est pas encore : `signInWithGoogle` reste codé, mais le
  /// bouton n'est pas dessiné tant que ce drapeau est faux. Android n'est pas
  /// la priorité, et la règle 4.8 de l'App Store n'exige Apple qu'en présence
  /// d'un autre fournisseur tiers — proposer Apple seul est permis.
  static const bool googleSignInEnabled = false;

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
