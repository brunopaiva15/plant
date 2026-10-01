import 'package:flutter/material.dart';

import '../core/native_shell.dart';
import '../design_system/design_system.dart';
import 'launch_silhouette.dart';

/// L'ouverture d'Auxine : le pot cligne de l'œil, puis joue l'ouverture de
/// Twitter — sa silhouette se ramasse, puis s'ouvre sur l'application comme
/// une fenêtre qui s'agrandit.
///
/// Le premier cadre reprend exactement l'écran de lancement natif — le pot de
/// 160 points au centre, sur le sauge du fond de l'icône —, si bien qu'on ne
/// voit pas la relève entre le système et Flutter. Pour que ce premier cadre
/// porte déjà le pot, il est retenu (`deferFirstFrame`) le temps de décoder
/// les images : sinon le fond apparaîtrait seul un instant.
///
/// Après le clin d'œil, la séquence reprend celle de Twitter, valeurs
/// comprises (voir « Implementing Twitter's App Loading Animation in React
/// Native », sur le blog de React Native) : une seconde, menée par la courbe
/// d'`Animated.timing` ; la silhouette passe à 0,8 sur le premier dixième,
/// puis à 70 ; l'application y paraît en fondu entre 15 et 30 %, et passe de
/// 110 à 100 % tout du long. Chez Twitter, le logo est une couche blanche
/// vue au travers du masque, nette à toutes les tailles. Ici, le pot
/// s'efface dès que la silhouette repart (entre 10 et 15 %) et laisse un
/// aplat de la couleur de fond de l'application : agrandie cinq ou seize
/// fois, l'image du pot ne serait plus qu'une tache floue.
///
/// Les barres natives d'iOS, posées par-dessus Flutter, sont voilées jusqu'à
/// ce que l'application ait fini de paraître dans la fenêtre — 30 % de
/// l'ouverture —, puis reviennent en fondu (`NativeShell.setLaunching`).
/// Les rendre à la fin seulement les faisait tomber d'un coup, 600 ms après
/// l'application : la courbe passe ce temps-là à poser l'échelle.
///
/// Avec « réduire les animations », ni clin d'œil ni zoom : le pot reste un
/// instant, puis s'efface. Un toucher saute le clin d'œil.
///
/// Les images viennent de `tool/build_app_icon.py` : `logo.webp` est le pot,
/// raccourci pour se montrer entier, sur son ombre, fond transparent ;
/// `clin_*.webp` l'œil de droite à trois moments de sa fermeture, découpé
/// dans le même cadrage et fondu sur les bords.
class LaunchSplash extends StatefulWidget {
  const LaunchSplash({super.key, required this.child});

  /// L'application, qui se construit dessous dès le premier cadre.
  final Widget child;

  /// Côté de l'image du pot, en points : le même que celui des écrans natifs
  /// (`LaunchScreen.storyboard`, `launch_background.xml`, et l'icône
  /// d'Android 12, posée au même côté dans son cadre de 288 dp).
  static const double logoSize = 160;

  /// Le fond : le sauge de l'icône, pris au milieu de son dégradé, en clair
  /// comme en sombre. Sur ce fond uni, le pot ne se détache d'aucun cadre.
  /// Même valeur que `SAUGE` dans `tool/build_app_icon.py`.
  static const Color background = Color(0xFF459765);

  /// La zone de l'œil dans l'image du pot, de 1024 px, là où se posent les
  /// images du clin d'œil. Même valeur que `OEIL` dans `tool/build_app_icon.py`.
  static const Rect eyeRect = Rect.fromLTWH(497, 614, 176, 176);

  static const _logo = AssetImage('assets/splash/logo.webp');
  static const _wink = [
    AssetImage('assets/splash/clin_50.webp'),
    AssetImage('assets/splash/clin_85.webp'),
    AssetImage('assets/splash/clin_100.webp'),
  ];

  @override
  State<LaunchSplash> createState() => _LaunchSplashState();
}

class _LaunchSplashState extends State<LaunchSplash> with SingleTickerProviderStateMixin {
  /// La chronologie entière, en millisecondes :
  ///   0–200      le pot tel que l'a laissé l'écran natif ;
  ///   200–640    le clin d'œil, le pot qui s'écrase puis se relève ;
  ///   640–1640   l'ouverture de Twitter.
  static const _total = 1640.0;
  static const _twitterStart = 640.0;
  static const _twitter = 1000.0;

  /// Le fondu des barres natives quand elles reviennent : le temps que la
  /// fenêtre finisse d'effacer le sauge, ou celui du fondu réduit.
  static const _chromeFade = Duration(milliseconds: 250);

