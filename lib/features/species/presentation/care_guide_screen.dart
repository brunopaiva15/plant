import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/l10n/care_labels.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/care/care_guide.dart';
import '../../../domain/care/care_profile.dart';
import '../../../domain/models/models.dart';
import '../../../domain/problems/plant_problem.dart';
import '../../plants/application/plant_providers.dart';

/// Fiche d'entretien d'une plante : quand l'arroser, quelle lumière lui
/// donner, quel substrat, quand rempoter, ce qu'il faut surveiller.
///
/// Les repères viennent du catalogue intégré, rattachés à l'espèce, au genre
/// ou à la famille ; la provenance est affichée pour rester honnête.
class CareGuideScreen extends ConsumerWidget {
  const CareGuideScreen({super.key, required this.plantId});

  final String plantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final summary = ref.watch(plantSummaryProvider(plantId)).value;
    final plant = summary?.plant;
    final location = plant?.locationId == null ? null : (ref.watch(locationsProvider).value ?? const <Location>[]).where((l) => l.id == plant!.locationId).firstOrNull;
    final family = speciesFamilyLookup(ref)(plant?.speciesName);
    final care = _completed(context, ref, ref.watch(careGuideProvider).resolve(plant?.speciesName, family: family), plant?.speciesName);
    return FloraPage(
      title: l10n.careGuide,
      // La fiche s'affiche tout de suite avec ce que le catalogue sait ; si
      // l'IA la complète, elle se repose en fondu plutôt que de changer
      // sèchement sous les yeux.
      child: AnimatedSwitcher(
        duration: Motion.of(context, Motion.standard),
        child: KeyedSubtree(
          key: ValueKey(care.match),
          child: CareGuideBody(care: care, plantName: plant?.name, speciesName: plant?.speciesName, location: location),
        ),
      ),
    );
  }

  /// La fiche, complétée par l'IA quand le catalogue n'a que des repères
  /// généraux à offrir.
  ///
  /// Une fiche de l'espèce, du genre ou de la famille a été renseignée à la
  /// main : on n'y touche pas. C'est seulement quand la fiche avoue ne rien
  /// savoir de particulier que la question part, une fois, en silence.
  ResolvedCare _completed(BuildContext context, WidgetRef ref, ResolvedCare care, String? species) {
    if (care.match != CareMatch.generic && care.match != CareMatch.category) return care;
    final name = species?.trim() ?? '';
    if (name.isEmpty) return care;
    final language = Localizations.localeOf(context).languageCode;
    final completion = ref.watch(careCompletionProvider((species: name, language: language))).value;
    if (completion == null) return care;
    return ResolvedCare(profile: completion.applyTo(care.profile), match: CareMatch.assisted);
  }
}

/// Corps de la fiche, réutilisable en sheet (création de plante, espèce).
class CareGuideBody extends ConsumerWidget {
  const CareGuideBody({super.key, required this.care, this.plantName, this.speciesName, this.location, this.header});

  final ResolvedCare care;
  final String? plantName;

  /// Nom scientifique, quand il est connu : c'est par lui que la base des
  /// problèmes retrouve ce qui touche cette plante.
  final String? speciesName;
  final Location? location;
  final Widget? header;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final p = care.profile;
    final now = DateTime.now();
    final south = ref.watch(southernHemisphereProvider);
    final actualLight = _lightOf(location);
    final currentDays = p.wateringDaysFor(now.month, south: south, actualLight: actualLight);

    final badges = <(String, String)>[
      if (p.mistLeaves) ('💦', l10n.careBadgeMist),
      if (p.dormantInWinter) ('❄️', l10n.careBadgeDormant),
      if (p.outdoorFriendly) ('🌤️', l10n.careBadgeOutdoor),
    ];

    final tips = [for (final key in p.tipKeys) l10n.careTip(key)].whereType<String>().toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ?header,

