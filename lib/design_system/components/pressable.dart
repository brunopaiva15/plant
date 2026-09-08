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

/// Surface tactile qui se rétracte légèrement à la pression (sensation iOS).
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

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final interactive = widget.enabled && (widget.onTap != null || widget.onLongPress != null);
    Widget child = widget.child;
    if (widget.highlightColor != null) {
      child = AnimatedContainer(
        duration: Motion.of(context, Motion.micro),
        color: _down && interactive ? widget.highlightColor : widget.highlightColor!.withValues(alpha: 0),
        child: child,
      );
    }
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
          child: AnimatedScale(
            scale: _down ? widget.scale : 1,
            duration: Motion.of(context, Motion.micro),
            curve: Motion.easeOut,
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
