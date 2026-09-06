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

/// La pose de l'objet à un instant donné : où il en est de sa respiration.
///
/// Tout dérive d'une seule phase, en tours. La hauteur et l'inclinaison sont
/// des sinus de cette phase, décalés d'un quart de tour pour que l'objet ne
/// monte pas et ne penche pas en même temps : c'est ce décalage qui donne
/// l'impression d'un objet qui flotte plutôt que d'un objet qui oscille.
/// L'ombre au sol se resserre et pâlit quand l'objet monte.
@visibleForTesting
class BreathPose {
  const BreathPose(this.phase);

  /// Avancement, en tours de respiration.
  final double phase;

  double get _angle => phase * 2 * math.pi;

  /// Hauteur, de -1 (au plus bas) à 1 (au plus haut).
  double get lift => math.sin(_angle);

  /// Inclinaison, de -1 à 1, en retard d'un quart de tour sur la hauteur.
  double get tilt => math.sin(_angle - math.pi / 2);

  /// Étendue de l'ombre au sol, de 0,82 (objet haut) à 1 (objet posé).
  double get shadowScale => 1 - 0.09 * (lift + 1);

  /// Opacité de l'ombre, de 0,55 (objet haut) à 1 (objet posé).
  double get shadowOpacity => 1 - 0.225 * (lift + 1);
}

class _ClayIllustrationState extends State<ClayIllustration> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  var _pose = const BreathPose(0);


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
  /// centre de l'écran, animations permises.
  void _sync() {
    final wanted = widget.animate && !_reduceMotion;
    if (wanted && !_ticker.isActive) {
      _ticker.start();
    } else if (!wanted && _ticker.isActive) {
      _ticker.stop();
      // Posé : à la hauteur de repos, sans inclinaison. L'objet ne quitte le
      // centre qu'en glissant hors champ, flou : ce retour au repos ne se
      // voit pas, et la respiration repart du repos à son retour.
      setState(() => _pose = const BreathPose(0));
    }
  }

  void _tick(Duration elapsed) {
    // La respiration part de la pose de repos : la phase zéro est l'objet
    // posé, ni haut ni bas, sans inclinaison, et la vitesse y est continue.
    setState(() => _pose = BreathPose(elapsed.inMicroseconds / ClayIllustration.breath.inMicroseconds));
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
    final pose = _pose;
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
            child: Transform.rotate(
              angle: angle,
              child: Image(
                image: ClayIllustration.provider(ClayIllustration.still(widget.slide), side, ratio),
                width: side,
                height: side,
                fit: BoxFit.contain,
                gaplessPlayback: true,
                filterQuality: FilterQuality.high,
                excludeFromSemantics: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
