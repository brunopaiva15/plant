import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../../design_system/design_system.dart';

/// Apparition décalée : chaque enfant entre à son tour, en fondu et en
/// remontant un peu. `t` est l'avancement global de la page (0 → 1).
class Stagger extends StatelessWidget {
  const Stagger({
    super.key,
    required this.t,
    required this.index,
    required this.child,
    this.count = 4,
    this.slide = 16,
    this.scaleFrom = 1,
  });

  final double t;
  final int index;
  final int count;
  final Widget child;
  final double slide;
  final double scaleFrom;

  @override
  Widget build(BuildContext context) {
    // Les entrées se chevauchent : la dernière commence avant la fin.
    final start = (index / (count + 1)).clamp(0.0, 0.9);
    final local = ((t - start) / (1 - start)).clamp(0.0, 1.0);
    final eased = Curves.easeOutCubic.transform(local);
    return Opacity(
      opacity: eased,
      child: Transform.translate(
        offset: Offset(0, slide * (1 - eased)),
        child: Transform.scale(scale: scaleFrom + (1 - scaleFrom) * eased, child: child),
      ),
    );
  }
}

/// Cadre commun des illustrations : un disque doux, et rien d'autre.
class ArtStage extends StatelessWidget {
  const ArtStage({super.key, required this.t, required this.child, this.size = 240});

  final double t;
  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final eased = Curves.easeOutCubic.transform(t.clamp(0.0, 1.0));
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.scale(
            scale: 0.9 + 0.1 * eased,
            child: Container(decoration: BoxDecoration(color: c.sageSoft, shape: BoxShape.circle)),
          ),
          child,
        ],
      ),
    );
  }
}

/// Écran 1 : une pousse qui sort de son pot, tige tracée puis feuilles.
class SproutArt extends StatelessWidget {
  const SproutArt({super.key, required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ArtStage(
      t: t,
      child: CustomPaint(
        size: const Size(240, 240),
        painter: _SproutPainter(t: t.clamp(0.0, 1.0), stem: c.sage, leaf: c.sage, pot: c.terracotta),
      ),
    );
  }
}

class _SproutPainter extends CustomPainter {
  _SproutPainter({required this.t, required this.stem, required this.leaf, required this.pot});

  final double t;
  final Color stem;
  final Color leaf;
  final Color pot;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final potTop = h * 0.66;

    // Le pot arrive en premier, la tige pousse ensuite, les feuilles finissent.
    final potIn = Curves.easeOutBack.transform((t / 0.35).clamp(0.0, 1.0));
    final grow = Curves.easeOutCubic.transform(((t - 0.2) / 0.55).clamp(0.0, 1.0));
    final leaves = Curves.easeOutBack.transform(((t - 0.55) / 0.45).clamp(0.0, 1.0));

    canvas.save();
    canvas.translate(w / 2, potTop);
    canvas.scale(potIn.clamp(0.0, 1.2));
    canvas.translate(-w / 2, -potTop);
    final potPath = Path()
      ..moveTo(w * 0.34, potTop)
      ..lineTo(w * 0.66, potTop)
      ..lineTo(w * 0.60, h * 0.86)
      ..lineTo(w * 0.40, h * 0.86)
      ..close();
    canvas.drawPath(potPath, Paint()..color = pot.withValues(alpha: 0.85));
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.32, potTop - h * 0.035, w * 0.36, h * 0.045), const Radius.circular(6)),
      Paint()..color = pot,
    );
    canvas.restore();

    if (grow <= 0) return;
    final stemPaint = Paint()
      ..color = stem
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final top = potTop - h * 0.34 * grow;
    final path = Path()..moveTo(w / 2, potTop - h * 0.03);
    path.quadraticBezierTo(w / 2 - w * 0.03 * grow, (potTop + top) / 2, w / 2, top);
    canvas.drawPath(path, stemPaint);

    if (leaves <= 0) return;
    for (final side in [-1.0, 1.0]) {
      canvas.save();
      canvas.translate(w / 2, top + h * 0.06);
      canvas.scale(side * leaves, leaves);
      final leafPath = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(w * 0.10, -h * 0.09, w * 0.20, -h * 0.02)
        ..quadraticBezierTo(w * 0.10, h * 0.03, 0, 0)
        ..close();
      canvas.drawPath(leafPath, Paint()..color = leaf.withValues(alpha: 0.9));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_SproutPainter old) => old.t != t;
}

