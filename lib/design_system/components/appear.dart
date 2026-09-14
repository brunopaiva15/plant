import 'package:flutter/widgets.dart';

import '../tokens/motion.dart';

/// Une pièce qui se pose : elle monte de huit points en s'éclaircissant, une
/// seule fois, avec un rang de retard sur celle du dessus.
///
/// C'est ce qui fait qu'une liste **se pose** au lieu d'apparaître d'un bloc.
/// Le retard est court — trente millisecondes par rang — et plafonné : au-delà
/// de [maxRank] rangs, tout le monde part ensemble, sans quoi une longue liste
/// se déroulerait encore alors que le doigt est déjà en train de défiler.
///
/// Donner une clé stable à chaque pièce (l'identifiant de la plante, par
/// exemple) : l'état suit alors son élément, et une carte déjà posée ne
/// rejoue rien quand la liste se réordonne.
///
/// Avec *réduire les animations*, la pièce est simplement là.
class Appear extends StatefulWidget {
  const Appear({super.key, required this.child, this.rank = 0});

  final Widget child;

  /// Le rang dans la liste : c'est lui qui décale le départ.
  final int rank;

  /// Le retard d'un rang au suivant.
  static const Duration step = Duration(milliseconds: 30);

  /// Au-delà, plus de retard.
  static const int maxRank = 8;

  /// De combien la pièce monte en se posant.
  static const double rise = 8;

  @override
  State<Appear> createState() => _AppearState();
}

class _AppearState extends State<Appear> with SingleTickerProviderStateMixin {
  late final Duration _delay = Appear.step * widget.rank.clamp(0, Appear.maxRank);
  late final AnimationController _c = AnimationController(vsync: this, duration: _delay + Motion.standard);

  /// Le retard vit dans la courbe, pas dans un minuteur : un `Timer` en
  /// attente survivrait au widget et ferait échouer les tests qui vérifient
  /// qu'il n'en reste aucun.
  late final CurvedAnimation _in = CurvedAnimation(
    parent: _c,
    curve: Interval(_delay.inMicroseconds / _c.duration!.inMicroseconds, 1, curve: Motion.easeOut),
  );

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _in.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _in,
      builder: (context, child) => Opacity(
        opacity: _in.value,
        child: Transform.translate(offset: Offset(0, (1 - _in.value) * Appear.rise), child: child),
      ),
      child: widget.child,
    );
  }
}
