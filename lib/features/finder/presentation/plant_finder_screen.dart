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

/// « Trouver une plante » : quatre questions, puis des espèces du catalogue
/// intégré qui y répondent, chacune avec sa fiche d'entretien.
///
/// Le tri se fait sur les fiches déjà embarquées : la réponse est immédiate et
/// hors ligne. L'IA n'intervient qu'ensuite, sur demande, quand le catalogue
/// n'a rien de convaincant à proposer.
class PlantFinderScreen extends ConsumerStatefulWidget {
  const PlantFinderScreen({super.key, this.picking = false});

  /// Ouvert depuis le sélecteur d'espèce : la proposition retenue lui est
  /// rendue, au lieu de lancer la création d'une plante.
  final bool picking;

  @override
  ConsumerState<PlantFinderScreen> createState() => _PlantFinderScreenState();
}

class _PlantFinderScreenState extends ConsumerState<PlantFinderScreen> {
  /// La page qui dit de quoi il s'agit, avant les questions.
  static const _intro = 0;

  /// Rang de la première question, et nombre de questions.
  static const _premiere = 1;
  static const _questions = 4;

  /// L'étape au champ libre, la seule à ouvrir le clavier.
  static const _libre = _premiere + 3;

  /// Les propositions, après la dernière question.
  static const _resultats = _premiere + _questions;

  final _page = PageController();
  final _note = TextEditingController();
  int _step = _intro;
  FinderCriteria _criteria = const FinderCriteria();
  List<FinderMatch> _matches = const [];
  List<AdvisorSuggestion> _suggestions = const [];
  bool _asking = false;

  @override
  void dispose() {
    _page.dispose();
    _note.dispose();
    super.dispose();
  }

