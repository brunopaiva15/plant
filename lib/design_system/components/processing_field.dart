import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/flora_theme.dart';
import '../tokens/radius.dart';

/// Un champ de points organique pour les traitements qui portent sur une image.
///
/// Contrairement à [ClayLoader], qui signale une petite attente locale, ce
/// composant occupe la surface en cours de traitement. Les points ne voyagent
/// pas : leur taille et leur opacité suivent une masse qui respire, afin que
/// l'image reste lisible et que le mouvement ressemble à une observation
/// plutôt qu'à un scanner.
///
/// [child] est la matière observée (une photo, typiquement) et [foreground]
/// reste immobile au-dessus du champ — la marque d'Iris, dans l'identification.
class ProcessingField extends StatefulWidget {
  const ProcessingField({
    super.key,
    required this.child,
    this.foreground,
    this.height = 220,
    this.borderRadius = Radii.xlAll,
  });

  final Widget child;
  final Widget? foreground;
  final double height;
  final BorderRadius borderRadius;

  @override
  State<ProcessingField> createState() => _ProcessingFieldState();
}

class _ProcessingFieldState extends State<ProcessingField> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  )..repeat();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce) {
      // Un état fixe assez organique pour garder le sens du composant, sans
      // mouvement caché qui continuerait à consommer des images.
      if (_controller.isAnimating) _controller.stop();
      _controller.value = 0.31;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: widget.borderRadius,
        child: SizedBox(
          width: double.infinity,
          height: widget.height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              widget.child,
              // Le bord se voile un peu plus que le centre : la photo reste
              // reconnaissable là où Iris regarde, et le champ ressort sans
              // transformer l'attente en écran opaque.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    radius: 0.92,
                    colors: [
                      c.surface.withValues(alpha: c.isDark ? 0.34 : 0.30),
                      c.surface.withValues(alpha: c.isDark ? 0.66 : 0.58),
                    ],
                  ),
                ),
              ),
              CustomPaint(
                painter: _ProcessingFieldPainter(
                  progress: _controller,
                  primary: c.terracotta,
                  secondary: c.sage,
                  dark: c.isDark,
                ),
              ),
              if (widget.foreground != null) Center(child: widget.foreground),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProcessingFieldPainter extends CustomPainter {
  _ProcessingFieldPainter({
    required this.progress,
    required this.primary,
    required this.secondary,
    required this.dark,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final Color primary;
  final Color secondary;
  final bool dark;

  static const double _spacing = 14;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final phase = progress.value * math.pi * 2;
    final cx = 0.035 * math.sin(phase * 0.78);
    final cy = 0.025 * math.cos(phase * 0.62);
    final breath = 0.97 + 0.045 * math.sin(phase);

    // Un halo presque imperceptible rassemble visuellement les points sans
    // dessiner une forme fermée autour d'Iris.
    final haloRect = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: size.width * 0.72,
      height: size.height * 0.82,
    );
    canvas.drawOval(
      haloRect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            primary.withValues(alpha: dark ? 0.11 : 0.08),
            primary.withValues(alpha: 0),
          ],
        ).createShader(haloRect),
    );

    for (double y = _spacing / 2; y < size.height; y += _spacing) {
      for (double x = _spacing / 2; x < size.width; x += _spacing) {
        final nx = (x / size.width) * 2 - 1 - cx;
        final ny = (y / size.height) * 2 - 1 - cy;
        final theta = math.atan2(ny, nx);

        // L'ellipse est volontairement irrégulière : trois fréquences lentes
        // empêchent l'œil de lire un cercle qui gonfle et dégonfle.
        final dist = math.sqrt(math.pow(nx / 0.92, 2) + math.pow(ny / 0.78, 2));
        final boundary = breath *
            (0.66 +
                0.045 * math.sin(theta * 3 + phase * 0.82) +
                0.030 * math.sin(theta * 5 - phase * 1.16) +
                0.018 * math.cos(theta * 2 + phase * 0.46));

        final strength = ((boundary - dist) / 0.23 + 0.52).clamp(0.0, 1.0).toDouble();
        final pulse = 0.5 + 0.5 * math.sin(dist * 13.5 - phase * 2.25 + theta * 0.7);

        final radius = 0.70 + strength * 1.95 * (0.86 + pulse * 0.14);
        final alpha = (0.035 + strength * (dark ? 0.49 : 0.41)).clamp(0.0, 1.0).toDouble();

        // La terre cuite domine au centre, le vert apparaît davantage sur la
        // périphérie. Le mélange se déplace très lentement, sans faire voyager
        // les points eux-mêmes.
        final mix = (0.28 + 0.36 * (1 - strength) + 0.10 * math.sin(theta + phase * 0.35))
            .clamp(0.0, 1.0)
            .toDouble();
        final dot = Color.lerp(primary, secondary, mix)!.withValues(alpha: alpha);

        canvas.drawCircle(Offset(x, y), radius, Paint()..color = dot);
      }
    }
  }

  @override
  bool shouldRepaint(_ProcessingFieldPainter old) =>
      old.progress != progress || old.primary != primary || old.secondary != secondary || old.dark != dark;
}
