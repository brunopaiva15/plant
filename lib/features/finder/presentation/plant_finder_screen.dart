import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/providers.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/finder_labels.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/species/plant_advisor.dart';
import '../../../domain/species/plant_finder.dart';
import '../../../domain/species/species_info.dart';
import '../../plants/presentation/create_plant_flow.dart';
import '../../species/presentation/care_guide_screen.dart';
import 'finder_cards.dart';

/// « Trouver une plante » : trois questions, puis des espèces du catalogue
/// intégré qui y répondent, chacune avec sa fiche d'entretien.
///
/// Les questions sont celles qui décident — l'endroit, le soin qu'on est
/// prêt à donner, les animaux et les enfants. Le genre de plante n'en est
/// pas une : c'est un filtre, posé sur les propositions, qui les refait sous
/// les yeux. Le tri se fait sur les fiches déjà embarquées : la réponse est
/// immédiate et hors ligne. L'IA n'intervient qu'ensuite, sur demande, quand
/// le catalogue n'a rien de convaincant à proposer.
class PlantFinderScreen extends ConsumerStatefulWidget {
  const PlantFinderScreen({super.key, this.picking = false});

  /// Ouvert depuis le sélecteur d'espèce : la proposition retenue lui est
  /// rendue, au lieu de lancer la création d'une plante.
  final bool picking;

  @override
  ConsumerState<PlantFinderScreen> createState() => _PlantFinderScreenState();
}

class _PlantFinderScreenState extends ConsumerState<PlantFinderScreen> {
  /// Les trois questions, dans l'ordre, puis les propositions.
  static const _spot = 0;
  static const _effort = 1;
  static const _safety = 2;
  static const _results = 3;
  static const _questions = 3;

  final _page = PageController();
  final _note = TextEditingController();
  int _step = _spot;
  FinderCriteria _criteria = const FinderCriteria();
  List<AdvisorSuggestion> _suggestions = const [];
  bool _asking = false;

  /// Une réponse vient d'être touchée : la tuile se colore, puis la page
  /// tourne. Le temps de voir ce qu'on a choisi, et pas un tap de plus.
  bool _advancing = false;

  /// On est revenu à une question depuis les propositions, pour changer une
  /// réponse : la nouvelle réponse y ramène directement.
  bool _editing = false;

  @override
  void dispose() {
    _page.dispose();
    _note.dispose();
    super.dispose();
  }

