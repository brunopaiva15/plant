import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../onboarding/presentation/onboarding_screen.dart';
import '../../onboarding/presentation/onboarding_stage.dart';
import '../application/cutting_guide_steps.dart';
import 'clay_sequence.dart';
import 'cutting_guide_stage.dart';

/// Ouvre le guide de bouturage, avant la création d'une bouture.
///
/// Rend `true` quand l'utilisateur veut créer la bouture — au bout du guide
/// ou en le passant —, `false` ou `null` s'il referme.
Future<bool?> showCuttingGuide(BuildContext context, {String? species}) {
  return showFloraFlow<bool>(context, builder: (ctx) => CuttingGuideView(species: species));
}

/// Le guide de bouturage : six étapes, chacune un objet d'argile qui joue
/// son geste sur un halo, un titre, une phrase.
///
/// Les textes sont ceux d'une bouture de tige dans l'eau. Quand l'espèce de
/// la plante mère est connue et que l'IA est permise, ils sont précisés pour
/// elle : le texte générique s'affiche d'abord, le texte précis le remplace
/// en fondu quand il arrive, et une ligne dit d'où il vient.
class CuttingGuideView extends ConsumerStatefulWidget {
  const CuttingGuideView({super.key, this.species});

  /// Nom scientifique de la plante mère, s'il est connu.
  final String? species;

  @override
  ConsumerState<CuttingGuideView> createState() => _CuttingGuideViewState();
}

class _CuttingGuideViewState extends ConsumerState<CuttingGuideView> with TickerProviderStateMixin {
  final _pages = PageController();

  /// L'entrée de la scène, jouée une fois à l'ouverture.
  late final _entry = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..forward();

  /// La levée du texte, rejouée à chaque étape neuve.
  late final _reveal = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();

  /// Les étapes dont le texte est déjà levé : revenir sur ses pas ne le
  /// relève pas.
  final _revealed = <int>{0};

  int _page = 0;
  double _offset = 0;

  /// En-tête (fermer, passer) et pied (points, bouton), avec leurs marges.
  static const double _topHeight = Space.sm + 40;
  static const double _bottomHeight = Space.md + 7 + Space.lg + 56 + Space.md;

