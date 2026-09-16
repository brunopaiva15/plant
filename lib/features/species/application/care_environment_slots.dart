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
  static const (double, double) anchor = (0.49571, 0.67344);

  /// Les emplacements, nommés comme les valeurs de `CarePlantSlot`.
  static const Map<String, (double, double)> slots = <String, (double, double)>{
    'back': (0.66834, 0.62538),
    'backCorner': (0.73979, 0.67797),
    'middle': (0.54328, 0.73347),
    'nearWindowEdgeOfBeam': (0.38955, 0.54527),
    'nearWindowOutsideBeam': (0.31054, 0.58718),
    'sunZone': (0.46101, 0.59787),
  };

  /// L'humidificateur, posé à côté de la plante, par emplacement.
  static const Map<String, (double, double)> humidifier =
      <String, (double, double)>{
        'back': (0.55334, 0.65038),
        'backCorner': (0.62479, 0.70297),
        'middle': (0.42828, 0.75847),
        'nearWindowEdgeOfBeam': (0.50455, 0.57027),
        'nearWindowOutsideBeam': (0.42554, 0.61218),
        'sunZone': (0.57601, 0.62287),
      };

  /// Le haut de l'humidificateur, d'où part la vapeur, par emplacement.
  static const Map<String, (double, double)> humidifierTop =
      <String, (double, double)>{
        'back': (0.55334, 0.53470),
        'backCorner': (0.62479, 0.58729),
        'middle': (0.42828, 0.64279),
        'nearWindowEdgeOfBeam': (0.50455, 0.45459),
        'nearWindowOutsideBeam': (0.42554, 0.49650),
        'sunZone': (0.57601, 0.50719),
      };

  /// La grille d'aération, sur le mur du fond.
  static const (double, double) vent = (0.78222, 0.15296);
}
