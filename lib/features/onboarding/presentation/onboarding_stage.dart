import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import 'clay_illustration.dart';

/// La scène de l'onboarding : une dalle d'argile au centre, et les cinq
/// objets du jardin qui s'y succèdent.
///
/// Les écrans ne défilent pas l'un après l'autre comme des diapositives : la
/// dalle reste là et change de couleur, les objets changent de place. Celui
/// de l'écran courant est au centre, net et animé ; les autres attendent hors
/// champ et traversent l'écran au rythme du doigt — le mouvement suit le
/// geste, il n'est pas joué après coup.
class OnboardingStage extends StatelessWidget {
  const OnboardingStage({
    super.key,
    required this.count,
    required this.offset,
    required this.page,
    required this.entry,
    required this.height,
    required this.reduceMotion,
    this.tint,
  });

  /// Nombre d'objets, un par écran de présentation.
  final int count;

  /// Position continue du carrousel. C'est la seule source du mouvement.
  final double offset;

  /// L'écran affiché, celui dont l'objet s'anime.
  final int page;

  /// Avancement de l'entrée de la page courante (0 → 1).
  final double entry;

  /// Hauteur de la scène, accordée à celle de l'écran.
  final double height;

  final bool reduceMotion;

  /// La couleur de l'écran courant, déjà mêlée à celle du suivant pendant le
  /// geste. Sans elle, la dalle prend le vert de l'app.
  final Color? tint;

  /// Côté de l'objet central pour une hauteur de scène donnée : il déborde
  /// franchement de la dalle, c'est lui qu'on regarde.
  static double sideOf(double height) => (height * 0.80).roundToDouble();

  /// Côté de la dalle : un peu moins que l'objet, pour qu'il la déborde.
  static double tileOf(double height) => (height * 0.64).roundToDouble();

  double get side => sideOf(height);

  /// Taille visible de la scène : elle se referme quand on quitte les écrans
  /// de présentation, pour laisser toute la hauteur au prénom.
  double get visibleHeight => height * (1 - _leaving);

  /// De 0 à 1 quand on passe des présentations à la page du prénom.
  double get _leaving => (offset - (count - 1)).clamp(0.0, 1.0);

  /// Chaque dalle penche d'un rien, tantôt à gauche, tantôt à droite : posée,
  /// pas alignée. Entre deux écrans, elle bascule de l'un à l'autre.
  static const _tilts = <double>[-0.055, 0.045, -0.04, 0.05, -0.045];

  double get _tilt {
    final o = offset.clamp(0.0, (count - 1).toDouble());
    final i = o.floor();
    final next = math.min(i + 1, count - 1);
    return ui.lerpDouble(_tilts[i % _tilts.length], _tilts[next % _tilts.length], o - i)!;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final width = MediaQuery.sizeOf(context).width;
    final leaving = _leaving;
    final rise = Curves.easeOutCubic.transform(entry);
    // La dalle se pose : elle arrive un peu petite et prend sa place, avec
    // un rien de dépassement, comme un objet lâché sur la table.
    final settle = reduceMotion ? 1.0 : 0.94 + 0.06 * Curves.easeOutBack.transform(entry);
    return SizedBox(
      height: visibleHeight,
      child: leaving >= 1
          ? const SizedBox.shrink()
          : ClipRect(
              child: OverflowBox(
                maxHeight: height,
                minHeight: height,
                alignment: Alignment.topCenter,
                child: Opacity(
                  opacity: 1 - leaving,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Transform.translate(
                        offset: Offset(0, height * 0.06),
                        child: Transform.scale(
                          scale: settle,
                          child: ClayTile(size: tileOf(height), color: tint ?? c.sage, angle: reduceMotion ? 0 : _tilt),
                        ),
                      ),
                      for (var i = count - 1; i >= 0; i--) _object(context, i, width, rise),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _object(BuildContext context, int index, double width, double rise) {
    // Distance continue à la place centrale, en écrans.
    final d = index - offset;
    // Un voisin n'existe que le temps du geste : à l'arrêt, il ne reste que
    // l'objet du milieu. L'écran au repos est net, jamais encombré.
    final opacity = 1 - (d.abs() / 0.8).clamp(0.0, 1.0);
    if (opacity <= 0.01) return const SizedBox.shrink();

    final near = d.abs().clamp(0.0, 1.0);
    final scale = 1 - 0.45 * Curves.easeOutCubic.transform(near);
    // Ceux qui arrivent montent à droite et descendent à gauche : la
    // composition reste en diagonale, jamais alignée.
    final dx = d * 0.62 * width;
    final dy = -30 * d.sign * near + 26 * (1 - rise) * (1 - near);
    final blur = reduceMotion ? 0.0 : 4.0 * Curves.easeIn.transform(near);

    Widget object = ClayIllustration(slide: index + 1, side: side, animate: index == page && near < 0.02);
    if (blur > 0.05) {
      object = ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: object,
      );
    }
    return Transform.translate(
      offset: Offset(dx, dy),
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Transform.scale(scale: scale, child: object),
      ),
    );
  }
}

/// Une dalle d'argile : un carré aux coins très ronds, dans la couleur de
/// l'écran, avec la lumière qui vient d'en haut. Le relief est peint, pas
/// simulé par une ombre plate : un bord clair en haut, une ombre logée en
/// bas, et l'ombre portée teintée de la même couleur.
class ClayTile extends StatelessWidget {
  const ClayTile({super.key, required this.size, required this.color, this.angle = 0});

  final double size;
  final Color color;

  /// Inclinaison, en radians.
  final double angle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // La couleur brute serait criarde sur toute une dalle : on la coupe de
    // blanc en clair, de fond en sombre, pour garder une pâte pastel.
    final body = Color.lerp(color, c.isDark ? c.canvas : Colors.white, c.isDark ? 0.40 : 0.34)!;
    return Transform.rotate(
      angle: angle,
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.square(size),
          painter: _ClayTilePainter(body: body, shadow: color, dark: c.isDark),
          isComplex: true,
        ),
      ),
    );
  }
}

