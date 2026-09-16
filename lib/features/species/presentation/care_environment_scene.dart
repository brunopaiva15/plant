import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../../design_system/design_system.dart';
import '../../../domain/care/care_profile.dart';
import '../application/care_environment_slots.dart';
import '../application/care_environment_spec.dart';

/// Le diorama « environnement idéal » : le décor lumineux rendu par Blender,
/// les props du climat (humidificateur, grille d'aération), l'ombre qui pose
/// la plante, la plante translatée sur l'emplacement qui dit son besoin, et
/// les effets d'air dessinés ici — vapeur et flux, jamais bakés : ils
/// respectent le reduced motion et passent à distance de la plante.
///
/// Les effets respirent quelques cycles à l'ouverture puis se reposent :
/// rien ne bouge en permanence dans la fiche. En reduced motion, ils sont
/// statiques mais lisibles.
///
/// Aucune sémantique ici : c'est le héros ([CareEnvironmentHero]) qui porte
/// la description, les images sont décoratives.
class CareEnvironmentScene extends StatefulWidget {
  const CareEnvironmentScene({super.key, required this.spec});

  final CareEnvironmentVisualSpec spec;

  @override
  State<CareEnvironmentScene> createState() => _CareEnvironmentSceneState();
}

class _CareEnvironmentSceneState extends State<CareEnvironmentScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _souffle = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  )..addStatusListener(_cycle);
  int _cycles = 0;

  void _cycle(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _souffle.reverse();
    } else if (status == AnimationStatus.dismissed) {
      _cycles += 1;
      if (_cycles < 3) _souffle.forward();
    }
  }

  bool get _effetsActifs =>
      widget.spec.hasHumidifier || widget.spec.hasAirflowEffect;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _metAJourAnimation();
  }

  @override
  void didUpdateWidget(CareEnvironmentScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    _metAJourAnimation();
  }

  void _metAJourAnimation() {
    final anime = _effetsActifs && !MediaQuery.disableAnimationsOf(context);
    if (anime && !_souffle.isAnimating) {
      _cycles = 0;
      _souffle.forward();
    } else if (!anime && _souffle.isAnimating) {
      _souffle.stop();
    }
  }

  @override
  void dispose() {
    _souffle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final spec = widget.spec;
    final slot = spec.slotFraction;
    const anchor = CareEnvironmentSlots.anchor;
    final anime = !MediaQuery.disableAnimationsOf(context);
    return AspectRatio(
      aspectRatio: CareEnvironmentSlots.aspect,
      child: RepaintBoundary(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              spec.backdropAsset,
              fit: BoxFit.cover,
              excludeFromSemantics: true,
            ),
            // L'humidificateur, posé à côté de la plante comme elle.
            if (spec.hasHumidifier)
              FractionalTranslation(
                translation: Offset(
                  spec.humidifierFraction.$1 - anchor.$1,
                  spec.humidifierFraction.$2 - anchor.$2,
                ),
                child: Image.asset(
                  'assets/care_scene/props/humidifier.webp',
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                ),
              ),
            CustomPaint(
              painter: _PlantShadowPainter(
                center: Offset(slot.$1, slot.$2),
                color: c.ink.withValues(alpha: 0.16),
              ),
            ),
            // La plante est rendue au centre du monde ; elle glisse jusqu'à
            // son emplacement, la base du pot sur le point projeté. Si un
            // asset manquait malgré tout (test d'assets dédié), le repli est
            // la feuille large — jamais une image cassée.
            FractionalTranslation(
              translation: Offset(slot.$1 - anchor.$1, slot.$2 - anchor.$2),
              child: Image.asset(
                spec.plantAsset,
                fit: BoxFit.cover,
                excludeFromSemantics: true,
                errorBuilder: (context, error, stack) => Image.asset(
                  'assets/care_scene/plants/broad_leaf.webp',
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                ),
              ),
            ),
            if (spec.hasHumidifier)
              AnimatedBuilder(
                animation: _souffle,
                builder: (context, _) => CustomPaint(
                  painter: _SteamPainter(
                    origin: Offset(
                      spec.steamOriginFraction.$1,
                      spec.steamOriginFraction.$2,
                    ),
                    t: anime ? _souffle.value : 0.45,
                    color: c.water,
                  ),
                ),
              ),
            if (spec.hasAirflowEffect)
              AnimatedBuilder(
                animation: _souffle,
                builder: (context, _) => CustomPaint(
                  painter: _AirflowPainter(
                    kind: spec.airflow!,
                    slot: Offset(slot.$1, slot.$2),
                    origin: Offset(
                      spec.airflowOriginFraction.$1,
                      spec.airflowOriginFraction.$2,
                    ),
                    t: anime ? _souffle.value : 0.45,
                    color: c.inkSecondary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// L'ombre qui pose la plante sur le sol du diorama : une ellipse douce sous
/// l'emplacement, pour qu'elle ne flotte pas.
class _PlantShadowPainter extends CustomPainter {
  const _PlantShadowPainter({required this.center, required this.color});

  /// Le centre de l'ombre, en coordonnées fractionnaires du cadre.
  final Offset center;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(center.dx * size.width, center.dy * size.height);
    // Taillée sur le pot rendu par le pipeline (~0,64 m de large à
    // l'échelle de la pièce), et non sur le cadre : une ombre plus large
    // que la plante la ferait flotter au lieu de la poser.
    final rect = Rect.fromCenter(
      center: c,
      width: size.width * 0.105,
      height: size.width * 0.028,
    );
    canvas.drawOval(
      rect,
      Paint()
        ..color = color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * 0.014),
    );
  }

  @override
  bool shouldRepaint(_PlantShadowPainter old) =>
      old.center != center || old.color != color;
}

/// La vapeur de l'humidificateur : trois volutes qui montent en respirant,
/// phase décalée l'une de l'autre. Statique (t fixe) en reduced motion.
class _SteamPainter extends CustomPainter {
  const _SteamPainter({
    required this.origin,
    required this.t,
    required this.color,
  });

  /// Le haut de l'humidificateur, en coordonnées fractionnaires.
  final Offset origin;

  /// La phase de la respiration, 0 à 1.
  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final o = Offset(origin.dx * size.width, origin.dy * size.height);
    final hauteur = size.width * 0.13;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.006
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final phase = (t + i / 3) % 1.0;
      final alpha = math.sin(math.pi * phase);
      final dx = (i - 1) * size.width * 0.016;
      final path = Path();
      const pas = 16;
      for (var k = 0; k <= pas; k++) {
        final u = k / pas;
        final x =
            o.dx +
            dx +
            math.sin(u * 4.5 + i * 2.1 + t * 2 * math.pi) *
                size.width *
                0.007 *
                (0.4 + u);
        final y = o.dy - u * hauteur * (0.35 + 0.65 * phase);
        if (k == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(
        path,
        paint..color = color.withValues(alpha: 0.45 * alpha),
      );
    }
  }

  @override
  bool shouldRepaint(_SteamPainter old) =>
      old.origin != origin || old.t != t || old.color != color;
}

/// Les lignes de flux de l'air. À abriter : elles entrent par l'ouverture —
/// la fenêtre dedans, le côté ouvert dehors — et traversent le haut du cadre,
/// à distance de la plante. Bien ventilé : elles respirent doucement autour
/// d'elle. Jamais de tempête.
class _AirflowPainter extends CustomPainter {
  const _AirflowPainter({
    required this.kind,
    required this.slot,
    required this.origin,
    required this.t,
    required this.color,
  });

  final AirflowPreference kind;

  /// L'emplacement de la plante, en coordonnées fractionnaires.
  final Offset slot;

  /// L'ouverture d'où vient l'air, en coordonnées fractionnaires.
  final Offset origin;
  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.005
      ..strokeCap = StrokeCap.round;
    if (kind == AirflowPreference.sheltered) {
      _fluxAbris(canvas, size, paint);
    } else {
      _fluxBrasse(canvas, size, paint);
    }
  }

  /// De l'ouverture vers la droite, en haut du cadre, loin de la plante : le
  /// courant traverse la piece sans l'atteindre.
  void _fluxAbris(Canvas canvas, Size size, Paint paint) {
    final w = size.width;
    final h = size.height;
    final depart = Offset(origin.dx * w, origin.dy * h);
    for (var i = 0; i < 3; i++) {
      final phase = (t + i / 3) % 1.0;
      final alpha = 0.38 * math.sin(math.pi * phase);
      final dy = (i - 1) * h * 0.045;
      final derive = math.sin(t * 2 * math.pi + i) * h * 0.012;
      final path = Path()
        ..moveTo(depart.dx - w * 0.05, depart.dy + dy + derive)
        ..cubicTo(
          w * 0.50,
          depart.dy + dy - h * 0.02 + derive,
          w * 0.74,
          depart.dy + dy + h * 0.03,
          w * 1.06,
          depart.dy + dy + h * 0.05,
        );
      canvas.drawPath(path, paint..color = color.withValues(alpha: alpha));
    }
  }

  /// Autour du feuillage, en cercles doux.
  void _fluxBrasse(Canvas canvas, Size size, Paint paint) {
    final w = size.width;
    final centre = Offset(slot.dx * w, slot.dy * size.height - w * 0.10);
    for (var i = 0; i < 3; i++) {
      final phase = (t + i / 3) % 1.0;
      final alpha = 0.35 * math.sin(math.pi * phase);
      final rayon = w * (0.10 + 0.05 * phase);
      final rect = Rect.fromCircle(center: centre, radius: rayon);
      canvas.drawArc(
        rect,
        -2.6 + i * 0.5,
        1.1,
        false,
        paint..color = color.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(_AirflowPainter old) =>
      old.kind != kind ||
      old.slot != slot ||
      old.origin != origin ||
      old.t != t ||
      old.color != color;
}
