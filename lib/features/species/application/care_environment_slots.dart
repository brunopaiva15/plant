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
    'back': (0.70399, 0.58717),
    'backCorner': (0.75827, 0.59838),
    'beamEdge': (0.54116, 0.55352),
    'besideBeam': (0.59544, 0.56474),
    'middle': (0.64972, 0.57595),
    'sunZone': (0.48688, 0.54231),
  };

  /// L'humidificateur, posé à côté de la plante, par emplacement.
  static const Map<String, (double, double)> humidifier =
      <String, (double, double)>{
        'back': (0.58899, 0.61217),
        'backCorner': (0.64327, 0.62338),
        'beamEdge': (0.42616, 0.57852),
        'besideBeam': (0.48044, 0.58974),
        'middle': (0.53472, 0.60095),
        'sunZone': (0.37188, 0.56731),
      };

  /// Le haut de l'humidificateur, d'où part la vapeur, par emplacement.
  static const Map<String, (double, double)> humidifierTop =
      <String, (double, double)>{
        'back': (0.58899, 0.54710),
        'backCorner': (0.64327, 0.55831),
        'beamEdge': (0.42616, 0.51345),
        'besideBeam': (0.48044, 0.52467),
        'middle': (0.53472, 0.53588),
        'sunZone': (0.37188, 0.50224),
      };

  /// D'où souffle l'air à abriter : la fenêtre dedans, l'ouverture au-dessus de la haie dehors.
  static const Map<String, (double, double)> airflow =
      <String, (double, double)>{
        'indoor': (0.29062, 0.30704),
        'outdoor': (0.27584, 0.32316),
      };
}
