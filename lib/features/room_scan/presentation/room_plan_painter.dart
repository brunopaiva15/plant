import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../../../design_system/design_system.dart';
import '../../../domain/care/care_profile.dart';
import '../../../domain/room/placement.dart';
import '../../../domain/room/scanned_room.dart';

/// Le passage du plan à l'écran et retour : la pièce tient dans le cadre,
/// centrée, à la même échelle dans les deux sens. C'est par là que le
/// peintre dessine, et que le doigt qui pose un radiateur retrouve le point
/// de la pièce qu'il a touché.
class RoomPlanGeometry {
  RoomPlanGeometry({required ScannedRoom room, required this.size, this.padding = 14}) {
    final (minX, minZ, maxX, maxZ) = room.bounds;
    _minX = minX;
    _minZ = minZ;
    final w = maxX - minX, h = maxZ - minZ;
    scale = w <= 0 || h <= 0 ? 0 : math.min((size.width - 2 * padding) / w, (size.height - 2 * padding) / h);
    _ox = (size.width - w * scale) / 2;
    _oz = (size.height - h * scale) / 2;
  }

  final Size size;
  final double padding;
  late final double scale;
  late final double _minX, _minZ, _ox, _oz;

  bool get isEmpty => scale <= 0;

  Offset toCanvas(RoomPoint p) => Offset(_ox + (p.x - _minX) * scale, _oz + (p.z - _minZ) * scale);

  RoomPoint toRoom(Offset o) => RoomPoint(_minX + (o.dx - _ox) / scale, _minZ + (o.dy - _oz) / scale);
}

/// Le plan d'une pièce vu de dessus : murs, fenêtres, portes, meubles en
/// silhouette, radiateurs posés, le lavis de la lumière lue place par place,
/// et les places retenues en pastilles numérotées.
///
/// Deux dimensions, dessinées par l'application — pas de moteur 3D, pour la
/// même raison que le diorama : ce qu'on veut lire est une distance et une
/// direction.
class RoomPlanPainter extends CustomPainter {
  RoomPlanPainter({
    required this.room,
    required this.colors,
    required this.numberStyle,
    this.fit,
    this.heaters = const [],
    this.padding = 14,
  });

  final ScannedRoom room;
  final FloraColors colors;
  final TextStyle numberStyle;
  final RoomFit? fit;
  final List<RoomPoint> heaters;
  final double padding;

  /// La taille d'un radiateur à l'écran, en mètres de pièce.
  static const double heaterWidth = 0.7;
  static const double heaterDepth = 0.12;

  @override
  void paint(Canvas canvas, Size size) {
    final g = RoomPlanGeometry(room: room, size: size, padding: padding);
    if (g.isEmpty) return;
    final at = g.toCanvas;
    final scale = g.scale;
    final (minX, minZ, maxX, maxZ) = room.bounds;

    // Le sol.
    final floor = Paint()..color = colors.surfaceMuted;
    if (room.floorPolygon.length >= 3) {
      final path = Path()..moveTo(at(room.floorPolygon.first).dx, at(room.floorPolygon.first).dy);
      for (final p in room.floorPolygon.skip(1)) {
        path.lineTo(at(p).dx, at(p).dy);
      }
      canvas.drawPath(path..close(), floor);
    } else {
      canvas.drawRect(Rect.fromPoints(at(RoomPoint(minX, minZ)), at(RoomPoint(maxX, maxZ))), floor);
    }

    // Le lavis de lumière : une tache douce par place évaluée, de l'ombre
    // au soleil. Les places se recouvrent : le lavis se lit en continu.
    final all = fit?.all ?? const <Placement>[];
    final radius = math.max(scale * 0.22, 6.0);
    for (final p in all) {
      if (p.surface != PlacementSurface.floor) continue;
      final t = p.light.index / (LightNeed.values.length - 1);
      final paint = Paint()
        ..color = Color.lerp(colors.sage.withValues(alpha: 0.18), colors.sun.withValues(alpha: 0.55), t)!
        ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, radius * 0.6);
      canvas.drawCircle(at(p.point), radius, paint);
    }