  void _go(int step) {
    Haptics.selection();
    // Le clavier du champ libre ne doit pas suivre sur les autres étapes.
    if (step != _libre) FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _step = step);
    _page.animateToPage(step, duration: Motion.of(context, Motion.emphasis), curve: Motion.emphasized);
  }

  /// Une réponse choisie enchaîne sur la question suivante : c'est un
  /// questionnaire, pas un formulaire.
  void _answer(FinderCriteria next) {
    setState(() => _criteria = next);
    _go(_step + 1);
  }

  void _search() {
    final criteria = _criteria.copyWith(note: _note.text);
    setState(() {
      _criteria = criteria;
      _matches = ref.read(plantFinderProvider).search(criteria);
      _suggestions = const [];
    });
    _go(_resultats);
  }

  void _restart() {
    setState(() {
      _criteria = const FinderCriteria();
      _matches = const [];
      _suggestions = const [];
      _note.clear();
    });
    // On repart à la première question : l'explication a été lue.
    _go(_premiere);
  }

  Future<void> _askAdvisor() async {
    if (_asking) return;
    final l10n = context.l10n;
    setState(() => _asking = true);
    try {
      final results = await ref.read(plantAdvisorProvider).suggest(
            criteria: _criteria,
            language: ref.read(preferencesProvider).locale?.languageCode ?? WidgetsBinding.instance.platformDispatcher.locale.languageCode,
            exclude: [for (final m in _matches) m.entry.scientificName],
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
                    icon: _step == _intro ? CupertinoIcons.xmark : CupertinoIcons.chevron_left,
                    semanticLabel: _step == _intro ? l10n.close : l10n.back,
                    onPressed: () => _step == _intro ? context.pop() : _go(_step - 1),
                  ),
                  const Spacer(),
                  if (_step >= _premiere && _step < _resultats)
                    _StepDots(count: _questions, index: _step - _premiere)
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
                children: [_introStep(), _spotStep(), _effortStep(), _safetyStep(), _kindStep(), _resultsStep()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Ce que la boussole promet, avant de commencer à demander. Sans elle,
  /// l'écran s'ouvrait sur « Où va-t-elle vivre ? » sans avoir dit de quoi
  /// il retournait.
  Widget _introStep() {
    final l10n = context.l10n;
    final c = context.colors;
    return _StepLayout(
      title: l10n.finderTitle,
      subtitle: l10n.finderIntro,
      body: Center(
        child: Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(color: c.sageSoft, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: const Text('🧭', style: TextStyle(fontSize: 44, height: 1)),
        ),
      ),
      actions: [
        FloraButton(label: l10n.continueLabel, expand: true, trailingIcon: CupertinoIcons.arrow_right, onPressed: () => _go(_premiere)),
      ],
    );
  }

  Widget _spotStep() {
    final l10n = context.l10n;
    return _StepLayout(
      title: l10n.finderStepSpot,
      subtitle: l10n.finderStepSpotHint,
      body: FloraGroup(
        children: [
          for (final spot in FinderSpot.values)
            _ChoiceRow(
              emoji: l10n.finderSpotEmoji(spot),
              label: l10n.finderSpotName(spot),
              selected: _criteria.spot == spot,
              onTap: () => _answer(_criteria.copyWith(spot: () => spot)),
            ),
        ],
      ),
      actions: [
        FloraButton(label: l10n.finderAnyAnswer, style: FloraButtonStyle.ghost, expand: true, onPressed: () => _answer(_criteria.copyWith(spot: () => null))),
      ],
    );
  }

  Widget _effortStep() {
    final l10n = context.l10n;
    return _StepLayout(
      title: l10n.finderStepEffort,
      subtitle: l10n.finderStepEffortHint,
      body: FloraGroup(
        children: [
          for (final effort in FinderEffort.values)
            _ChoiceRow(
              emoji: l10n.finderEffortEmoji(effort),
              label: l10n.finderEffortName(effort),
              selected: _criteria.effort == effort,
              onTap: () => _answer(_criteria.copyWith(effort: () => effort)),
            ),
        ],
      ),
      actions: [
        FloraButton(label: l10n.finderAnyAnswer, style: FloraButtonStyle.ghost, expand: true, onPressed: () => _answer(_criteria.copyWith(effort: () => null))),
      ],
    );
  }

  Widget _safetyStep() {
    final l10n = context.l10n;
    return _StepLayout(
      title: l10n.finderStepSafety,
      subtitle: l10n.finderStepSafetyHint,
      body: FloraGroup(
        children: [
          _ChoiceRow(
            emoji: '🐾',
            label: l10n.finderSafetyYes,
            selected: _criteria.safeOnly,
            onTap: () => _answer(_criteria.copyWith(safeOnly: true)),
          ),
          _ChoiceRow(
            emoji: '🙅',
            label: l10n.finderSafetyNo,
            selected: !_criteria.safeOnly,
            onTap: () => _answer(_criteria.copyWith(safeOnly: false)),
          ),
        ],
      ),
      actions: const [],
    );
  }

  Widget _kindStep() {
    final l10n = context.l10n;
    return _StepLayout(
      title: l10n.finderStepKind,
      subtitle: l10n.finderStepKindHint,
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: Space.xs,
            runSpacing: Space.xs,
            children: [
              for (final category in SpeciesCategory.values)
                FloraChip(
                  label: l10n.speciesCategoryName(category),
                  emoji: category.emoji,
                  selected: _criteria.categories.contains(category),
                  onTap: () => setState(() {
                    final next = {..._criteria.categories};
                    if (!next.remove(category)) next.add(category);
                    _criteria = _criteria.copyWith(categories: next);
                  }),
                ),
            ],
          ),
          const SizedBox(height: Space.xl),
          Text(l10n.finderNote, style: context.text.callout.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: Space.xs),
          FloraTextField(controller: _note, hint: l10n.finderNoteHint, minLines: 2, maxLines: 4),
          const SizedBox(height: Space.xs),
          Text(l10n.finderNoteFooter, style: context.text.caption),
        ],
      ),
      actions: [
        FloraButton(label: l10n.finderSubmit, icon: CupertinoIcons.sparkles, expand: true, onPressed: _search),
      ],
    );
  }

  Widget _resultsStep() {
    final l10n = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;
    final advisor = ref.watch(plantAdvisorProvider);
    return ListView(
      physics: floraScrollPhysics,
      padding: const EdgeInsets.fromLTRB(Space.page, Space.lg, Space.page, Space.huge),
      children: [
        Text(l10n.finderResults, style: context.text.title1),
        const SizedBox(height: Space.xs),
        Text(_matches.isEmpty ? l10n.finderEmptySubtitle : l10n.finderResultsHint, style: context.text.callout),
        const SizedBox(height: Space.lg),
        if (_matches.isEmpty)
          EmptyState(emoji: '🌱', title: l10n.finderEmptyTitle, compact: true)
        else
          FloraGroup(
            children: [
              for (final match in _matches)
                FloraListRow(
                  leading: Text(match.entry.category.emoji, style: const TextStyle(fontSize: 20)),
                  title: match.entry.commonName(lang),
                  subtitle: [
                    match.entry.scientificName,
                    ...match.reasons.map(l10n.finderReasonName),
                  ].join(' · '),
                  titleMaxLines: 2,
                  onTap: () => _open(scientificName: match.entry.scientificName, commonName: match.entry.commonName(lang), family: match.entry.family),
                ),
            ],
          ),
        if (_suggestions.isNotEmpty) ...[
          SectionHeader(title: l10n.finderAiSection, padding: const EdgeInsets.fromLTRB(0, Space.xl, 0, Space.xs)),
          Text(l10n.finderAiHint, style: context.text.caption),
          const SizedBox(height: Space.sm),
          FloraGroup(
            children: [
              for (final suggestion in _suggestions)
                FloraListRow(
                  leading: const Text('✨', style: TextStyle(fontSize: 20)),
                  title: suggestion.commonName ?? suggestion.scientificName,
                  subtitle: suggestion.reason.isEmpty ? suggestion.scientificName : '${suggestion.scientificName} · ${suggestion.reason}',
                  titleMaxLines: 2,
                  onTap: () => _open(scientificName: suggestion.scientificName, commonName: suggestion.commonName),
                ),
            ],
          ),
        ],
        const SizedBox(height: Space.lg),
        if (advisor.isConfigured)
          FloraButton(
            label: l10n.finderAskAi,
            icon: CupertinoIcons.sparkles,
            style: FloraButtonStyle.tonal,
            expand: true,
            loading: _asking,
            onPressed: _askAdvisor,
          ),
        const SizedBox(height: Space.xs),
        FloraButton(label: l10n.finderRestart, style: FloraButtonStyle.ghost, expand: true, onPressed: _restart),
      ],
    );
  }

  Future<void> _open({required String scientificName, String? commonName, String? family}) async {
    final l10n = context.l10n;
    final chosen = await showFinderSpeciesSheet(
      context,
      scientificName: scientificName,
      commonName: commonName,
      family: family,
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
}) =>
    showFloraSheet<bool>(
      context,
      scrollable: true,
      builder: (_) => _SpeciesSheet(scientificName: scientificName, actionLabel: actionLabel, actionIcon: actionIcon, commonName: commonName, family: family),
    );

