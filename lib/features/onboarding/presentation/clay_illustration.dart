import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Une illustration 3D de l'onboarding : une image fixe, et une boucle de 24
/// images jouée à l'arrivée sur l'écran.
///
/// Le principe est celui d'`UIImageView.animationImages` : les 24 images sont
/// décodées à l'avance, puis échangées au rythme du ticker. L'image fixe reste
/// le repli — c'est elle que l'on voit avant le décodage, et c'est la seule
/// chose affichée si le système demande de réduire les animations.
///
/// La boucle ne tourne pas sans fin, et elle ne s'arrête pas net non plus :
/// elle joue [playFor] à vitesse constante, puis ralentit sans à-coup — sa
/// vitesse décroît jusqu'à zéro — pour se poser exactement sur la pose de
/// l'image fixe. Un objet qui s'immobilise comme un pendule qui s'apaise
/// ressemble à quelque chose de vivant ; un objet qui se fige d'un coup
/// ressemble à une image qu'on aurait remplacée.
///
/// Les images de la boucle sont plus petites que l'image fixe. Pour que le
/// changement de définition ne se voie pas, l'image fixe se fond dans la
/// première image au départ, et la dernière image se fond dans l'image fixe
/// quand l'objet ne bouge presque plus.
class ClayIllustration extends StatefulWidget {
  const ClayIllustration({super.key, required this.slide, required this.side, this.animate = true, this.playFor = const Duration(milliseconds: 1000)});

  /// Numéro de l'écran, de 1 à 5.
  final int slide;

  /// Côté de l'illustration, en points. La scène l'accorde à la hauteur de
  /// l'écran : grand sur un grand téléphone, plus sage sur un petit.
  final double side;

  /// L'écran est-il à l'affichage ? À `false`, la boucle s'arrête.
  final bool animate;

  /// Temps de jeu à pleine vitesse. Passé ce délai, la boucle ralentit
  /// jusqu'à s'immobiliser sur la pose de repos.
  final Duration playFor;

  /// Nombre d'images de la boucle. La 24e enchaîne sur la 1re sans coupure.
  static const int frameCount = 24;

  /// Durée d'un tour de boucle à pleine vitesse.
  static const Duration loop = Duration(seconds: 1);

  /// Chemin de l'image fixe d'un écran.
  static String still(int slide) => 'assets/onboarding/onboarding_$slide.png';

  /// Chemin d'une des 24 images de la boucle d'un écran.
  static String frame(int slide, int index) => 'assets/onboarding/frames_$slide/${index.toString().padLeft(2, '0')}.png';

  /// Les images sont décodées à la taille où elles s'affichent, pas à leur
  /// taille de fichier : l'image fixe fait 1024 px de côté et pèserait quatre
  /// mégaoctets en mémoire sans cela. Les images de la boucle, plus petites
  /// que l'écran, restent à leur taille : agrandir au décodage n'ajouterait
  /// rien que le rendu ne fasse déjà.
  static ImageProvider _provider(String path, double side, double pixelRatio) {
    return ResizeImage(AssetImage(path), width: (side * pixelRatio).round(), policy: ResizeImagePolicy.fit);
  }

  static List<ImageProvider> _providers(int slide, double side, double pixelRatio) => [
    _provider(still(slide), side, pixelRatio),
    for (var i = 0; i < frameCount; i++) _provider(frame(slide, i), side, pixelRatio),
  ];

  /// Décode d'avance les images d'un écran, pour que la boucle démarre sans
  /// à-coup à l'arrivée sur celui-ci.
  static Future<void> precache(BuildContext context, int slide, double side) async {
    final ratio = MediaQuery.devicePixelRatioOf(context);
    for (final provider in _providers(slide, side, ratio)) {
      if (!context.mounted) return;
      await precacheImage(provider, context);
    }
  }

  /// L'image fixe seule : ce dont a besoin un objet qui ne fait que figurer.
  static Future<void> precacheStill(BuildContext context, int slide, double side) {
    return precacheImage(_provider(still(slide), side, MediaQuery.devicePixelRatioOf(context)), context);
  }