  /// Les images du clin d'œil, pas à pas : un pas dure 40 ms, sauf l'œil
  /// fermé, tenu 160 ms. `null`, c'est l'œil ouvert de l'image du pot.
  static const _winkSteps = <(double, int?)>[
    (200, 0), (240, 1), (280, 2), (440, 1), (480, 0), (520, null),
  ];

  late final AnimationController _controller;
  bool _started = false;
  bool _done = false;
  bool _reduced = false;
  bool _chromeShown = false;

  @override
  void initState() {
    super.initState();
    NativeShell.setLaunching(true);
    _controller = AnimationController(vsync: this)
      ..addListener(_revealChrome)
      ..addStatusListener((status) {
        if (status != AnimationStatus.completed) return;
        NativeShell.setLaunching(false);
        setState(() => _done = true);
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _reduced = MediaQuery.disableAnimationsOf(context);
    final binding = WidgetsBinding.instance;
    binding.deferFirstFrame();
    // Une image qui ne vient pas ne doit pas laisser l'écran figé : au-delà
    // d'une seconde, l'ouverture part telle quelle.
    Future.wait([
      for (final image in [LaunchSplash._logo, ...LaunchSplash._wink]) precacheImage(image, context),
    ]).timeout(const Duration(seconds: 1), onTimeout: () => const []).whenComplete(() {
      binding.allowFirstFrame();
      if (!mounted) return;
      _controller.duration = Duration(milliseconds: _reduced ? 550 : _total.round());
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    if (!_done) NativeShell.setLaunching(false);
    super.dispose();
  }

  /// Rend les barres natives dès que l'application a paru : en même temps
  /// qu'elle, et non après. Sans le zoom, au début du fondu.
  void _revealChrome() {
    if (_chromeShown) return;
    final ms = _controller.value * (_reduced ? 550 : _total);
    if (_reduced ? ms < 300 : _progress(ms) < 30) return;
    _chromeShown = true;
    NativeShell.setLaunching(false, fade: _chromeFade);
  }

  /// Un toucher saute l'attente et le clin d'œil : l'ouverture part aussitôt.
  void _skip() {
    if (_reduced || _done) return;
    final start = _twitterStart / _total;
    if (_controller.value < start) _controller.forward(from: start);
  }

  /// L'avancée de l'ouverture de Twitter, de 0 à 100, à l'instant [ms].
  static double _progress(double ms) => 100 * _rnEaseInOut.transform(((ms - _twitterStart) / _twitter).clamp(0.0, 1.0));

  /// Une interpolation par morceaux, comme `interpolate` de React Native :
  /// linéaire entre deux points, bloquée aux extrémités.
  static double _interpolate(double p, List<double> input, List<double> output) {
    if (p <= input.first) return output.first;
    for (var i = 1; i < input.length; i++) {
      if (p <= input[i]) return output[i - 1] + (output[i] - output[i - 1]) * (p - input[i - 1]) / (input[i] - input[i - 1]);
    }
    return output.last;
  }

  static double _phase(double ms, double from, double to, [Curve curve = Curves.linear]) =>
      curve.transform(((ms - from) / (to - from)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    // L'application garde sa place dans l'arbre du premier au dernier cadre :
    // la sortir de la pile à la fin la reconstruirait entière.
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, app) {
        final ms = _controller.value * (_reduced ? 550 : _total);
        // L'application passe de 110 à 100 % pendant l'ouverture.
        final appScale = _done || _reduced ? 1.0 : _interpolate(_progress(ms), const [0, 100], const [1.1, 1]);
        return Stack(
          fit: StackFit.expand,
          children: [
            Transform.scale(scale: appScale, child: app),
            if (!_done)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _skip,
                child: ExcludeSemantics(child: _reduced ? _buildReduced(ms) : _buildFull(ms)),
              ),
          ],
        );
      },
    );
  }

  Widget _buildReduced(double ms) {
    // 300 ms immobile, puis 250 ms de fondu.
    final fade = _phase(ms, 300, 550, Motion.easeOut);
    return Opacity(
      opacity: 1 - fade,
      child: const Stack(
        fit: StackFit.expand,
        children: [ColoredBox(color: LaunchSplash.background), Center(child: _Pot(frame: null))],
      ),
    );
  }

  Widget _buildFull(double ms) {
    int? frame;
    for (final (at, image) in _winkSteps) {
      if (ms >= at) frame = image;
    }

    // Le clin d'œil : le pot s'écrase sur sa base en fermant l'œil, tient,
    // puis se relève d'un rebond élastique.
    final press = _phase(ms, 200, 290, Curves.easeOutCubic) * (1 - _phase(ms, 440, _twitterStart, Curves.elasticOut));
    final squashX = 1 + 0.035 * press;
    final squashY = 1 - 0.05 * press;

    // L'ouverture de Twitter : la silhouette se ramasse à 0,8 sur le premier
    // dixième, puis s'ouvre jusqu'à 70 fois sa taille ; l'application y
    // paraît en fondu entre 15 et 30 %.
    final p = _progress(ms);
    final scale = _interpolate(p, const [0, 10, 100], const [1, 0.8, 70]);
    final app = _interpolate(p, const [0, 15, 30], const [0, 0, 1]);
    final pot = 1 - _interpolate(p, const [0, 10, 15], const [0, 0, 1]);

    final opening = ms >= _twitterStart;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (!opening)
          const ColoredBox(color: LaunchSplash.background)
        else
          // La couche blanche de Twitter : la silhouette remplie du fond de
          // l'application, que celle-ci recouvre en fondu.
          CustomPaint(painter: _Window(scale: scale, fill: context.colors.canvas.withValues(alpha: 1 - app))),
        if (pot > 0)
          Center(
            child: Opacity(
              opacity: pot,
              child: Transform.scale(
                scale: scale,
                child: Transform(
                  alignment: Alignment.bottomCenter,
                  transform: Matrix4.diagonal3Values(squashX, squashY, 1),
                  child: _Pot(frame: opening ? null : frame),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// `Easing.inOut(Easing.ease)`, la courbe par défaut d'`Animated.timing` :
/// l'ease de CSS (0,42 ; 0 ; 1 ; 1) joué à l'aller sur la première moitié,
/// et en miroir sur la seconde.
const _rnEaseInOut = _MirroredCurve(Cubic(0.42, 0, 1, 1));

class _MirroredCurve extends Curve {
  const _MirroredCurve(this.ease);

  final Curve ease;

  @override
  double transformInternal(double t) => t < 0.5 ? ease.transform(t * 2) / 2 : 1 - ease.transform((1 - t) * 2) / 2;
}

/// Le pot, avec l'œil de droite à l'image [frame] du clin d'œil.
class _Pot extends StatelessWidget {
  const _Pot({required this.frame});

  final int? frame;

  @override
  Widget build(BuildContext context) {
    const size = LaunchSplash.logoSize;
    const unit = size / 1024;
    const eye = LaunchSplash.eyeRect;
    final frame = this.frame;
    return SizedBox.square(
      dimension: size,
      child: Stack(
        children: [
          const Positioned.fill(child: Image(image: LaunchSplash._logo, filterQuality: FilterQuality.medium)),
          if (frame != null)
            Positioned(
              left: eye.left * unit,
              top: eye.top * unit,
              width: eye.width * unit,
              height: eye.height * unit,
              child: Image(image: LaunchSplash._wink[frame], filterQuality: FilterQuality.medium),
            ),
        ],
      ),
    );
  }
}

/// Le fond sauge percé de la silhouette du pot, à l'échelle [scale].
///
/// Un tracé, et non une image découpée par un mode de fusion : sur l'iPhone,
/// le moteur de rendu remplissait de noir la découpe d'une couche à part, et
/// l'application ne se voyait qu'une fois l'ouverture finie. Le rectangle et
/// le contour du pot (`launchSilhouette`, tiré du rendu par
/// `tool/build_app_icon.py`) se remplissent en pair-impair : tout sauf le pot.
class _Window extends CustomPainter {
  const _Window({required this.scale, required this.fill});

  final double scale;

  /// La couleur de la silhouette elle-même, par-dessus l'application.
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final side = LaunchSplash.logoSize * scale;
    final origin = bounds.center - Offset(side / 2, side / 2);
    final pot = [
      for (var i = 0; i + 1 < launchSilhouette.length; i += 2)
        origin + Offset(launchSilhouette[i] * side, launchSilhouette[i + 1] * side),
    ];
    final silhouette = Path()..addPolygon(pot, true);
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(bounds)
      ..addPath(silhouette, Offset.zero);
    canvas.drawPath(path, Paint()..color = LaunchSplash.background);
    if (fill.a > 0) canvas.drawPath(silhouette, Paint()..color = fill);
  }

  @override
  bool shouldRepaint(_Window old) => old.scale != scale || old.fill != fill;
}
