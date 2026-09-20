import 'dart:math' as math;

import '../care/care_profile.dart';
import 'placement.dart';
import 'room_light_model.dart';
import 'scanned_room.dart';

/// Où, dans une pièce relevée, une fiche d'entretien serait le mieux.
///
/// Calqué sur `HomeClimateAdvisor` : une fonction pure, sans dépendance,
/// qui compare ce que la pièce donne à ce que la fiche demande. La lumière
/// se juge contre `lightFloor` et `light` — la plus basse que la plante
/// accepte, et son idéal —, l'air qui bouge seulement si la fiche a un
/// avis, la pièce d'eau seulement si l'humidité de la fiche s'en soucie.
/// `null` reste un silence, jamais un conseil.
abstract final class RoomFitAdvisor {
  /// Le pas de la grille au sol, en mètres.
  static const double gridStep = 0.25;

  /// La marge aux murs : un pot ne se pose pas dans la plinthe.
  static const double wallMargin = 0.2;

  /// Deux places à moins de cette distance sont la même zone.
  static const double zoneRadius = 0.6;

  /// Sous ce score, la meilleure place ne convient pas.
  static const double acceptableScore = 0.5;

  /// À partir de ce score, la place convient sans réserve.
  static const double goodScore = 0.9;

  /// Le nombre de places nommées.
  static const int maxPlacements = 3;

  /// À moins de cette distance d'un radiateur, l'air est sec et chaud.
  static const double heaterRadius = 0.8;

