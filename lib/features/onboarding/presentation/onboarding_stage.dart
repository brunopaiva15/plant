import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import 'clay_illustration.dart';

/// La scène de l'onboarding : les cinq objets du jardin, qui se succèdent
/// au centre de l'écran sur un halo de couleur.
///
/// Les écrans ne défilent pas l'un après l'autre comme des diapositives : le
/// halo reste là et change de couleur, les objets changent de place. Celui
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
  /// geste. Sans elle, le halo prend le vert de l'app.
  final Color? tint;

  /// Côté de l'objet central pour une scène donnée : il prend presque toute
  /// la hauteur, sans jamais déborder des marges de la page.
  static double sideOf(double height, double width) => math.min(height * 0.92, width - 2 * inset).roundToDouble();

  /// Marge de la scène par rapport aux bords de l'écran.
  static const double inset = Space.page;

  /// Taille visible de la scène : elle rapetisse à l'approche du dernier
  /// écran, qui a ses propres boutons sous le texte, puis se referme quand on
  /// le quitte, pour laisser toute la hauteur au prénom.
  double get visibleHeight => height * shrink * (1 - _leaving);

  /// Part de sa taille que garde la scène sur le dernier écran.
  static const double compact = 0.62;

  /// De 1 (pleine taille) à [compact] entre l'avant-dernier et le dernier
  /// écran.
  double get shrink => 1 - (1 - compact) * _compacting;

  double get _compacting => count < 2 ? 0 : (offset - (count - 2)).clamp(0.0, 1.0);

  /// De 0 à 1 quand on passe du dernier écran à la page du prénom.
  double get _leaving => (offset - (count - 1)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final width = MediaQuery.sizeOf(context).width;
    final side = sideOf(height, width);
    final leaving = _leaving;
    final rise = Curves.easeOutCubic.transform(entry);
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
                  // La scène rapetisse d'un bloc, halo et objet ensemble,
                  // depuis son bord haut : ce qui est en dessous suit.
                  child: Transform.scale(
                    scale: shrink,
                    alignment: Alignment.topCenter,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        // Le halo : une tache de couleur douce, sans bord, qui
                        // s'épanouit à l'arrivée sur l'écran.
                        Transform.scale(
                          scale: reduceMotion ? 1 : 0.9 + 0.1 * rise,
                          child: _Halo(color: tint ?? c.sage, size: side * 1.18, dark: c.isDark),
                        ),
                        for (var i = count - 1; i >= 0; i--) _object(context, i, width, side, rise),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _object(BuildContext context, int index, double width, double side, double rise) {
    // Distance continue à la place centrale, en écrans.
    final d = index - offset;
    // Un voisin n'existe que le temps du geste : à l'arrêt, il ne reste que
    // l'objet du milieu. L'écran au repos est net, jamais encombré.
    final opacity = 1 - (d.abs() / 0.8).clamp(0.0, 1.0);
    if (opacity <= 0.01) return const SizedBox.shrink();

    final near = d.abs().clamp(0.0, 1.0);
    final scale = 1 - 0.4 * Curves.easeOutCubic.transform(near);
    // Ceux qui arrivent montent à droite et descendent à gauche : la
    // composition reste en diagonale, jamais alignée.
    final dx = d * 0.7 * width;
    final dy = -24 * d.sign * near + 20 * (1 - rise) * (1 - near);
    final blur = reduceMotion ? 0.0 : 5.0 * Curves.easeIn.transform(near);
    // L'objet arrive un peu petit et prend sa place, comme posé.
    final settle = reduceMotion ? 1.0 : 0.96 + 0.04 * rise;

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
        opacity: (opacity * (near < 0.02 ? (reduceMotion ? 1 : 0.4 + 0.6 * rise) : 1)).clamp(0.0, 1.0),
        child: Transform.scale(scale: scale * settle, child: object),
      ),
    );
  }
}

