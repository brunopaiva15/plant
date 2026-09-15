import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/cuttings/propagation_guide_resolver.dart';
import '../../onboarding/presentation/onboarding_screen.dart';
import '../../onboarding/presentation/onboarding_stage.dart';
import '../application/propagation_guides.dart';
import 'clay_sequence.dart';
import 'propagation_guide_stage.dart';

/// Ouvre le guide de multiplication, avant la création d'une nouvelle plante.
///
/// Rend `true` quand l'utilisateur veut créer la plante — au bout du guide
/// ou en le passant —, `false` ou `null` s'il referme.
Future<bool?> showPropagationGuide(BuildContext context, {String? species}) {
  return showFloraFlow<bool>(context, builder: (ctx) => PropagationGuideView(species: species));
}

/// Le guide de multiplication : le geste adapté à la plante, montré étape
/// par étape.
///
/// Quand la plante se multiplie de plusieurs façons — une sansevieria se
/// divise ou se bouture par feuille —, un écran de choix vient d'abord. La
/// méthode retenue décide de tout ce qui suit : les animations, les étapes,
/// les textes, et ce que l'IA a le droit de préciser.
class PropagationGuideView extends ConsumerStatefulWidget {
  const PropagationGuideView({super.key, this.species});

  /// Nom scientifique de la plante mère, s'il est connu.
  final String? species;

  @override
  ConsumerState<PropagationGuideView> createState() => _PropagationGuideViewState();
}

class _PropagationGuideViewState extends ConsumerState<PropagationGuideView> with TickerProviderStateMixin {
  final _pages = PageController();

  /// L'entrée de la scène, jouée une fois à l'ouverture.
  late final _entry = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..forward();

  /// La levée du texte, rejouée à chaque étape neuve.
  late final _reveal = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();

  /// Les étapes dont le texte est déjà levé : revenir sur ses pas ne le
  /// relève pas.
  final _revealed = <int>{0};

  /// Les façons de multiplier cette plante, la conseillée d'abord.
  late final List<PropagationOption> _options = _resolve();

  /// Celle qu'on suit. Une seule façon : elle est choisie d'office et
  /// l'écran de choix ne paraît pas.
  PropagationOption? _choice;

  int _page = 0;
  double _offset = 0;

  /// En-tête (fermer, passer) et pied (points, bouton), avec leurs marges.
  static const double _topHeight = Space.sm + 40;
  static const double _bottomHeight = Space.md + 7 + Space.lg + 56 + Space.md;

  List<PropagationOption> _resolve() {
    final species = widget.species?.trim();
    final care = ref.read(careGuideProvider).resolve(species, family: speciesFamilyOf(ref, species));
    return resolvePropagationOptions(
      profile: care.profile,
      scientificName: species,
      family: speciesFamilyOf(ref, species),
    );
  }

  @override
  void initState() {
    super.initState();
    if (_options.length == 1) _choice = _options.first;
    _pages.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _choice != null) _keepSequences(0);
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

  PropagationGuide get _guide => propagationGuideOf(_choice!.kind);

  /// Nombre de pages : l'introduction, puis une par étape du guide.
  int get _count => _guide.length + 1;

  /// L'étape d'une page, ou `null` pour l'introduction.
  PropagationStep? _stepOf(int page) => page == 0 ? null : _guide.steps[page - 1];

