// Généré par tool/build_care_scene_assets.py — ne pas éditer à la main.
//
// Positions des emplacements de plante dans le cadre de la scène
// d'environnement idéal, en coordonnées fractionnaires (x depuis la
// gauche, y depuis le haut). La géométrie de tool/care_scene/room.py,
// projetée par la caméra fixe, est la source de vérité : ce fichier est
// régénéré à chaque construction des assets.
abstract final class CareEnvironmentSlots {
  /// Format du cadre (largeur / hauteur).
  static const double aspect = 1.12527;

  /// Point d'ancrage de la plante dans son image : la base du pot,
  /// rendue au centre du monde.
  static const (double, double) anchor = (0.49538, 0.66888);

  /// Centre du plateau du guéridon dans son image : la base du pot
  /// vient s'y poser.
  static const (double, double) pedestalPot = (0.49538, 0.58218);

  /// Les emplacements, nommés comme les valeurs de `CarePlantSlot`.
  static const Map<String, (double, double)> slots = <String, (double, double)>{
    'back': (0.66543, 0.65835),
    'backCorner': (0.71002, 0.67231),
    'beamEdge': (0.53165, 0.61646),
    'besideBeam': (0.57625, 0.63042),
    'middle': (0.62084, 0.64438),
    'sunZone': (0.48706, 0.60250),
  };
  /// L'humidificateur, posé à côté de la plante, par emplacement.
  static const Map<String, (double, double)> humidifier = <String, (double, double)>{
    'back': (0.55043, 0.68335),
    'backCorner': (0.59502, 0.69731),
    'beamEdge': (0.41665, 0.64146),
    'besideBeam': (0.46125, 0.65542),
    'middle': (0.50584, 0.66938),
    'sunZone': (0.37206, 0.62750),
  };

  /// Le haut de l'humidificateur, d'où part la vapeur, par emplacement.
  static const Map<String, (double, double)> humidifierTop = <String, (double, double)>{
    'back': (0.55043, 0.60453),
    'backCorner': (0.59502, 0.61849),
    'beamEdge': (0.41665, 0.56264),
    'besideBeam': (0.46125, 0.57660),
    'middle': (0.50584, 0.59056),
    'sunZone': (0.37206, 0.54868),
  };

  /// D'où souffle l'air à abriter : la fenêtre dans la pièce, l'ouverture au-dessus de la haie dehors, le vide par-dessus le garde-corps sur un balcon.
  static const Map<String, (double, double)> airflow = <String, (double, double)>{
    'balcony': (0.27249, 0.36314),
    'indoor': (0.27464, 0.31695),
    'outdoor': (0.25874, 0.33647),
  };
}