/// Une tache de couleur ronde et sans bord, plus dense au centre.
class _Halo extends StatelessWidget {
  const _Halo({required this.color, required this.size, required this.dark});

  final Color color;
  final double size;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: dark ? 0.42 : 0.34),
              color.withValues(alpha: dark ? 0.22 : 0.16),
              color.withValues(alpha: 0),
            ],
            stops: const [0, 0.45, 1],
          ),
        ),
      ),
    );
  }
}

/// Le fond : le fond de l'app, à peine teinté de la couleur de l'écran, et
/// deux lueurs très diffuses dans cette couleur — une qui monte derrière la
/// scène, une qui déborde d'un coin. Elles bougent d'un rien à l'arrivée sur
/// chaque écran, puis se posent.
class OnboardingBackdrop extends StatelessWidget {
  const OnboardingBackdrop({super.key, required this.tint, required this.drift, required this.reduceMotion, this.glow = 1});

  /// La couleur de l'écran courant, déjà interpolée entre deux écrans.
  final Color tint;

  /// Avancement du souffle d'arrivée, de 0 à 1.
  final double drift;
  final bool reduceMotion;

  /// Force des lueurs, de 0 à 1 : elles s'éteignent avec la scène quand on
  /// quitte les écrans de présentation.
  final double glow;

