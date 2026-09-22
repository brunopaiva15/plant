import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/native_shell.dart';
import '../design_system/design_system.dart';

/// L'ouverture d'Auxine : le pot cligne de l'œil, prend son élan, puis sa
/// silhouette s'ouvre sur l'application, comme une fenêtre qui s'agrandit.
///
/// Le premier cadre reprend exactement l'écran de lancement natif — le pot de
/// 160 points au centre, sur le sauge du fond de l'icône —, si bien qu'on ne
/// voit pas la relève entre le système et Flutter. Pour que ce premier cadre
/// porte déjà le pot, il est retenu (`deferFirstFrame`) le temps de décoder
/// les images : sinon le fond apparaîtrait seul un instant.
///
/// Rien n'y est linéaire. Le pot s'écrase un peu en fermant l'œil et se
/// relève d'un rebond ; il prend une inspiration avant de se ramasser ; la
/// fenêtre s'ouvre en accélérant, et l'application, un rien trop grande, se
/// pose sous elle en dépassant d'un cheveu. C'est ce qui sépare une ouverture
/// qui respire d'une image qu'on agrandit.
///
/// Les barres natives d'iOS, posées par-dessus Flutter, sont voilées tant que
/// l'ouverture dure (`NativeShell.setLaunching`).
///
/// Avec « réduire les animations », ni clin d'œil ni zoom : le pot reste un
/// instant, puis s'efface. Un toucher passe directement à l'élan.
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
  ///   640–960    l'élan : une inspiration, puis le pot se ramasse ;
  ///   960–1400   la fenêtre s'ouvre, l'application se pose dessous.
  static const _total = 1400.0;
  static const _gatherStart = 640.0;
  static const _zoomStart = 960.0;

  /// Les images du clin d'œil, pas à pas : un pas dure 40 ms, sauf l'œil
  /// fermé, tenu 160 ms. `null`, c'est l'œil ouvert de l'image du pot.
  static const _winkSteps = <(double, int?)>[
    (200, 0), (240, 1), (280, 2), (440, 1), (480, 0), (520, null),
  ];

  late final AnimationController _controller;
  bool _started = false;
  bool _done = false;
  bool _reduced = false;

  /// Le pot décodé, pour la fenêtre : c'est sa silhouette qu'on découpe dans
  /// le fond. `null` tant qu'il n'est pas prêt — le fond part alors en fondu.
  ui.Image? _hole;

  @override
  void initState() {
    super.initState();
    NativeShell.setLaunching(true);
    _controller = AnimationController(vsync: this)
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
      _decode(LaunchSplash._logo).then<ui.Image?>((image) => _hole = image, onError: (Object _) => null),
    ]).timeout(const Duration(seconds: 1), onTimeout: () => const []).whenComplete(() {
      binding.allowFirstFrame();
      if (!mounted) return;
      _controller.duration = Duration(milliseconds: _reduced ? 550 : _total.round());
      _controller.forward();
    });
  }

  /// L'image elle-même, et non un widget qui l'affiche : le peintre de la
  /// fenêtre en a besoin pour découper le fond.
  Future<ui.Image> _decode(ImageProvider provider) {
    final done = Completer<ui.Image>();
    final stream = provider.resolve(createLocalImageConfiguration(context));
    late final ImageStreamListener listener;
    listener = ImageStreamListener((info, _) {
      if (!done.isCompleted) done.complete(info.image.clone());
      stream.removeListener(listener);
    }, onError: (error, stack) {
      if (!done.isCompleted) done.completeError(error, stack);
      stream.removeListener(listener);
    });
    stream.addListener(listener);
    return done.future;
  }

  @override
  void dispose() {
    _controller.dispose();
    _hole?.dispose();
    if (!_done) NativeShell.setLaunching(false);
    super.dispose();
  }

  /// Un toucher saute l'attente et le clin d'œil : on part droit à l'élan.
  void _skip() {
    if (_reduced || _done) return;
    final gather = _gatherStart / _total;
    if (_controller.value < gather) _controller.forward(from: gather);
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
        // L'application, un rien trop grande, se pose sous la fenêtre qui
        // s'ouvre et dépasse d'un cheveu avant de s'arrêter.
        final settle = _reduced ? 1.0 : _phase(ms, _zoomStart, _total, Curves.easeOutBack);
        final appScale = _done ? 1.0 : 1.07 - 0.07 * settle;
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
    final press = _phase(ms, 200, 290, Curves.easeOutCubic) * (1 - _phase(ms, 440, 640, Curves.elasticOut));
    final squashX = 1 + 0.035 * press;
    final squashY = 1 - 0.05 * press;

    // L'élan : une inspiration, puis le pot se ramasse.
    final inhale = _phase(ms, _gatherStart, 780, Curves.easeOutCubic);
    final gather = _phase(ms, 780, _zoomStart, Curves.easeInOutCubic);
    // La fenêtre : elle part lentement et accélère jusqu'à sortir de
    // l'écran — trente fois le pot, assez pour que sa silhouette déborde
    // l'écran le plus grand.
    final zoom = _phase(ms, _zoomStart, _total, Curves.easeInCubic);
    final scale = (1 + 0.06 * inhale - 0.22 * gather) * (1 - zoom) + 30 * zoom;
    // Le pot s'efface dès que la fenêtre s'ouvre : on voit l'application au
    // travers de sa silhouette.
    final pot = 1 - _phase(ms, _zoomStart, _zoomStart + 160, Curves.easeOut);

    final opening = ms >= _zoomStart;
    final hole = _hole;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (!opening)
          const ColoredBox(color: LaunchSplash.background)
        else if (hole != null)
          CustomPaint(painter: _Window(image: hole, scale: scale))
        else
          Opacity(opacity: 1 - _phase(ms, _zoomStart, _total, Motion.easeOut), child: const ColoredBox(color: LaunchSplash.background)),
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
/// L'ombre au pied du pot, à demi transparente, n'est pas une fenêtre : la
/// matrice de couleur ne garde du masque que ce qui est franchement opaque,
/// c'est-à-dire le pot et sa pousse.
class _Window extends CustomPainter {
  const _Window({required this.image, required this.scale});

  final ui.Image image;
  final double scale;

  static const _solid = ColorFilter.matrix([
    0, 0, 0, 0, 0, //
    0, 0, 0, 0, 0, //
    0, 0, 0, 0, 0, //
    0, 0, 0, 4, -510,
  ]);

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.saveLayer(bounds, Paint());
    canvas.drawRect(bounds, Paint()..color = LaunchSplash.background);
    final side = LaunchSplash.logoSize * scale;
    final window = Rect.fromCenter(center: bounds.center, width: side, height: side);
    final src = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    canvas.drawImageRect(
      image,
      src,
      window,
      Paint()
        ..blendMode = BlendMode.dstOut
        ..colorFilter = _solid
        ..filterQuality = FilterQuality.medium,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_Window old) => old.scale != scale || old.image != image;
}
