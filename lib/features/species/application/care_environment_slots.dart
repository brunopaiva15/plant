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

  /// Centre du plateau du guéridon dans son image : la base du pot
  /// vient s'y poser.
  static const (double, double) pedestalPot = (0.49571, 0.52598);

  /// Les emplacements, nommés comme les valeurs de `CarePlantSlot`.
  static const Map<String, (double, double)> slots = <String, (double, double)>{
    'back': (0.65370, 0.58886),
    'backCorner': (0.69513, 0.60038),
    'beamEdge': (0.52941, 0.55429),
    'besideBeam': (0.57084, 0.56581),
    'middle': (0.61227, 0.57733),
    'sunZone': (0.48798, 0.54276),
  };
  /// L'humidificateur, posé à côté de la plante, par emplacement.
  static const Map<String, (double, double)> humidifier = <String, (double, double)>{
    'back': (0.53870, 0.61386),
    'backCorner': (0.58013, 0.62538),
    'beamEdge': (0.41441, 0.57929),
    'besideBeam': (0.45584, 0.59081),
    'middle': (0.49727, 0.60233),
    'sunZone': (0.37298, 0.56776),
  };

  /// Le haut de l'humidificateur, d'où part la vapeur, par emplacement.
  static const Map<String, (double, double)> humidifierTop = <String, (double, double)>{
    'back': (0.53870, 0.54879),
    'backCorner': (0.58013, 0.56031),
    'beamEdge': (0.41441, 0.51422),
    'besideBeam': (0.45584, 0.52574),
    'middle': (0.49727, 0.53726),
    'sunZone': (0.37298, 0.50269),
  };

  /// D'où souffle l'air à abriter : la fenêtre dans la pièce, l'ouverture au-dessus de la haie dehors, le vide par-dessus le garde-corps sur un balcon.
  static const Map<String, (double, double)> airflow = <String, (double, double)>{
    'balcony': (0.28862, 0.34518),
    'indoor': (0.29062, 0.30704),
    'outdoor': (0.27584, 0.32316),
  };
}
