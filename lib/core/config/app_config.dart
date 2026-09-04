/// Configuration de marque et limites produit.
///
/// Le nom de travail est « Flora ». Rien d'autre dans le code ne dépend du nom :
/// changer [appName] suffit à rebrander l'application.
abstract final class AppConfig {
  static const String appName = 'Flora';
  static const String bundleId = 'ch.vergasta.plant';

  /// Schéma des liens encodés dans les QR codes (`flora://plant/<id>`).
  static const String linkScheme = 'flora';

  /// Limite de plantes actives de l'offre gratuite (freemium, non agressif).
  static const int freePlantLimit = 10;

  /// Durée pendant laquelle une action peut être annulée.
  static const Duration undoWindow = Duration(seconds: 5);

  /// Fenêtre « à venir » de l'écran Aujourd'hui.
  static const int upcomingDays = 7;

  /// Intervalles par défaut (jours) des routines créées avec une plante.
  static const int defaultWateringInterval = 7;
  static const int defaultFertilizingInterval = 30;
}
