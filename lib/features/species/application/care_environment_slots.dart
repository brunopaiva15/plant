// Généré par tool/build_care_scene_assets.py — ne pas éditer à la main.
//
// Positions des emplacements de plante dans le cadre de la scène
// d'environnement idéal, en coordonnées fractionnaires (x depuis la
// gauche, y depuis le haut). La géométrie de tool/care_scene/room.py,
// projetée par la caméra fixe, est la source de vérité : ce fichier est
// régénéré à chaque construction des assets.
abstract final class CareEnvironmentSlots {
  /// Format du cadre (largeur / hauteur).
  static const double aspect = 1.00;

  /// Point d'ancrage de la plante dans son image : la base du pot,
  /// rendue au centre du monde.
  static const (double, double) anchor = (0.49571, 0.59756);

  /// Les emplacements, nommés comme les valeurs de `CarePlantSlot`.
  static const Map<String, (double, double)> slots = <String, (double, double)>{
    'back': (0.66834, 0.57053),
    'backCorner': (0.73979, 0.60011),
    'middle': (0.54328, 0.63133),
    'nearWindowEdgeOfBeam': (0.38955, 0.52547),
    'nearWindowOutsideBeam': (0.31054, 0.54904),
    'sunZone': (0.46101, 0.55505),
  };

  /// L'humidificateur, posé à côté de la plante, par emplacement.
  static const Map<String, (double, double)> humidifier =
      <String, (double, double)>{
        'back': (0.55334, 0.59553),
        'backCorner': (0.62479, 0.62511),
        'middle': (0.42828, 0.65633),
        'nearWindowEdgeOfBeam': (0.50455, 0.55047),
        'nearWindowOutsideBeam': (0.42554, 0.57404),
        'sunZone': (0.57601, 0.58005),
      };

  /// Le haut de l'humidificateur, d'où part la vapeur, par emplacement.
  static const Map<String, (double, double)> humidifierTop =
      <String, (double, double)>{
        'back': (0.55334, 0.53046),
        'backCorner': (0.62479, 0.56004),
        'middle': (0.42828, 0.59126),
        'nearWindowEdgeOfBeam': (0.50455, 0.48540),
        'nearWindowOutsideBeam': (0.42554, 0.50897),
        'sunZone': (0.57601, 0.51498),
      };

  /// D'où souffle l'air à abriter : la fenêtre dedans, l'ouverture au-dessus de la haie dehors.
  static const Map<String, (double, double)> airflow =
      <String, (double, double)>{
        'indoor': (0.29062, 0.30704),
        'outdoor': (0.27584, 0.32316),
      };
}
