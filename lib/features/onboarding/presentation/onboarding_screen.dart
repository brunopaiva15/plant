import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../plants/presentation/create_plant_flow.dart';
import 'onboarding_art.dart';

/// Un écran de présentation : une illustration animée, un titre, une phrase.
class _Slide {
  const _Slide({required this.title, required this.body, required this.art});

  final String Function(AppLocalizations) title;
  final String Function(AppLocalizations) body;
  final Widget Function(double t) art;
}

final _slides = <_Slide>[
  _Slide(title: (l) => l.onboardingTitle, body: (l) => l.onboardingSubtitle, art: (t) => SproutArt(t: t)),
  _Slide(title: (l) => l.onbTodayTitle, body: (l) => l.onbTodayBody, art: (t) => TodayArt(t: t)),
  _Slide(title: (l) => l.onbCareTitle, body: (l) => l.onbCareBody, art: (t) => SeasonArt(t: t)),
  _Slide(title: (l) => l.onbGardenTitle, body: (l) => l.onbGardenBody, art: (t) => GardenArt(t: t)),
  _Slide(title: (l) => l.onbPrivacyTitle, body: (l) => l.onbPrivacyBody, art: (t) => PrivacyArt(t: t)),
];

/// Présentation animée, puis le prénom. La première plante se crée dans le
/// flow standard : l'utilisateur découvre l'app en s'en servant.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> with SingleTickerProviderStateMixin {
  final _name = TextEditingController();
  final _pages = PageController();
  late final _entry = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..forward();
  int _page = 0;

  /// Dernière page : la saisie du prénom, après les diapositives.
  bool get _onNamePage => _page == _slides.length;

  @override
  void dispose() {
    _name.dispose();
    _pages.dispose();
    _entry.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    Haptics.light();
    _pages.animateToPage(page, duration: Motion.of(context, Motion.emphasis), curve: Motion.emphasized);
  }

  void _onPageChanged(int page) {
    setState(() => _page = page);
    // Chaque diapositive rejoue son animation à l'arrivée, jamais avant.
    _entry
      ..reset()
      ..forward();
  }

  Future<void> _finish({required bool addPlant}) async {
    final prefs = ref.read(preferencesProvider.notifier);
    if (_name.text.trim().isNotEmpty) await prefs.setDisplayName(_name.text);
    await prefs.setOnboardingDone();
    if (!mounted) return;
    context.go(Routes.today);
    if (addPlant) {
      await Future<void>.delayed(Motion.of(context, Motion.emphasis));
      if (mounted) await startCreatePlantFlow(context, ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final reduce = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      backgroundColor: c.canvas,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 44,
              child: Row(
                children: [
                  const SizedBox(width: Space.page),
                  Expanded(child: _Dots(count: _slides.length + 1, index: _page)),
                  if (!_onNamePage)
                    FloraButton(
                      label: l10n.skip,
                      style: FloraButtonStyle.ghost,
                      size: FloraButtonSize.small,
                      onPressed: () => _goTo(_slides.length),
                    )
                  else
                    const SizedBox(width: Space.page),
                  const SizedBox(width: Space.xs),
                ],
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
                      builder: (context, _) {
                        // Hors de la page courante, l'illustration reste à
                        // son état final : pas d'animation en coulisses.
                        final t = reduce || i != _page ? 1.0 : _entry.value;
                        return _SlideView(slide: slide, t: t);
                      },
                    ),
                  _NamePage(
                    controller: _name,
                    onSubmit: () => _finish(addPlant: true),
                    onSkip: () => _finish(addPlant: false),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.md),
              child: AnimatedSize(
                duration: Motion.of(context, Motion.standard),
                child: _onNamePage
                    ? const SizedBox(width: double.infinity)
                    : FloraButton(
                        label: _page == _slides.length - 1 ? l10n.onbStart : l10n.continueLabel,
                        expand: true,
                        onPressed: () => _goTo(_page + 1),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide, required this.t});

  final _Slide slide;
  final double t;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.page),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          slide.art(t),
          const SizedBox(height: Space.xxl),
          Stagger(
            t: t,
            index: 2,
            count: 4,
            child: Text(slide.title(l10n), style: context.text.title1, textAlign: TextAlign.center),
          ),
          const SizedBox(height: Space.sm),
          Stagger(
            t: t,
            index: 3,
            count: 4,
            child: Text(slide.body(l10n), style: context.text.body.copyWith(color: c.inkSecondary), textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}

/// Points de progression : le point courant s'allonge en une petite barre.
class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      label: context.l10n.onbStepOf(index + 1, count),
      child: Row(
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: Motion.of(context, Motion.standard),
              curve: Motion.easeOut,
              margin: const EdgeInsets.only(right: 6),
              width: i == index ? 22 : 7,
              height: 7,
              decoration: BoxDecoration(color: i == index ? c.sage : c.line, borderRadius: BorderRadius.circular(4)),
            ),
        ],
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
          Text(l10n.askNameTitle, style: context.text.title1),
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
          FloraButton(label: l10n.addFirstPlant, expand: true, onPressed: onSubmit),
          const SizedBox(height: Space.xs),
          FloraButton(label: l10n.later, style: FloraButtonStyle.ghost, expand: true, onPressed: onSkip),
          const SizedBox(height: Space.md),
        ],
      ),
    );
  }
}