class _ClayTilePainter extends CustomPainter {
  const _ClayTilePainter({required this.body, required this.shadow, required this.dark});

  final Color body;
  final Color shadow;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final radius = size.shortestSide * 0.36;
    final path = RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(radius)).getOuterPath(rect);

    // L'ombre portée, dans la couleur de la dalle : une ombre grise sur un
    // fond teinté ferait sale.
    canvas.drawPath(
      path.shift(Offset(0, size.height * 0.07)),
      Paint()
        ..color = shadow.withValues(alpha: dark ? 0.35 : 0.42)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.shortestSide * 0.09),
    );

    // La matière : un dégradé à peine perceptible, du haut éclairé au bas.
    final light = Color.lerp(body, Colors.white, dark ? 0.10 : 0.16)!;
    final deep = Color.lerp(body, Colors.black, dark ? 0.16 : 0.08)!;
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [light, body, deep],
          stops: const [0, 0.55, 1],
        ).createShader(rect),
    );

    // Le relief : tout ce qui est hors de la dalle, décalé et flouté, puis
    // rogné à la dalle. Décalé vers le bas, il éclaire le bord haut ; vers le
    // haut, il ombre le bord bas. C'est ce creux qui fait la pâte.
    final outside = rect.inflate(size.shortestSide);
    Path rim(Offset by) => Path.combine(PathOperation.difference, Path()..addRect(outside), path.shift(by));
    final edge = size.shortestSide;
    canvas.save();
    canvas.clipPath(path);
    canvas.drawPath(
      rim(Offset(0, edge * 0.05)),
      Paint()
        ..color = Colors.white.withValues(alpha: dark ? 0.28 : 0.85)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, edge * 0.05),
    );
    canvas.drawPath(
      rim(Offset(0, -edge * 0.06)),
      Paint()
        ..color = Color.lerp(shadow, Colors.black, dark ? 0.55 : 0.30)!.withValues(alpha: dark ? 0.55 : 0.38)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, edge * 0.07),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ClayTilePainter old) => old.body != body || old.shadow != shadow || old.dark != dark;
}

/// Le fond : tout l'écran prend la couleur de l'écran courant, coupée de
/// fond pour rester lisible, et une lueur plus franche monte derrière la
/// scène à l'arrivée, puis se pose. Rien n'a de bord : c'est ce qui distingue
/// une ambiance d'un aplat.
class OnboardingBackdrop extends StatelessWidget {
  const OnboardingBackdrop({super.key, required this.tint, required this.drift, required this.reduceMotion});

  /// La couleur de l'écran courant, déjà interpolée entre deux écrans.
  final Color tint;

  /// Avancement du souffle d'arrivée, de 0 à 1 : la lueur monte d'un rien et
  /// s'arrête.
  final double drift;
  final bool reduceMotion;

  /// Le fond d'un écran pour une couleur donnée : c'est aussi la couleur
  /// qu'on donne au [Scaffold], pour que rien ne dépasse aux bords.
  static Color wash(FloraColors c, Color tint) => Color.lerp(c.canvas, tint, c.isDark ? 0.16 : 0.13)!;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = reduceMotion ? 1.0 : Curves.easeOutCubic.transform(drift);
    return IgnorePointer(
      child: ColoredBox(
        color: wash(c, tint),
        child: Stack(
          children: [
            // La lueur derrière la scène : elle monte de quelques points à
            // l'arrivée sur chaque écran.
            _Glow(
              color: tint.withValues(alpha: c.isDark ? 0.30 : 0.34),
              size: 560,
              at: Alignment(0, -0.62 + 0.08 * (1 - t)),
            ),
            // Un halo bas, plus discret, qui répond au premier.
            _Glow(
              color: tint.withValues(alpha: c.isDark ? 0.14 : 0.16),
              size: 620,
              at: Alignment(0.9, 1.15 - 0.05 * t),
            ),
          ],
        ),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size, required this.at});

  final Color color;
  final double size;
  final Alignment at;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: at,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}