        // Arrosage : la question qu'on se pose en premier.
        FloraCard(
          padding: const EdgeInsets.all(Space.lg),
          color: c.waterSoft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('💧', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: Space.sm),
                  Text(l10n.careWatering, style: context.text.title3),
                ],
              ),
              const SizedBox(height: Space.sm),
              Text(l10n.careWateringNow(currentDays), style: context.text.title2.copyWith(color: c.water)),
              const SizedBox(height: 2),
              Text(l10n.careWateringSeasons(p.wateringSummerDays, p.wateringWinterDays), style: context.text.callout),
            ],
          ),
        ),
        const SizedBox(height: Space.md),

        if (badges.isNotEmpty) ...[
          Wrap(
            spacing: Space.xs,
            runSpacing: Space.xs,
            children: [for (final (emoji, label) in badges) FloraChip(label: label, emoji: emoji)],
          ),
          const SizedBox(height: Space.md),
        ],

        FloraGroup(
          children: [
            _row('☀️', l10n.careLight, l10n.lightName(p.light)),
            _row('💨', l10n.careHumidity, l10n.humidityName(p.humidity)),
            if (p.idealTempMinC != null && p.idealTempMaxC != null)
              _row('🌡️', l10n.careTemperature, l10n.careTempIdeal(p.idealTempMinC!, p.idealTempMaxC!), subtitle: p.minTempC == null ? null : l10n.careTempMin(p.minTempC!))
            else if (p.minTempC != null)
              _row('🌡️', l10n.careTemperature, l10n.careTempMin(p.minTempC!)),
            _row('🪵', l10n.careSoil, l10n.soilName(p.soil)),
            _row(
              '🧪',
              l10n.careFertilizing,
              p.fertilizingDays == null ? l10n.careNoFertilizer : l10n.careEveryDays(p.fertilizingDays!),
              subtitle: p.fertilizingDays == null ? null : l10n.fertilizeWindowLabel(p.fertilizingWindow.forHemisphere(south: south), context.localeTag),
            ),
            _row('🪴', l10n.careRepotting, l10n.repotLabel(p.repotEveryMonths)),
            _row('📈', l10n.careDifficulty, l10n.difficultyName(p.difficulty)),
            _row(
              p.toxicity == Toxicity.toxic ? '☠️' : '🐾',
              l10n.careToxicity,
              l10n.toxicityName(p.toxicity),
              subtitle: p.toxicity == Toxicity.toxic || p.toxicity == Toxicity.mild ? l10n.careToxicPets : null,
              danger: p.toxicity == Toxicity.toxic,
            ),
          ],
        ),

        if (tips.isNotEmpty) ...[
          const SizedBox(height: Space.lg),
          Text(l10n.careTips, style: context.text.title3),
          const SizedBox(height: Space.sm),
          for (final tip in tips)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.xs),
              child: FloraCard(
                padding: const EdgeInsets.all(Space.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('✳️', style: TextStyle(fontSize: 15, color: c.sage)),
                    const SizedBox(width: Space.sm),
                    Expanded(child: Text(tip, style: context.text.callout.copyWith(color: c.ink))),
                  ],
                ),
              ),
            ),
        ],

        if (p.issues.isNotEmpty) ...[
          const SizedBox(height: Space.lg),
          Text(l10n.careIssues, style: context.text.title3),
          const SizedBox(height: Space.sm),
          FloraGroup(children: [for (final i in p.issues) FloraListRow(leading: const Text('👀', style: TextStyle(fontSize: 16)), title: l10n.issueName(i), dense: true, chevron: false, titleMaxLines: 2)]),
        ],

        if (speciesName != null && speciesName!.trim().isNotEmpty) _KnownProblems(speciesName: speciesName!, issues: p.issues),

        if (p.propagation.isNotEmpty) ...[
          const SizedBox(height: Space.lg),
          Text(l10n.carePropagation, style: context.text.title3),
          const SizedBox(height: Space.sm),
          Wrap(
            spacing: Space.xs,
            runSpacing: Space.xs,
            children: [for (final m in p.propagation) FloraChip(label: l10n.propagationName(m), emoji: '🌱')],
          ),
        ],

        const SizedBox(height: Space.lg),
        Text(l10n.careMatchLabel(care), style: context.text.caption.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(
          switch (care.match) {
            CareMatch.assisted => l10n.careAssistedNote,
            CareMatch.species || CareMatch.genus => l10n.careDisclaimer,
            _ => l10n.careMatchNote,
          },
          style: context.text.caption,
        ),
      ],
    );
  }

  static Widget _row(String emoji, String title, String value, {String? subtitle, bool danger = false}) {
    return Builder(
      builder: (context) => FloraListRow(
        leading: Text(emoji, style: const TextStyle(fontSize: 18)),
        title: title,
        subtitle: subtitle,
        chevron: false,
        dense: subtitle == null,
        trailing: Text(
          value,
          style: context.text.callout.copyWith(color: danger ? context.colors.danger : context.colors.ink, fontWeight: FontWeight.w600),
          textAlign: TextAlign.end,
        ),
      ),
    );
  }

  /// Lumière réelle de l'emplacement (« faible / moyenne / forte »), quand
  /// elle est renseignée : une plante en pleine lumière boit plus vite.
  static LightNeed? _lightOf(Location? location) => lightNeedFromCode(location?.light);
}

