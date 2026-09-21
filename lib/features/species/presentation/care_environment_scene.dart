import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../../design_system/design_system.dart';
import '../../../domain/care/care_profile.dart';
import '../application/care_environment_slots.dart';
import '../application/care_environment_spec.dart';

/// La teinte que la variante de lumière pose sur ce qui est posé dans le
/// décor — la plante, le guéridon, l'humidificateur.
///
/// La plante est rendue une seule fois, dans son propre studio : la rendre
/// six fois, une par lumière, aurait multiplié les images par six. Sans
/// correction elle garde donc le même éclat au fond d'une pièce sombre que
/// dans la tache de soleil, et se lit comme une vignette collée sur le
/// décor. Un gain par canal et un peu de saturation suffisent à la faire
/// entrer dans la lumière de la pièce, pour zéro octet.
///
/// Les valeurs suivent les variantes de `tool/care_scene/room.py` : l'écart
/// d'ambiance entre `shade` et `fullSun` y est d'environ un tiers.
ColorFilter _lumiereDeLaScene(LightNeed light) {
  final (double gr, double gg, double gb, double sat) = switch (light) {
    LightNeed.shade => (0.78, 0.78, 0.76, 0.90),
    LightNeed.lowLight => (0.85, 0.85, 0.83, 0.94),
    LightNeed.indirect => (0.92, 0.92, 0.91, 0.97),
    LightNeed.brightIndirect => (0.99, 0.99, 0.98, 1.00),
    LightNeed.someSun => (1.05, 1.02, 0.97, 1.04),
    LightNeed.fullSun => (1.10, 1.05, 0.96, 1.07),
  };
  // Saturation autour de la luminance, puis gain par canal. L'alpha n'est
  // pas touché : la silhouette garde exactement sa découpe.
  const lr = 0.2126, lg = 0.7152, lb = 0.0722;
  double c(double l, bool diagonale, double gain) =>
      gain * (diagonale ? l + sat * (1 - l) : l - sat * l);
  return ColorFilter.matrix(<double>[
    c(lr, true, gr), c(lg, false, gr), c(lb, false, gr), 0, 0,
    c(lr, false, gg), c(lg, true, gg), c(lb, false, gg), 0, 0,
    c(lr, false, gb), c(lg, false, gb), c(lb, true, gb), 0, 0,
    0, 0, 0, 1, 0,
  ]);
}

/// Le diorama « environnement idéal » : le décor lumineux rendu par Blender,
/// les props du climat (humidificateur), l'ombre qui pose la plante, la
/// plante translatée sur son support, et les effets d'air
/// dessinés ici — vapeur et flux, jamais bakés : ils respectent le reduced
/// motion et passent à distance de la plante.
///
/// Dans la pièce, le guéridon — un prop rendu seul, comme l'humidificateur —
/// est posé sur l'emplacement qui dit le besoin de lumière, et les petits et
/// moyens gabarits sont réellement posés sur son plateau. Les grands
/// gabarits restent au sol.
///
/// À l'ouverture, la scène **se pose** : le cadre est d'abord serré sur la
/// plante, qui descend sur son emplacement et y laisse une onde ; puis la
/// caméra recule et découvre la pièce autour d'elle. Le regard part de la
/// plante et finit sur l'endroit où elle est — c'est ce que la scène
/// raconte. La pose se rejoue quand la plante change de place, de
/// silhouette ou de décor. En reduced motion, la scène est posée dès la
/// première image.
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

  /// Le temps de la pose : la plante descend, l'onde la désigne, la caméra
  /// recule.
  static const Duration poseDuration = Duration(milliseconds: 1400);

  /// Le grossissement de départ, centré sur la plante. Assez pour que la
  /// pièce se découvre au recul, pas au point de perdre le sol sous le pot.
  static const double zoomInitial = 1.30;

  /// De combien la plante descend en se posant, en fraction de la hauteur
  /// du cadre.
  static const double chute = 0.045;

  @override
  State<CareEnvironmentScene> createState() => _CareEnvironmentSceneState();
}

