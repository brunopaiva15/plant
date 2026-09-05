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

  /// Côté de l'objet central pour une hauteur de scène donnée : il occupe
  /// presque toute la carte, c'est lui qu'on regarde.
  static double sideOf(double height) => (height * 0.90).roundToDouble();

  /// Marge de la carte d'argile par rapport aux bords de l'écran.
  static const double inset = Space.page;

  double get side => sideOf(height);

  /// Taille visible de la scène : elle se referme quand on quitte les écrans
  /// de présentation, pour laisser toute la hauteur au prénom.
  double get visibleHeight => height * (1 - _leaving);

  /// De 0 à 1 quand on passe des présentations à la page du prénom.
  double get _leaving => (offset - (count - 1)).clamp(0.0, 1.0);

  /// Chaque carte penche d'un rien, tantôt à gauche, tantôt à droite : posée,
  /// pas alignée. Entre deux écrans, elle bascule de l'une à l'autre.
  static const _tilts = <double>[-0.03, 0.025, -0.02, 0.03, -0.025];

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
                      // La carte garde une marge dans la scène : penchée, ses
                      // coins ne doivent pas en sortir, et son ombre non plus.
                      Transform.translate(
                        offset: const Offset(0, 6),
                        child: Transform.scale(
                          scale: settle,
                          child: Transform.rotate(
                            angle: reduceMotion ? 0 : _tilt,
                            child: ClaySurface(
                              color: tint ?? c.sage,
                              radius: 44,
                              depth: 1.6,
                              child: SizedBox(width: width - 2 * inset - 8, height: height - 48),
                            ),
                          ),
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

/// Une surface d'argile : une forme gonflée, dans une couleur pastel
/// saturée, avec la lumière qui vient d'en haut à gauche.
///
/// La recette est celle du claymorphisme : une ombre portée dans la teinte
/// de la surface, un bord clair logé en haut à gauche, une ombre logée en
/// bas à droite. Les deux ombres intérieures sont ce qui fait la pâte —
/// sans elles il ne reste qu'un aplat arrondi. [depth] multiplie décalages
/// et flous : une grande carte a un relief plus profond qu'un bouton.
class ClaySurface extends StatelessWidget {
  const ClaySurface({super.key, required this.color, required this.child, this.radius = 24, this.depth = 1});

  /// La teinte de base : la surface en est une version pastel, l'ombre une
  /// version foncée.
  final Color color;
  final Widget child;
  final double radius;
  final double depth;

  /// La couleur de la surface pour une teinte donnée : coupée de blanc en
  /// clair, à peine assombrie en sombre, où les teintes sont déjà claires.
  static Color surfaceOf(FloraColors c, Color tint) => Color.lerp(tint, c.isDark ? c.canvas : Colors.white, c.isDark ? 0.18 : 0.30)!;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return CustomPaint(
      painter: _ClayPainter(surface: surfaceOf(c, color), tint: color, radius: radius, depth: depth, dark: c.isDark),
      isComplex: true,
      child: child,
    );
  }
}

class _ClayPainter extends CustomPainter {
  const _ClayPainter({required this.surface, required this.tint, required this.radius, required this.depth, required this.dark});

  final Color surface;
  final Color tint;
  final double radius;
  final double depth;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(radius)).getOuterPath(rect);
    final shade = Color.lerp(tint, Colors.black, 0.25)!;

    // L'ombre portée, décalée aussi en x : la lumière vient d'un coin.
    canvas.drawPath(
      path.shift(Offset(8 * depth, 8 * depth)),
      Paint()
        ..color = shade.withValues(alpha: dark ? 0.30 : 0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12 * depth),
    );

    // La surface : un pastel plein. Le relief vient des ombres, pas d'un
    // dégradé.
    canvas.drawPath(path, Paint()..color = surface);

    // Les ombres intérieures : tout ce qui est hors de la forme, décalé et
    // flouté, puis rogné à la forme. Décalé vers le bas à droite, le trou
    // laisse une lumière en haut à gauche ; vers le haut à gauche, une ombre
    // en bas à droite.
    final outside = rect.inflate(size.shortestSide);
    Path rim(Offset by) => Path.combine(PathOperation.difference, Path()..addRect(outside), path.shift(by));
    canvas.save();
    canvas.clipPath(path);
    canvas.drawPath(
      rim(Offset(6 * depth, 6 * depth)),
      Paint()
        ..color = Colors.white.withValues(alpha: dark ? 0.35 : 0.55)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 * depth),
    );
    canvas.drawPath(
      rim(Offset(-6 * depth, -6 * depth)),
      Paint()
        ..color = shade.withValues(alpha: dark ? 0.45 : 0.25)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 * depth),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ClayPainter old) => old.surface != surface || old.tint != tint || old.radius != radius || old.depth != depth || old.dark != dark;
}

