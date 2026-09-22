import 'package:flutter/material.dart';

import '../design_system/design_system.dart';

/// L'ouverture d'Auxine : le logo cligne de l'œil, prend son élan, puis
/// grossit jusqu'à disparaître et laisse voir l'application.
///
/// Le premier cadre reprend exactement l'écran de lancement natif — le pot de
/// 160 points au centre, sur le sauge du fond de l'icône —, si bien qu'on ne
/// voit pas la relève entre le système et Flutter. Pour que ce
/// premier cadre porte déjà le logo, il est retenu (`deferFirstFrame`) le
/// temps de décoder les images : sinon le fond apparaîtrait seul un instant.
///
/// Avec « réduire les animations », ni clin d'œil ni zoom : le pot reste un
/// instant, puis s'efface. Un toucher passe directement au zoom.
///
/// Les images viennent de `tool/build_app_icon.py` : `logo.webp` est le pot,
/// raccourci pour se montrer entier, sur son ombre, fond transparent, `clin_*.webp` l'œil de droite à
/// trois moments de sa fermeture, découpé dans le même cadrage et fondu sur
/// les bords.
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
  ///   0–250     le pot tel que l'a laissé l'écran natif ;
  ///   250–690   le clin d'œil ;
  ///   690–880   l'élan : le pot se ramasse ;
  ///   880–1380  le zoom, pendant que le fond puis le pot s'effacent.
  static const _total = 1380.0;
  static const _zoomStart = 880.0;

  /// Les images du clin d'œil, pas à pas : un pas dure 40 ms, sauf l'œil
  /// fermé, tenu 160 ms. `null`, c'est l'œil ouvert de l'image du pot.
  static const _winkSteps = <(double, int?)>[
    (250, 0), (290, 1), (330, 2), (490, 1), (530, 0), (570, null),
  ];

  late final AnimationController _controller;
  bool _started = false;
  bool _done = false;
  bool _reduced = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) setState(() => _done = true);
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
    // d'une seconde, le logo s'affiche tel quel.
    Future.wait([
      for (final image in [LaunchSplash._logo, ...LaunchSplash._wink]) precacheImage(image, context),
    ]).timeout(const Duration(seconds: 1), onTimeout: () => const []).whenComplete(() {
      binding.allowFirstFrame();
      if (!mounted) return;
      if (_reduced) {
        _controller.duration = const Duration(milliseconds: 550);
      } else {
        _controller.duration = Duration(milliseconds: _total.round());
      }
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Un toucher saute l'attente et le clin d'œil : on part droit au zoom.
  void _skip() {
    if (_reduced || _done) return;
    final zoom = _zoomStart / _total;
    if (_controller.value < zoom) _controller.forward(from: zoom);
  }

  double _phase(double ms, double from, double to, Curve curve) =>
      curve.transform(((ms - from) / (to - from)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    if (_done) return widget.child;
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _skip,
          child: ExcludeSemantics(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => _reduced ? _buildReduced(context) : _buildFull(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReduced(BuildContext context) {
    // 300 ms immobile, puis 250 ms de fondu.
    final fade = _phase(_controller.value * 550, 300, 550, Motion.easeOut);
    return Opacity(opacity: 1 - fade, child: _stage(context, scale: 1, frame: null));
  }

  Widget _buildFull(BuildContext context) {
    final ms = _controller.value * _total;
    int? frame;
    for (final (at, image) in _winkSteps) {
      if (ms >= at) frame = image;
    }
    // L'élan ramasse le pot à 88 %, puis le zoom l'emporte à 16 fois sa
    // taille : assez pour qu'il déborde de l'écran le plus large.
    final gather = _phase(ms, 690, _zoomStart, Motion.easeInOut);
    final zoom = _phase(ms, _zoomStart, _total, Curves.easeInCubic);
    final scale = (1 - 0.12 * gather) + 15.12 * zoom;
    final backdrop = 1 - _phase(ms, _zoomStart, 1180, Motion.easeOut);
    final logo = 1 - _phase(ms, 1130, _total, Motion.easeOut);
    return _stage(context, scale: scale, frame: frame, backdrop: backdrop, logo: logo);
  }

  Widget _stage(BuildContext context, {required double scale, int? frame, double backdrop = 1, double logo = 1}) {
    const size = LaunchSplash.logoSize;
    const unit = size / 1024;
    final eye = LaunchSplash.eyeRect;
    return Stack(
      fit: StackFit.expand,
      children: [
        Opacity(opacity: backdrop, child: const ColoredBox(color: LaunchSplash.background)),
        Center(
          child: Opacity(
            opacity: logo,
            child: Transform.scale(
              scale: scale,
              child: SizedBox.square(
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
              ),
            ),
          ),
        ),
      ],
    );
  }
}
