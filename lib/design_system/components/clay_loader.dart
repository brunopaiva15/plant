import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/flora_theme.dart';
import 'clay.dart';

/// L'indicateur de chargement : une motte d'argile qui tombe, s'écrase,
/// rebondit en tremblant, se remodèle et repart. Un petit film d'animation
/// image par image, pas une roue qui tourne.
///
/// [size] est le diamètre de la motte au repos ; le widget prend un peu plus
/// de place pour le saut et les éclaboussures. Avec `reduced motion`, la
/// motte reste posée.
class ClayLoader extends StatefulWidget {
  const ClayLoader({super.key, this.size = 44, this.color});

  /// Diamètre de la motte au repos.
  final double size;

  /// Terre cuite par défaut.
  final Color? color;

  @override
  State<ClayLoader> createState() => _ClayLoaderState();
}

class _ClayLoaderState extends State<ClayLoader> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

  @override
  void initState() {
    super.initState();
    _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce && _c.isAnimating) _c.stop();
    if (!reduce && !_c.isAnimating) _c.repeat();
    final width = widget.size * 1.9;
    final height = widget.size * 1.7;
    return RepaintBoundary(
      child: CustomPaint(
        size: Size(width, height),
        painter: _ClayLoaderPainter(
          progress: reduce ? const AlwaysStoppedAnimation(0.72) : _c,
          color: widget.color ?? c.terracotta,
          shadow: c.isDark ? Colors.black : const Color(0xFF5E2C14),
          dark: c.isDark,
          diameter: widget.size,
        ),
      ),
    );
  }
}

class _ClayLoaderPainter extends CustomPainter {
  _ClayLoaderPainter({required this.progress, required this.color, required this.shadow, required this.dark, required this.diameter}) : super(repaint: progress);

  final Animation<double> progress;
  final Color color;
  final Color shadow;
  final bool dark;
  final double diameter;

  // Le scénario d'un cycle, en fraction du temps :
  //   0.00 – 0.20  la motte tombe (étirée)
  //   0.20 – 0.30  elle s'écrase au sol, les éclaboussures partent
  //   0.30 – 0.62  elle rebondit sur place, de moins en moins
  //   0.62 – 0.84  elle respire, sa silhouette se remodèle
  //   0.84 – 0.92  elle se ramasse avant le saut
  //   0.92 – 1.00  elle décolle (étirée) et la boucle reprend en l'air
  static const _drop = 0.20, _splat = 0.30, _settle = 0.62, _crouch = 0.84, _launch = 0.92;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    final r = diameter / 2;
    final floor = size.height - r * 0.35;
    final cx = size.width / 2;

    // Hauteur (0 = au sol, 1 = au sommet du saut) et déformation.
    double lift = 0, sx = 1, sy = 1;
    if (t < _drop) {
      final p = t / _drop;
      lift = 1 - p * p; // la chute accélère
      sx = 0.90;
      sy = 1.14;
    } else if (t < _splat) {
      final p = Curves.easeOutCubic.transform((t - _drop) / (_splat - _drop));
      sx = _lerp(0.90, 1.42, p);
      sy = _lerp(1.14, 0.56, p);
    } else if (t < _settle) {
      // Une oscillation amortie autour de la forme de repos.
      final p = (t - _splat) / (_settle - _splat);
      final wobble = math.exp(-3.2 * p) * math.cos(p * math.pi * 3.0);
      sx = 1 + 0.42 * wobble;
      sy = 1 - 0.44 * wobble;
    } else if (t < _crouch) {
      final p = (t - _settle) / (_crouch - _settle);
      sx = 1 + 0.03 * math.sin(p * math.pi * 2);
      sy = 1 - 0.03 * math.sin(p * math.pi * 2);
    } else if (t < _launch) {
      final p = Curves.easeInOut.transform((t - _crouch) / (_launch - _crouch));
      sx = _lerp(1.0, 1.18, p);
      sy = _lerp(1.0, 0.82, p);
    } else {
      final p = (t - _launch) / (1 - _launch);
      lift = 1 - (1 - p) * (1 - p); // le décollage est vif puis ralentit
      sx = _lerp(1.18, 0.90, math.min(1, p * 2));
      sy = _lerp(0.82, 1.14, math.min(1, p * 2));
    }
    final jump = (size.height - diameter * 1.15).clamp(0.0, size.height);
    final cy = floor - r * sy - lift * jump;

    // L'ombre au sol : plus la motte est haute, plus l'ombre est petite et pâle.
    final groundW = r * sx * _lerp(1.15, 0.7, lift);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + r * 0.12, floor + r * 0.02), width: groundW * 2, height: r * 0.42),
      Paint()
        ..color = shadow.withValues(alpha: (dark ? 0.45 : 0.22) * _lerp(1, 0.35, lift))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.16),
    );

    // Les éclaboussures : cinq gouttes qui partent à l'impact et retombent.
    if (t >= _drop + 0.02 && t < _settle) {
      final p = ((t - _drop - 0.02) / (_settle - _drop - 0.02)).clamp(0.0, 1.0);
      final fly = Curves.easeOutCubic.transform(p);
      final fade = (1 - Curves.easeIn.transform(p)).clamp(0.0, 1.0);
      for (var i = 0; i < 6; i++) {
        // Trois gouttes de chaque côté, qui jaillissent du bord écrasé.
        final side = i < 3 ? -1 : 1;
        final k = i % 3;
        final angle = side * (0.25 + 0.4 * k); // rasant → plus haut
        final dist = r * 1.05 + r * (0.55 + 0.35 * k) * fly;
        final gravity = r * 1.1 * p * p;
        final o = Offset(cx + side * math.cos(angle) * dist, floor - r * 0.25 - math.sin(angle.abs()) * dist * 0.9 + gravity);
        final dr = r * (0.16 - 0.03 * k) * (1 - 0.5 * p);
        canvas.drawCircle(o, dr, Paint()..color = color.withValues(alpha: fade));
        canvas.drawCircle(o.translate(-dr * 0.3, -dr * 0.3), dr * 0.35, Paint()..color = Colors.white.withValues(alpha: 0.45 * fade));
      }
    }

    // La motte : un cercle dont le bord ondule lentement, écrasé ou étiré.
    final path = Path();
    const n = 40;
    final phase = t * math.pi * 2;
    for (var i = 0; i <= n; i++) {
      final a = i / n * math.pi * 2;
      final wave = 1 + 0.045 * math.sin(3 * a + phase) + 0.03 * math.sin(5 * a - phase * 2) + 0.02 * math.cos(2 * a + phase);
      final x = cx + math.cos(a) * r * sx * wave;
      final y = cy + math.sin(a) * r * sy * wave;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    paintClay(canvas, path, bounds: Offset.zero & size, color: color, depth: ClayDepth.deep, dark: dark, dropShadow: false);
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  bool shouldRepaint(_ClayLoaderPainter old) => old.color != color || old.dark != dark || old.diameter != diameter || old.progress != progress;
}