/// Ce que la base locale connaît de cette plante en particulier.
///
/// Elle sert déjà de vocabulaire au diagnostic ; elle a autant sa place ici,
/// à froid, quand on lit la fiche sans avoir de problème. Les troubles
/// universels en sont retirés — « manque d'eau » vaut pour tout le monde et
/// n'apprend rien sur l'espèce —, tout comme ce que « À surveiller » vient de
/// dire juste au-dessus.
class _KnownProblems extends ConsumerStatefulWidget {
  const _KnownProblems({required this.speciesName, required this.issues});

  final String speciesName;

  /// Les soucis déjà listés par la fiche, pour ne pas les redire.
  final List<CommonIssue> issues;

  @override
  ConsumerState<_KnownProblems> createState() => _KnownProblemsState();
}

class _KnownProblemsState extends ConsumerState<_KnownProblems> {
  /// Au-delà, la liste se replie. Une tomate en accumule une trentaine, et
  /// une fiche n'est pas un catalogue de malheurs.
  static const int preview = 6;

  bool _all = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final catalog = ref.watch(problemCatalogProvider).value;
    if (catalog == null) return const SizedBox.shrink();
    final found = catalog.specificTo(
      species: widget.speciesName,
      family: speciesFamilyLookup(ref)(widget.speciesName),
      covered: widget.issues,
    );
    if (found.isEmpty) return const SizedBox.shrink();
    final shown = _all ? found : found.take(preview).toList();
    final language = Localizations.localeOf(context).languageCode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: Space.lg),
        Text(l10n.careKnownProblems, style: context.text.title3),
        const SizedBox(height: Space.xxs),
        // La base le dit elle-même : les hôtes cités sont des exemples, et un
        // genre ne rend pas toutes ses espèces sensibles.
        Text(l10n.careKnownProblemsNote, style: context.text.caption),
        const SizedBox(height: Space.sm),
        FloraGroup(
          children: [
            for (final p in shown)
              FloraListRow(
                leading: Text(_emoji(p.kind), style: const TextStyle(fontSize: 16)),
                title: p.nameIn(language),
                dense: true,
                chevron: false,
                titleMaxLines: 2,
              ),
            if (shown.length < found.length)
              FloraListRow(
                leading: const Text('⋯', style: TextStyle(fontSize: 16)),
                title: l10n.seeAll,
                dense: true,
                onTap: () => setState(() => _all = true),
              ),
          ],
        ),
      ],
    );
  }

  static String _emoji(ProblemKind kind) => switch (kind) {
        ProblemKind.disorder => '🌦️',
        ProblemKind.pest => '🐛',
        ProblemKind.disease => '🦠',
        ProblemKind.condition => '🌫️',
      };
}
