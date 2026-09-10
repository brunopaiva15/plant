import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'clay_illustration.dart';

/// Une plante de la collection : son image, sa place, sa taille, et la dérive
/// lente qui la fait graviter autour de cette place.
class _Plant {
  const _Plant(this.name, {required this.x, required this.y, required this.scale, required this.phase, required this.orbit, required this.period});

  final String name;

  /// Ancrage, en fraction du côté, depuis le centre de la scène.
  final double x;
  final double y;

  /// Taille de la plante, en fraction du côté de la scène.
  final double scale;

  /// Décalage de départ de la dérive, en tours.
  final double phase;

  /// Rayon de la dérive, en fraction du côté.
  final double orbit;

  /// Durée d'un tour complet, en secondes.
  final double period;

  String get asset => 'assets/onboarding/collection_$name.webp';
}

/// La collection, de l'arrière vers l'avant : les dernières passent devant.
const _plants = <_Plant>[
  _Plant('sansevieria', x: -0.28, y: -0.12, scale: 0.46, phase: 0.00, orbit: 0.016, period: 11.0),
  _Plant('monstera', x: 0.02, y: -0.10, scale: 0.56, phase: 0.35, orbit: 0.013, period: 13.0),
  _Plant('caoutchouc', x: 0.27, y: -0.02, scale: 0.46, phase: 0.62, orbit: 0.018, period: 9.5),
  _Plant('ronde', x: -0.17, y: 0.22, scale: 0.34, phase: 0.18, orbit: 0.021, period: 8.0),
  _Plant('semis', x: 0.20, y: 0.26, scale: 0.27, phase: 0.80, orbit: 0.024, period: 7.0),
];

/// Les plantes qui gravitent de l'écran « Toutes vos plantes, ici ».
///
/// Cinq silhouettes différentes — un monstera, un caoutchouc, une
/// sansevieria, une petite plante ronde, un semis — posées les unes à côté
/// des autres, chacune dérivant lentement autour de sa place, à son rythme et
/// sur son ellipse. Aucune ne tourne à la vitesse d'une autre : la
/// composition ne se remet jamais telle qu'elle était, et rien ne bat la
/// mesure.
///
/// Elles ne portent pas d'ombre au sol : elles ne sont posées sur rien, elles
/// flottent dans le halo de l'écran.
///
/// Les images sont rendues sous Blender (`tool/build_collection.py`), une par
/// plante. Rien n'est décodé en cours de route : elles sont posées une fois,
/// et c'est le moteur de rendu qui les fait dériver, à la cadence de l'écran.
/// Avec « réduire les animations », elles restent à leur place.
class PlantCluster extends StatefulWidget {
  const PlantCluster({super.key, required this.side, this.animate = true});

  /// Côté de la scène, en points.
  final double side;

  /// L'écran est-il à l'affichage ? À `false`, tout se pose.
  final bool animate;

  /// Décode d'avance les cinq images, pour que la scène arrive nette.
  static Future<void> precache(BuildContext context, double side) {
    final ratio = MediaQuery.devicePixelRatioOf(context);
    return Future.wait([
      for (final plant in _plants) precacheImage(ClayIllustration.provider(plant.asset, side * plant.scale, ratio), context),
    ]);
  }

  @override
  State<PlantCluster> createState() => _PlantClusterState();
}

class _PlantClusterState extends State<PlantCluster> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);

  /// L'horloge de la dérive : son temps fait tourner les ellipses, son
  /// amplitude dit à quel point elles s'écartent de leur place.
  final _breath = Breath();

  /// Les plantes doivent-elles dériver ? Relevé à chaque changement, pour que
  /// le tick n'ait pas à interroger le contexte.
  bool _wanted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(PlantCluster old) {
    super.didUpdateWidget(old);
    _sync();
  }

  bool get _reduceMotion => MediaQuery.disableAnimationsOf(context);

  void _sync() {
    final reduce = _reduceMotion;
    _wanted = widget.animate && !reduce;
    if (reduce) {
      if (_ticker.isActive) _ticker.stop();
      // Posées d'emblée : la composition est exactement celle qui a été
      // choisie, et rien n'a à s'en retirer.
      if (!_breath.resting) setState(_breath.rest);
      return;
    }
    if (_wanted && !_ticker.isActive) _ticker.start();
    // Celles qui s'en vont gardent l'horloge le temps de revenir à leur
    // place : c'est [_tick] qui la range.
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
    final ratio = MediaQuery.devicePixelRatioOf(context);
    return SizedBox.square(
      dimension: side,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          for (final plant in _plants) _one(plant, side, ratio),
        ],
      ),
    );
  }

  Widget _one(_Plant plant, double side, double ratio) {
    final angle = 2 * math.pi * (plant.phase + _breath.seconds / plant.period);
    // Une ellipse plus large que haute : cela dérive, cela ne tourne pas en
    // rond. L'inclinaison est en retard d'un quart de tour sur la dérive, ce
    // qui donne un objet qui flotte plutôt qu'un objet qui oscille.
    //
    // L'amplitude ouvre et referme l'ellipse : chaque plante part de sa place
    // et y revient. Sans elle, la dérive s'ouvrait d'un coup à sa phase de
    // départ, et les cinq plantes sautaient ensemble en arrivant au centre.
    final level = _breath.level;
    final dx = math.cos(angle) * plant.orbit * side * level;
    final dy = math.sin(angle) * plant.orbit * side * 0.62 * level;
    final tilt = math.sin(angle - math.pi / 2) * 0.02 * level;
    final plantSide = side * plant.scale;
    return Transform.translate(
      offset: Offset(plant.x * side + dx, plant.y * side + dy),
      child: Transform.rotate(
        angle: tilt,
        child: Image(
          image: ClayIllustration.provider(plant.asset, plantSide, ratio),
          width: plantSide,
          height: plantSide,
          fit: BoxFit.contain,
          gaplessPlayback: true,
          filterQuality: FilterQuality.high,
          excludeFromSemantics: true,
        ),
      ),
    );
  }
}
