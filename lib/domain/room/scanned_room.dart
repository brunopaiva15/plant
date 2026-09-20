/// Une pièce relevée par RoomPlan, réduite à ce que le modèle de lumière
/// lit : des murs, des fenêtres, des portes, des meubles, un sol.
///
/// Le repère est celui d'ARKit, en mètres : *x* et *z* au sol, *y* vers le
/// haut. Il est orienté au hasard au lancement du relevé ; le nord n'y
/// existe que par [ScannedRoom.northOffsetDeg], mesuré à part.
///
/// Rien n'est inventé : un champ absent du JSON vaut une liste vide, jamais
/// une erreur — un relevé sans porte est un relevé sans porte.
library;

import 'dart:math' as math;

/// Un point au sol, en mètres.
class RoomPoint {
  const RoomPoint(this.x, this.z);

  final double x;
  final double z;

  double distanceTo(RoomPoint o) => math.sqrt((x - o.x) * (x - o.x) + (z - o.z) * (z - o.z));

  RoomPoint operator +(RoomPoint o) => RoomPoint(x + o.x, z + o.z);
  RoomPoint operator -(RoomPoint o) => RoomPoint(x - o.x, z - o.z);
  RoomPoint scale(double k) => RoomPoint(x * k, z * k);
  double dot(RoomPoint o) => x * o.x + z * o.z;
  double get length => math.sqrt(x * x + z * z);
  RoomPoint get normalized => length == 0 ? this : scale(1 / length);

  @override
  bool operator ==(Object other) => other is RoomPoint && other.x == x && other.z == z;

  @override
  int get hashCode => Object.hash(x, z);

  @override
  String toString() => 'RoomPoint($x, $z)';
}

/// Les huit points cardinaux, dans l'ordre de la boussole.
enum CardinalDirection {
  north,
  northEast,
  east,
  southEast,
  south,
  southWest,
  west,
  northWest;

  /// Le cap du point, en degrés depuis le nord, dans le sens horaire.
  double get bearing => index * 45.0;

  /// Le point le plus proche d'un cap.
  static CardinalDirection fromBearing(double degrees) {
    final norm = ((degrees % 360) + 360) % 360;
    return CardinalDirection.values[((norm + 22.5) ~/ 45) % 8];
  }
}

enum RoomSurfaceKind { wall, window, door, opening }

/// Une surface plane : un mur, ou ce qui s'y découpe.
class RoomSurface {
  const RoomSurface({
    required this.kind,
    required this.center,
    required this.along,
    required this.normal,
    required this.width,
    required this.height,
    required this.bottomY,
    this.parentId,
    this.id,
  });

  final RoomSurfaceKind kind;

  /// Le centre au sol.
  final RoomPoint center;

  /// La direction de la largeur, unitaire.
  final RoomPoint along;

  /// La normale au sol, unitaire, d'un côté ou de l'autre : RoomPlan ne dit
  /// pas lequel. [ScannedRoom.inwardNormal] tranche.
  final RoomPoint normal;
  final double width;
  final double height;

  /// Le bas de la surface, en mètres : l'appui d'une fenêtre, le sol d'un mur.
  final double bottomY;
  final String? parentId;
  final String? id;

  double get topY => bottomY + height;
  double get area => width * height;
  RoomPoint get start => center - along.scale(width / 2);
  RoomPoint get end => center + along.scale(width / 2);
}

/// Un objet reconnu : son empreinte au sol et sa hauteur.
class RoomObject {
  const RoomObject({
    required this.category,
    required this.center,
    required this.along,
    required this.width,
    required this.length,
    required this.height,
    required this.bottomY,
  });

  /// La catégorie RoomPlan, telle quelle (`table`, `storage`, `sofa`…).
  final String category;
  final RoomPoint center;
  final RoomPoint along;
  final double width;
  final double length;
  final double height;
  final double bottomY;

  double get topY => bottomY + height;
  RoomPoint get across => RoomPoint(-along.z, along.x);

  /// Les quatre coins de l'empreinte, dans l'ordre.
  List<RoomPoint> get corners {
    final a = along.scale(width / 2);
    final b = across.scale(length / 2);
    return [center + a + b, center - a + b, center - a - b, center + a - b];
  }

  bool contains(RoomPoint p) {
    final d = p - center;
    return d.dot(along).abs() <= width / 2 && d.dot(across).abs() <= length / 2;
  }
}

/// Le type de pièce que RoomPlan reconnaît, sur iOS 17.
enum RoomSectionLabel {
  bathroom,
  bedroom,
  diningRoom,
  kitchen,
  laundryRoom,
  livingRoom;

  static RoomSectionLabel? decode(String? raw) => switch (raw) {
        'bathroom' => bathroom,
        'bedroom' => bedroom,
        'diningRoom' => diningRoom,
        'kitchen' => kitchen,
        'laundryRoom' => laundryRoom,
        'livingRoom' => livingRoom,
        _ => null,
      };

  /// Une pièce d'eau : l'air y est plus humide que dans le reste de la maison.
  bool get isHumid => this == bathroom || this == kitchen || this == laundryRoom;
}

class ScannedRoom {
  ScannedRoom({
    required this.walls,
    required this.windows,
    required this.doors,
    required this.openings,
    required this.objects,
    this.floorPolygon = const [],
    this.section,
    this.northOffsetDeg,
  });