  /// Rend la mémoire des images animées d'un écran que l'on ne regarde plus.
  /// L'image fixe, elle, reste : l'objet continue de figurer en orbite.
  static void evictFrames(BuildContext context, int slide, double side) {
    final ratio = MediaQuery.devicePixelRatioOf(context);
    for (var i = 0; i < frameCount; i++) {
      _provider(frame(slide, i), side, ratio).evict();
    }
  }

  @override
  State<ClayIllustration> createState() => _ClayIllustrationState();
}

/// Où en est la boucle à un instant donné : la position dans le cycle, et la
/// part de l'image fixe à montrer par-dessus.
///
/// Le mouvement se lit sur une horloge unique, en tours de boucle. À pleine
/// vitesse, un tour dure [ClayIllustration.loop]. Puis la vitesse décroît en
/// ligne droite jusqu'à zéro : c'est le freinage le plus simple qui parte
/// sans secousse — la vitesse est la même de part et d'autre de l'instant où
/// il commence — et arrive sans secousse. La distance à parcourir est
/// choisie pour finir sur un tour entier, c'est-à-dire sur la pose de repos.
@visibleForTesting
class LoopClock {
  const LoopClock({required this.playFor});

  final Duration playFor;

  /// Tours joués à pleine vitesse.
  double get _cruise => playFor.inMicroseconds / ClayIllustration.loop.inMicroseconds;

  /// Tours parcourus pendant le freinage : ce qu'il manque pour boucler, plus
  /// un tour complet, pour que le ralentissement ait le temps de se voir.
  double get _braking => (_cruise + 1).ceilToDouble() - _cruise;

  /// Durée du freinage. La vitesse décroissant en ligne droite depuis un tour
  /// par [ClayIllustration.loop], la distance parcourue vaut la moitié de ce
  /// qu'elle vaudrait à pleine vitesse : il faut donc deux fois le temps.
  Duration get brakingDuration => ClayIllustration.loop * (2 * _braking);

  /// Durée totale, de la première image à l'immobilité.
  Duration get total => playFor + brakingDuration;

  /// Avancement du freinage, de 0 (il commence) à 1 (l'objet est posé).
  double _braked(Duration elapsed) {
    final since = elapsed - playFor;
    if (since <= Duration.zero) return 0;
    return (since.inMicroseconds / brakingDuration.inMicroseconds).clamp(0.0, 1.0);
  }

  /// Position dans la boucle, en tours ; la partie fractionnaire donne
  /// l'image à montrer.
  double phase(Duration elapsed) {
    if (elapsed <= playFor) return elapsed.inMicroseconds / ClayIllustration.loop.inMicroseconds;
    final u = _braked(elapsed);
    return _cruise + _braking * (1 - (1 - u) * (1 - u));
  }

  /// Image de la boucle à montrer.
  int frame(Duration elapsed) {
    final p = phase(elapsed);
    return ((p - p.floor()) * ClayIllustration.frameCount).floor() % ClayIllustration.frameCount;
  }

  /// Part de l'image fixe à montrer par-dessus la boucle, de 0 à 1.
  ///
  /// Au départ, l'image fixe s'efface en un quart de seconde : l'objet
  /// commence à bouger avant qu'on ait vu la définition changer. À la fin,
  /// elle revient sur le dernier tiers du freinage, quand l'objet ne se
  /// déplace plus que de quelques images d'un cycle : la netteté revient
  /// comme une mise au point, pas comme un remplacement.
  double still(Duration elapsed) {
    final fadeIn = 1 - (elapsed.inMicroseconds / const Duration(milliseconds: 250).inMicroseconds).clamp(0.0, 1.0);
    final u = _braked(elapsed);
    final fadeOut = u >= 1 ? 1.0 : ((u - 0.66) / 0.34).clamp(0.0, 1.0);
    return math.max(Curves.easeOut.transform(fadeIn), Curves.easeInOut.transform(fadeOut));
  }

  /// L'objet est-il posé ?
  bool done(Duration elapsed) => elapsed >= total;
}