  /// Le fond d'un écran pour une couleur donnée : c'est aussi la couleur
  /// qu'on donne au [Scaffold], pour que rien ne dépasse aux bords.
  static Color wash(FloraColors c, Color tint) => Color.lerp(c.canvas, tint, c.isDark ? 0.06 : 0.04)!;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = reduceMotion ? 1.0 : Curves.easeOutCubic.transform(drift);
    return IgnorePointer(
      child: ColoredBox(
        color: wash(c, tint),
        child: Stack(
          children: [
            _Glow(
              color: tint.withValues(alpha: (c.isDark ? 0.20 : 0.16) * glow),
              size: 720,
              at: Alignment(-0.9, -1.1 + 0.06 * (1 - t)),
            ),
            _Glow(
              color: tint.withValues(alpha: (c.isDark ? 0.12 : 0.10) * glow),
              size: 560,
              at: Alignment(1.3, 0.1 - 0.05 * (1 - t)),
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

/// Le bouton de l'onboarding.
///
/// Plein : une dalle d'encre — noire en clair, blanche en sombre — aux coins
/// continus, comme les boutons des systèmes récents. Le texte y passe sur
/// toutes les teintes de l'onboarding, là où le blanc échouerait sur le
/// jaune ; et la couleur reste à la scène, le bouton n'a pas à s'en
/// disputer. Discret : le libellé seul, pour le choix secondaire.
class OnboardingButton extends StatelessWidget {
  const OnboardingButton({super.key, required this.label, required this.onPressed, this.trailingIcon, this.filled = true});

  final String label;
  final VoidCallback onPressed;
  final IconData? trailingIcon;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = filled ? c.canvas : c.ink.withValues(alpha: 0.7);
    final style = context.text.body.copyWith(color: fg, fontWeight: FontWeight.w600, fontSize: 17, letterSpacing: -0.3);
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label, style: style, maxLines: 1),
          ),
        ),
        if (trailingIcon != null) ...[const SizedBox(width: Space.xs), Icon(trailingIcon, size: 20, color: fg)],
      ],
    );
    return Pressable(
      onTap: onPressed,
      scale: 0.97,
      semanticLabel: label,
      child: filled
          ? Container(
              height: 56,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: Space.xl),
              decoration: ShapeDecoration(
                color: c.ink,
                shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(18)),
                shadows: [
                  BoxShadow(
                    color: c.ink.withValues(alpha: c.isDark ? 0.0 : 0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: row,
            )
          : Container(height: 48, alignment: Alignment.center, child: row),
    );
  }
}

/// Un titre qui se lève ligne à ligne, chaque ligne sortant de son propre
/// masque.
///
/// Le masque compte autant que le mouvement : sans lui les lignes glisseraient
/// sur le fond au lieu d'émerger du texte. Les lignes sont celles que le
/// texte prend à cette largeur : la hauteur du titre levé est exactement
/// celle du titre posé, et rien ne se coupe en dessous.
class RisingTitle extends StatelessWidget {
  const RisingTitle({super.key, required this.text, required this.style, required this.t});

  final String text;
  final TextStyle style;

  /// Avancement de la levée (0 → 1).
  final double t;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    // Mesuré et dessiné dans le même style, celui que [Text] utiliserait.
    final style = DefaultTextStyle.of(context).style.merge(this.style);
    return LayoutBuilder(
      builder: (context, constraints) {
        final lines = layoutLines(text, style, constraints.maxWidth, scaler, direction);
        // Le titre est découpé pour l'œil seulement : la synthèse vocale doit
        // entendre une phrase, pas une liste de lignes.
        return Semantics(
          label: text,
          header: true,
          excludeSemantics: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, line) in lines.indexed)
                ClipRect(
                  child: SizedBox(
                    height: line.height,
                    child: Builder(
                      builder: (context) {
                        // Les lignes se lèvent l'une après l'autre, en se
                        // chevauchant.
                        final start = (i * 0.18).clamp(0.0, 0.6);
                        final local = ((t - start) / (1 - start)).clamp(0.0, 1.0);
                        final eased = Curves.easeOutCubic.transform(local);
                        return Transform.translate(
                          offset: Offset(0, line.height * (1 - eased)),
                          child: Opacity(
                            opacity: eased,
                            child: Text(line.text, style: style, maxLines: 1, softWrap: false, overflow: TextOverflow.visible),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Les lignes que [text] occupe dans [style] à la largeur [width], avec
  /// leur hauteur.
  ///
  /// La fin de chaque ligne est le point situé à sa droite, hors du texte :
  /// c'est ce qui vaut sur tous les moteurs, là où la frontière de ligne du
  /// paragraphe ne compte pas les retours à la ligne automatiques partout.
  static List<TitleLine> layoutLines(String text, TextStyle style, double width, TextScaler scaler, TextDirection direction) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: direction,
      textScaler: scaler,
    )..layout(maxWidth: width);
    final lines = <TitleLine>[];
    var start = 0;
    var top = 0.0;
    for (final metrics in painter.computeLineMetrics()) {
      final end = math.max(painter.getPositionForOffset(Offset(width + 1, top + metrics.height / 2)).offset, start);
      final line = text.substring(start, end).trim();
      if (line.isNotEmpty) lines.add(TitleLine(line, metrics.height));
      top += metrics.height;
      start = end;
      // Une ligne se termine sur l'espace qui la sépare de la suivante.
      while (start < text.length && text[start] == ' ') {
        start++;
      }
      if (start >= text.length) break;
    }
    painter.dispose();
    return lines;
  }
}

/// Une ligne d'un titre levé : son texte et sa hauteur.
class TitleLine {
  const TitleLine(this.text, this.height);

  final String text;
  final double height;
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

/// Les points de progression : un par écran, celui de l'écran courant
/// s'étire en pilule dans la couleur de l'écran. C'est l'indicateur de page
/// du système, et il dit tout ce qu'il y a à dire.
class OnboardingProgress extends StatelessWidget {
  const OnboardingProgress({super.key, required this.count, required this.index, this.color});

  final int count;
  final int index;

  /// Couleur du pas courant. Sans elle, le vert de l'app.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final on = Color.lerp(color ?? c.sage, c.ink, c.isDark ? 0.0 : 0.15)!;
    return Semantics(
      label: context.l10n.onbStepOf(index + 1, count),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            AnimatedContainer(
              duration: Motion.of(context, Motion.emphasis),
              curve: Motion.emphasized,
              width: i == index ? 24 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: i == index ? on : c.ink.withValues(alpha: c.isDark ? 0.22 : 0.14),
                borderRadius: BorderRadius.circular(3.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