class _CareEnvironmentSceneState extends State<CareEnvironmentScene>
    with TickerProviderStateMixin {
  /// La respiration des effets d'air : trois cycles, puis le repos.
  late final AnimationController _souffle = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  )..addStatusListener(_cycle);
  int _cycles = 0;

  /// La pose, en un seul contrôleur : trois intervalles qui se chevauchent
  /// pour que l'onde parte à l'instant où le pot touche, et que la caméra
  /// recule pendant que l'onde s'éteint.
  late final AnimationController _pose = AnimationController(
    vsync: this,
    duration: CareEnvironmentScene.poseDuration,
  );

  /// La plante descend sur son emplacement en s'éclaircissant.
  late final CurvedAnimation _atterrissage = CurvedAnimation(
    parent: _pose,
    curve: const Interval(0.0, 0.32, curve: Motion.easeOut),
  );

  /// L'onde qui part du pot quand il touche, et s'éteint en s'élargissant.
  late final CurvedAnimation _onde = CurvedAnimation(
    parent: _pose,
    curve: const Interval(0.26, 0.72, curve: Motion.easeOut),
  );

  /// La caméra recule du gros plan sur la plante au cadre entier.
  late final CurvedAnimation _recul = CurvedAnimation(
    parent: _pose,
    curve: const Interval(0.40, 1.0, curve: Motion.emphasized),
  );

  bool _posee = false;

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
    // Une seule fois : le réglage se lit ici, jamais dans `initState`, où
    // le `MediaQuery` n'est pas encore accessible.
    if (!_posee) {
      _posee = true;
      _joueLaPose();
    }
  }

  @override
  void didUpdateWidget(CareEnvironmentScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    _metAJourAnimation();
    // La plante change de place, de silhouette ou de décor : elle se pose
    // à nouveau, et le regard la retrouve là où elle est allée.
    final avant = oldWidget.spec;
    final apres = widget.spec;
    if (avant.slot != apres.slot ||
        avant.plant != apres.plant ||
        avant.environment != apres.environment) {
      _joueLaPose();
    }
  }

  void _joueLaPose() {
    if (MediaQuery.disableAnimationsOf(context)) {
      _pose.value = 1;
    } else {
      _pose.forward(from: 0);
    }
  }

  void _metAJourAnimation() {
    final reduit = MediaQuery.disableAnimationsOf(context);
    final anime = _effetsActifs && !reduit;
    if (anime && !_souffle.isAnimating) {
      _cycles = 0;
      _souffle.forward();
    } else if (!anime && _souffle.isAnimating) {
      _souffle.stop();
    }
    // Le réglage change pendant la pose : elle se termine sur-le-champ.
    if (reduit && _pose.isAnimating) _pose.value = 1;
  }

  @override
  void dispose() {
    _atterrissage.dispose();
    _onde.dispose();
    _recul.dispose();
    _pose.dispose();
    _souffle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final spec = widget.spec;
    final plant = spec.plantFraction;
    const anchor = CareEnvironmentSlots.anchor;
    final anime = !MediaQuery.disableAnimationsOf(context);
    // Ce qui est posé dans le décor prend sa lumière ; le décor, lui, la
    // porte déjà (il est rendu une fois par variante).
    final lumiere = _lumiereDeLaScene(spec.light);
    // Le diorama est une maquette posée dans la fiche : les coins s'arrondissent
    // comme les cartes alentour, sinon le carré de pelouse fait bloc collé.
    // Le recul part d'un gros plan sur le feuillage : l'ancre est un peu
    // au-dessus de la base du pot, pour cadrer la plante et non le sol.
    // Le point d'ancrage ne bouge pas à l'écran pendant le recul, si bien
    // que la plante reste là où le regard l'a trouvée et que c'est la
    // pièce qui se découvre autour d'elle.
    final ancreZoom = FractionalOffset(plant.$1, plant.$2 - 0.12);
    return ClipRRect(
      borderRadius: Radii.largeAll,
      child: AspectRatio(
        aspectRatio: CareEnvironmentSlots.aspect,
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _recul,
            builder: (context, child) => Transform.scale(
              scale:
                  CareEnvironmentScene.zoomInitial +
                  (1 - CareEnvironmentScene.zoomInitial) * _recul.value,
              alignment: ancreZoom,
              child: child,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  spec.backdropAsset,
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                ),
                // Le guéridon est un prop rendu seul, comme l'humidificateur :
                // sa base vient se poser sur le slot lumineux, la plante sur
                // son plateau.
                if (spec.hasPedestal)
                  FractionalTranslation(
                    translation: Offset(
                      spec.slotFraction.$1 - anchor.$1,
                      spec.slotFraction.$2 - anchor.$2,
                    ),
                    child: ColorFiltered(
                      colorFilter: lumiere,
                      child: Image.asset(
                        spec.pedestalAsset,
                        fit: BoxFit.cover,
                        excludeFromSemantics: true,
                      ),
                    ),
                  ),
                // L'humidificateur reste au sol : à côté du guéridon quand la
                // plante est dessus, ou à côté de la plante quand elle est au sol.
                // Un plateau de billes prendra la même place, une fois l'image
                // livrée ; en attendant, un besoin tenu par le plateau seul
                // n'invente pas de machine.
                if (spec.hasHumidifier)
                  FractionalTranslation(
                    translation: Offset(
                      spec.humidifierFraction.$1 - anchor.$1,
                      spec.humidifierFraction.$2 - anchor.$2,
                    ),
                    child: ColorFiltered(
                      colorFilter: lumiere,
                      child: Image.asset(
                        'assets/care_scene/props/humidifier.webp',
                        fit: BoxFit.cover,
                        excludeFromSemantics: true,
                      ),
                    ),
                  ),
                // L'ombre du pot naît avec la plante qui se pose ; celle du
                // guéridon, meuble de la pièce, est là dès le départ. L'onde
                // de la pose se dessine dans la même couche, sous la plante.
                AnimatedBuilder(
                  animation: _pose,
                  builder: (context, _) => CustomPaint(
                    painter: _PlantShadowPainter(
                      pot: Offset(plant.$1, plant.$2),
                      support: spec.hasPedestal
                          ? Offset(spec.slotFraction.$1, spec.slotFraction.$2)
                          : null,
                      color: c.ink.withValues(alpha: 0.30),
                      pose: _atterrissage.value,
                      onde: _onde.value,
                      couleurOnde: c.sage,
                    ),
                  ),
                ),
                // La plante est rendue au centre du monde ; sa base de pot vient
                // se poser soit sur le plateau du guéridon, soit sur le slot au
                // sol. Elle descend d'un peu plus haut en s'éclaircissant, et
                // touche exactement là où l'ombre l'attend. Si un asset manquait
                // malgré tout (test d'assets dédié), le repli est la feuille
                // large — jamais une image cassée.
                AnimatedBuilder(
                  animation: _atterrissage,
                  builder: (context, child) => FractionalTranslation(
                    translation: Offset(
                      plant.$1 - anchor.$1,
                      plant.$2 -
                          anchor.$2 -
                          CareEnvironmentScene.chute *
                              (1 - _atterrissage.value),
                    ),
                    child: Opacity(opacity: _atterrissage.value, child: child),
                  ),
                  child: ColorFiltered(
                    colorFilter: lumiere,
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
                        slot: Offset(plant.$1, plant.$2),
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
        ),
      ),
    );
  }
}