class _SpeciesSheet extends ConsumerWidget {
  const _SpeciesSheet({required this.scientificName, required this.actionLabel, required this.actionIcon, this.commonName, this.family});

  final String scientificName;
  final String actionLabel;
  final IconData actionIcon;
  final String? commonName;
  final String? family;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final care = ref.watch(careGuideProvider).resolve(scientificName, family: family ?? speciesFamilyLookup(ref)(scientificName));
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(title: commonName ?? scientificName),
          Padding(
            padding: const EdgeInsets.only(bottom: Space.md),
            child: Text(scientificName, style: context.text.caption),
          ),
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

/// Une réponse possible : emoji, libellé, et la coche quand elle est choisie.
class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({required this.emoji, required this.label, required this.selected, required this.onTap});

  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return FloraListRow(
      leading: Text(emoji, style: const TextStyle(fontSize: 20)),
      title: label,
      titleMaxLines: 2,
      trailing: selected ? Icon(CupertinoIcons.checkmark_alt, size: 18, color: c.sage) : null,
      chevron: !selected,
      onTap: onTap,
    );
  }
}

/// Même mise en page que le flow de création : titre, corps, actions en bas.
class _StepLayout extends StatelessWidget {
  const _StepLayout({required this.title, required this.body, required this.actions, this.subtitle, this.scrollable = false});

  final String title;
  final String? subtitle;
  final Widget body;
  final List<Widget> actions;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: Space.lg),
        Text(title, style: context.text.title1),
        if (subtitle != null) ...[const SizedBox(height: Space.xs), Text(subtitle!, style: context.text.callout)],
        const SizedBox(height: Space.xl),
      ],
    );
    final content = scrollable
        ? SingleChildScrollView(
            physics: floraScrollPhysics,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: Space.page),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [header, body]),
          )
        : SingleChildScrollView(
            physics: floraScrollPhysics,
            padding: const EdgeInsets.symmetric(horizontal: Space.page),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [header, body]),
          );
    return Column(
      children: [
        Expanded(child: content),
        if (actions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.page, Space.md, Space.page, Space.md),
            child: Column(mainAxisSize: MainAxisSize.min, children: actions),
          ),
      ],
    );
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: Motion.of(context, Motion.standard),
            curve: Motion.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == index ? 20 : 6,
            height: 6,
            decoration: BoxDecoration(color: i == index ? c.sage : c.line, borderRadius: Radii.fullAll),
          ),
      ],
    );
  }
}
