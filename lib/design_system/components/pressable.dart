import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../core/haptics.dart';
import '../tokens/motion.dart';

/// Côté minimal d'une cible tactile, en points.
///
/// Les HIG d'Apple ne transigent pas : 44 × 44. Un rond de 32 px reste un
/// rond de 32 px à l'écran — c'est la surface qui écoute le doigt qui
/// s'élargit autour, sans rien déplacer.
const double kMinTapTarget = 44;

/// Surface tactile qui s'écrase sous le doigt et se détend au relâchement.
///
/// Deux choses la distinguent d'un simple rétrécissement. D'abord la pièce
/// **s'aplatit plus qu'elle ne s'éloigne** : l'axe vertical cède environ
/// quatre fois plus que l'horizontal, comme une pâte qu'on écrase — un
/// rétrécissement égal dans les deux axes, c'est du papier qui s'en va, pas
/// de l'argile qui reçoit un doigt. Ensuite le
/// retour est un **ressort** ([Springs.release]) : il reprend la vitesse en
/// cours et dépasse d'un cheveu, si bien qu'un doigt relâché en plein appui
/// ne rejoue pas une animation depuis le début.
///
/// Elle diffuse aussi sa pression à l'argile sous elle ([PressDepth]) : le
/// relief d'un [ClayBox] rentre pendant qu'on appuie dessus.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = 0.97,
    this.haptic = true,
    this.enabled = true,
    this.semanticLabel,
    this.semanticHint,
    this.minTapTarget = true,
    this.highlightColor,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final bool haptic;
  final bool enabled;
  final String? semanticLabel;

  /// Ce que l'action fera, dit à VoiceOver après le libellé.
  final String? semanticHint;

  /// Élargit la zone d'écoute à [kMinTapTarget] sans toucher au dessin.
  ///
  /// À désactiver seulement quand un parent garantit déjà la surface et que
  /// l'agrandissement décalerait la mise en page.
  final bool minTapTarget;

  /// Voile posé pendant l'appui, pour les surfaces qui ne se rétractent pas
  /// (les lignes de liste, qui doivent malgré tout répondre au doigt).
  final Color? highlightColor;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> with SingleTickerProviderStateMixin {
  /// La pression, de 0 (au repos) à 1 (enfoncée). Sans bornes : le ressort du
  /// relâchement passe sous zéro, et c'est ce dépassement qui fait la détente.
  late final AnimationController _press = AnimationController.unbounded(vsync: this);

  bool _down = false;

  /// Faut-il jouer le ressort ? Lu à l'abonnement, pas dans le rappel du
  /// geste : une pièce qui disparaît sous le doigt annule son appui *pendant*
  /// qu'elle se démonte, et un élément désactivé ne peut plus remonter à son
  /// [MediaQuery].
  bool _animate = true;

  /// L'écrasement : ce qu'on retire à la hauteur et qu'on rend à la largeur,
  /// de part et d'autre du rétrécissement commun.
  ///
  /// Borné à deux points de pourcentage — au-delà, un bouton qui se rétracte
  /// beaucoup (0,9 pour un bouton icône) deviendrait une flaque. Et toujours
  /// sous le rétrécissement lui-même, pour qu'une carte pleine largeur ne
  /// déborde jamais de ses marges sous le doigt.
  static const double _maxSquash = 0.02;

  double get _squash => math.min((1 - widget.scale) * 0.6, _maxSquash);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _animate = !MediaQuery.disableAnimationsOf(context);
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  void _set(bool down) {
    if (_down == down || !mounted) return;
    _down = down;
    _press.springTo(down ? 1 : 0, spring: down ? Springs.press : Springs.release, animate: _animate);
  }

  @override
  Widget build(BuildContext context) {
    final interactive = widget.enabled && (widget.onTap != null || widget.onLongPress != null);
    Widget child = widget.child;
    if (widget.highlightColor != null) {
      child = _Highlight(press: _press, color: widget.highlightColor!, enabled: interactive, child: child);
    }
    // La pression descend aux [ClayBox] de la pièce : le relief s'enfonce
    // avec elle.
    child = PressDepth(depth: _press, child: child);
    final shrink = 1 - widget.scale;
    return Semantics(
      button: interactive,
      enabled: interactive,
      label: widget.semanticLabel,
      hint: widget.semanticHint,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: interactive ? (_) => _set(true) : null,
        onTapUp: interactive ? (_) => _set(false) : null,
        onTapCancel: interactive ? () => _set(false) : null,
        onTap: interactive && widget.onTap != null
            ? () {
                if (widget.haptic) Haptics.light();
                widget.onTap!();
              }
            : null,
        onLongPress: interactive && widget.onLongPress != null
            ? () {
                _set(false);
                Haptics.success();
                widget.onLongPress!();
              }
            : null,
        child: MinTapTarget(
          enabled: widget.minTapTarget,
          child: AnimatedBuilder(
            animation: _press,
            builder: (context, child) {
              final p = _press.value;
              return Transform(
                transform: Matrix4.diagonal3Values(1 - (shrink - _squash) * p, 1 - (shrink + _squash) * p, 1),
                alignment: Alignment.center,
                child: child,
              );
            },
            child: AnimatedOpacity(
              opacity: widget.enabled ? 1 : 0.45,
              duration: Motion.of(context, Motion.micro),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Le voile d'appui des surfaces qui ne s'écrasent pas — les lignes de liste,
/// qui doivent malgré tout répondre au doigt. Il suit la même pression, donc
/// la même détente.
class _Highlight extends StatelessWidget {
  const _Highlight({required this.press, required this.color, required this.enabled, required this.child});

  final Animation<double> press;
  final Color color;
  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: press,
      builder: (context, child) => ColoredBox(
        color: color.withValues(alpha: color.a * (enabled ? press.value.clamp(0.0, 1.0) : 0)),
        child: child,
      ),
      child: child,
    );
  }
}

/// La pression d'un [Pressable], offerte à l'argile qui se trouve dessous.
///
/// C'est un [InheritedWidget] et non un [InheritedNotifier] à dessein : ce qui
/// change soixante fois par seconde, c'est la valeur du contrôleur, pas le
/// widget. Les pièces d'argile s'y abonnent elles-mêmes, et seul leur peintre
/// repasse — le reste de l'arbre ne se reconstruit pas sous le doigt.
class PressDepth extends InheritedWidget {
  const PressDepth({super.key, required this.depth, required super.child});

  /// De 0 (au repos) à 1 (enfoncée) ; dépasse un peu de part et d'autre.
  final Animation<double> depth;

  /// La pression du [Pressable] le plus proche, ou `null` hors de tout appui.
  static Animation<double>? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PressDepth>()?.depth;

  @override
  bool updateShouldNotify(PressDepth old) => old.depth != depth;
}

/// Réserve [kMinTapTarget] autour de son enfant sans l'étirer : l'enfant garde
/// sa taille naturelle, centré, et c'est la boîte qui grandit.
///
/// Quand le parent impose déjà une hauteur ou une largeur au moins égale à la
/// cible, les contraintes passent intactes : une carte pleine largeur se pose
/// exactement comme avant.
class MinTapTarget extends SingleChildRenderObjectWidget {
  const MinTapTarget({super.key, this.enabled = true, this.size = kMinTapTarget, required Widget super.child});

  final bool enabled;
  final double size;

  Size get _target => enabled ? Size(size, size) : Size.zero;

  @override
  RenderMinTapTarget createRenderObject(BuildContext context) => RenderMinTapTarget(_target);

  @override
  void updateRenderObject(BuildContext context, RenderMinTapTarget renderObject) {
    renderObject.target = _target;
  }
}

class RenderMinTapTarget extends RenderShiftedBox {
  RenderMinTapTarget(this._target) : super(null);

  Size _target;

  Size get target => _target;

  set target(Size value) {
    if (_target == value) return;
    _target = value;
    markNeedsLayout();
  }

  /// Ne relâche que les minimums qui sont sous la cible : au-dessus, le parent
  /// savait ce qu'il voulait, on ne s'en mêle pas.
  BoxConstraints _forChild(BoxConstraints c) => BoxConstraints(
        minWidth: c.minWidth >= _target.width ? c.minWidth : 0,
        maxWidth: c.maxWidth,
        minHeight: c.minHeight >= _target.height ? c.minHeight : 0,
        maxHeight: c.maxHeight,
      );

  @override
  double computeMinIntrinsicWidth(double height) => math.max(super.computeMinIntrinsicWidth(height), _target.width);

  @override
  double computeMaxIntrinsicWidth(double height) => math.max(super.computeMaxIntrinsicWidth(height), _target.width);

  @override
  double computeMinIntrinsicHeight(double width) => math.max(super.computeMinIntrinsicHeight(width), _target.height);

  @override
  double computeMaxIntrinsicHeight(double width) => math.max(super.computeMaxIntrinsicHeight(width), _target.height);

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final child = this.child;
    if (child == null) return constraints.constrain(_target);
    final childSize = child.getDryLayout(_forChild(constraints));
    return constraints.constrain(
      Size(math.max(childSize.width, _target.width), math.max(childSize.height, _target.height)),
    );
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.constrain(_target);
      return;
    }
    child.layout(_forChild(constraints), parentUsesSize: true);
    size = constraints.constrain(
      Size(math.max(child.size.width, _target.width), math.max(child.size.height, _target.height)),
    );
    (child.parentData! as BoxParentData).offset = Alignment.center.alongOffset(size - child.size as Offset);
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (super.hitTest(result, position: position)) return true;
    if (!size.contains(position)) return false;
    // Le doigt est tombé dans la marge ajoutée : on le renvoie au centre de
    // l'enfant, pour que ce soit bien lui qui réponde.
    final child = this.child;
    if (child == null) return false;
    final center = child.size.center(Offset.zero);
    return result.addWithRawTransform(
      transform: MatrixUtils.forceToPoint(center),
      position: center,
      hitTest: (BoxHitTestResult result, Offset position) => child.hitTest(result, position: center),
    );
  }
}
