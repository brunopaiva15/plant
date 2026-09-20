import 'dart:math' as math;

import '../care/care_profile.dart';
import 'scanned_room.dart';

/// Ce qu'un point d'une pièce relevée reçoit de ses fenêtres, en crans de
/// [LightNeed] : pur, sans capteur, sans widget.
///
/// Pour chaque fenêtre visible du point, un apport — aire × orientation ×
/// cos α / d² — et les apports s'additionnent. La tache de soleil tranche
/// les deux crans du haut ; six seuils font le reste. Ce n'est pas un
/// facteur de lumière du jour : c'est une heuristique qui rend les six crans
/// dans le bon ordre, et qui est **calibrée sur la pièce du diorama**
/// (docs/13, « Les six lumières ») — `test/domain/room_light_model_test.dart`
/// exige que les six emplacements de la scène rendent leurs six crans.
/// Déplacer un seuil casse ce test avant de casser une fiche.
abstract final class RoomLightModel {
  /// Le facteur d'une orientation, hémisphère nord ; le sud le lit en miroir.
  static double orientationFactor(CardinalDirection? d, {bool southern = false}) {
    if (d == null) return unknownOrientationFactor;
    final dir = southern ? _mirror(d) : d;
    return switch (dir) {
      CardinalDirection.south => 1.0,
      CardinalDirection.southEast || CardinalDirection.southWest => 0.85,
      CardinalDirection.east || CardinalDirection.west => 0.6,
      CardinalDirection.northEast || CardinalDirection.northWest => 0.4,
      CardinalDirection.north => 0.3,
    };
  }

  /// Une fenêtre dont on ne sait pas où elle donne compte comme une fenêtre
  /// à l'est ou à l'ouest, et n'a pas de tache de soleil.
  static const double unknownOrientationFactor = 0.6;

  /// Sous ce rayon, une fenêtre n'éclaire pas plus fort : on ne se colle pas
  /// à la vitre.
  static const double minDistance = 0.5;

  /// La hauteur à laquelle la lumière se lit pour un pot posé au sol.
  static const double potHeight = 0.3;

  /// Les seuils d'apport, du plus clair au plus sombre, hors tache de soleil.
  static const double brightIndirectAt = 0.38;
  static const double indirectAt = 0.29;
  static const double lowLightAt = 0.225;

  /// La portée de la tache de soleil, en fraction de la hauteur du haut de
  /// la fenêtre au-dessus du sol : un soleil à 45°, celui d'une mi-saison.
  static const double sunReachPerHeight = 1.0;

  /// Le dernier cinquième de la tache est son bord : le soleil n'y passe
  /// qu'une partie de la journée.
  static const double sunEdgeFraction = 0.8;

  /// L'apport total d'un point, et s'il est dans la tache de soleil.
  static LightSample sample(ScannedRoom room, RoomPoint p, {required double height, required bool southern, List<CardinalDirection?>? directions}) {
    var total = 0.0;
    var sun = SunPatch.none;
    for (var i = 0; i < room.windows.length; i++) {
      final w = room.windows[i];
      if (!isVisible(room, p, w, height: height)) continue;
      final inward = room.inwardNormal(w);
      final toP = p - w.center;
      final d = math.max(toP.length, minDistance);
      final cos = toP.normalized.dot(inward);
      if (cos <= 0) continue;
      final direction = directions != null && i < directions.length ? directions[i] : room.windowDirection(w);
      total += w.area * orientationFactor(direction, southern: southern) * cos / (d * d);
      final patch = _sunPatch(room, p, w, inward, direction, southern: southern);
      if (patch.index > sun.index) sun = patch;
    }
    return LightSample(total, sun);
  }

  /// Le cran de lumière d'un point.
  static LightNeed lightAt(ScannedRoom room, RoomPoint p, {double height = potHeight, bool southern = false, List<CardinalDirection?>? directions}) =>
      sample(room, p, height: height, southern: southern, directions: directions).light;

