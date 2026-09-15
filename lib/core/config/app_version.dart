/// La version de l'application, lue sur le binaire qui tourne.
///
/// Une seule valeur à tenir à jour, la ligne `version:` de `pubspec.yaml` :
/// Flutter la recopie dans `CFBundleShortVersionString` et `CFBundleVersion`
/// côté iOS, dans `versionName` et `versionCode` côté Android, et
/// `package_info_plus` la relit sur le binaire au lancement. Le code n'en
/// garde pas de copie, donc l'écran ne peut plus annoncer un numéro qui ment
/// — il l'avait fait deux fois, 0.1.0 pour une application en 1.0.0, puis la
/// build 3 pour une application compilée en 4.
///
/// Fournie par `appVersionProvider`, que `main()` remplace par la valeur
/// lue. Les tests qui en ont besoin la remplacent aussi : hors d'un binaire
/// installé, il n'y a pas de version à lire.
class AppVersion {
  const AppVersion({required this.name, required this.build});

  /// La partie visible du numéro, « 1.0.0 ».
  final String name;

  /// Le numéro de compilation, « 4 ». Une chaîne, et non un entier : c'est
  /// ce que les deux plateformes donnent, et iOS accepte des numéros à
  /// plusieurs segments qu'un `int` ne saurait pas porter.
  final String build;

  /// « 1.0.0 (4) », la forme montrée au pied des réglages.
  String get label => '$name ($build)';
}