/// L'ombre qui pose le pot sur son support, et le meuble sur le sol.
///
/// Elle fuit la fenêtre : dans les deux décors le jour vient de la gauche,
/// et l'ombre bakée du fauteuil part vers la droite. Une ellipse centrée et
/// symétrique, comme celle d'avant, contredisait cette lumière et nimbait
/// l'objet au lieu de le poser.
///
/// Deux passes à chaque contact : un noyau serré, qui fait le contact
/// lui-même, et un halo large et clair pour l'ombre portée. Une seule
/// ellipse très floue ne donne ni l'un ni l'autre.
///
/// Elle porte aussi la pose : l'ombre du pot naît avec la plante qui
/// descend, et deux ondes concentriques partent du point de contact quand
/// elle touche, à plat sur le sol, avant de s'éteindre. C'est ce qui
/// désigne l'emplacement — le seul moment où la scène pointe quelque chose.
class _PlantShadowPainter extends CustomPainter {
  const _PlantShadowPainter({
    required this.pot,
    required this.support,
    required this.color,
    this.pose = 1,
    this.onde = 1,
    this.couleurOnde = const Color(0x00000000),
  });

  /// Le centre de l'ombre du pot, en coordonnées fractionnaires du cadre.
  final Offset pot;

  /// Le point au sol sous le guéridon, quand la plante est dessus — `null`
  /// quand elle est posée directement au sol.
  final Offset? support;

