import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Une illustration 3D de l'onboarding : une image fixe, et une boucle de 24
/// images jouée à 24 im/s tant que l'écran est à l'affichage.
///
/// Le principe est celui d'`UIImageView.animationImages` : les 24 images sont
/// décodées à l'avance, puis échangées au rythme du ticker. L'image fixe reste
/// le repli — c'est elle que l'on voit avant le décodage, et c'est la seule
/// chose affichée si le système demande de réduire les animations.
class ClayIllustration extends StatefulWidget {
  const ClayIllustration({super.key, required this.slide, required this.side, this.animate = true});

  /// Numéro de l'écran, de 1 à 5.
  final int slide;

  /// Côté de l'illustration, en points. La scène l'accorde à la hauteur de
  /// l'écran : grand sur un grand téléphone, plus sage sur un petit.
  final double side;

  /// L'écran est-il à l'affichage ? À `false`, la boucle s'arrête.
  final bool animate;

  /// Nombre d'images de la boucle. La 24e enchaîne sur la 1re sans coupure.
  static const int frameCount = 24;

  static const Duration _loop = Duration(seconds: 1);

  /// Chemin de l'image fixe d'un écran.
  static String still(int slide) => 'assets/onboarding/onboarding_$slide.png';

  /// Chemin d'une des 24 images de la boucle d'un écran.
  static String frame(int slide, int index) => 'assets/onboarding/frames_$slide/${index.toString().padLeft(2, '0')}.png';

  /// Les images sont décodées à la taille où elles s'affichent, pas à leur
  /// taille de fichier : l'image fixe fait 1024 px de côté et pèserait quatre
  /// mégaoctets en mémoire sans cela.
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

class _ClayIllustrationState extends State<ClayIllustration> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  var _frame = 0;

  /// Les images sont-elles toutes décodées ? Tant que non, on montre le fixe :
  /// une boucle qui saute des images se voit plus qu'une image immobile.
  var _ready = false;

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
    if (old.slide != widget.slide || old.side != widget.side) {
      _ready = false;
      _frame = 0;
      _load();
    } else if (widget.animate && !old.animate && !_ready) {
      // L'objet arrive au centre : c'est maintenant qu'il faut ses images.
      _load();
    }
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
    final wanted = _ready && widget.animate && !_reduceMotion;
    if (wanted && !_ticker.isActive) {
      _ticker.start();
    } else if (!wanted && _ticker.isActive) {
      _ticker.stop();
      _frame = 0;
    }
  }

  bool get _reduceMotion => MediaQuery.disableAnimationsOf(context);

  void _tick(Duration elapsed) {
    final micros = ClayIllustration._loop.inMicroseconds;
    final next = elapsed.inMicroseconds % micros * ClayIllustration.frameCount ~/ micros;
    if (next != _frame) setState(() => _frame = next);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playing = _ready && widget.animate && !_reduceMotion;
    final path = playing ? ClayIllustration.frame(widget.slide, _frame) : ClayIllustration.still(widget.slide);
    return SizedBox.square(
      dimension: widget.side,
      child: Image(
        image: ClayIllustration._provider(path, widget.side, MediaQuery.devicePixelRatioOf(context)),
        fit: BoxFit.contain,
        // Sans cela, chaque changement d'image ferait clignoter le décodage.
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        excludeFromSemantics: true,
      ),
    );
  }
}