  static RoomFit place(CareProfile profile, ScannedRoom room, {bool southern = false, List<CardinalDirection?>? directions}) {
    final candidates = _candidates(room);
    if (candidates.isEmpty) return RoomFit.empty;
    final humid = room.section?.isHumid ?? false;
    final all = <Placement>[];
    for (final c in candidates) {
      final sample = RoomLightModel.sample(room, c.point, height: c.height, southern: southern, directions: directions);
      final light = sample.light;
      final drafty = RoomLightModel.isDrafty(room, c.point);
      final nearest = _nearestVisibleWindow(room, c, directions);
      all.add(Placement(
        point: c.point,
        surface: c.surface,
        light: light,
        score: score(profile, light: light, drafty: drafty, humidRoom: humid),
        drafty: drafty,
        humidRoom: humid,
        windowIndex: nearest?.$1,
        windowDistance: nearest?.$2,
        windowDirection: nearest?.$3,
      ));
    }
    // Le score d'abord ; à score égal, la lumière la plus proche de l'idéal
    // de la fiche : le toléré vient après le préféré.
    all.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      return (a.light.index - profile.light.index).abs().compareTo((b.light.index - profile.light.index).abs());
    });
    final best = all.first.score;
    if (best < acceptableScore) {
      return RoomFit(verdict: RoomFitVerdict.unsuitable, placements: const [], shortfall: _shortfall(profile, all), all: all);
    }
    // Les places à la hauteur de la meilleure, regroupées par zone : une
    // zone est représentée par sa place la mieux notée.
    final floor = math.max(best - 0.05, acceptableScore);
    final zones = <Placement>[];
    for (final p in all) {
      if (p.score < floor) break;
      if (zones.any((z) => z.point.distanceTo(p.point) < zoneRadius)) continue;
      zones.add(p);
      if (zones.length == maxPlacements) break;
    }
    return RoomFit(
      verdict: best >= goodScore ? RoomFitVerdict.good : RoomFitVerdict.acceptable,
      placements: zones,
      shortfall: best >= goodScore ? null : _shortfall(profile, all),
      all: all,
    );
  }

  /// Le score d'une place, de 0 à 1.
  static double score(CareProfile profile, {required LightNeed light, required bool drafty, required bool humidRoom}) {
    var s = _lightScore(profile, light);
    switch (profile.airflow) {
      case AirflowPreference.sheltered when drafty:
        s *= 0.5;
      case AirflowPreference.ventilated when drafty:
        s = math.min(1, s * 1.1);
      default:
        break;
    }
    if (humidRoom) {
      switch (profile.humidity) {
        case HumidityNeed.high:
          s = math.min(1, s * 1.1);
        case HumidityNeed.low:
          s *= 0.7;
        case HumidityNeed.average:
          break;
      }
    }
    return s;
  }

  /// Dans la plage acceptée, 1 ; un cran sous le plancher, 0,5 ; deux ou
  /// plus, 0. Au-dessus de l'idéal, 0,6 puis 0,2 : une fougère en plein
  /// soleil brûle, et `lightTolerance` ne va que vers le bas.
  static double _lightScore(CareProfile profile, LightNeed light) {
    final floor = profile.lightFloor.index;
    final ideal = profile.light.index;
    final v = light.index;
    if (v >= floor && v <= ideal) return 1;
    if (v < floor) return floor - v == 1 ? 0.5 : 0;
    return v - ideal == 1 ? 0.6 : 0.2;
  }

  static RoomFitShortfall _shortfall(CareProfile profile, List<Placement> all) {
    final lights = all.map((p) => p.light.index);
    final darkest = lights.reduce(math.min);
    final brightest = lights.reduce(math.max);
    if (brightest < profile.lightFloor.index) return RoomFitShortfall.tooDark;
    if (darkest > profile.light.index) return RoomFitShortfall.tooBright;
    if (profile.airflow == AirflowPreference.sheltered && all.every((p) => p.drafty)) return RoomFitShortfall.drafty;
    if (profile.humidity == HumidityNeed.low && all.first.humidRoom) return RoomFitShortfall.tooDry;
    return brightest <= profile.light.index ? RoomFitShortfall.tooDark : RoomFitShortfall.tooBright;
  }

  /// La grille au sol, le dessus des tables et des meubles, l'appui des
  /// fenêtres : les plantes vivent sur les meubles autant que par terre.
  static List<_Candidate> _candidates(ScannedRoom room) {
    final out = <_Candidate>[];
    final (minX, minZ, maxX, maxZ) = room.bounds;
    if (maxX - minX < gridStep || maxZ - minZ < gridStep) return out;
    final tall = [for (final o in room.objects) if (o.topY - room.floorY > 1.2) o];
    for (var x = minX + wallMargin; x <= maxX - wallMargin + 1e-9; x += gridStep) {
      for (var z = minZ + wallMargin; z <= maxZ - wallMargin + 1e-9; z += gridStep) {
        final p = RoomPoint(_round(x), _round(z));
        if (!room.contains(p)) continue;
        if (room.objects.any((o) => o.contains(p))) continue;
        if (_tooCloseToWall(room, p)) continue;
        out.add(_Candidate(p, PlacementSurface.floor, RoomLightModel.potHeight));
      }
    }
    for (final o in room.objects) {
      final surface = switch (o.category) {
        'table' => PlacementSurface.table,
        'storage' when !tall.contains(o) => PlacementSurface.storage,
        _ => null,
      };
      if (surface == null) continue;
      out.add(_Candidate(o.center, surface, o.topY - room.floorY + 0.1));
    }
    for (final w in room.windows) {
      // L'appui : un pot y tient si la fenêtre ne descend pas jusqu'au sol.
      final sill = w.bottomY - room.floorY;
      if (sill < 0.3) continue;
      out.add(_Candidate(w.center + room.inwardNormal(w).scale(0.15), PlacementSurface.sill, sill + 0.1));
    }
    return out;
  }

  static bool _tooCloseToWall(ScannedRoom room, RoomPoint p) {
    for (final w in room.walls) {
      final d = p - w.start;
      final t = d.dot(w.along).clamp(0.0, w.width);
      if ((d - w.along.scale(t)).length < wallMargin - 1e-9) return true;
    }
    return false;
  }

  static (int, double, CardinalDirection?)? _nearestVisibleWindow(ScannedRoom room, _Candidate c, List<CardinalDirection?>? directions) {
    (int, double, CardinalDirection?)? best;
    for (var i = 0; i < room.windows.length; i++) {
      final w = room.windows[i];
      if (!RoomLightModel.isVisible(room, c.point, w, height: c.height)) continue;
      final d = c.point.distanceTo(w.center);
      if (best == null || d < best.$2) {
        final direction = directions != null && i < directions.length ? directions[i] : room.windowDirection(w);
        best = (i, d, direction);
      }
    }
    return best;
  }

  static double _round(double v) => (v * 1000).roundToDouble() / 1000;
}

class _Candidate {
  const _Candidate(this.point, this.surface, this.height);

  final RoomPoint point;
  final PlacementSurface surface;

  /// La hauteur à laquelle la lumière se lit, au-dessus du sol.
  final double height;
}