    // Les meubles, en silhouette.
    final furniture = Paint()..color = colors.surface;
    final outline = Paint()
      ..color = colors.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final o in room.objects) {
      final c = o.corners.map(at).toList();
      final path = Path()..addPolygon(c, true);
      canvas.drawPath(path, furniture);
      canvas.drawPath(path, outline);
    }

    // Les murs, puis ce qui s'y découpe : une fenêtre est un trait clair
    // dans le mur, une porte un trait fin.
    final wall = Paint()
      ..color = colors.ink
      ..strokeWidth = math.max(scale * 0.12, 3)
      ..strokeCap = StrokeCap.square;
    for (final s in room.walls) {
      canvas.drawLine(at(s.start), at(s.end), wall);
    }
    final window = Paint()
      ..color = colors.sunSoft
      ..strokeWidth = wall.strokeWidth
      ..strokeCap = StrokeCap.butt;
    final windowEdge = Paint()
      ..color = colors.sun
      ..strokeWidth = math.max(wall.strokeWidth * 0.35, 1.5)
      ..strokeCap = StrokeCap.butt;
    for (final s in room.windows) {
      canvas.drawLine(at(s.start), at(s.end), window);
      canvas.drawLine(at(s.start), at(s.end), windowEdge);
    }
    final door = Paint()
      ..color = colors.surface
      ..strokeWidth = wall.strokeWidth
      ..strokeCap = StrokeCap.butt;
    final doorArc = Paint()
      ..color = colors.inkTertiary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final s in [...room.doors, ...room.openings]) {
      canvas.drawLine(at(s.start), at(s.end), door);
      if (s.kind == RoomSurfaceKind.door) {
        final inward = room.inwardNormal(s);
        final hinge = at(s.start);
        final r = s.width * scale;
        final a0 = math.atan2(at(s.end).dy - hinge.dy, at(s.end).dx - hinge.dx);
        final sweep = (inward.x * s.along.z - inward.z * s.along.x) >= 0 ? -math.pi / 2 : math.pi / 2;
        canvas.drawArc(Rect.fromCircle(center: hinge, radius: r), a0, sweep, false, doorArc);
      }
    }

    // Les radiateurs : une barre rose contre le mur, et trois ailettes.
    final heaterPaint = Paint()..color = colors.rose;
    final fin = Paint()
      ..color = colors.surface
      ..strokeWidth = 1;
    for (final h in heaters) {
      final c = at(h);
      final w = heaterWidth * scale, d = math.max(heaterDepth * scale, 5.0);
      // Le long du mur le plus proche : l'orientation vient du mur.
      final wallDir = _wallDirectionAt(h);
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(math.atan2(wallDir.z, wallDir.x));
      final rect = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: w, height: d), Radius.circular(d / 2));
      canvas.drawRRect(rect, heaterPaint);
      for (final k in [-0.25, 0.0, 0.25]) {
        canvas.drawLine(Offset(k * w, -d / 2 + 1), Offset(k * w, d / 2 - 1), fin);
      }
      canvas.restore();
    }

    // Les places retenues, numérotées dans l'ordre du classement.
    final placements = fit?.placements ?? const <Placement>[];
    for (var i = 0; i < placements.length; i++) {
      final o = at(placements[i].point);
      canvas.drawCircle(o, 12, Paint()..color = colors.shadow.withValues(alpha: 0.25));
      canvas.drawCircle(o, 11, Paint()..color = colors.terracotta);
      final tp = TextPainter(
        text: TextSpan(text: '${i + 1}', style: numberStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, o - Offset(tp.width / 2, tp.height / 2));
    }
  }

  RoomPoint _wallDirectionAt(RoomPoint p) {
    RoomSurface? best;
    var bestD = double.infinity;
    for (final w in room.walls) {
      final d = p - w.start;
      final t = d.dot(w.along).clamp(0.0, w.width);
      final dist = (d - w.along.scale(t)).length;
      if (dist < bestD) {
        bestD = dist;
        best = w;
      }
    }
    return best?.along ?? const RoomPoint(1, 0);
  }

  @override
  bool shouldRepaint(RoomPlanPainter old) => old.room != room || old.fit != fit || old.colors != colors || old.heaters != heaters;
}
