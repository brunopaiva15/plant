import 'dart:math' as math;

import 'scanned_room.dart';

/// Lit le JSON d'un `CapturedRoom` de RoomPlan, tel que `JSONEncoder`
/// l'écrit, et n'en garde que ce que le modèle de lumière lit.
///
/// Le format est celui du `Codable` de RoomPlan : les catégories sont des
/// dictionnaires à une clé (`{"door": {"isOpen": false}}`), les
/// transformations des matrices 4 × 4 en colonnes, les dimensions des
/// triplets largeur · hauteur · longueur. Il change d'une version d'iOS à
/// l'autre : chaque forme rencontrée a sa fixture dans
/// `test/domain/fixtures/`, et le lecteur tolère ce qu'il ne connaît pas —
/// un champ absent vaut une liste vide, une surface illisible est ignorée.
abstract final class RoomPlanParser {
  static ScannedRoom parse(Map<String, Object?> json, {double? northOffsetDeg}) {
    final walls = _surfaces(json['walls'], RoomSurfaceKind.wall);
    final windows = _surfaces(json['windows'], RoomSurfaceKind.window);
    final doors = _surfaces(json['doors'], RoomSurfaceKind.door);
    final openings = _surfaces(json['openings'], RoomSurfaceKind.opening);
    final objects = _objects(json['objects']);
    final floor = _floorPolygon(json['floors']);
    return ScannedRoom(
      walls: walls,
      windows: windows,
      doors: doors,
      openings: openings,
      objects: objects,
      floorPolygon: floor,
      section: _section(json['sections'], walls),
      northOffsetDeg: northOffsetDeg,
    );
  }

  static List<RoomSurface> _surfaces(Object? raw, RoomSurfaceKind kind) {
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is Map) ?_surface(item, kind),
    ];
  }

  static RoomSurface? _surface(Map item, RoomSurfaceKind kind) {
    final t = _transform(item['transform']);
    final d = _dimensions(item['dimensions']);
    if (t == null || d == null) return null;
    final along = _floorDir(t.column(0));
    final normal = _floorDir(t.column(2));
    if (along == null || normal == null) return null;
    final (tx, ty, tz) = t.translation;
    return RoomSurface(
      kind: kind,
      center: RoomPoint(tx, tz),
      along: along,
      normal: normal,
      width: d.$1,
      height: d.$2,
      bottomY: ty - d.$2 / 2,
      id: item['identifier'] as String?,
      parentId: item['parentIdentifier'] as String?,
    );
  }

  static List<RoomObject> _objects(Object? raw) {
    if (raw is! List) return const [];
    final out = <RoomObject>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final t = _transform(item['transform']);
      final d = _dimensions(item['dimensions']);
      final category = _categoryName(item['category']);
      if (t == null || d == null || category == null) continue;
      final along = _floorDir(t.column(0)) ?? const RoomPoint(1, 0);
      final (tx, ty, tz) = t.translation;
      out.add(RoomObject(
        category: category,
        center: RoomPoint(tx, tz),
        along: along,
        width: d.$1,
        height: d.$2,
        length: d.$3,
        bottomY: ty - d.$2 / 2,
      ));
    }
    return out;
  }

  /// Le contour du premier sol, projeté au sol : RoomPlan donne ses coins
  /// dans le repère de la surface, qu'il faut ramener dans celui de la pièce.
  static List<RoomPoint> _floorPolygon(Object? raw) {
    if (raw is! List || raw.isEmpty || raw.first is! Map) return const [];
    final floor = raw.first as Map;
    final corners = floor['polygonCorners'];
    final t = _transform(floor['transform']);
    if (corners is! List || t == null) return const [];
    final out = <RoomPoint>[];
    for (final c in corners) {
      if (c is! List || c.length < 3) continue;
      final local = [for (final v in c) (v as num).toDouble()];
      final (x, _, z) = t.apply(local[0], local[1], local[2]);
      out.add(RoomPoint(x, z));
    }
    return out.length >= 3 ? out : const [];
  }

  /// La section dont le centre est le plus proche du milieu des murs : une
  /// pièce relevée seule n'en a qu'une, un relevé qui déborde peut en avoir deux.
  static RoomSectionLabel? _section(Object? raw, List<RoomSurface> walls) {
    if (raw is! List || raw.isEmpty) return null;
    RoomSectionLabel? best;
    var bestD = double.infinity;
    var cx = 0.0, cz = 0.0;
    for (final w in walls) {
      cx += w.center.x;
      cz += w.center.z;
    }
    final centroid = walls.isEmpty ? const RoomPoint(0, 0) : RoomPoint(cx / walls.length, cz / walls.length);
    for (final s in raw) {
      if (s is! Map) continue;
      final label = RoomSectionLabel.decode(_categoryName(s['label']));
      if (label == null) continue;
      final c = s['center'];
      final d = c is List && c.length >= 3 ? centroid.distanceTo(RoomPoint((c[0] as num).toDouble(), (c[2] as num).toDouble())) : 0.0;
      if (d < bestD) {
        bestD = d;
        best = label;
      }
    }
    return best;
  }

  /// `{"door": {"isOpen": false}}`, `"door"`, ou `{"door": {}}` : le nom.
  static String? _categoryName(Object? raw) {
    if (raw is String) return raw;
    if (raw is Map && raw.length == 1) return raw.keys.first as String?;
    return null;
  }

  static (double, double, double)? _dimensions(Object? raw) {
    if (raw is! List || raw.length < 3) return null;
    final v = [for (final n in raw.take(3)) n is num ? n.toDouble() : double.nan];
    if (v.any((n) => n.isNaN)) return null;
    return (v[0], v[1], v[2]);
  }

  static _Transform? _transform(Object? raw) {
    if (raw is! List) return null;
    final flat = <double>[];
    for (final e in raw) {
      if (e is num) {
        flat.add(e.toDouble());
      } else if (e is List) {
        for (final n in e) {
          if (n is num) flat.add(n.toDouble());
        }
      }
    }
    return flat.length == 16 ? _Transform(flat) : null;
  }

  /// La projection au sol d'un axe, unitaire ; `null` pour un axe vertical.
  static RoomPoint? _floorDir((double, double, double) axis) {
    final p = RoomPoint(axis.$1, axis.$3);
    return p.length < 1e-3 ? null : p.normalized;
  }
}

/// Une matrice 4 × 4 en colonnes, comme `simd_float4x4`.
class _Transform {
  const _Transform(this.m);

  final List<double> m;

  (double, double, double) column(int i) => (m[i * 4], m[i * 4 + 1], m[i * 4 + 2]);
  (double, double, double) get translation => column(3);

  (double, double, double) apply(double x, double y, double z) => (
        m[0] * x + m[4] * y + m[8] * z + m[12],
        m[1] * x + m[5] * y + m[9] * z + m[13],
        m[2] * x + m[6] * y + m[10] * z + m[14],
      );
}

/// Une transformation de RoomPlan à partir d'un centre, d'un lacet au sol et
/// d'une hauteur : de quoi écrire des fixtures et des tests sans matrice à
/// la main. Le lacet est l'angle de l'axe de largeur, en degrés, depuis +x
/// vers −z.
List<double> roomPlanTransform({required double x, required double y, required double z, double yawDeg = 0}) {
  final r = yawDeg * math.pi / 180;
  final c = math.cos(r), s = math.sin(r);
  // Colonne 0 : la largeur ; colonne 1 : le haut ; colonne 2 : la normale.
  return [c, 0, -s, 0, 0, 1, 0, 0, s, 0, c, 0, x, y, z, 1];
}
