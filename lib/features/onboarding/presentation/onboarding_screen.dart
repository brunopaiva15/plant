import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../plants/presentation/create_plant_flow.dart';
import '../../support/presentation/support_screen.dart';
import 'clay_illustration.dart';
import 'onboarding_stage.dart';

/// Un écran de présentation : un objet du jardin, un titre, une phrase.
class _Slide {
  const _Slide({required this.title, required this.body, required this.tint});

  final String Function(AppLocalizations) title;
  final String Function(AppLocalizations) body;

  /// Couleur d'ambiance de l'écran.
  final Color Function(FloraColors) tint;
}

final _slides = <_Slide>[
  _Slide(
    title: (l) => l.onboardingTitle,
    body: (l) => l.onboardingSubtitle,
    tint: (c) => c.sage,
  ),
  _Slide(
    title: (l) => l.onbTodayTitle,
    body: (l) => l.onbTodayBody,
    tint: (c) => c.water,
  ),
  _Slide(
    title: (l) => l.onbCareTitle,
    body: (l) => l.onbCareBody,
    tint: (c) => c.sun,
  ),
  _Slide(
    title: (l) => l.onbGardenTitle,
    body: (l) => l.onbGardenBody,
    tint: (c) => c.terracotta,
  ),
  _Slide(
    title: (l) => l.onbPrivacyTitle,
    body: (l) => l.onbPrivacyBody,
    tint: (c) => c.rose,
  ),
];

