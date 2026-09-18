import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

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
    this.foregroundAlignment = Alignment.center,
    this.height = 220,
    this.borderRadius = Radii.xlAll,
  });

  final Widget child;
  final Widget? foreground;

  /// Où placer le premier plan. Le centre reste le défaut pour les usages
  /// existants ; les scans peuvent le remonter afin de libérer le sujet.
  final Alignment foregroundAlignment;

  /// Hauteur imposée. `null` fait remplir les contraintes du parent.
  final double? height;
  final BorderRadius borderRadius;

  @override
  State<ProcessingField> createState() => _ProcessingFieldState();
}

class _ProcessingFieldState extends State<ProcessingField>
    with TickerProviderStateMixin {
  /// Impulsion vsync. La valeur 0–1 ne décrit rien : c'est le temps écoulé
  /// depuis le départ du champ qui nourrit la masse, comme le TimelineView
  /// d'origine, sans sauter en fin de boucle.
  late final AnimationController _heartbeat;

  /// Petite entrée de matière : le champ ne "pop" pas sur la photo.
  late final AnimationController _appearance;

  late final Animation<double> _fade;
  late final Animation<double> _scale;

  /// Instant du premier battement : le temps du champ part de zéro, pour que
  /// les deux secondes d'un scan montrent déjà la dérive.
  Duration _origin = Duration.zero;

  @override
  void initState() {
    super.initState();
    _origin = SchedulerBinding.instance.currentFrameTimeStamp;
    _heartbeat = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _appearance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..forward();
    _fade = CurvedAnimation(parent: _appearance, curve: Curves.easeOutCubic);
    _scale = Tween<double>(begin: 0.988, end: 1).animate(_fade);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion(MediaQuery.disableAnimationsOf(context));
  }

  void _syncMotion(bool reduce) {
    if (reduce) {
      if (_heartbeat.isAnimating) _heartbeat.stop();
      _appearance
        ..stop()
        ..value = 1;
    } else {
      if (!_heartbeat.isAnimating) {
        _origin = SchedulerBinding.instance.currentFrameTimeStamp;
        _heartbeat.repeat();
      }
      if (!_appearance.isAnimating && _appearance.value == 0) {
        _appearance.forward();
      }
    }
  }

  double get _elapsedSeconds {
    final delta = SchedulerBinding.instance.currentFrameTimeStamp - _origin;
    return delta.inMicroseconds / Duration.microsecondsPerSecond;
  }

  @override
  void dispose() {
    _heartbeat.dispose();
    _appearance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final reduce = MediaQuery.disableAnimationsOf(context);
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
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
                Positioned.fill(
                  child: IgnorePointer(
                    child: RepaintBoundary(
                      child: AnimatedBuilder(
                        animation: _heartbeat,
                        builder: (context, _) {
                          return CustomPaint(
                            painter: _ProcessingFieldPainter(
                              time: reduce ? null : _elapsedSeconds,
                              primary: const Color(0xFFFDFBF7),
                              secondary: const Color(0xFFF0EBE3),
                              accent: const Color(0xFFE7EFE6),
                              dark: c.isDark,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                if (widget.foreground != null)
                  Align(
                    alignment: widget.foregroundAlignment,
                    child: widget.foreground,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProcessingFieldPainter extends CustomPainter {
  _ProcessingFieldPainter({
    required this.time,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.dark,
  });

  /// Secondes depuis le départ du champ. `null` est l'image fixe : masse au
  /// centre, souffle à mi-course, plis non tournés — Reduce Motion et fin de
  /// travail, comme le ProcessingField d'origine.
  final double? time;
  final Color primary;
  final Color secondary;
  final Color accent;
  final bool dark;

  static const double _spacing = 14;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    // Les périodes ci-dessous ne se divisent pas entre elles : la forme
    // dérive, respire et se replie sans rejouer une boucle courte.
    final twoPi = math.pi * 2;
    final t = time;
    final foldT = t ?? 0;

    // Grille carrée fixe qui couvre réellement tout le cadre.
    final columns = math.max(1, (size.width / _spacing).round());
    final step = size.width / columns;
    final rows = math.max(1, (size.height / step).round());
    final originY = (size.height - step * rows) / 2;

    // La masse se déplace sous la grille ; aucun centre de point ne bouge.
    final centreX = t == null
        ? size.width / 2
        : size.width * (0.5 + 0.17 * math.sin(twoPi * foldT / 8.3));
    final centreY = t == null
        ? size.height / 2
        : size.height * (0.5 + 0.19 * math.sin(twoPi * foldT / 6.7 + 0.9));
    final breath = t == null ? 1.0 : 1 + 0.10 * math.sin(twoPi * foldT / 6.1);
    final swell = t == null
        ? 0.82
        : 0.82 + 0.18 * math.sin(twoPi * foldT / 7.1);
    final reachX = math.max(0.5, size.width * 0.40 * breath);
    final reachY = math.max(0.5, size.height * 0.40 * breath);

    final fold1 = 0.34 * foldT;
    final fold2 = -0.22 * foldT;
    final fold3 = 0.16 * foldT;
    final depth1 = 0.10 + 0.08 * math.sin(twoPi * foldT / 5.9);
    final depth2 = 0.06 + 0.05 * math.sin(twoPi * foldT / 4.3 + 1.7);
    final depth3 = 0.05 + 0.04 * math.sin(twoPi * foldT / 7.7 + 0.4);

    const softness = 0.34;
    const radiusFloorRatio = 0.085;
    const radiusMaxRatio = 0.19;
    const inkFloor = 0.30;
    const inkMax = 0.85;
    final radiusFloor = step * radiusFloorRatio;
    final radiusSpan = step * radiusMaxRatio - radiusFloor;
    const inkSpan = inkMax - inkFloor;

    for (var row = 0; row < rows; row++) {
      final y = originY + step * (row + 0.5);
      final ny = (y - centreY) / reachY;

      for (var column = 0; column < columns; column++) {
        final x = step * (column + 0.5);
        final nx = (x - centreX) / reachX;

        final distance = math.sqrt(nx * nx + ny * ny);
        final angle = math.atan2(ny, nx);
        final outline =
            1 +
            depth1 * math.sin(3 * angle + fold1) +
            depth2 * math.sin(5 * angle + fold2) +
            depth3 * math.sin(2 * angle + fold3);

        final ramp = ((outline + softness - distance) / (2 * softness)).clamp(
          0.0,
          1.0,
        );
        final smooth = ramp * ramp * (3 - 2 * ramp);
        final level = (smooth * swell).clamp(0.0, 1.0);

        final radius = radiusFloor + radiusSpan * level;
        final alpha = (inkFloor + inkSpan * level) * (dark ? 0.92 : 0.78);

        // Presque monochrome, comme l'original : juste un soupçon de sauge
        // dans les points les plus calmes pour rester dans la matière Auxine.
        final quiet = 1 - level;
        final base = Color.lerp(primary, secondary, quiet * 0.35)!;
        final dot = Color.lerp(
          base,
          accent,
          quiet * 0.10,
        )!.withValues(alpha: alpha);

        canvas.drawCircle(Offset(x, y), radius, Paint()..color = dot);
      }
    }
  }

  @override
  bool shouldRepaint(_ProcessingFieldPainter old) =>
      old.time != time ||
      old.primary != primary ||
      old.secondary != secondary ||
      old.accent != accent ||
      old.dark != dark;
}