  /// La fenêtre se voit-elle du point ? Aucun mur entre les deux — sauf
  /// celui qui la porte — ni aucun meuble plus haut que le point.
  static bool isVisible(ScannedRoom room, RoomPoint p, RoomSurface window, {required double height}) {
    // Le point de visée est ramené juste devant la vitre : un mur qui
    // finit dans le même plan que la fenêtre ne doit pas la cacher.
    final target = window.center + room.inwardNormal(window).scale(0.05);
    for (final wall in room.walls) {
      if (wall.id != null && wall.id == window.parentId) continue;
      if (_holds(wall, window)) continue;
      if (segmentsCross(p, target, wall.start, wall.end)) return false;
    }
    for (final o in room.objects) {
      if (o.topY - room.floorY <= height) continue;
      if (o.contains(p)) continue;
      final c = o.corners;
      for (var i = 0; i < 4; i++) {
        if (segmentsCross(p, target, c[i], c[(i + 1) % 4])) return false;
      }
    }
    return true;
  }

  /// Le mur porte-t-il la fenêtre ? Quand RoomPlan ne le dit pas, la
  /// géométrie le dit : son centre est sur le segment du mur, à un doigt près.
  static bool _holds(RoomSurface wall, RoomSurface window) {
    final d = window.center - wall.start;
    final t = d.dot(wall.along);
    if (t < -0.1 || t > wall.width + 0.1) return false;
    final off = (d - wall.along.scale(t)).length;
    return off < 0.2;
  }

  static SunPatch _sunPatch(ScannedRoom room, RoomPoint p, RoomSurface w, RoomPoint inward, CardinalDirection? direction, {required bool southern}) {
    if (direction == null) return SunPatch.none;
    final dir = southern ? _mirror(direction) : direction;
    final strong = dir == CardinalDirection.south || dir == CardinalDirection.southEast || dir == CardinalDirection.southWest;
    final weak = dir == CardinalDirection.east || dir == CardinalDirection.west;
    if (!strong && !weak) return SunPatch.none;
    final toP = p - w.center;
    final depth = toP.dot(inward);
    final reach = (w.topY - room.floorY) * sunReachPerHeight;
    if (depth <= 0 || depth > reach) return SunPatch.none;
    // Le soleil balaie : la tache déborde de l'ouverture d'un peu, plus loin.
    final lateral = toP.dot(w.along).abs();
    if (lateral > w.width / 2 + 0.15 * depth) return SunPatch.none;
    if (weak) return SunPatch.edge;
    return depth >= reach * sunEdgeFraction ? SunPatch.edge : SunPatch.full;
  }

  static CardinalDirection _mirror(CardinalDirection d) => switch (d) {
        CardinalDirection.north => CardinalDirection.south,
        CardinalDirection.northEast => CardinalDirection.southEast,
        CardinalDirection.southEast => CardinalDirection.northEast,
        CardinalDirection.south => CardinalDirection.north,
        CardinalDirection.southWest => CardinalDirection.northWest,
        CardinalDirection.northWest => CardinalDirection.southWest,
        CardinalDirection.east || CardinalDirection.west => d,
      };

  /// À moins d'un mètre d'une porte ou d'une ouverture, l'air bouge.
  static const double draftRadius = 1.0;

  static bool isDrafty(ScannedRoom room, RoomPoint p) {
    for (final s in [...room.doors, ...room.openings]) {
      if (p.distanceTo(s.center) < draftRadius) return true;
    }
    return false;
  }
}

/// La tache de soleil, en trois états ordonnés.
enum SunPatch { none, edge, full }

/// L'apport d'un point et sa part de soleil.
class LightSample {
  const LightSample(this.total, this.sun);

  final double total;
  final SunPatch sun;

  LightNeed get light => switch (sun) {
        SunPatch.full => LightNeed.fullSun,
        SunPatch.edge => LightNeed.someSun,
        SunPatch.none => total >= RoomLightModel.brightIndirectAt
            ? LightNeed.brightIndirect
            : total >= RoomLightModel.indirectAt
                ? LightNeed.indirect
                : total >= RoomLightModel.lowLightAt
                    ? LightNeed.lowLight
                    : LightNeed.shade,
      };
}