  /// La teinte de l'ombre, à son opacité de noyau ; le halo en dérive.
  final Color color;

  /// L'avancement de la pose de la plante, 0 à 1 : l'ombre du pot suit.
  final double pose;

  /// L'avancement de l'onde, 0 à 1. À 0 elle n'est pas encore partie, à 1
  /// elle s'est éteinte : dans les deux cas rien ne se dessine.
  final double onde;
  final Color couleurOnde;

  /// Le sens dans lequel l'ombre s'étire, à l'opposé de la fenêtre.
  static const _fuite = Offset(0.030, 0.006);

  @override
  void paint(Canvas canvas, Size size) {
    if (support case final s?) {
      // Le meuble au sol, puis le pot sur son plateau : deux contacts, deux
      // ombres, la seconde plus petite parce qu'elle tombe de moins haut.
      _contact(canvas, size, s, 0.080, 0.021, 1.0, 1.0);
      _contact(canvas, size, pot, 0.058, 0.015, 0.72, pose);
    } else {
      _contact(canvas, size, pot, 0.090, 0.024, 1.0, pose);
    }
    if (onde > 0 && onde < 1) _onde(canvas, size);
  }

  void _contact(
    Canvas canvas,
    Size size,
    Offset c,
    double largeur,
    double hauteur,
    double echelle,
    double presence,
  ) {
    if (presence <= 0) return;
    final paint = Paint();
    final teinte = color.withValues(alpha: color.a * presence);
    // Le halo d'abord, le noyau par-dessus : l'inverse effacerait le noyau.
    _ellipse(canvas, size, paint, c + _fuite * echelle, largeur * 1.55,
        hauteur * 1.45, 0.019, teinte.withValues(alpha: teinte.a * 0.45));
    _ellipse(canvas, size, paint, c + _fuite * 0.42 * echelle, largeur,
        hauteur, 0.006, teinte);
  }

  /// Deux anneaux à plat sur le sol, le second un temps derrière le
  /// premier, qui s'élargissent depuis le pied du pot et s'effacent.
  void _onde(Canvas canvas, Size size) {
    final centre = Offset(pot.dx * size.width, pot.dy * size.height);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.0055
      ..strokeCap = StrokeCap.round;
    for (final retard in const [0.0, 0.22]) {
      final t = ((onde - retard) / (1 - retard)).clamp(0.0, 1.0);
      if (t <= 0 || t >= 1) continue;
      // Un départ franc, sans pop : l'anneau s'allume sur ses premiers
      // pour cent, puis s'éteint en s'élargissant.
      final alpha = 0.55 * math.min(1.0, t * 8) * (1 - t);
      final largeur = size.width * (0.06 + 0.16 * t);
      canvas.drawOval(
        Rect.fromCenter(center: centre, width: largeur, height: largeur * 0.36),
        paint..color = couleurOnde.withValues(alpha: alpha),
      );
    }
  }

  void _ellipse(
    Canvas canvas,
    Size size,
    Paint paint,
    Offset c,
    double largeur,
    double hauteur,
    double flou,
    Color couleur,
  ) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(c.dx * size.width, c.dy * size.height),
        width: size.width * largeur,
        height: size.width * hauteur,
      ),
      paint
        ..color = couleur
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * flou),
    );
  }

  @override
  bool shouldRepaint(_PlantShadowPainter old) =>
      old.pot != pot ||
      old.support != support ||
      old.color != color ||
      old.pose != pose ||
      old.onde != onde ||
      old.couleurOnde != couleurOnde;
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
