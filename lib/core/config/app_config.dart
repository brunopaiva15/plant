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
  /// Le code est écrit et vérifié des deux côtés — le Kotlin compile contre
  /// le SDK réel, le Swift lit de vrais capteurs sur un iPhone —, et le
  /// drapeau est pourtant faux. Les Home APIs plafonnent à cent comptes
  /// tant que le projet n'est pas enregistré dans la console Google Home, et
  /// cette console n'ouvre pas encore ses inscriptions. Cent comptes, c'est
  /// un bouton qui marche pour les premiers et échoue pour les suivants.
  ///
  /// Le passer à vrai demande aussi le SDK à la construction : il ne se
  /// prend ni sur Maven ni sur SwiftPM, mais se télécharge pour un projet
  /// déclaré, puis se donne à la construction — `-PgoogleHomeRepo=<dossier>`
  /// côté Android, un paquet local ajouté au projet Xcode côté iOS, qui
  /// demande iOS 17. Sans lui, le bouton « Connecter Google Home » répondra
  /// toujours « aucun capteur ». La marche à suivre est dans
  /// `docs/05-technical-architecture.md`, section « Google Home ».
  static const bool googleHomeEnabled = false;

  /// La ligne « Google Home · Bientôt » de Profil › Capteurs de la maison.
  /// Elle dit une intégration écrite mais pas ouverte, et ne sert donc que
  /// tant que [googleHomeEnabled] est faux : Google Home branché, Google
  /// Home devient une maison comme une autre, avec son bouton.
  static const bool googleHomeSoon = true;

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
