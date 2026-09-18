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
  /// Hauteur imposée. `null` fait remplir les contraintes du parent.
  final double? height;
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
              // Un voile clair garde la photo lisible sans brunir l'analyse.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    radius: 1.05,
                    colors: [
                      Colors.white.withValues(alpha: c.isDark ? 0.18 : 0.14),
                      c.surface.withValues(alpha: c.isDark ? 0.32 : 0.26),
                    ],
                  ),
                ),
              ),
              CustomPaint(
                painter: _ProcessingFieldPainter(
                  progress: _controller,
                  primary: const Color(0xFFFDFBF7),
                  secondary: const Color(0xFFF0EBE3),
                  accent: const Color(0xFFE7EFE6),
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
    required this.accent,
    required this.dark,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final Color primary;
  final Color secondary;
  final Color accent;
  final bool dark;

  static const double _spacing = 14;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final phase = progress.value * math.pi * 2;
    final cx = 0.035 * math.sin(phase * 0.78);
    final cy = 0.025 * math.cos(phase * 0.62);
    final breath = 0.98 + 0.04 * math.sin(phase);

    // Le nuage organique reste plus vivant au centre, mais le champ de points
    // ne s'arrête plus à sa frontière : toute la photo participe à la lecture.
    for (double y = _spacing / 2; y < size.height; y += _spacing) {
      for (double x = _spacing / 2; x < size.width; x += _spacing) {
        final nx = (x / size.width) * 2 - 1 - cx;
        final ny = (y / size.height) * 2 - 1 - cy;
        final theta = math.atan2(ny, nx);

        final dist = math.sqrt(
          math.pow(nx / 0.96, 2) + math.pow(ny / 0.86, 2),
        );

        final boundary = breath *
            (0.72 +
                0.045 * math.sin(theta * 3 + phase * 0.82) +
                0.030 * math.sin(theta * 5 - phase * 1.16) +
                0.018 * math.cos(theta * 2 + phase * 0.46));

        // Intensité de la masse centrale.
        final core = ((boundary - dist) / 0.30 + 0.58)
            .clamp(0.0, 1.0)
            .toDouble();

        // Intensité de fond : elle ne tombe jamais à zéro, même dans les
        // coins. C'est elle qui fait couvrir le champ sur toute la photo.
        final field = (1.12 - dist / 1.55).clamp(0.18, 1.0).toDouble();

        final pulse =
            0.5 + 0.5 * math.sin(dist * 13.5 - phase * 2.25 + theta * 0.7);

        final strength =
            (0.35 * field + 0.65 * core).clamp(0.0, 1.0).toDouble();

        final radius =
            0.85 + field * 0.38 + strength * 1.35 * (0.86 + pulse * 0.14);

        final alpha = (0.10 +
                field * (dark ? 0.10 : 0.08) +
                strength * (dark ? 0.24 : 0.20))
            .clamp(0.0, 1.0)
            .toDouble();

        // Blanc cassé en majorité, avec juste une trace de sauge très douce
        // pour éviter un champ purement clinique.
        final accentMix =
            (0.12 +
                    0.16 * (1 - strength) +
                    0.05 * math.sin(theta + phase * 0.35))
                .clamp(0.0, 1.0)
                .toDouble();

        final base =
            Color.lerp(primary, secondary, 0.55 * (1 - strength))!;
        final dot =
            Color.lerp(base, accent, accentMix)!.withValues(alpha: alpha);

        canvas.drawCircle(Offset(x, y), radius, Paint()..color = dot);
      }
    }
  }

  @override
  bool shouldRepaint(_ProcessingFieldPainter old) =>
      old.progress != progress ||
      old.primary != primary ||
      old.secondary != secondary ||
      old.accent != accent ||
      old.dark != dark;
}
