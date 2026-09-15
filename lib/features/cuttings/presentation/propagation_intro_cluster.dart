import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../onboarding/presentation/clay_illustration.dart';
import '../application/propagation_guides.dart';
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

/// Range [count] objets sur deux rangées, la seconde passant devant.
///
/// Un guide n'a pas toujours six étapes : la grappe se calcule, elle n'est
/// plus écrite à la main. Quatre objets tiennent en deux rangées de deux,
/// huit en deux rangées de quatre, et chacun garde sa dérive propre — deux
/// objets qui tourneraient ensemble se verraient.
List<_Piece> _layout(int count) {
  if (count <= 0) return const [];
  final haut = (count + 1) ~/ 2;
  final bas = count - haut;
  final parRangee = math.max(haut, bas);
  final scale = 1.45 / (parRangee + 0.45);
  final demi = 0.5 - scale * 0.52;
  // Les périodes ne sont pas des multiples les unes des autres : la grappe
  // ne retombe jamais dans la même figure.
  const periodes = [11.0, 13.0, 9.5, 8.0, 10.0, 7.5, 12.0, 8.8];
  const phases = [0.0, 0.35, 0.62, 0.18, 0.80, 0.50, 0.24, 0.68];
  const orbites = [0.014, 0.012, 0.016, 0.018, 0.015, 0.020, 0.013, 0.017];

  double place(int i, int n) => n == 1 ? 0.0 : -demi + 2 * demi * i / (n - 1);

  return [
    for (var i = 0; i < count; i++)
      () {
        final enHaut = i < haut;
        final rang = enHaut ? i : i - haut;
        final n = enHaut ? haut : bas;
        return _Piece(
          x: place(rang, n),
          // La rangée du bas descend un peu plus qu'elle ne monte : elle
          // passe devant, et la grappe s'assied.
          y: (enHaut ? -0.17 : 0.21) + (i.isEven ? -0.02 : 0.02),
          scale: scale * (i.isEven ? 1.0 : 0.94),
          phase: phases[i % phases.length],
          orbit: orbites[i % orbites.length],
          period: periodes[i % periodes.length],
        );
      }(),
  ];
}

/// Les gestes du guide réunis, sur la page qui l'ouvre.
///
/// Chaque séquence joue à petite taille, l'une à côté de l'autre, et dérive
/// lentement autour de sa place, à son rythme et sur son ellipse, comme la
/// collection de l'onboarding. C'est le guide entier vu d'un coup, avant de
/// le feuilleter étape par étape. Sans ombre au sol : les objets ne sont
/// posés sur rien, ils flottent dans le halo.
class PropagationIntroCluster extends StatefulWidget {
  const PropagationIntroCluster({super.key, required this.steps, required this.side, this.animate = true});

  /// Les étapes du guide, dans l'ordre.
  final List<PropagationStep> steps;

  /// Côté de la scène, en points.
  final double side;

  /// La page est-elle à l'affichage ? À `false`, tout se pose.
  final bool animate;

  @override
  State<PropagationIntroCluster> createState() => _PropagationIntroClusterState();
}

class _PropagationIntroClusterState extends State<PropagationIntroCluster> with SingleTickerProviderStateMixin {
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
  void didUpdateWidget(PropagationIntroCluster old) {
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
    final pieces = _layout(widget.steps.length);
    return SizedBox.square(
      dimension: side,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [for (final (i, piece) in pieces.indexed) _one(i, piece, side)],
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
        child: ClaySequence(asset: widget.steps[index].asset, side: side * piece.scale, animate: widget.animate, float: false),
      ),
    );
  }
}