  @override
  void initState() {
    super.initState();
    _pages.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _keepSequences(0);
    });
  }

  @override
  void dispose() {
    _pages.removeListener(_onScroll);
    _pages.dispose();
    _entry.dispose();
    _reveal.dispose();
    super.dispose();
  }

  void _onScroll() {
    final page = _pages.hasClients ? _pages.page : null;
    if (page != null && page != _offset) setState(() => _offset = page);
  }

  /// Charge d'avance la séquence de l'étape suivante.
  void _keepSequences(int page) {
    for (final i in {page, page + 1}) {
      if (i < cuttingGuideSteps.length) ClaySequence.precache(cuttingGuideSteps[i].asset);
    }
  }

  void _goTo(int page) {
    Haptics.light();
    final duration = Motion.of(context, Motion.emphasis);
    if (duration == Duration.zero) {
      _pages.jumpToPage(page);
    } else {
      _pages.animateToPage(page, duration: duration, curve: Motion.emphasized);
    }
  }

  void _onPageChanged(int page) {
    setState(() => _page = page);
    _keepSequences(page);
    if (_revealed.add(page)) {
      _reveal
        ..reset()
        ..forward();
    } else {
      _reveal.value = 1;
    }
  }

  double _revealOf(int i) {
    if (i == _page) return _reveal.value;
    return _revealed.contains(i) ? 1 : 0;
  }

  void _close(bool create) {
    Haptics.light();
    Navigator.of(context, rootNavigator: true).pop(create);
  }

  /// La scène prend ce que la hauteur laisse une fois le texte servi. Le
  /// texte précisé par l'IA peut être plus long que le générique : il
  /// défile s'il le faut, la scène ne bouge pas.
  double _stageHeight(BuildContext context) {
    final mq = MediaQuery.of(context);
    final text = mq.textScaler.scale(190);
    final free = mq.size.height - mq.padding.vertical - _topHeight - _bottomHeight - text;
    return free.clamp(180.0, 400.0);
  }

  Color _tint(FloraColors c) {
    final tints = [for (final step in cuttingGuideSteps) step.tint(c)];
    final o = _offset.clamp(0.0, (tints.length - 1).toDouble());
    final i = o.floor();
    final next = math.min(i + 1, tints.length - 1);
    return Color.lerp(tints[i], tints[next], o - i)!;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final tint = _tint(c);
    final species = widget.species?.trim() ?? '';
    final language = Localizations.localeOf(context).languageCode;
    final refined = species.isEmpty ? null : ref.watch(cuttingGuideRefinementProvider((species: species, language: language))).value;
    final last = _page == cuttingGuideSteps.length - 1;

    return Scaffold(
      backgroundColor: OnboardingBackdrop.wash(c, tint),
      body: Stack(
        children: [
          Positioned.fill(child: OnboardingBackdrop(tint: tint, drift: 1, reduceMotion: reduce)),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(Space.md, Space.sm, Space.md, 0),
                  child: SizedBox(
                    height: 40,
                    child: Row(
                      children: [
                        FloraIconButton(icon: CupertinoIcons.xmark, semanticLabel: l10n.close, onPressed: () => _close(false)),
                        const Spacer(),
                        FloraButton(label: l10n.skip, style: FloraButtonStyle.ghost, size: FloraButtonSize.small, onPressed: () => _close(true)),
                      ],
                    ),
                  ),
                ),
                AnimatedBuilder(
                  animation: _entry,
                  builder: (context, _) => CuttingGuideStage(
                    offset: _offset,
                    page: _page,
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
                      for (final (i, step) in cuttingGuideSteps.indexed)
                        AnimatedBuilder(
                          animation: _reveal,
                          builder: (context, _) => _StepText(
                            step: step,
                            refined: refined?.of(step.step),
                            species: species,
                            t: reduce ? 1.0 : _revealOf(i),
                            parallax: reduce ? 0 : (_offset - i).clamp(-1.0, 1.0),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(Space.page, Space.md, Space.page, Space.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(child: OnboardingProgress(count: cuttingGuideSteps.length, index: _page, color: tint)),
                      const SizedBox(height: Space.lg),
                      OnboardingButton(
                        label: last ? l10n.cuttingGuideStart : l10n.continueLabel,
                        trailingIcon: last ? CupertinoIcons.leaf_arrow_circlepath : CupertinoIcons.arrow_right,
                        onPressed: () => last ? _close(true) : _goTo(_page + 1),
                      ),
                    ],
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

/// Le texte d'une étape : le titre qui se lève, puis la phrase — générique
/// d'abord, précisée par l'IA quand elle arrive — et la ligne qui dit d'où
/// vient la précision.
class _StepText extends StatelessWidget {
  const _StepText({required this.step, required this.refined, required this.species, required this.t, required this.parallax});

  final CuttingGuideStep step;

  /// Le texte précisé pour l'espèce, ou `null` tant qu'il n'y en a pas.
  final String? refined;
  final String species;
  final double t;
  final double parallax;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final width = MediaQuery.sizeOf(context).width;
    final fade = (1 - parallax.abs() * 1.6).clamp(0.0, 1.0);
    final body = refined ?? step.body(l10n);

    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.page, Space.xl, Space.page, 0),
      child: Opacity(
        opacity: fade,
        child: Transform.translate(
          offset: Offset(parallax * -width * 0.18, 0),
          child: SingleChildScrollView(
            physics: floraScrollPhysics,
            padding: const EdgeInsets.only(bottom: Space.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RisingTitle(text: step.title(l10n), style: onboardingTitleStyle(context), t: t),
                const SizedBox(height: Space.sm),
                Stagger(
                  t: t,
                  index: 3,
                  count: 4,
                  slide: 10,
                  child: AnimatedSwitcher(
                    duration: Motion.of(context, Motion.slow),
                    switchInCurve: Motion.easeOut,
                    switchOutCurve: Motion.easeOut,
                    layoutBuilder: (current, previous) => Stack(
                      alignment: Alignment.topLeft,
                      children: [...previous, ?current],
                    ),
                    child: Column(
                      key: ValueKey(body),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(body, style: onboardingBodyStyle(context)),
                        if (refined != null) ...[
                          const SizedBox(height: Space.sm),
                          Text(l10n.cuttingGuideRefined(species), style: context.text.caption.copyWith(color: c.inkTertiary)),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
