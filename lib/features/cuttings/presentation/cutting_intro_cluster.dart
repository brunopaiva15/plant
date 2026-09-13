import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../onboarding/presentation/clay_illustration.dart';
import '../application/cutting_guide_steps.dart';
import 'clay_sequence.dart';

/// Une séquence de la page d'introduction : sa place, sa taille, et la
/// dérive lente qui la fait graviter autour de cette place.
class _Piece {
  const _Piece({required this.x, required this.y, required this.scale, required this.phase, required this.orbit, required this.period});

  /// Ancrage, en fraction du côté, depuis le centre de la scène.
  final double x;
  final double y;

  /// Taille de l'objet, en fraction du côté de la scène.
  final double scale;

  /// Décalage de départ de la dérive, en tours.
  final double phase;

  /// Rayon de la dérive, en fraction du côté.
  final double orbit;

  /// Durée d'un tour complet, en secondes.
  final double period;
}

/// Les six objets, dans l'ordre des étapes, de l'arrière vers l'avant : la
/// rangée du haut, puis celle du bas, qui passe devant.
const _pieces = <_Piece>[
  _Piece(x: -0.27, y: -0.16, scale: 0.44, phase: 0.00, orbit: 0.014, period: 11.0),
  _Piece(x: 0.06, y: -0.19, scale: 0.44, phase: 0.35, orbit: 0.012, period: 13.0),
  _Piece(x: 0.36, y: -0.12, scale: 0.40, phase: 0.62, orbit: 0.016, period: 9.5),
  _Piece(x: -0.31, y: 0.21, scale: 0.40, phase: 0.18, orbit: 0.018, period: 8.0),
  _Piece(x: 0.01, y: 0.23, scale: 0.42, phase: 0.80, orbit: 0.015, period: 10.0),
  _Piece(x: 0.32, y: 0.20, scale: 0.40, phase: 0.50, orbit: 0.020, period: 7.5),
];

/// Les six gestes réunis, sur la page qui ouvre le guide.
///
/// Chaque séquence joue à petite taille, l'une à côté de l'autre, et dérive
/// lentement autour de sa place, à son rythme et sur son ellipse, comme la
/// collection de l'onboarding. C'est le guide entier vu d'un coup, avant de
/// le feuilleter étape par étape. Sans ombre au sol : les objets ne sont
/// posés sur rien, ils flottent dans le halo.
class CuttingIntroCluster extends StatefulWidget {
  const CuttingIntroCluster({super.key, required this.side, this.animate = true});

  /// Côté de la scène, en points.
  final double side;

  /// La page est-elle à l'affichage ? À `false`, tout se pose.
  final bool animate;

  @override
  State<CuttingIntroCluster> createState() => _CuttingIntroClusterState();
}

class _CuttingIntroClusterState extends State<CuttingIntroCluster> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);

  /// L'horloge de la dérive : son temps fait tourner les ellipses, son
  /// amplitude dit à quel point elles s'écartent de leur place.
  final _breath = Breath();
  bool _wanted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(CuttingIntroCluster old) {
    super.didUpdateWidget(old);
    _sync();
  }

  bool get _reduceMotion => MediaQuery.disableAnimationsOf(context);

  void _sync() {
    final reduce = _reduceMotion;
    _wanted = widget.animate && !reduce;
    if (reduce) {
      if (_ticker.isActive) _ticker.stop();
      if (!_breath.resting) setState(_breath.rest);
      return;
    }
    if (_wanted && !_ticker.isActive) _ticker.start();
  }

  void _tick(Duration elapsed) {
    setState(() => _breath.advance(elapsed, breathing: _wanted));
    if (!_wanted && _breath.resting) _ticker.stop();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final side = widget.side;
    return SizedBox.square(
      dimension: side,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [for (final (i, piece) in _pieces.indexed) _one(i, piece, side)],
      ),
    );
  }

  Widget _one(int index, _Piece piece, double side) {
    final angle = 2 * math.pi * (piece.phase + _breath.seconds / piece.period);
    final level = _breath.level;
    final dx = math.cos(angle) * piece.orbit * side * level;
    final dy = math.sin(angle) * piece.orbit * side * 0.62 * level;
    final tilt = math.sin(angle - math.pi / 2) * 0.02 * level;
    return Transform.translate(
      offset: Offset(piece.x * side + dx, piece.y * side + dy),
      child: Transform.rotate(
        angle: tilt,
        child: ClaySequence(asset: cuttingGuideSteps[index].asset, side: side * piece.scale, animate: widget.animate, float: false),
      ),
    );
  }
}