/// Présentation animée, le prénom, puis le soutien facultatif au développeur.
///
/// Les écrans ne se remplacent pas l'un l'autre comme des diapositives : le
/// fond change de teinte, les objets du jardin tournent autour de la place
/// centrale, et seul le texte défile. La première plante se crée ensuite dans
/// le flow standard — l'app se découvre en s'en servant.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> with TickerProviderStateMixin {
  final _name = TextEditingController();
  final _pages = PageController();
  late final _entry = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..forward();

  /// La dérive du fond : un souffle d'une seconde et demie à l'arrivée sur
  /// chaque écran, qui ralentit et se pose. Rien ne bouge à perpétuité.
  late final _float = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..forward();

  int _page = 0;

  /// Position continue du carrousel : c'est elle qui fait tourner les objets
  /// et virer la couleur du fond, au rythme du doigt.
  double _offset = 0;

  /// Le choix fait sur la page du prénom, à honorer une fois l'onboarding fini.
  bool _addPlant = false;

  int get _nameIndex => _slides.length;
  int get _supportIndex => _slides.length + 1;
  int get _pageCount => _slides.length + 2;

  /// La scène prend un bon tiers de la hauteur, sans jamais écraser le texte
  /// sur un petit téléphone.
  double _stageHeight(BuildContext context) => (MediaQuery.sizeOf(context).height * 0.48).clamp(280.0, 420.0);

  @override
  void initState() {
    super.initState();
    _pages.addListener(_onScroll);
    // Le premier écran est déjà à l'affichage : on prépare le suivant.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _keepIllustrations(0);
    });
  }

  @override
  void dispose() {
    _pages.removeListener(_onScroll);
    _name.dispose();
    _pages.dispose();
    _entry.dispose();
    _float.dispose();
    super.dispose();
  }

  void _onScroll() {
    final page = _pages.hasClients ? _pages.page : null;
    if (page != null && page != _offset) setState(() => _offset = page);
  }

  /// Garde en mémoire les images animées de l'écran courant et du suivant, et
  /// rend celles des autres : vingt-quatre images décodées par écran, cela
  /// compte. Les objets en orbite n'ont besoin que de leur image fixe.
  void _keepIllustrations(int page) {
    final keep = {page, page + 1};
    final side = (_stageHeight(context) * 0.66).roundToDouble();
    for (var i = 0; i < _slides.length; i++) {
      if (keep.contains(i)) {
        ClayIllustration.precache(context, i + 1, side);
      } else {
        ClayIllustration.evictFrames(context, i + 1, side);
      }
    }
  }

  void _goTo(int page) {
    Haptics.light();
    _pages.animateToPage(page, duration: Motion.of(context, Motion.emphasis), curve: Motion.emphasized);
  }

  void _onPageChanged(int page) {
    setState(() => _page = page);
    _keepIllustrations(page);
    // Chaque écran rejoue son entrée à l'arrivée, jamais avant ; le fond
    // reprend son souffle en même temps.
    _entry
      ..reset()
      ..forward();
    _float
      ..reset()
      ..forward();
  }

  void _toSupport({required bool addPlant}) {
    _addPlant = addPlant;
    _goTo(_supportIndex);
  }

  Future<void> _finish() async {
    final prefs = ref.read(preferencesProvider.notifier);
    if (_name.text.trim().isNotEmpty) await prefs.setDisplayName(_name.text);
    await prefs.setOnboardingDone();
    if (!mounted) return;
    context.go(Routes.today);
    if (_addPlant) {
      await Future<void>.delayed(Motion.of(context, Motion.emphasis));
      if (mounted) await startCreatePlantFlow(context, ref);
    }
  }

  /// La couleur de l'écran, déjà mêlée à celle du suivant pendant le geste.
  Color _tint(FloraColors c) {
    final o = _offset.clamp(0.0, (_slides.length - 1).toDouble());
    final i = o.floor();
    final next = math.min(i + 1, _slides.length - 1);
    return Color.lerp(_slides[i].tint(c), _slides[next].tint(c), o - i)!;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final onSlides = _page < _slides.length;
    final current = math.min(_page, _slides.length - 1);

    return Scaffold(
      backgroundColor: c.canvas,
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _float,
              builder: (context, _) => OnboardingAurora(tint: _tint(c), drift: Curves.easeOutCubic.transform(_float.value), reduceMotion: reduce),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(Space.page, Space.sm, Space.sm, 0),
                  child: SizedBox(
                    height: 36,
                    child: Row(
                      children: [
                        Expanded(child: OnboardingProgress(count: _pageCount, index: _page)),
                        SizedBox(
                          width: 96,
                          child: onSlides
                              ? Align(
                                  alignment: Alignment.centerRight,
                                  child: FloraButton(
                                    label: l10n.skip,
                                    style: FloraButtonStyle.ghost,
                                    size: FloraButtonSize.small,
                                    onPressed: () => _goTo(_nameIndex),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedBuilder(
                  animation: Listenable.merge([_entry, _float]),
                  builder: (context, _) => OnboardingStage(
                    count: _slides.length,
                    offset: _offset,
                    page: current,
                    entry: reduce ? 1 : _entry.value,
                    height: _stageHeight(context),
                    reduceMotion: reduce,
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _pages,
                    onPageChanged: _onPageChanged,
                    children: [
                      for (final (i, slide) in _slides.indexed)
                        AnimatedBuilder(
                          animation: _entry,
                          builder: (context, _) => _SlideText(
                            slide: slide,
                            t: reduce || i != _page ? 1.0 : _entry.value,
                            parallax: reduce ? 0 : (_offset - i).clamp(-1.0, 1.0),
                          ),
                        ),
                      _NamePage(
                        controller: _name,
                        onSubmit: () => _toSupport(addPlant: true),
                        onSkip: () => _toSupport(addPlant: false),
                      ),
                      _SupportPage(onDone: _finish),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.md),
                  child: AnimatedSize(
                    duration: Motion.of(context, Motion.standard),
                    child: onSlides
                        ? FloraButton(
                            label: _page == _slides.length - 1 ? l10n.onbStart : l10n.continueLabel,
                            trailingIcon: CupertinoIcons.arrow_right,
                            expand: true,
                            onPressed: () => _goTo(_page + 1),
                          )
                        : const SizedBox(width: double.infinity),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Le texte d'un écran : le titre qui se lève mot à mot, puis la phrase.
class _SlideText extends StatelessWidget {
  const _SlideText({required this.slide, required this.t, required this.parallax});

  final _Slide slide;
  final double t;
  final double parallax;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final width = MediaQuery.sizeOf(context).width;
    // Le texte suit le geste de moins près que la page : c'est ce décalage qui
    // creuse la profondeur.
    final fade = (1 - parallax.abs() * 1.6).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.page),
      child: Opacity(
        opacity: fade,
        child: Transform.translate(
          offset: Offset(parallax * -width * 0.18, 0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RisingTitle(
                text: slide.title(l10n),
                style: context.text.display.copyWith(fontSize: 38, height: 1.1, letterSpacing: -1),
                t: t,
              ),
              const SizedBox(height: Space.sm),
              Stagger(
                t: t,
                index: 4,
                count: 5,
                child: Text(
                  slide.body(l10n),
                  style: context.text.body.copyWith(color: c.inkSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NamePage extends StatelessWidget {
  const _NamePage({required this.controller, required this.onSubmit, required this.onSkip});

  final TextEditingController controller;
  final VoidCallback onSubmit;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.page),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: Space.xxl),
          Text(l10n.askNameTitle, style: context.text.display.copyWith(fontSize: 38, height: 1.1, letterSpacing: -1)),
          const SizedBox(height: Space.xs),
          Text(l10n.askNameSubtitle, style: context.text.callout),
          const SizedBox(height: Space.xl),
          FloraTextField(
            controller: controller,
            hint: l10n.yourNameHint,
            large: true,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onSubmit(),
          ),
          const Spacer(),
          FloraButton(label: l10n.addFirstPlant, trailingIcon: CupertinoIcons.arrow_right, expand: true, onPressed: onSubmit),
          const SizedBox(height: Space.xs),
          FloraButton(label: l10n.later, style: FloraButtonStyle.ghost, expand: true, onPressed: onSkip),
          const SizedBox(height: Space.md),
        ],
      ),
    );
  }
}

/// La toute fin : l'app est gratuite, et on peut soutenir son développeur.
/// Rien n'y oblige — le bouton du bas passe outre en un geste.
class _SupportPage extends StatelessWidget {
  const _SupportPage({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.md),
      child: SupportPitch(onDone: onDone),
    );
  }
}