  /// Charge d'avance la séquence de la page suivante. L'introduction les
  /// montre toutes : elles sont alors déjà là.
  void _keepSequences(int page) {
    for (final i in {page, page + 1}) {
      final step = i < _count ? _stepOf(i) : null;
      if (step != null) ClaySequence.precache(step.asset);
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

  void _pick(PropagationOption option) {
    Haptics.light();
    setState(() => _choice = option);
    _entry
      ..reset()
      ..forward();
    _keepSequences(0);
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
    if (_choice == null) return c.sage;
    final tints = [c.sage, for (final step in _guide.steps) step.tint(c)];
    final o = _offset.clamp(0.0, (tints.length - 1).toDouble());
    final i = o.floor();
    final next = math.min(i + 1, tints.length - 1);
    return Color.lerp(tints[i], tints[next], o - i)!;
  }

  /// La petite ligne sous le texte d'une étape, ou `null`. Celle des étapes
  /// d'enracinement vient de la fiche de l'espèce — eau, substrat, ou les
  /// deux — et non du guide, qui ne connaît pas la plante.
  (String, String)? _noteOf(PropagationStep step, AppLocalizations l10n) {
    if (step.showsMedium) {
      final milieu = rootingMediumLabel(l10n, _choice!.medium);
      if (milieu != null) return (l10n.pgNoteMedium, milieu);
    }
    final note = step.note;
    return note == null ? null : (note.label(l10n), note.value(l10n));
  }

  /// Le titre de l'introduction : le geste, et l'espèce quand on la connaît.
  String _introTitle(AppLocalizations l10n) {
    final name = _guide.name(l10n);
    final species = widget.species?.trim() ?? '';
    return species.isEmpty ? name : l10n.pgIntroTitle(name, species);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final tint = _tint(c);

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
                        if (_choice != null)
                          FloraButton(label: l10n.skip, style: FloraButtonStyle.ghost, size: FloraButtonSize.small, onPressed: () => _close(true)),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: _choice == null ? _picker(l10n) : _walkthrough(l10n, reduce, tint),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── L'écran de choix ───────────────────────────────────────────────────
  Widget _picker(AppLocalizations l10n) {
    return SingleChildScrollView(
      physics: floraScrollPhysics,
      padding: const EdgeInsets.fromLTRB(Space.page, Space.xl, Space.page, Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RisingTitle(text: l10n.pgPickTitle, style: onboardingTitleStyle(context), t: 1),
          const SizedBox(height: Space.sm),
          Text(l10n.pgPickBody, style: onboardingBodyStyle(context)),
          const SizedBox(height: Space.lg),
          for (final (i, option) in _options.indexed) ...[
            if (i > 0) const SizedBox(height: Space.sm),
            _MethodCard(
              guide: propagationGuideOf(option.kind),
              recommended: i == 0,
              onTap: () => _pick(option),
            ),
          ],
        ],
      ),
    );
  }

  // ── Le guide ───────────────────────────────────────────────────────────
  Widget _walkthrough(AppLocalizations l10n, bool reduce, Color tint) {
    final species = widget.species?.trim() ?? '';
    final language = Localizations.localeOf(context).languageCode;
    final refined = species.isEmpty
        ? null
        : ref.watch(propagationRefinementProvider((species: species, language: language, kind: _choice!.kind))).value;
    final last = _page == _count - 1;

    return Column(
      children: [
        AnimatedBuilder(
          animation: _entry,
          builder: (context, _) => PropagationGuideStage(
            steps: _guide.steps,
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
              for (var i = 0; i < _count; i++)
                AnimatedBuilder(
                  animation: _reveal,
                  builder: (context, _) {
                    final step = _stepOf(i);
                    final note = step == null ? null : _noteOf(step, l10n);
                    return _PageText(
                      title: step == null ? _introTitle(l10n) : step.title(l10n),
                      body: step == null ? l10n.pgIntroBody(_guide.length) : refined?.at(i - 1) ?? step.fallbackBody(l10n),
                      noteLabel: note?.$1,
                      noteValue: note?.$2,
                      t: reduce ? 1.0 : _revealOf(i),
                      parallax: reduce ? 0 : (_offset - i).clamp(-1.0, 1.0),
                    );
                  },
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.page, Space.md, Space.page, Space.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: OnboardingProgress(count: _count, index: _page, color: tint)),
              const SizedBox(height: Space.lg),
              OnboardingButton(
                label: last
                    ? _guide.startLabel(l10n)
                    : _page == 0
                        ? l10n.next
                        : l10n.continueLabel,
                trailingIcon: last ? CupertinoIcons.leaf_arrow_circlepath : CupertinoIcons.arrow_right,
                onPressed: () => last ? _close(true) : _goTo(_page + 1),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Une méthode proposée, sur l'écran de choix : son nom, ce qu'elle vaut,
/// et la mention « Conseillée » sur la première.
class _MethodCard extends StatelessWidget {
  const _MethodCard({required this.guide, required this.recommended, required this.onTap});

  final PropagationGuide guide;
  final bool recommended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    return FloraCard(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(guide.name(l10n), style: context.text.callout.copyWith(color: c.ink, fontWeight: FontWeight.w600))),
                    if (recommended) ...[
                      const SizedBox(width: Space.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: c.sageSoft, borderRadius: Radii.fullAll),
                        child: Text(l10n.pgRecommended, style: context.text.caption.copyWith(color: c.sage, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(guide.hint(l10n), style: context.text.caption.copyWith(color: c.inkSecondary)),
              ],
            ),
          ),
          const SizedBox(width: Space.xs),
          Icon(CupertinoIcons.chevron_right, size: 16, color: c.inkTertiary),
        ],
      ),
    );
  }
}

/// Le texte d'une page : le titre qui se lève, la phrase — générique
/// d'abord, précisée par l'IA quand elle arrive —, et parfois une ligne de
/// plus, celle qui évite l'erreur.
class _PageText extends StatelessWidget {
  const _PageText({
    required this.title,
    required this.body,
    required this.t,
    required this.parallax,
    this.noteLabel,
    this.noteValue,
  });

  final String title;
  final String body;
  final String? noteLabel;
  final String? noteValue;
  final double t;
  final double parallax;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final width = MediaQuery.sizeOf(context).width;
    final fade = (1 - parallax.abs() * 1.6).clamp(0.0, 1.0);
    final label = noteLabel;
    final value = noteValue;

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
                RisingTitle(text: title, style: onboardingTitleStyle(context), t: t),
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
                    child: Text(body, key: ValueKey(body), style: onboardingBodyStyle(context)),
                  ),
                ),
                if (label != null && value != null) ...[
                  const SizedBox(height: Space.sm),
                  Stagger(
                    t: t,
                    index: 4,
                    count: 5,
                    slide: 10,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: context.text.caption.copyWith(color: c.inkTertiary, fontWeight: FontWeight.w600)),
                        const SizedBox(width: Space.xs),
                        Expanded(child: Text(value, style: context.text.caption.copyWith(color: c.inkSecondary))),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
