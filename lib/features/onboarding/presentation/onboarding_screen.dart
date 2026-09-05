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
  _Slide(title: (l) => l.onboardingTitle, body: (l) => l.onboardingSubtitle, tint: (c) => c.sage),
  _Slide(title: (l) => l.onbTodayTitle, body: (l) => l.onbTodayBody, tint: (c) => c.water),
  _Slide(title: (l) => l.onbCareTitle, body: (l) => l.onbCareBody, tint: (c) => c.sun),
  _Slide(title: (l) => l.onbGardenTitle, body: (l) => l.onbGardenBody, tint: (c) => c.terracotta),
  _Slide(title: (l) => l.onbPrivacyTitle, body: (l) => l.onbPrivacyBody, tint: (c) => c.rose),
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

  /// La scène prend ce que la hauteur laisse une fois le texte servi : un
  /// titre de trois lignes et sa phrase tiennent toujours, sur un petit
  /// téléphone la dalle rapetisse, sur un grand elle s'arrête avant de
  /// devenir énorme.
  double _stageHeight(BuildContext context) {
    final mq = MediaQuery.of(context);
    final free = mq.size.height - mq.padding.vertical - _chromeHeight - _textReserve;
    return free.clamp(240.0, 460.0);
  }

  /// En-tête (progression) et pied (bouton), avec leurs marges.
  static const double _chromeHeight = 52 + 78;

  /// Hauteur garantie au texte d'un écran.
  static const double _textReserve = 230;

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
    final side = OnboardingStage.sideOf(_stageHeight(context));
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
    final tint = _tint(c);

    return Scaffold(
      backgroundColor: OnboardingBackdrop.wash(c, tint),
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _float,
              builder: (context, _) =>
                  OnboardingBackdrop(tint: tint, drift: _float.value, reduceMotion: reduce, glow: 1 - (_offset - (_slides.length - 1)).clamp(0.0, 1.0)),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(Space.page, Space.sm, Space.md, 0),
                  child: SizedBox(
                    height: 40,
                    child: Row(
                      children: [
                        Expanded(
                          child: OnboardingProgress(count: _pageCount, index: _page, color: tint),
                        ),
                        const SizedBox(width: Space.md),
                        SizedBox(
                          width: 80,
                          child: onSlides
                              ? Align(
                                  alignment: Alignment.centerRight,
                                  child: _SkipButton(label: l10n.skip, onPressed: () => _goTo(_nameIndex)),
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
                    tint: tint,
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
                          builder: (context, _) =>
                              _SlideText(slide: slide, t: reduce || i != _page ? 1.0 : _entry.value, parallax: reduce ? 0 : (_offset - i).clamp(-1.0, 1.0)),
                        ),
                      _NamePage(controller: _name, tint: tint, onSubmit: () => _toSupport(addPlant: true), onSkip: () => _toSupport(addPlant: false)),
                      _SupportPage(onDone: _finish),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.md),
                  child: AnimatedSize(
                    duration: Motion.of(context, Motion.standard),
                    child: onSlides
                        ? ClayButton(
                            label: _page == _slides.length - 1 ? l10n.onbStart : l10n.continueLabel,
                            trailingIcon: CupertinoIcons.arrow_right,
                            tint: tint,
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

/// « Passer » : un mot, en encre, sans cadre. Il ne se dispute pas la place
/// avec le bouton du bas.
class _SkipButton extends StatelessWidget {
  const _SkipButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: onPressed,
      semanticLabel: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.xs, vertical: Space.xs),
        child: Text(
          label,
          style: context.text.body.copyWith(fontWeight: FontWeight.w600, color: c.ink.withValues(alpha: 0.72)),
        ),
      ),
    );
  }
}

/// Le texte d'un écran : le titre qui se lève mot à mot, puis la phrase.
/// Rangé à gauche, sous la scène — un titre d'affiche, pas une légende.
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
      padding: const EdgeInsets.fromLTRB(Space.page, Space.xl, Space.page, 0),
      child: Opacity(
        opacity: fade,
        child: Transform.translate(
          offset: Offset(parallax * -width * 0.18, 0),
          // Un texte qui tient ne défile pas ; un titre trop long pour un
          // très petit écran se lit quand même, au lieu d'être coupé.
          child: SingleChildScrollView(
            physics: floraScrollPhysics,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RisingTitle(text: slide.title(l10n), style: onboardingTitleStyle(context), t: t, alignment: WrapAlignment.start),
                const SizedBox(height: Space.md),
                Stagger(
                  t: t,
                  index: 4,
                  count: 5,
                  child: Text(slide.body(l10n), style: context.text.body.copyWith(fontSize: 19, height: 1.35, color: c.ink.withValues(alpha: 0.72))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Le titre d'un écran d'onboarding : plus grand et plus serré que le
/// `display` de l'app, parce qu'ici il est seul sur sa page.
TextStyle onboardingTitleStyle(BuildContext context) =>
    context.text.display.copyWith(fontSize: 44, height: 1.04, letterSpacing: -1.8, fontWeight: FontWeight.w800);

class _NamePage extends StatelessWidget {
  const _NamePage({required this.controller, required this.tint, required this.onSubmit, required this.onSkip});

  final TextEditingController controller;
  final Color tint;
  final VoidCallback onSubmit;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.page),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: Space.xxl),
          Text(l10n.askNameTitle, style: onboardingTitleStyle(context)),
          const SizedBox(height: Space.sm),
          Text(l10n.askNameSubtitle, style: context.text.body.copyWith(fontSize: 19, height: 1.35, color: c.ink.withValues(alpha: 0.72))),
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
          ClayButton(label: l10n.addFirstPlant, trailingIcon: CupertinoIcons.arrow_right, tint: tint, onPressed: onSubmit),
          const SizedBox(height: Space.xs),
          ClayButton(label: l10n.later, tint: tint, filled: false, onPressed: onSkip),
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