  void _go(int step) {
    Haptics.selection();
    // Le clavier du champ libre ne doit pas suivre sur les questions.
    if (step != _results) FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _step = step);
    _page.animateToPage(step, duration: Motion.of(context, Motion.emphasis), curve: Motion.emphasized);
  }

  void _back() {
    if (_step == _spot) {
      context.pop();
      return;
    }
    if (_editing) {
      _editing = false;
      _go(_results);
      return;
    }
    _go(_step - 1);
  }

  /// Une réponse choisie enchaîne sur la question suivante : c'est un
  /// questionnaire, pas un formulaire. Depuis les propositions, elle y
  /// ramène.
  void _answer(FinderCriteria next) {
    if (_advancing) return;
    Haptics.selection();
    setState(() {
      _criteria = next;
      _advancing = true;
    });
    final linger = Motion.of(context, Motion.standard);
    Future<void>.delayed(linger, () {
      if (!mounted) return;
      _advancing = false;
      final destination = _editing ? _results : _step + 1;
      _editing = false;
      _go(destination);
    });
  }

  /// Retour à une question depuis les propositions, par sa puce.
  void _edit(int step) {
    _editing = true;
    _go(step);
  }

  void _toggleCategory(SpeciesCategory? category) {
    Haptics.selection();
    setState(() {
      if (category == null) {
        _criteria = _criteria.copyWith(categories: const {});
        return;
      }
      final next = {..._criteria.categories};
      if (!next.remove(category)) next.add(category);
      _criteria = _criteria.copyWith(categories: next);
    });
  }

  void _restart() {
    setState(() {
      _criteria = const FinderCriteria();
      _suggestions = const [];
      _editing = false;
      _note.clear();
    });
    _go(_spot);
  }

  Future<void> _askAdvisor(List<FinderMatch> matches) async {
    if (_asking) return;
    final l10n = context.l10n;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _asking = true);
    try {
      final results = await ref.read(plantAdvisorProvider).suggest(
            criteria: _criteria.copyWith(note: _note.text),
            language: Localizations.localeOf(context).languageCode,
            exclude: [for (final m in matches) m.entry.scientificName, for (final s in _suggestions) s.scientificName],
          );
      if (!mounted) return;
      if (results.isEmpty) {
        ref.read(toastProvider.notifier).show(ToastData(message: l10n.finderAiError, emoji: '!'));
      } else {
        Haptics.success();
      }
      setState(() => _suggestions = results);
    } on AdvisorException {
      if (mounted) ref.read(toastProvider.notifier).show(ToastData(message: l10n.finderAiError, emoji: '!'));
    } catch (e, st) {
      ref.read(crashReporterProvider).report(e, st, context: 'finder.advisor');
      if (mounted) ref.read(toastProvider.notifier).show(ToastData(message: l10n.finderAiError, emoji: '!'));
    } finally {
      if (mounted) setState(() => _asking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.canvas,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.md, Space.xs, Space.md, 0),
              child: Row(
                children: [
                  FloraIconButton(
                    icon: _step == _spot ? CupertinoIcons.xmark : CupertinoIcons.chevron_left,
                    semanticLabel: _step == _spot ? l10n.close : l10n.back,
                    onPressed: _back,
                  ),
                  const Spacer(),
                  if (_step < _results)
                    StepDots(count: _questions, index: _step)
                  else
                    Text(l10n.finderTitle, style: context.text.callout.copyWith(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _page,
                physics: const NeverScrollableScrollPhysics(),
                children: [_spotStep(), _effortStep(), _safetyStep(), _resultsStep()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _spotStep() {
    final l10n = context.l10n;
    return _QuestionStep(
      number: 1,
      title: l10n.finderStepSpot,
      subtitle: l10n.finderStepSpotHint,
      answers: [
        for (final (i, spot) in FinderSpot.values.indexed)
          _AnswerTile(
            emoji: l10n.finderSpotEmoji(spot),
            label: l10n.finderSpotName(spot),
            hint: l10n.finderSpotHint(spot),
            selected: _criteria.spot == spot,
            variant: i,
            onTap: () => _answer(_criteria.copyWith(spot: () => spot)),
          ),
      ],
      footer: FloraButton(label: l10n.finderAnyAnswer, style: FloraButtonStyle.ghost, expand: true, onPressed: () => _answer(_criteria.copyWith(spot: () => null))),
    );
  }

  Widget _effortStep() {
    final l10n = context.l10n;
    return _QuestionStep(
      number: 2,
      title: l10n.finderStepEffort,
      subtitle: l10n.finderStepEffortHint,
      answers: [
        for (final (i, effort) in FinderEffort.values.indexed)
          _AnswerTile(
            emoji: l10n.finderEffortEmoji(effort),
            label: l10n.finderEffortName(effort),
            hint: l10n.finderEffortHint(effort),
            selected: _criteria.effort == effort,
            variant: i + 1,
            onTap: () => _answer(_criteria.copyWith(effort: () => effort)),
          ),
      ],
      footer: FloraButton(label: l10n.finderAnyAnswer, style: FloraButtonStyle.ghost, expand: true, onPressed: () => _answer(_criteria.copyWith(effort: () => null))),
    );
  }

  Widget _safetyStep() {
    final l10n = context.l10n;
    return _QuestionStep(
      number: 3,
      title: l10n.finderStepSafety,
      subtitle: l10n.finderStepSafetyHint,
      answers: [
        _AnswerTile(
          emoji: '🐾',
          label: l10n.finderSafetyYes,
          hint: l10n.finderSafetyYesHint,
          selected: _criteria.safeOnly,
          variant: 2,
          onTap: () => _answer(_criteria.copyWith(safeOnly: true)),
        ),
        _AnswerTile(
          emoji: '🙅',
          label: l10n.finderSafetyNo,
          hint: l10n.finderSafetyNoHint,
          selected: !_criteria.safeOnly,
          variant: 3,
          onTap: () => _answer(_criteria.copyWith(safeOnly: false)),
        ),
      ],
    );
  }

  Widget _resultsStep() {
    final l10n = context.l10n;
    final advisor = ref.watch(plantAdvisorProvider);
    final matches = ref.watch(plantFinderProvider).search(_criteria);
    final side = Space.page + readableInset(context);
    final shown = [for (final m in matches) m.entry.scientificName, for (final s in _suggestions) s.scientificName];

    Widget inset(Widget child) => Padding(padding: EdgeInsets.symmetric(horizontal: side), child: child);

    final categories = <(SpeciesCategory?, String, String?)>[
      (null, l10n.speciesCatAll, null),
      for (final category in SpeciesCategory.values) (category, l10n.speciesCategoryName(category), category.emoji),
    ];

    return ListView(
      physics: floraScrollPhysics,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.only(top: Space.lg, bottom: Space.huge),
      children: [
        inset(Text(l10n.finderResults, style: context.text.title1)),
        const SizedBox(height: Space.sm),
        // Les réponses, en puces : chacune ramène à sa question, et la
        // nouvelle réponse revient ici. Pas besoin de tout recommencer pour
        // changer d'avis sur la lumière.
        inset(
          Wrap(
            spacing: Space.xs,
            runSpacing: Space.xs,
            children: [
              _AnswerChip(
                emoji: _criteria.spot == null ? '📍' : l10n.finderSpotEmoji(_criteria.spot!),
                label: _criteria.spot == null ? l10n.finderChipSpotAny : l10n.finderSpotName(_criteria.spot!),
                onTap: () => _edit(_spot),
              ),
              _AnswerChip(
                emoji: _criteria.effort == null ? '💧' : l10n.finderEffortEmoji(_criteria.effort!),
                label: _criteria.effort == null ? l10n.finderChipEffortAny : l10n.finderEffortName(_criteria.effort!),
                onTap: () => _edit(_effort),
              ),
              _AnswerChip(
                emoji: _criteria.safeOnly ? '🐾' : '🙅',
                label: _criteria.safeOnly ? l10n.finderChipSafe : l10n.finderSafetyNo,
                onTap: () => _edit(_safety),
              ),
            ],
          ),
        ),
        const SizedBox(height: Space.md),
        // Le genre de plante, en filtre plutôt qu'en question : la liste se
        // refait sous les yeux, et « Toutes » y ramène.
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: floraScrollPhysics,
            padding: EdgeInsets.symmetric(horizontal: side),
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: Space.xs),
            itemBuilder: (context, i) {
              final (category, label, emoji) = categories[i];
              final selected = category == null ? _criteria.categories.isEmpty : _criteria.categories.contains(category);
              return FloraChip(label: label, emoji: emoji, selected: selected, onTap: () => _toggleCategory(category));
            },
          ),
        ),
        const SizedBox(height: Space.lg),
        if (matches.isEmpty)
          inset(EmptyState(emoji: '🌱', title: l10n.finderEmptyTitle, subtitle: l10n.finderEmptySubtitle, compact: true))
        else ...[
          inset(FinderTopPickCard(match: matches.first, onTap: () => _open(matches.first))),
          if (matches.length > 1) ...[
            const SizedBox(height: Space.xl),
            inset(Text(l10n.finderAlternatives, style: context.text.title2)),
            const SizedBox(height: Space.sm),
            for (final (i, match) in matches.skip(1).indexed) ...[
              if (i > 0) const SizedBox(height: Space.sm),
              inset(FinderMatchCard(match: match, index: i + 1, onTap: () => _open(match))),
            ],
          ],
        ],
        if (advisor.isConfigured) ...[
          const SizedBox(height: Space.xl),
          inset(
            FloraCard(
              padding: const EdgeInsets.all(Space.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Text('✨', style: TextStyle(fontSize: 22, height: 1)),
                      const SizedBox(width: Space.sm),
                      Expanded(child: Text(l10n.finderAiTitle, style: context.text.title3)),
                    ],
                  ),
                  const SizedBox(height: Space.xs),
                  Text(l10n.finderAiBody, style: context.text.callout),
                  const SizedBox(height: Space.md),
                  FloraTextField(controller: _note, hint: l10n.finderNoteHint, minLines: 2, maxLines: 4),
                  const SizedBox(height: Space.md),
                  FloraButton(
                    label: l10n.finderAskAi,
                    icon: CupertinoIcons.sparkles,
                    style: FloraButtonStyle.tonal,
                    expand: true,
                    loading: _asking,
                    onPressed: () => _askAdvisor(matches),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (_suggestions.isNotEmpty) ...[
          const SizedBox(height: Space.xl),
          inset(Text(l10n.finderAiSection, style: context.text.title2)),
          const SizedBox(height: Space.xxs),
          inset(Text(l10n.finderAiHint, style: context.text.caption)),
          const SizedBox(height: Space.sm),
          for (final (i, suggestion) in _suggestions.indexed) ...[
            if (i > 0) const SizedBox(height: Space.sm),
            inset(FinderAdvisorCard(suggestion: suggestion, index: i, onTap: () => _openSuggestion(suggestion))),
          ],
        ],
        inset(FinderPhotoSource(scientificNames: shown)),
        const SizedBox(height: Space.xl),
        inset(FloraButton(label: l10n.finderRestart, style: FloraButtonStyle.ghost, expand: true, onPressed: _restart)),
      ],
    );
  }

  Future<void> _open(FinderMatch match) {
    final lang = Localizations.localeOf(context).languageCode;
    return _openSpecies(
      scientificName: match.entry.scientificName,
      commonName: match.entry.commonName(lang),
      family: match.entry.family,
      emoji: match.entry.category.emoji,
      reasons: match.reasons,
    );
  }

  Future<void> _openSuggestion(AdvisorSuggestion suggestion) =>
      _openSpecies(scientificName: suggestion.scientificName, commonName: suggestion.commonName, emoji: '✨');

  Future<void> _openSpecies({required String scientificName, required String emoji, String? commonName, String? family, List<FinderReason> reasons = const []}) async {
    final l10n = context.l10n;
    final chosen = await showFinderSpeciesSheet(
      context,
      scientificName: scientificName,
      commonName: commonName,
      family: family,
      emoji: emoji,
      reasons: reasons,
      actionLabel: widget.picking ? l10n.useThis : l10n.finderAdd,
      actionIcon: widget.picking ? CupertinoIcons.checkmark_alt : CupertinoIcons.plus,
    );
    if (chosen != true || !mounted) return;
    if (widget.picking) {
      context.pop(SpeciesSuggestion(key: 0, scientificName: scientificName, family: family, commonName: commonName));
      return;
    }
    await startCreatePlantFlow(context, ref, speciesName: scientificName);
  }
}

/// Fiche d'une proposition : ce que l'application sait de l'espèce, et le
/// geste qui suit — l'ajouter au jardin.
Future<bool?> showFinderSpeciesSheet(
  BuildContext context, {
  required String scientificName,
  required String actionLabel,
  required IconData actionIcon,
  String? commonName,
  String? family,
  String emoji = '🪴',
  List<FinderReason> reasons = const [],
}) =>
    showFloraSheet<bool>(
      context,
      scrollable: true,
      builder: (_) => _SpeciesSheet(
        scientificName: scientificName,
        actionLabel: actionLabel,
        actionIcon: actionIcon,
        commonName: commonName,
        family: family,
        emoji: emoji,
        reasons: reasons,
      ),
    );

class _SpeciesSheet extends ConsumerWidget {
  const _SpeciesSheet({
    required this.scientificName,
    required this.actionLabel,
    required this.actionIcon,
    required this.emoji,
    required this.reasons,
    this.commonName,
    this.family,
  });

  final String scientificName;
  final String actionLabel;
  final IconData actionIcon;
  final String emoji;
  final List<FinderReason> reasons;
  final String? commonName;
  final String? family;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final care = ref.watch(careGuideProvider).resolve(scientificName, family: family ?? speciesFamilyLookup(ref)(scientificName));
    final credit = speciesPhotoCredit(context, ref.watch(finderThumbnailProvider(scientificName)).asData?.value);
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.md, Space.xs, Space.md, Space.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SpeciesTile(scientificName: scientificName, emoji: emoji, size: 64, variant: 1),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(commonName ?? scientificName, style: context.text.title2, maxLines: 2, overflow: TextOverflow.ellipsis),
                    if (commonName != null) ...[
                      const SizedBox(height: 2),
                      Text(scientificName, style: context.text.caption.copyWith(fontStyle: FontStyle.italic)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (reasons.isNotEmpty) ...[const SizedBox(height: Space.sm), FinderReasons(reasons: reasons)],
          if (credit != null) ...[const SizedBox(height: Space.xs), Text(credit, style: context.text.caption)],
          const SizedBox(height: Space.lg),
          CareGuideBody(care: care, speciesName: scientificName),
          const SizedBox(height: Space.lg),
          FloraButton(label: actionLabel, icon: actionIcon, expand: true, onPressed: () => Navigator.of(context).pop(true)),
          const SizedBox(height: Space.xs),
          // La fiche d'entretien dit comment s'en occuper ; GBIF dit ce que
          // c'est, avec des photos d'observation et sa taxonomie. Le
          // catalogue ne connaît pas la clé GBIF de l'espèce, donc on ouvre
          // la recherche par nom, qui tombe juste sur un nom accepté.
          FloraButton(
            label: l10n.speciesOpenGbif,
            icon: CupertinoIcons.arrow_up_right_square,
            style: FloraButtonStyle.secondary,
            expand: true,
            onPressed: () => launchUrl(
              Uri.https('www.gbif.org', '/species/search', {'q': scientificName}),
              mode: LaunchMode.externalApplication,
            ),
          ),
        ],
      ),
    );
  }
}

/// Une question : son rang, son titre, une ligne pour la situer, et ses
/// réponses en tuiles. Le geste facultatif (« Peu importe ») reste au bas de
/// l'écran, comme dans le flow de création.
class _QuestionStep extends StatelessWidget {
  const _QuestionStep({required this.number, required this.title, required this.subtitle, required this.answers, this.footer});

  final int number;
  final String title;
  final String subtitle;
  final List<Widget> answers;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final side = Space.page + readableInset(context);
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: floraScrollPhysics,
            padding: EdgeInsets.fromLTRB(side, Space.lg, side, Space.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.finderQuestionOf(number, _PlantFinderScreenState._questions), style: context.text.caption.copyWith(color: c.sage, fontWeight: FontWeight.w700)),
                const SizedBox(height: Space.xs),
                Text(title, style: context.text.title1),
                const SizedBox(height: Space.xs),
                Text(subtitle, style: context.text.callout),
                const SizedBox(height: Space.xl),
                for (final (i, answer) in answers.indexed) ...[
                  if (i > 0) const SizedBox(height: Space.sm),
                  answer,
                ],
              ],
            ),
          ),
        ),
        if (footer != null)
          Padding(
            padding: EdgeInsets.fromLTRB(side, Space.md, side, Space.md),
            child: footer,
          ),
      ],
    );
  }
}