class _ClayIllustrationState extends State<ClayIllustration> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  late LoopClock _clock = LoopClock(playFor: widget.playFor);
  var _frame = 0;

  /// Part de l'image fixe par-dessus la boucle, de 0 à 1.
  var _still = 1.0;

  /// Les images sont-elles toutes décodées ? Tant que non, on montre le fixe :
  /// une boucle qui saute des images se voit plus qu'une image immobile.
  var _ready = false;

  /// La boucle a joué son temps et s'est posée : elle ne repart qu'à la
  /// prochaine arrivée sur l'écran.
  var _played = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Le réglage « réduire les animations » peut changer en cours de route.
    _sync();
  }

  @override
  void didUpdateWidget(ClayIllustration old) {
    super.didUpdateWidget(old);
    if (old.playFor != widget.playFor) _clock = LoopClock(playFor: widget.playFor);
    if (old.slide != widget.slide || old.side != widget.side) {
      _ready = false;
      _frame = 0;
      _still = 1;
      _load();
    } else if (widget.animate && !old.animate && !_ready) {
      // L'objet arrive au centre : c'est maintenant qu'il faut ses images.
      _load();
    }
    // Quitter l'écran remet la boucle à zéro : elle rejouera au retour.
    if (!widget.animate) _played = false;
    _sync();
  }

  /// L'image fixe d'abord — elle suffit à un objet qui ne fait que passer.
  /// Les vingt-quatre images de la boucle ne se chargent que pour celui qui
  /// s'anime, et elles pèsent trop pour les charger à tout hasard.
  Future<void> _load() async {
    final slide = widget.slide;
    await ClayIllustration.precacheStill(context, slide, widget.side);
    if (!mounted || slide != widget.slide || !widget.animate) return;
    await ClayIllustration.precache(context, slide, widget.side);
    if (!mounted || slide != widget.slide) return;
    setState(() => _ready = true);
    _sync();
  }

  /// Le ticker ne tourne que quand il a quelque chose à montrer. Appelée
  /// depuis les points où une reconstruction suit de toute façon, elle change
  /// l'image courante sans `setState`.
  void _sync() {
    final wanted = _ready && widget.animate && !_played && !_reduceMotion;
    if (wanted && !_ticker.isActive) {
      _ticker.start();
    } else if (!wanted && _ticker.isActive) {
      _ticker.stop();
      _frame = 0;
      _still = 1;
    }
  }

  bool get _reduceMotion => MediaQuery.disableAnimationsOf(context);

  void _tick(Duration elapsed) {
    if (_clock.done(elapsed)) {
      // Posé, sur la même pose que l'image fixe : on la laisse seule.
      _ticker.stop();
      setState(() {
        _played = true;
        _frame = 0;
        _still = 1;
      });
      return;
    }
    final frame = _clock.frame(elapsed);
    final still = _clock.still(elapsed);
    if (frame != _frame || still != _still) {
      setState(() {
        _frame = frame;
        _still = still;
      });
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ratio = MediaQuery.devicePixelRatioOf(context);
    final playing = _ticker.isActive;
    final still = Image(
      image: ClayIllustration._provider(ClayIllustration.still(widget.slide), widget.side, ratio),
      fit: BoxFit.contain,
      gaplessPlayback: true,
      filterQuality: FilterQuality.high,
      excludeFromSemantics: true,
    );
    return SizedBox.square(
      dimension: widget.side,
      child: !playing
          ? still
          : Stack(
              fit: StackFit.expand,
              children: [
                Image(
                  image: ClayIllustration._provider(ClayIllustration.frame(widget.slide, _frame), widget.side, ratio),
                  fit: BoxFit.contain,
                  // Sans cela, chaque changement d'image ferait clignoter le décodage.
                  gaplessPlayback: true,
                  // Les images de la boucle sont agrandies au rendu : le filtre
                  // le plus fin est ce qui les garde lisses.
                  filterQuality: FilterQuality.high,
                  excludeFromSemantics: true,
                ),
                if (_still > 0.001) Opacity(opacity: _still, child: still),
              ],
            ),
    );
  }
}
