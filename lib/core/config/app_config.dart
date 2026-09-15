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
  /// « Iris 8 » aujourd'hui. Un modèle réentraîné change donc de numéro sans
  /// qu'on touche au code, et l'écran ne peut pas afficher un numéro qui ment.
  static const String modelName = 'Iris';

  /// « Iris 8 » quand le modèle a annoncé sa version, « Iris » tout court
  /// tant qu'il n'a rien dit — pas encore chargé, ou métadonnées absentes.
  static String modelDisplayName([String? version]) =>
      version == null || version.isEmpty ? modelName : '$modelName $version';

  /// Éditeur, tel qu'il apparaît au pied des réglages.
  static const String publisher = 'Vergasta Digital';
  static const String privacyUrl = 'https://vergasta.ch/privacy';

  // Le numéro de version ne s'écrit pas ici : il vit dans `pubspec.yaml`,
  // seul endroit à changer pour une livraison, et `AppVersion` le lit sur le
  // binaire au lancement.

  /// Schéma des liens encodés dans les QR codes (`auxine://plant/<id>`) et
  /// de la redirection déclarée côté Supabase pour la connexion Google. Le
  /// nom de l'application, tel que la personne le voit : une étiquette qui
  /// l'affiche en clair dit d'où elle vient.
  static const String linkScheme = 'auxine';

  /// Fournisseurs tiers proposés sur l'écran Compte, en plus de l'e-mail par
  /// code. Apple est livré (natif, iPhone et iPad, entitlement
  /// `com.apple.developer.applesignin` dans `ios/Runner/Runner.entitlements`).
  /// Google ne l'est pas encore : `signInWithGoogle` reste codé, mais le
  /// bouton n'est pas dessiné tant que ce drapeau est faux. Android n'est pas
  /// la priorité, et la règle 4.8 de l'App Store n'exige Apple qu'en présence
  /// d'un autre fournisseur tiers — proposer Apple seul est permis.
  static const bool googleSignInEnabled = false;

  /// Google Home, en plus d'Apple Maison : mêmes deux nombres — la
  /// température et l'humidité d'une pièce — lus sur les Home APIs, sur
  /// iPhone comme sur Android.
  ///
  /// Vrai : la maison se propose. Mais elle ne répondra que si le SDK des
  /// Home APIs est compilé dans l'application, et il ne l'est pas par
  /// défaut — à la différence de HomeKit, les Home APIs ne sont pas dans le
  /// système, et leur SDK ne se prend ni sur Maven ni sur SwiftPM. Il se
  /// télécharge depuis la console Google Home pour un projet déclaré, avec
  /// son client OAuth, puis se donne à la construction :
  /// `-PgoogleHomeRepo=<dossier>` côté Android, un paquet local ajouté au
  /// projet Xcode côté iOS.
  ///
  /// Donc : une construction **sans** le SDK et avec ce drapeau vrai montre
  /// un bouton « Connecter Google Home » qui répondra toujours « aucun
  /// capteur ». C'est utile pour éprouver l'écran, jamais pour livrer. La
  /// marche à suivre est dans `docs/05-technical-architecture.md`, section
  /// « Google Home ».
  static const bool googleHomeEnabled = true;

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