/// Une réponse possible : une tuile d'argile avec son emoji, son libellé et
/// une ligne qui dit ce qu'il recouvre. Choisie, elle passe au pastel et
/// prend sa coche.
class _AnswerTile extends StatelessWidget {
  const _AnswerTile({required this.emoji, required this.label, required this.hint, required this.selected, required this.variant, required this.onTap});

  final String emoji;
  final String label;
  final String hint;
  final bool selected;
  final int variant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return MergeSemantics(
      child: Semantics(
        selected: selected,
        child: Pressable(
          onTap: onTap,
          scale: 0.98,
          child: ClayBox(
            color: selected ? c.sageSoft : c.surface,
            shape: const ClayShape.rounded(Radii.large),
            padding: const EdgeInsets.all(Space.md),
            child: Row(
              children: [
                EmojiTile(emoji: emoji, size: 48, variant: variant, background: selected ? c.surface : c.surfaceMuted),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: context.text.body.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(hint, style: context.text.caption),
                    ],
                  ),
                ),
                const SizedBox(width: Space.sm),
                AnimatedOpacity(
                  duration: Motion.of(context, Motion.micro),
                  opacity: selected ? 1 : 0,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(color: c.sage, shape: BoxShape.circle),
                    child: Icon(CupertinoIcons.checkmark_alt, size: 16, color: c.onSage),
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

/// Une réponse rappelée sur la page des propositions ; la toucher ramène à
/// sa question.
class _AnswerChip extends StatelessWidget {
  const _AnswerChip({required this.emoji, required this.label, required this.onTap});

  final String emoji;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: onTap,
      scale: 0.95,
      semanticLabel: label,
      semanticHint: context.l10n.finderChangeAnswer,
      child: Container(
        padding: const EdgeInsets.fromLTRB(Space.sm, Space.xs, Space.xs, Space.xs),
        decoration: BoxDecoration(color: c.surface, borderRadius: Radii.fullAll, border: Border.all(color: c.line)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 15)),
            const SizedBox(width: 6),
            Flexible(child: Text(label, style: context.text.callout.copyWith(color: c.ink, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: Space.xxs),
            Icon(CupertinoIcons.pencil, size: 14, color: c.inkTertiary),
          ],
        ),
      ),
    );
  }
}
