import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/l10n/care_labels.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/care/care_guide.dart';
import '../../../domain/care/care_profile.dart';
import '../../../domain/care/grow_light.dart';
import '../../../domain/models/models.dart';
import '../../../domain/problems/plant_problem.dart';
import '../../home_climate/presentation/home_climate_widgets.dart';
import '../../plants/application/plant_providers.dart';
import '../../problems/presentation/problem_kind_icon.dart';

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
          child: CareGuideBody(care: care, plantName: plant?.name, speciesName: plant?.speciesName, location: location, plantLight: plant?.light),
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
  const CareGuideBody({super.key, required this.care, this.plantName, this.speciesName, this.location, this.header, this.plantLight});

  final ResolvedCare care;
  final String? plantName;

  /// Nom scientifique, quand il est connu : c'est par lui que la base des
  /// problèmes retrouve ce qui touche cette plante.
  final String? speciesName;
  final Location? location;
  final Widget? header;

  /// Lumière renseignée sur la plante elle-même ; elle prime sur celle de
  /// l'emplacement.
  final LightNeed? plantLight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final p = care.profile;
    final now = DateTime.now();
    final south = ref.watch(southernHemisphereProvider);
    final actualLight = plantLight ?? _lightOf(location);
    final currentDays = p.wateringDaysFor(now.month, south: south, actualLight: actualLight);
    final tips = [for (final key in p.tipKeys) l10n.careTip(key)].whereType<String>().toList();
    final lamp = GrowLight.forNeed(p.light);
    final humidity = p.humidityRange;
    // Une annuelle ne se rempote pas : son rapport au pot n'a rien à dire.
    final potBadge = p.repotEveryMonths == null ? null : l10n.potBadge(p.pot);

    // Chaque volet du soin a sa carte et sa teinte : l'arrosage en bleu,
    // la lumière en ocre, l'humidité en rose, l'engrais en sauge, le
    // rempotage en terre cuite. Ce qui ne se pratique pas — température,
    // difficulté, toxicité — reste une liste, à la suite.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ?header,

        // Arrosage : la question qu'on se pose en premier, et le seul chiffre
        // de la fiche qui change avec la saison.
        _AspectCard(
          emoji: '💧',
          variant: 0,
          tint: c.waterSoft,
          title: l10n.careWatering,
          value: l10n.careWateringNow(currentDays),
          valueColor: c.water,
          prominent: true,
          detail: l10n.careWateringSeasons(p.wateringSummerDays, p.wateringWinterDays),
          badge: p.dormantInWinter ? ('❄️', l10n.careBadgeDormant) : null,
        ),
        const SizedBox(height: Space.md),

        // La lumière porte la lampe qui la remplace : sans fenêtre, c'est le
        // seul volet de la fiche qui s'achète.
        _AspectCard(
          emoji: '☀️',
          variant: 1,
          tint: c.sunSoft,
          title: l10n.careLight,
          value: l10n.lightName(p.light),
          detail: l10n.careLightLamp(lamp.ppfdMin, lamp.ppfdMax, lamp.hours),
          badge: p.outdoorFriendly ? ('🌤️', l10n.careBadgeOutdoor) : null,
          notes: [l10n.careLightLampDli(lamp.dliMin, lamp.dliMax)],
        ),
        const SizedBox(height: Space.md),

        // L'humidité en pourcentage : un salon se juge au mot, une serre se
        // règle au chiffre.
        _AspectCard(
          emoji: '💨',
          variant: 2,
          tint: c.roseSoft,
          title: l10n.careHumidity,
          value: l10n.humidityName(p.humidity),
          detail: l10n.careHumidityRange(humidity.$1, humidity.$2),
          badge: p.mistLeaves ? ('💦', l10n.careBadgeMist) : null,
          notes: [if (p.humidity == HumidityNeed.high) l10n.careHumidityGreenhouse],
        ),
        const SizedBox(height: Space.md),

        // La pièce, mesurée : elle répond à la lumière et à l'air d'au-dessus.
        HomeClimateFitCard(profile: p),

        _AspectCard(
          emoji: '🧪',
          variant: 3,
          tint: c.sageSoft,
          title: l10n.careFertilizing,
          value: p.fertilizingDays == null ? l10n.careNoFertilizer : l10n.careEveryDays(p.fertilizingDays!),
          detail: p.fertilizingDays == null ? null : l10n.fertilizeWindowLabel(p.fertilizingWindow.forHemisphere(south: south), context.localeTag),
        ),
        const SizedBox(height: Space.md),

        // Le substrat se lit avec le rempotage : c'est le jour où il sert. Le
        // rapport au pot aussi : il dit si la racine qui sort par le fond est
        // un signal ou l'état normal de l'espèce.
        _AspectCard(
          emoji: '🪴',
          variant: 0,
          tint: c.terracottaSoft,
          title: l10n.careRepotting,
          value: l10n.repotLabel(p.repotEveryMonths),
          detail: '${l10n.careSoil} · ${l10n.soilName(p.soil)}',
          badge: potBadge == null ? null : ('🫙', potBadge),
          notes: [if (p.repotEveryMonths != null) l10n.potNote(p)],
        ),
        const SizedBox(height: Space.md),

        // Floraison et repos ne concernent pas toutes les plantes : leurs
        // cartes paraissent quand l'espèce les a, et restent crème plutôt que
        // de prendre une sixième teinte aux cinq volets qui se pratiquent.
        if (p.bloom case final bloom?) ...[
          _AspectCard(
            emoji: '🌸',
            variant: 1,
            title: l10n.careBloom,
            value: l10n.monthRangeLabel(bloom.window.forHemisphere(south: south), context.localeTag),
            badge: bloom.indoors ? null : ('🪟', l10n.careBloomOutdoors),
            notes: [for (final key in bloom.triggerKeys) ?l10n.bloomTrigger(key)],
          ),
          const SizedBox(height: Space.md),
        ],

        if (p.dormancy case final rest?) ...[
          _AspectCard(
            emoji: '💤',
            variant: 2,
            title: l10n.careRest,
            value: l10n.monthRangeLabel(rest.window.forHemisphere(south: south), context.localeTag),
            detail: l10n.restStorage(rest),
            notes: [l10n.careRestNote],
          ),
          const SizedBox(height: Space.md),
        ],

        FloraGroup(
          children: [
            if (p.idealTempMinC != null && p.idealTempMaxC != null)
              _row('🌡️', l10n.careTemperature, l10n.careTempIdeal(p.idealTempMinC!, p.idealTempMaxC!), subtitle: p.minTempC == null ? null : l10n.careTempMin(p.minTempC!))
            else if (p.minTempC != null)
              _row('🌡️', l10n.careTemperature, l10n.careTempMin(p.minTempC!)),
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

/// Un volet du soin : arrosage, lumière, humidité, engrais, rempotage.
///
/// Une carte par volet, teintée de la couleur du sujet, plutôt qu'une ligne
/// parmi douze : on retrouve l'arrosage à sa couleur avant d'avoir lu le mot,
/// et le détail d'un volet reste avec lui. L'anatomie est celle des cartes du
/// matin — une tuile d'emoji, un titre qui est un nom, un constat — et sur une
/// carte teintée la tuile reste crème.
class _AspectCard extends StatelessWidget {
  const _AspectCard({
    required this.emoji,
    required this.variant,
    required this.title,
    required this.value,
    this.tint,
    this.detail,
    this.valueColor,
    this.badge,
    this.notes = const [],
    this.prominent = false,
  });

  final String emoji;

  /// Gabarit de la tuile d'argile : les volets se suivent, leurs tuiles ne se
  /// ressemblent pas tout à fait.
  final int variant;

  /// Teinte du sujet. `null` pour les volets qui ne concernent pas toutes les
  /// plantes — floraison, repos — : la carte reste crème et sa tuile prend le
  /// gris de fond, sans quoi elle disparaîtrait.
  final Color? tint;

  final String title;
  final String value;
  final String? detail;

  /// Couleur du constat, quand l'accent tient le texte (le bleu de l'eau).
  final Color? valueColor;

  /// Le repère qui ne vaut que pour ce volet : « Brumiser » sous l'humidité,
  /// « Repos hivernal » sous l'arrosage.
  final (String, String)? badge;

  /// Ce qu'il faut faire de la valeur, en une phrase par idée : la règle du
  /// rempotage, la dose de la lampe, les conditions d'une floraison.
  final List<String> notes;

  /// L'arrosage porte son chiffre plus grand : c'est la question qu'on se pose
  /// en premier.
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return MergeSemantics(
      child: FloraCard(
        color: tint,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EmojiTile(emoji: emoji, background: tint == null ? null : c.surface, variant: variant),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.text.caption.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(value, style: (prominent ? context.text.title2 : context.text.title3).copyWith(color: valueColor ?? c.ink)),
                  if (detail != null) ...[
                    const SizedBox(height: 2),
                    Text(detail!, style: context.text.callout),
                  ],
                  if (badge case final b?) ...[
                    const SizedBox(height: Space.sm),
                    FloraChip(label: b.$2, emoji: b.$1),
                  ],
                  for (final note in notes) ...[
                    const SizedBox(height: Space.xs),
                    Text(note, style: context.text.caption),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
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
    // Groupées par famille : le symbole se montre alors une fois par groupe,
    // assez grand pour se lire, et il porte le mot qui va avec.
    final familles = <ProblemKind, List<PlantProblem>>{};
    for (final p in shown) {
      (familles[p.kind] ??= []).add(p);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: Space.lg),
        Text(l10n.careKnownProblems, style: context.text.title3),
        const SizedBox(height: Space.xxs),
        // La base le dit elle-même : les hôtes cités sont des exemples, et un
        // genre ne rend pas toutes ses espèces sensibles.
        Text(l10n.careKnownProblemsNote, style: context.text.caption),
        for (final entry in familles.entries) ...[
          const SizedBox(height: Space.md),
          Row(
            children: [
              ProblemKindIcon(kind: entry.key),
              const SizedBox(width: Space.sm),
              Text(l10n.problemKindPlural(entry.key), style: context.text.callout.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: Space.xs),
          FloraGroup(
            children: [
              for (final p in entry.value)
                FloraListRow(title: p.nameIn(language), dense: true, chevron: false, titleMaxLines: 2),
            ],
          ),
        ],
        if (shown.length < found.length) ...[
          const SizedBox(height: Space.sm),
          FloraButton(
            label: l10n.seeAll,
            style: FloraButtonStyle.ghost,
            size: FloraButtonSize.small,
            onPressed: () => setState(() => _all = true),
          ),
        ],
      ],
    );
  }

}
