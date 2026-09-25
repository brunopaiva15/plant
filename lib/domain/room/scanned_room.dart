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

/// Ce qui habille une fenêtre. RoomPlan ne le voit pas ; la main le dit.
enum WindowDressing {
  none,

  /// Un voilage : la lumière divisée par deux, et plus de soleil direct.
  sheer,

  /// Un rideau ou un store souvent tiré : la lumière divisée par trois.
  drawn;

  double get factor => switch (this) { none => 1.0, sheer => 0.5, drawn => 1 / 3 };
}

/// La taille d'une fenêtre que la main ajoute, quand le relevé l'a manquée
/// — RoomPlan ne voit pas une fenêtre derrière un rideau tiré. Le relevé ne
/// mesure rien ici : chaque taille porte ses trois dimensions, et le genre
/// du repère dit laquelle, comme il dit le voilage et le rideau.
enum HandWindow {
  small(width: 0.6, height: 0.8, sill: 1.1),
  standard(width: 1.2, height: 1.3, sill: 0.9),
  wide(width: 2.2, height: 2.1, sill: 0.05);

  const HandWindow({required this.width, required this.height, required this.sill});

  final double width;
  final double height;

  /// La hauteur de l'appui au-dessus du sol.
  final double sill;
}

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
    this.byHand = false,
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

  /// La main l'a ajoutée, le capteur ne l'a pas vue : une fenêtre derrière
  /// un rideau tiré, que RoomPlan manque.
  final bool byHand;

  double get topY => bottomY + height;
  double get area => width * height;
  RoomPoint get start => center - along.scale(width / 2);
  RoomPoint get end => center + along.scale(width / 2);

  /// Le même découpage lu comme une fenêtre : la géométrie ne change pas,
  /// le genre si. C'est par là qu'un vide éclaire — celui que RoomPlan n'a
  /// pas reconnu comme fenêtre, celui d'un balcon, celui que la main
  /// désigne.
  RoomSurface asWindow({bool byHand = false}) => RoomSurface(
        kind: RoomSurfaceKind.window,
        center: center,
        along: along,
        normal: normal,
        width: width,
        height: height,
        bottomY: bottomY,
        parentId: parentId,
        id: id,
        byHand: byHand,
      );
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

  /// La même pièce lue comme un balcon ou une terrasse : les ouvertures —
  /// le côté sans mur — éclairent comme des fenêtres, à la suite des
  /// fenêtres pour que leurs rangs ne bougent pas ; dehors, l'air bouge
  /// partout, et une porte n'y change rien.
  ScannedRoom asOutdoor() => ScannedRoom(
        walls: walls,
        windows: [...windows, for (final o in openings) o.asWindow()],
        doors: const [],
        openings: const [],
        objects: objects,
        floorPolygon: floorPolygon,
        section: section,
        northOffsetDeg: northOffsetDeg,
      );

  /// Le point d'un mur le plus proche, à moins de [within] : un radiateur
  /// se pose contre un mur, et le doigt vise à côté.
  RoomPoint snapToWall(RoomPoint p, {double within = 0.5}) {
    final wall = nearestWall(p);
    if (wall == null) return p;
    final onWall = _onSurface(wall, p);
    return (p - onWall).length < within ? onWall : p;
  }

  /// Le mur le plus proche d'un point, quelle que soit la distance ; `null`
  /// quand la pièce n'a pas de mur.
  RoomSurface? nearestWall(RoomPoint p) {
    RoomSurface? best;
    var bestD = double.infinity;
    for (final w in walls) {
      final dist = (p - _onSurface(w, p)).length;
      if (dist < bestD) {
        bestD = dist;
        best = w;
      }
    }
    return best;
  }

  /// Le point d'une surface le plus proche d'un point, sans sortir de son
  /// segment : un mur, ou ce qui s'y découpe.
  static RoomPoint _onSurface(RoomSurface surface, RoomPoint p) {
    final t = (p - surface.start).dot(surface.along).clamp(0.0, surface.width);
    return surface.start + surface.along.scale(t);
  }

  /// De combien un vide l'emporte sur le mur qui le porte, quand le doigt
  /// vise les deux : un trou est dans le plan de son mur, et RoomPlan les
  /// ajuste séparément — dix centimètres les séparent au pire.
  static const double openingMargin = 0.1;

  /// Le vide que le doigt vise : celui dont le segment est au moins aussi
  /// proche que le mur le plus proche. Un vide est dans le plan de son
  /// mur : viser l'un, c'est viser l'autre, et le vide l'emporte là où il
  /// perce. `null` quand le doigt vise le mur plein.
  RoomSurface? openingAt(RoomPoint p) {
    final wall = nearestWall(p);
    final wallD = wall == null ? double.infinity : (p - _onSurface(wall, p)).length;
    RoomSurface? best;
    var bestD = double.infinity;
    for (final o in openings) {
      final dist = (p - _onSurface(o, p)).length;
      if (dist < bestD) {
        bestD = dist;
        best = o;
      }
    }
    return best != null && bestD <= wallD + openingMargin ? best : null;
  }

  /// La fenêtre que la main pose au plus près d'un point : elle se couche
  /// sur le mur le plus proche — c'est lui qui lui donne son orientation —,
  /// sans déborder de ses bords, et prend les dimensions de sa taille.
  /// `null` quand la pièce n'a pas de mur pour la porter.
  ///
  /// Sauf sur un vide du relevé : RoomPlan range dans les ouvertures la
  /// fenêtre qu'il n'a pas reconnue, et ce trou-là, lui, est mesuré. La
  /// fenêtre en prend la place et les dimensions plutôt que celles de sa
  /// taille, et le vide lui cède la sienne ([withWindows]).
  RoomSurface? handWindowAt(RoomPoint p, HandWindow size) {
    final opening = openingAt(p);
    if (opening != null) return opening.asWindow(byHand: true);
    final wall = nearestWall(p);
    if (wall == null) return null;
    final width = math.min(size.width, wall.width);
    final half = width / 2;
    // `clamp` ne rend un double que si ses deux bornes en sont statiquement :
    // `toDouble` le garantit, sinon `scale` reçoit un num et la compilation
    // échoue.
    final t = (p - wall.start).dot(wall.along).clamp(half, math.max(half, wall.width - half)).toDouble();
    return RoomSurface(
      kind: RoomSurfaceKind.window,
      center: wall.start + wall.along.scale(t),
      along: wall.along,
      normal: wall.normal,
      width: width,
      height: size.height,
      bottomY: floorY + size.sill,
      parentId: wall.id,
      byHand: true,
    );
  }

  /// La même pièce avec des fenêtres de plus, à la suite des siennes : les
  /// rangs des fenêtres du relevé ne bougent pas, et les ouvertures d'un
  /// balcon ([asOutdoor]) viennent encore après.
  ///
  /// Un vide qu'une de ces fenêtres recouvre n'en est plus un : il ne fait
  /// plus courant d'air, et dehors il n'éclaire pas une seconde fois.
  ScannedRoom withWindows(List<RoomSurface> extra) => extra.isEmpty
      ? this
      : ScannedRoom(
          walls: walls,
          windows: [...windows, ...extra],
          doors: doors,
          openings: [
            for (final o in openings)
              if (!extra.any((w) => _covers(w, o))) o,
          ],
          objects: objects,
          floorPolygon: floorPolygon,
          section: section,
          northOffsetDeg: northOffsetDeg,
        );

  /// Une fenêtre recouvre-t-elle ce vide ? Par son identifiant quand le
  /// relevé en donne un, par sa place sinon.
  static bool _covers(RoomSurface window, RoomSurface opening) => window.id != null && opening.id != null
      ? window.id == opening.id
      : window.center.distanceTo(opening.center) < 0.05;

  /// Le vide dont l'appui est au moins à cette hauteur du sol ne se
  /// traverse pas : c'est une fenêtre.
  static const double windowSillMin = 0.4;

  /// La même pièce, les vides qui ne se traversent pas lus comme des
  /// fenêtres. RoomPlan range dans les ouvertures ce qu'il n'a pas reconnu
  /// comme fenêtre — un vitrage derrière un rideau, une baie, un jour de
  /// travers —, et un trou dont l'appui est à quarante centimètres du sol
  /// n'est pas un passage. Elles viennent à la suite des fenêtres du
  /// relevé : les rangs tiennent, et l'orientation comme le rideau
  /// continuent de s'indexer par le rang.
  ScannedRoom withRaisedOpeningsAsWindows() {
    bool raised(RoomSurface o) => o.bottomY - floorY >= windowSillMin;
    if (!openings.any(raised)) return this;
    return ScannedRoom(
      walls: walls,
      windows: [
        ...windows,
        for (final o in openings)
          if (raised(o)) o.asWindow(),
      ],
      doors: doors,
      openings: [
        for (final o in openings)
          if (!raised(o)) o,
      ],
      objects: objects,
      floorPolygon: floorPolygon,
      section: section,
      northOffsetDeg: northOffsetDeg,
    );
  }

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
bool segmentsCross(RoomPoint a, RoomPoint b, RoomPoint c, RoomPoint d) => crossFraction(a, b, c, d) != null;

/// La fraction du segment *a → b* où il croise *c – d*, ou `null` s'ils ne
/// se croisent pas : une visée sait ainsi où elle rencontre un obstacle,
/// et pas seulement qu'elle le rencontre.
double? crossFraction(RoomPoint a, RoomPoint b, RoomPoint c, RoomPoint d) {
  double orient(RoomPoint p, RoomPoint q, RoomPoint r) => (q.x - p.x) * (r.z - p.z) - (q.z - p.z) * (r.x - p.x);
  final o1 = orient(a, b, c), o2 = orient(a, b, d), o3 = orient(c, d, a), o4 = orient(c, d, b);
  if (o1 * o2 >= 0 || o3 * o4 >= 0) return null;
  return o3 / (o3 - o4);
}
