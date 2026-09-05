import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import 'clay_illustration.dart';

/// La scène de l'onboarding : les cinq objets du jardin, en orbite.
///
/// Les écrans ne défilent pas l'un après l'autre comme des diapositives : les
/// objets, eux, restent là et changent de place. Celui de l'écran courant est
/// au centre, net et animé ; les autres attendent hors champ et traversent
/// l'écran au rythme du doigt — le mouvement suit le geste, il n'est pas joué
/// après coup.
class OnboardingStage extends StatelessWidget {
  const OnboardingStage({
    super.key,
    required this.count,
    required this.offset,
    required this.page,
    required this.entry,
    required this.height,
    required this.reduceMotion,
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

  /// Côté de l'objet central : la scène lui laisse les deux tiers de sa
  /// hauteur, le reste va aux éclats qui l'entourent.
  double get side => (height * 0.66).roundToDouble();

  /// Taille visible de la scène : elle se referme quand on quitte les écrans
  /// de présentation, pour laisser toute la hauteur au prénom.
  double get visibleHeight => height * (1 - _leaving);

  /// De 0 à 1 quand on passe des présentations à la page du prénom.
  double get _leaving => (offset - (count - 1)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final leaving = _leaving;
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
                      for (var i = count - 1; i >= 0; i--) _object(context, i, width),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _object(BuildContext context, int index, double width) {
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
    final dy = -30 * d.sign * near + 26 * (1 - Curves.easeOutCubic.transform(entry)) * (1 - near);
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

/// Le fond : trois souffles de couleur qui dérivent lentement et changent de
/// teinte d'un écran à l'autre. Rien n'a de bord : c'est ce qui distingue une
/// ambiance d'un aplat.
class OnboardingAurora extends StatelessWidget {
  const OnboardingAurora({super.key, required this.tint, required this.drift, required this.reduceMotion});

  /// La couleur de l'écran courant, déjà interpolée entre deux écrans.
  final Color tint;

  final double drift;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final phase = reduceMotion ? 0.0 : drift * 2 * math.pi;
    return IgnorePointer(
      child: Stack(
        children: [
          _Blob(color: tint.withValues(alpha: 0.28), size: 460, at: Alignment(-0.9 + 0.10 * math.sin(phase), -0.75 + 0.06 * math.cos(phase))),
          _Blob(color: tint.withValues(alpha: 0.20), size: 380, at: Alignment(1.0 + 0.08 * math.cos(phase * 0.8), -0.2 + 0.10 * math.sin(phase * 0.7))),
          _Blob(color: c.sage.withValues(alpha: 0.10), size: 520, at: Alignment(0.1 + 0.12 * math.sin(phase * 0.6), 1.05 + 0.05 * math.cos(phase))),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.color, required this.size, required this.at});

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

/// Un titre qui se lève mot à mot, chaque mot sortant de sa propre ligne.
///
/// Le masque compte autant que le mouvement : sans lui les mots glisseraient
/// sur le fond au lieu d'émerger du texte.
class RisingTitle extends StatelessWidget {
  const RisingTitle({super.key, required this.text, required this.style, required this.t});

  final String text;
  final TextStyle style;

  /// Avancement de la levée (0 → 1).
  final double t;

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
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 2,
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
/// pleine. Plus discret qu'une rangée de points, et plus grand.
class OnboardingProgress extends StatelessWidget {
  const OnboardingProgress({super.key, required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
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
                height: 4,
                decoration: BoxDecoration(color: i <= index ? c.sage : c.line, borderRadius: BorderRadius.circular(2)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