/// Écran 2 : trois lignes de tâches qui se cochent l'une après l'autre.
class TodayArt extends StatelessWidget {
  const TodayArt({super.key, required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const emojis = ['💧', '🌿', '🪴'];
    return ArtStage(
      t: t,
      child: SizedBox(
        width: 158,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Stagger(
                  t: t,
                  index: i,
                  count: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: Space.xs, vertical: Space.xs),
                    decoration: BoxDecoration(color: c.surface, borderRadius: Radii.mediumAll, boxShadow: c.isDark ? null : Shadows.soft(c.shadow)),
                    child: Row(
                      children: [
                        Text(emojis[i], style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: Space.xs),
                        Expanded(
                          child: Container(
                            height: 7,
                            decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: BorderRadius.circular(4)),
                          ),
                        ),
                        const SizedBox(width: Space.xs),
                        _Check(t: ((t - 0.35 - i * 0.15) / 0.3).clamp(0.0, 1.0), color: c.sage),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Coche qui se dessine, plutôt qu'un simple fondu.
class _Check extends StatelessWidget {
  const _Check({required this.t, required this.color});

  final double t;
  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(size: const Size(20, 20), painter: _CheckPainter(t: t, color: color));
}

class _CheckPainter extends CustomPainter {
  _CheckPainter({required this.t, required this.color});

  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    canvas.drawCircle(center, radius, Paint()..color = color.withValues(alpha: 0.15 + 0.85 * t));
    if (t <= 0) return;
    final p = Path()
      ..moveTo(size.width * 0.28, size.height * 0.52)
      ..lineTo(size.width * 0.44, size.height * 0.68)
      ..lineTo(size.width * 0.74, size.height * 0.34);
    final metrics = p.computeMetrics().first;
    canvas.drawPath(
      metrics.extractPath(0, metrics.length * Curves.easeOutCubic.transform(t)),
      Paint()
        ..color = const Color(0xFFFFFFFF)
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.t != t;
}

/// Écran 3 : un anneau saisonnier qui se remplit, une goutte au centre.
class SeasonArt extends StatelessWidget {
  const SeasonArt({super.key, required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ArtStage(
      t: t,
      child: SizedBox(
        width: 240,
        height: 240,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(size: const Size(240, 240), painter: _RingPainter(t: t.clamp(0.0, 1.0), track: c.surface, fill: c.water)),
            Stagger(t: t, index: 2, count: 3, scaleFrom: 0.6, child: const Text('💧', style: TextStyle(fontSize: 54))),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.t, required this.track, required this.fill});

  final double t;
  final Color track;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width * 0.34;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final stroke = Paint()
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, stroke..color = track);
    // Trois quarts de tour : l'anneau n'est jamais « plein », comme un
    // rythme qui continue.
    canvas.drawArc(rect, -math.pi / 2, math.pi * 1.5 * Curves.easeOutCubic.transform(t), false, stroke..color = fill);

    // Quatre repères de saison sur l'anneau.
    for (var i = 0; i < 4; i++) {
      final angle = -math.pi / 2 + i * math.pi / 2;
      final at = Offset(center.dx + radius * math.cos(angle), center.dy + radius * math.sin(angle));
      final appear = ((t - 0.3 - i * 0.12) / 0.3).clamp(0.0, 1.0);
      // En blanc : sur l'arc rempli, un repère de la même couleur ne se
      // verrait pas du tout.
      canvas.drawCircle(at, 5.5 * appear, Paint()..color = track);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.t != t;
}

/// Écran 4 : quatre tuiles qui se posent, une par section de l'app.
class GardenArt extends StatelessWidget {
  const GardenArt({super.key, required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const tiles = ['🏡', '🧰', '🗓️', '📷'];
    return ArtStage(
      t: t,
      child: SizedBox(
        width: 168,
        height: 168,
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: Space.sm,
          crossAxisSpacing: Space.sm,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (var i = 0; i < tiles.length; i++)
              Stagger(
                t: t,
                index: i,
                scaleFrom: 0.7,
                child: Container(
                  decoration: BoxDecoration(color: c.surface, borderRadius: Radii.largeAll, boxShadow: c.isDark ? null : Shadows.soft(c.shadow)),
                  alignment: Alignment.center,
                  child: Text(tiles[i], style: const TextStyle(fontSize: 30)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Écran 5 : le téléphone au centre, le nuage optionnel autour.
class PrivacyArt extends StatelessWidget {
  const PrivacyArt({super.key, required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ArtStage(
      t: t,
      child: SizedBox(
        width: 240,
        height: 240,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Stagger(
              t: t,
              index: 0,
              scaleFrom: 0.85,
              child: Container(
                width: 92,
                height: 148,
                decoration: BoxDecoration(color: c.surface, borderRadius: Radii.largeAll, boxShadow: c.isDark ? null : Shadows.soft(c.shadow)),
                alignment: Alignment.center,
                child: const Text('🪴', style: TextStyle(fontSize: 40)),
              ),
            ),
            // Assez rentrés pour rester dans le disque, aux angles où il
            // est le plus large.
            Positioned(top: 46, right: 46, child: Stagger(t: t, index: 2, scaleFrom: 0.5, child: const Text('☁️', style: TextStyle(fontSize: 26)))),
            Positioned(bottom: 50, left: 46, child: Stagger(t: t, index: 3, scaleFrom: 0.5, child: const Text('🔒', style: TextStyle(fontSize: 24)))),
          ],
        ),
      ),
    );
  }
}
