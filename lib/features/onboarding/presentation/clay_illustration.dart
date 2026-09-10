import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Une illustration 3D de l'onboarding : une seule image, en pleine
/// définition, que l'écran anime lui-même.
///
/// Les premières versions échangeaient vingt-quatre images pré-rendues à la
/// façon d'`UIImageView.animationImages`. C'était une boucle de faible
/// définition, qui sautait des images dès que le décodage prenait du retard,
/// et qui finissait par un remplacement visible par l'image nette. Ici il n'y
/// a rien à décoder en cours de route : l'image est posée une fois, et c'est
/// le moteur de rendu qui la fait flotter, à la cadence de l'écran, sans fin
/// et sans coupure. L'objet respire doucement — quelques points de haut en
/// bas, un degré d'inclinaison — et son ombre au sol suit le mouvement.
/// Avec « réduire les animations », il reste posé.
class ClayIllustration extends StatefulWidget {
  const ClayIllustration({super.key, required this.slide, required this.side, this.animate = true});

  /// Numéro de l'écran, de 1 à [count].
  final int slide;

  /// Côté de l'illustration, en points. La scène l'accorde à la hauteur de
  /// l'écran : grand sur un grand téléphone, plus sage sur un petit.
  final double side;

  /// L'écran est-il à l'affichage ? À `false`, l'objet reste posé.
  final bool animate;

  /// Nombre d'illustrations disponibles.
  static const int count = 6;

  /// Durée d'une respiration complète.
  static const Duration breath = Duration(milliseconds: 3400);

  /// Chemin de l'image d'un écran.
  static String still(int slide) => 'assets/onboarding/onboarding_$slide.png';

  /// L'image est décodée à la taille où elle s'affiche, pas à sa taille de
  /// fichier : elle fait 1024 px de côté et pèserait quatre mégaoctets en
  /// mémoire sans cela.
  static ImageProvider provider(String path, double side, double pixelRatio) {
    return ResizeImage(AssetImage(path), width: (side * pixelRatio).round(), policy: ResizeImagePolicy.fit);
  }

  /// Décode d'avance l'image d'un écran, pour qu'elle arrive nette.
  static Future<void> precache(BuildContext context, int slide, double side) {
    return precacheImage(provider(still(slide), side, MediaQuery.devicePixelRatioOf(context)), context);
  }

  @override
  State<ClayIllustration> createState() => _ClayIllustrationState();
}

/// La pose de l'objet à un instant donné : où il en est de sa respiration, et
/// à quelle amplitude il la respire.
///
/// Tout dérive d'une seule phase, en tours. La hauteur et l'inclinaison sont
/// des sinus de cette phase, décalés d'un quart de tour pour que l'objet ne
/// monte pas et ne penche pas en même temps : c'est ce décalage qui donne
/// l'impression d'un objet qui flotte plutôt que d'un objet qui oscille.
/// L'ombre au sol se resserre et pâlit quand l'objet monte.
///
/// L'amplitude est le second réglage, et il compte autant : aucune phase ne
/// donne l'objet posé — quand la hauteur s'annule l'inclinaison est à son
/// extrême —, si bien que le repos ne peut pas être un instant du cycle. Il
/// est une amplitude nulle, et l'objet passe de l'un à l'autre en respirant
/// plus ou moins fort, jamais d'un saut.
class BreathPose {
  const BreathPose(this.phase, {this.amplitude = 1});

  /// L'objet posé, immobile : ni décalé, ni penché, son ombre entière.
  const BreathPose.rest()
      : phase = 0,
        amplitude = 0;

  /// Avancement, en tours de respiration.
  final double phase;

  /// Ampleur de la respiration, de 0 (posé) à 1 (pleine).
  final double amplitude;

  double get _angle => phase * 2 * math.pi;

  /// Hauteur ramenée entre 0 (au plus bas, ou posé) et 1 (au plus haut) :
  /// c'est elle que suit l'ombre au sol.
  double get _height => amplitude * (math.sin(_angle) + 1) / 2;

  /// Hauteur, de -1 (au plus bas) à 1 (au plus haut).
  double get lift => amplitude * math.sin(_angle);

  /// Inclinaison, de -1 à 1, en retard d'un quart de tour sur la hauteur.
  double get tilt => amplitude * math.sin(_angle - math.pi / 2);

  /// Étendue de l'ombre au sol, de 0,82 (objet haut) à 1 (objet posé).
  double get shadowScale => 1 - 0.18 * _height;

  /// Opacité de l'ombre, de 0,55 (objet haut) à 1 (objet posé).
  double get shadowOpacity => 1 - 0.45 * _height;
}

/// L'horloge de ce qui vit sur la scène : la respiration d'un objet d'argile,
/// la pousse adulte de la plante de l'icône, la dérive des plantes de la
/// collection.
///
/// Elle donne deux choses : le temps écoulé, qui fait tourner le cycle, et
/// l'amplitude, qui dit à quel point l'objet vit. L'amplitude monte quand
/// l'objet arrive au centre et redescend quand il s'en va — c'est tout
/// l'intérêt de cette horloge. Sans elle, prendre et rendre son souffle
/// revenait à passer d'un coup entre deux poses sans rapport : l'objet
/// sautait d'un degré et son ombre d'un quart de son opacité, à chaque écran
/// quitté comme à chaque écran posé.
class Breath {
  /// Temps que met la respiration à s'installer, et à se retirer.
  static const Duration settle = Duration(milliseconds: 500);