/// Le fond : presque blanc, à peine teinté de la couleur de l'écran — c'est
/// la carte d'argile qui porte la couleur, pas la page. Une lueur douce
/// monte derrière la scène à l'arrivée, puis se pose.
class OnboardingBackdrop extends StatelessWidget {
  const OnboardingBackdrop({super.key, required this.tint, required this.drift, required this.reduceMotion, this.glow = 1});

  /// La couleur de l'écran courant, déjà interpolée entre deux écrans.
  final Color tint;

  /// Avancement du souffle d'arrivée, de 0 à 1 : la lueur monte d'un rien et
  /// s'arrête.
  final double drift;
  final bool reduceMotion;

  /// Force de la lueur, de 0 à 1 : elle s'éteint avec la scène quand on
  /// quitte les écrans de présentation.
  final double glow;

  /// Le fond d'un écran pour une couleur donnée : c'est aussi la couleur
  /// qu'on donne au [Scaffold], pour que rien ne dépasse aux bords.
  static Color wash(FloraColors c, Color tint) => Color.lerp(c.canvas, tint, c.isDark ? 0.08 : 0.05)!;

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
              color: tint.withValues(alpha: (c.isDark ? 0.16 : 0.18) * glow),
              size: 620,
              at: Alignment(0, -0.55 + 0.08 * (1 - t)),
            ),
            // Un halo bas, plus discret, qui répond au premier.
            _Glow(
              color: tint.withValues(alpha: (c.isDark ? 0.08 : 0.10) * glow),
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

/// Le bouton de l'onboarding : une pilule d'argile dans la couleur de
/// l'écran, texte en encre. Plus haut que la pilule de l'app — ici il n'y a
/// qu'un geste à faire, il doit s'imposer.
class ClayButton extends StatelessWidget {
  const ClayButton({super.key, required this.label, required this.onPressed, required this.tint, this.trailingIcon, this.filled = true});

  final String label;
  final VoidCallback onPressed;

  /// La couleur de l'écran : celle de la pâte du bouton plein, et du texte
  /// du bouton discret.
  final Color tint;
  final IconData? trailingIcon;

  /// Plein : la pilule d'argile, le geste principal. Sinon : un bouton
  /// discret, sans matière, pour le choix secondaire.
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // Le texte est toujours en encre : sur ces pastels, l'encre passe
    // partout, là où le blanc échouerait sur le jaune.
    final fg = filled ? FloraColors.light.ink : Color.lerp(tint, c.ink, c.isDark ? 0.0 : 0.25)!;
    final style = context.text.body.copyWith(color: fg, fontWeight: FontWeight.w700, fontSize: 18, letterSpacing: -0.2);
    final row = Row(
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
    );
    return Pressable(
      onTap: onPressed,
      scale: 0.965,
      semanticLabel: label,
      child: filled
          ? ClaySurface(
              color: tint,
              radius: 22,
              child: Container(
                height: 62,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: Space.xl),
                child: row,
              ),
            )
          : Container(height: 52, alignment: Alignment.center, child: row),
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