/// Le bouton de l'onboarding : une dalle d'encre aux coins ronds, posée sur
/// une ombre de la couleur de l'écran. Plus haut et plus franc que la pilule
/// de l'app — ici il n'y a qu'un geste à faire, il doit s'imposer.
class ClayButton extends StatelessWidget {
  const ClayButton({super.key, required this.label, required this.onPressed, required this.tint, this.trailingIcon, this.filled = true});

  final String label;
  final VoidCallback onPressed;

  /// La couleur de l'écran : elle colore l'ombre du bouton plein, et le
  /// bouton discret tout entier.
  final Color tint;
  final IconData? trailingIcon;

  /// Plein : encre sur fond, le geste principal. Sinon : un bouton discret,
  /// dans la couleur de l'écran, pour le choix secondaire.
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = filled ? c.canvas : Color.lerp(tint, c.ink, c.isDark ? 0.0 : 0.25)!;
    final style = context.text.body.copyWith(color: fg, fontWeight: FontWeight.w700, fontSize: 18, letterSpacing: -0.2);
    return Pressable(
      onTap: onPressed,
      scale: 0.965,
      semanticLabel: label,
      child: Container(
        height: filled ? 62 : 52,
        alignment: Alignment.center,
        decoration: ShapeDecoration(
          color: filled ? c.ink : Colors.transparent,
          shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(filled ? 24 : 20)),
          shadows: filled
              ? [
                  BoxShadow(
                    color: tint.withValues(alpha: c.isDark ? 0.30 : 0.42),
                    blurRadius: 30,
                    offset: const Offset(0, 14),
                  ),
                  BoxShadow(
                    color: c.ink.withValues(alpha: c.isDark ? 0.0 : 0.16),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : const [],
        ),
        foregroundDecoration: filled
            ? ShapeDecoration(
                shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(24)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: c.isDark ? 0.22 : 0.14),
                    Colors.white.withValues(alpha: 0),
                  ],
                  stops: const [0, 0.55],
                ),
              )
            : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label, style: style, maxLines: 1),
              ),
            ),
            if (trailingIcon != null) ...[const SizedBox(width: Space.xs), Icon(trailingIcon, size: 22, color: fg)],
          ],
        ),
      ),
    );
  }
}

/// Un titre qui se lève mot à mot, chaque mot sortant de sa propre ligne.
///
/// Le masque compte autant que le mouvement : sans lui les mots glisseraient
/// sur le fond au lieu d'émerger du texte.
class RisingTitle extends StatelessWidget {
  const RisingTitle({super.key, required this.text, required this.style, required this.t, this.alignment = WrapAlignment.center});

  final String text;
  final TextStyle style;

  /// Avancement de la levée (0 → 1).
  final double t;

  /// Où les mots se rangent sur la ligne.
  final WrapAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final words = text.split(' ');
    final lineHeight = (style.fontSize ?? 34) * (style.height ?? 1.1);
    // Le titre est découpé pour l'œil seulement : la synthèse vocale doit
    // entendre une phrase, pas une liste de mots.
    return Semantics(
      label: text,
      header: true,
      excludeSemantics: true,
      child: Wrap(
        alignment: alignment,
        spacing: (style.fontSize ?? 34) * 0.24,
        runSpacing: 0,
        children: [
          for (final (i, word) in words.indexed)
            ClipRect(
              child: SizedBox(
                height: lineHeight,
                child: Builder(
                  builder: (context) {
                    // Les mots se lèvent l'un après l'autre, en se chevauchant.
                    final start = (i / (words.length + 2)).clamp(0.0, 0.7);
                    final local = ((t - start) / (1 - start)).clamp(0.0, 1.0);
                    final eased = Curves.easeOutCubic.transform(local);
                    return Transform.translate(
                      offset: Offset(0, lineHeight * (1 - eased)),
                      child: Text(word, style: style, maxLines: 1),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Apparition décalée : chaque enfant entre à son tour, en fondu et en
/// remontant un peu. `t` est l'avancement global de la page (0 → 1).
class Stagger extends StatelessWidget {
  const Stagger({super.key, required this.t, required this.index, required this.child, this.count = 4, this.slide = 16, this.scaleFrom = 1});

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

/// Les barres de progression : une par écran, celle des écrans franchis est
/// pleine, dans la couleur de l'écran. Plus discret qu'une rangée de points,
/// et plus grand.
class OnboardingProgress extends StatelessWidget {
  const OnboardingProgress({super.key, required this.count, required this.index, this.color});

  final int count;
  final int index;

  /// Couleur des pas franchis. Sans elle, le vert de l'app.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final done = Color.lerp(color ?? c.sage, c.ink, c.isDark ? 0.0 : 0.2)!;
    return Semantics(
      label: context.l10n.onbStepOf(index + 1, count),
      child: Row(
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: AnimatedContainer(
                duration: Motion.of(context, Motion.standard),
                curve: Motion.easeOut,
                height: 6,
                decoration: BoxDecoration(
                  color: i <= index ? done : c.ink.withValues(alpha: c.isDark ? 0.14 : 0.10),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