  double _seconds = 0;
  double _level = 0;
  Duration _last = Duration.zero;

  /// Temps écoulé à respirer, en secondes.
  double get seconds => _seconds;

  /// À quel point l'objet respire, de 0 (posé) à 1 (pleine respiration).
  double get level => _level;

  /// L'objet est-il tout à fait posé ? L'horloge n'a alors plus rien à faire.
  bool get resting => _level <= 0;

  /// La pose d'un objet qui respire au rythme de [ClayIllustration.breath].
  BreathPose get pose => BreathPose(_seconds / _breathSeconds, amplitude: _level);

  static final double _breathSeconds = ClayIllustration.breath.inMicroseconds / Duration.microsecondsPerSecond;

  /// Avance l'horloge jusqu'à [elapsed], l'objet respirant ou non.
  ///
  /// Le pas est plafonné à une image : l'horloge d'un écran quitté puis repris
  /// recompte depuis zéro, et sans ce plafond le premier tick d'après ferait
  /// tourner l'objet de tout le temps passé ailleurs.
  void advance(Duration elapsed, {required bool breathing}) {
    final dt = ((elapsed - _last).inMicroseconds / Duration.microsecondsPerSecond).clamp(0.0, 1 / 30);
    _last = elapsed;
    _seconds += dt;
    final step = dt / (settle.inMicroseconds / Duration.microsecondsPerSecond);
    _level = (breathing ? _level + step : _level - step).clamp(0.0, 1.0);
  }

  /// Pose l'objet sur-le-champ, sans le laisser rendre son souffle. Sans
  /// animations, il n'y a rien à retirer en douceur : il n'a jamais respiré.
  void rest() {
    _seconds = 0;
    _level = 0;
  }
}

class _ClayIllustrationState extends State<ClayIllustration> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  final _breath = Breath();
  var _pose = const BreathPose.rest();

  /// L'objet doit-il respirer ? Relevé à chaque changement, pour que le tick
  /// n'ait pas à interroger le contexte.
  bool _wanted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Le réglage « réduire les animations » peut changer en cours de route.
    _sync();
  }

  @override
  void didUpdateWidget(ClayIllustration old) {
    super.didUpdateWidget(old);
    _sync();
  }

  bool get _reduceMotion => MediaQuery.disableAnimationsOf(context);

  /// Le ticker ne tourne que quand il a quelque chose à montrer : l'objet au
  /// centre de l'écran, animations permises — ou la respiration qu'il lui
  /// reste à rendre en le quittant.
  void _sync() {
    final reduce = _reduceMotion;
    _wanted = widget.animate && !reduce;
    if (reduce) {
      if (_ticker.isActive) _ticker.stop();
      if (!_breath.resting) {
        setState(() {
          _breath.rest();
          _pose = _breath.pose;
        });
      }
      return;
    }
    if (_wanted && !_ticker.isActive) _ticker.start();
    // L'objet qui s'en va garde son horloge le temps de reposer : c'est
    // [_tick] qui la range une fois la respiration rendue.
  }

  void _tick(Duration elapsed) {
    _breath.advance(elapsed, breathing: _wanted);
    setState(() => _pose = _breath.pose);
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
    return ClayFloat(
      side: side,
      pose: _pose,
      child: Image(
        image: ClayIllustration.provider(ClayIllustration.still(widget.slide), side, ratio),
        width: side,
        height: side,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        filterQuality: FilterQuality.high,
        excludeFromSemantics: true,
      ),
    );
  }
}

/// L'objet posé sur la scène : son ombre au sol, et la respiration qui les
/// lie. Ce qui flotte est donné par l'appelant — une image d'argile, ou la
/// plante de l'icône qui pousse.
class ClayFloat extends StatelessWidget {
  const ClayFloat({super.key, required this.side, required this.pose, required this.child});

  final double side;
  final BreathPose pose;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Quelques points de course et un degré d'angle : assez pour vivre,
    // pas assez pour distraire du titre.
    final dy = -pose.lift * side * 0.02;
    final angle = pose.tilt * 0.018;
    return SizedBox.square(
      dimension: side,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // L'ombre au sol, sous l'objet : elle dit à quelle hauteur il flotte.
          Positioned(
            bottom: side * 0.04,
            child: Transform.scale(
              scaleX: pose.shadowScale,
              scaleY: pose.shadowScale,
              child: Opacity(
                opacity: pose.shadowOpacity,
                child: Container(
                  width: side * 0.64,
                  height: side * 0.10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.elliptical(side * 0.32, side * 0.05)),
                    gradient: RadialGradient(
                      colors: [Colors.black.withValues(alpha: 0.14), Colors.black.withValues(alpha: 0)],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(0, dy),
            child: Transform.rotate(angle: angle, child: child),
          ),
        ],
      ),
    );
  }
}
