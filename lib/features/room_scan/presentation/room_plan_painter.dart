import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../../../design_system/design_system.dart';
import '../../../domain/care/care_profile.dart';
import '../../../domain/room/placement.dart';
import '../../../domain/room/scanned_room.dart';

/// Le plan d'une pièce vu de dessus : murs, fenêtres, portes, meubles en
/// silhouette, le lavis de la lumière lue place par place, et les places
/// retenues en pastilles numérotées.
///
/// Deux dimensions, dessinées par l'application — pas de moteur 3D, pour la
/// même raison que le diorama : ce qu'on veut lire est une distance et une
/// direction.
class RoomPlanPainter extends CustomPainter {
  RoomPlanPainter({required this.room, required this.colors, required this.numberStyle, this.fit, this.padding = 14});

  final ScannedRoom room;
  final FloraColors colors;
  final TextStyle numberStyle;
  final RoomFit? fit;
  final double padding;

  @override
  void paint(Canvas canvas, Size size) {
    final (minX, minZ, maxX, maxZ) = room.bounds;
    final w = maxX - minX, h = maxZ - minZ;
    if (w <= 0 || h <= 0) return;
    final scale = math.min((size.width - 2 * padding) / w, (size.height - 2 * padding) / h);
    final ox = (size.width - w * scale) / 2, oz = (size.height - h * scale) / 2;
    Offset at(RoomPoint p) => Offset(ox + (p.x - minX) * scale, oz + (p.z - minZ) * scale);

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

  @override
  bool shouldRepaint(RoomPlanPainter old) => old.room != room || old.fit != fit || old.colors != colors;
}