  final List<RoomSurface> walls;
  final List<RoomSurface> windows;
  final List<RoomSurface> doors;
  final List<RoomSurface> openings;
  final List<RoomObject> objects;

  /// Le contour du sol, quand RoomPlan le donne (iOS 17). Sinon vide, et
  /// [contains] se rabat sur la boîte des murs.
  final List<RoomPoint> floorPolygon;
  final RoomSectionLabel? section;

  /// Le cap, dans le repère du relevé, de la direction qui pointe vers le
  /// nord : mesuré pendant le relevé par la boussole et le lacet de la
  /// caméra. `null` quand la boussole n'a rien donné de stable.
  final double? northOffsetDeg;

  /// Le milieu de la pièce, d'après ses murs : c'est de là qu'on regarde
  /// pour savoir de quel côté d'une surface est l'intérieur.
  late final RoomPoint centroid = _centroid();

  RoomPoint _centroid() {
    final pts = floorPolygon.isNotEmpty ? floorPolygon : [for (final w in walls) w.center];
    if (pts.isEmpty) return const RoomPoint(0, 0);
    var x = 0.0, z = 0.0;
    for (final p in pts) {
      x += p.x;
      z += p.z;
    }
    return RoomPoint(x / pts.length, z / pts.length);
  }

  /// Le sol, en hauteur : le bas du mur le plus bas, ou zéro.
  late final double floorY = walls.isEmpty ? 0 : walls.map((w) => w.bottomY).reduce(math.min);

  /// La boîte des murs, ou du contour du sol : (minX, minZ, maxX, maxZ).
  late final (double, double, double, double) bounds = _bounds();

  (double, double, double, double) _bounds() {
    final pts = floorPolygon.isNotEmpty ? floorPolygon : [for (final w in walls) ...[w.start, w.end]];
    if (pts.isEmpty) return (0, 0, 0, 0);
    var minX = double.infinity, minZ = double.infinity, maxX = -double.infinity, maxZ = -double.infinity;
    for (final p in pts) {
      minX = math.min(minX, p.x);
      minZ = math.min(minZ, p.z);
      maxX = math.max(maxX, p.x);
      maxZ = math.max(maxZ, p.z);
    }
    return (minX, minZ, maxX, maxZ);
  }

  /// La surface au sol, en m², d'après le contour ou la boîte.
  double get floorAreaM2 {
    if (floorPolygon.length >= 3) {
      var s = 0.0;
      for (var i = 0; i < floorPolygon.length; i++) {
        final a = floorPolygon[i], b = floorPolygon[(i + 1) % floorPolygon.length];
        s += a.x * b.z - b.x * a.z;
      }
      return s.abs() / 2;
    }
    final (minX, minZ, maxX, maxZ) = bounds;
    return (maxX - minX) * (maxZ - minZ);
  }

  /// La normale d'une surface tournée vers l'intérieur de la pièce.
  RoomPoint inwardNormal(RoomSurface s) => (centroid - s.center).dot(s.normal) >= 0 ? s.normal : s.normal.scale(-1);

  /// Le point est-il dans la pièce ? Par le contour du sol s'il existe, par
  /// la boîte des murs sinon.
  bool contains(RoomPoint p) {
    if (floorPolygon.length >= 3) return _inPolygon(p, floorPolygon);
    final (minX, minZ, maxX, maxZ) = bounds;
    return p.x >= minX && p.x <= maxX && p.z >= minZ && p.z <= maxZ;
  }

  /// Le cap compas d'une direction du relevé, si le nord est connu.
  double? bearingOf(RoomPoint direction) {
    final offset = northOffsetDeg;
    if (offset == null) return null;
    return (((headingOf(direction) - offset) % 360) + 360) % 360;
  }

  /// Le cap d'une direction dans le repère d'ARKit : zéro vers −z, quatre-vingt-dix vers +x.
  static double headingOf(RoomPoint d) => ((math.atan2(d.x, -d.z) * 180 / math.pi) % 360 + 360) % 360;

  /// L'orientation d'une fenêtre : le côté dehors de sa normale, lu à la boussole.
  CardinalDirection? windowDirection(RoomSurface window) {
    final b = bearingOf(inwardNormal(window).scale(-1));
    return b == null ? null : CardinalDirection.fromBearing(b);
  }

  static bool _inPolygon(RoomPoint p, List<RoomPoint> poly) {
    var inside = false;
    for (var i = 0, j = poly.length - 1; i < poly.length; j = i++) {
      final a = poly[i], b = poly[j];
      if ((a.z > p.z) != (b.z > p.z) && p.x < (b.x - a.x) * (p.z - a.z) / (b.z - a.z) + a.x) inside = !inside;
    }
    return inside;
  }
}

/// Deux segments au sol se croisent-ils ?
bool segmentsCross(RoomPoint a, RoomPoint b, RoomPoint c, RoomPoint d) {
  double orient(RoomPoint p, RoomPoint q, RoomPoint r) => (q.x - p.x) * (r.z - p.z) - (q.z - p.z) * (r.x - p.x);
  final o1 = orient(a, b, c), o2 = orient(a, b, d), o3 = orient(c, d, a), o4 = orient(c, d, b);
  return o1 * o2 < 0 && o3 * o4 < 0;
}
