import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/l10n/care_labels.dart';
import '../../../core/l10n/l10n.dart';
import '../../../data/species/species_catalog.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/care/care_guide.dart';
import '../../../domain/care/care_profile.dart';
import '../../../domain/care/grow_light.dart';
import '../../../domain/care/leaf_signs.dart';
import '../../../domain/care/toxicity.dart';
import '../../../domain/models/models.dart';
import '../../../domain/problems/plant_problem.dart';
import '../../../domain/species/species_info.dart';
import '../../community/presentation/community_tips_section.dart';
import '../../home_climate/presentation/home_climate_widgets.dart';
import '../../plants/application/plant_providers.dart';
import '../../problems/presentation/problem_kind_icon.dart';
import '../../room_scan/presentation/room_fit_entry.dart';
import 'care_environment_hero.dart';
import 'care_guide_copy.dart';
import 'water_types_sheet.dart';

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
    final location = plant?.locationId == null
        ? null
        : (ref.watch(locationsProvider).value ?? const <Location>[])
            .where((l) => l.id == plant!.locationId)
            .firstOrNull;
    final family = speciesFamilyLookup(ref)(plant?.speciesName);
    final care = _completed(
      context,
      ref,
      ref.watch(careGuideProvider).resolve(plant?.speciesName, family: family),
      plant?.speciesName,
    );
    return FloraPage(
      title: l10n.careGuide,
      // La fiche s'affiche tout de suite avec ce que le catalogue sait ; si
      // l'IA la complète, elle se repose en fondu plutôt que de changer
      // sèchement sous les yeux.
      bleed: true,
      child: AnimatedSwitcher(
        duration: Motion.of(context, Motion.standard),
        child: KeyedSubtree(
          key: ValueKey(care.match),
          child: CareGuideBody(
            care: care,
            plantId: plant?.id,
            plantName: plant?.name,
            speciesName: plant?.speciesName,
            family: family,
            location: location,
            plantLight: plant?.light,
            category: plant?.speciesName == null ? null : SpeciesCatalog.findAccepted(plant!.speciesName!)?.category,
          ),
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
    return ResolvedCare(profile: completion.applyTo(care.profile), match: CareMatch.assisted, toxicity: care.toxicity);
  }
}

/// Corps de la fiche, réutilisable en sheet (création de plante, espèce).
class CareGuideBody extends ConsumerWidget {
  const CareGuideBody({
    super.key,
    required this.care,
    this.plantId,
    this.plantName,
    this.speciesName,
    this.family,
    this.location,
    this.header,
    this.plantLight,
    this.category,
    this.showEnvironmentHero = true,
    this.paper = true,
  });

  final ResolvedCare care;

  /// La plante du jardin dont c'est la fiche, quand c'en est une : c'est
  /// elle que « Où la poser » peut poser sur le plan.
  final String? plantId;
  final String? plantName;

  /// Nom scientifique, quand il est connu : c'est par lui que la base des
  /// problèmes retrouve ce qui touche cette plante.
  final String? speciesName;

  /// Famille botanique, quand elle est connue : c'est par elle que la scène
  /// d'environnement retrouve une silhouette de conifère ou de palmier.
  final String? family;

  final Location? location;
  final Widget? header;

  /// Lumière renseignée sur la plante elle-même ; elle prime sur celle de
  /// l'emplacement.
  final LightNeed? plantLight;

  /// La catégorie d'usage de l'espèce, quand le catalogue la connaît : elle
  /// départage la scène d'environnement entre la pièce et dehors.
  final SpeciesCategory? category;

  /// Le diorama « emplacement idéal » en tête de fiche. Les contextes qui
  /// intègrent la fiche autrement peuvent s'en passer.
  final bool showEnvironmentHero;

  /// La fiche comme objet : une feuille posée sur le fond de la page. Le
  /// dénicheur, qui l'affiche déjà dans une sheet, s'en passe — une feuille
  /// sur une feuille ne se lit pas.
  final bool paper;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final p = care.profile;
    final toxicity = care.toxicity;
    final now = DateTime.now();
    final south = ref.watch(southernHemisphereProvider);
    final actualLight = plantLight ?? _lightOf(location);
    final currentDays = p.wateringDaysFor(now.month, south: south, actualLight: actualLight);
    final tips = [for (final key in p.tipKeys) l10n.careTip(key)].whereType<String>().toList();
    final hasTemperature = (p.idealTempMinC != null && p.idealTempMaxC != null) || p.damageBelowC != null;
    final lamp = GrowLight.forNeed(p.light);
    final humidity = p.humidityRange;
    // Une annuelle ne se rempote pas : son rapport au pot n'a rien à dire.
    final potBadge = p.repotEveryMonths == null ? null : l10n.potBadge(p.pot);

    // La fiche suit maintenant le chemin réel d'entretien : d'abord où placer
    // la plante et le climat qu'elle demande, ensuite ce qu'on fait au pot,
    // puis les conditions particulières et enfin les informations de sécurité.
    // Chaque volet garde la teinte de son sujet : l'arrosage et l'eau en bleu,
    // la lumière en ocre, l'humidité en rose, l'engrais en sauge, le pot en
    // terre cuite.
    final fiche = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ?header,

        // Le résumé spatial d'abord : où la plante serait bien, avant le
        // détail des besoins. La scène montre l'idéal de la fiche, jamais
        // l'état réel de la pièce — c'est HomeClimateFitCard qui compare.
        if (showEnvironmentHero)
          CareEnvironmentHero(profile: p, speciesName: speciesName, family: family, category: category),
        // Puis le réel, quand une pièce est relevée : où, chez soi, cette
        // fiche serait le mieux. La scène ne change pas pour autant.
        if (showEnvironmentHero) RoomFitEntry(care: care, plantId: plantId, plantName: plantName),

        SectionHeader(title: l10n.needsSection, padding: const EdgeInsets.only(bottom: Space.sm)),

        // L'emplacement vient en premier : sans la bonne lumière, les autres
        // fréquences de la fiche deviennent vite fausses. Et faute de fenêtre,
        // c'est le seul besoin de la fiche qui s'achète : la lampe qui le tient
        // se dit ici, en intensité reçue puis en dose du jour.
        _AspectCard(
          emoji: '☀️',
          variant: 1,
          tint: c.sunSoft,
          title: l10n.careLight,
          value: l10n.lightName(p.light),
          details: [
            ?l10n.lightFloorNote(p),
            l10n.careLightLamp(lamp.ppfdMin, lamp.ppfdMax, lamp.hours),
          ],
          badge: p.outdoorFriendly ? ('🌤️', l10n.guideBadgeOutdoor) : null,
          notes: [l10n.careLightLampDli(lamp.dliMin, lamp.dliMax)],
        ),
        const SizedBox(height: Space.md),

        // L'arrosage reste le chiffre le plus visible, mais arrive après la
        // lumière qui influence justement son intervalle.
        _AspectCard(
          emoji: '💧',
          variant: 0,
          tint: c.waterSoft,
          title: l10n.careWatering,
          // La règle de séchage d'abord : c'est elle qui dit quand arroser.
          // L'intervalle en jours suit, comme une estimation.
          value: l10n.dryDownName(p.dryDownRule),
          valueColor: c.water,
          details: [l10n.careWateringNow(currentDays), l10n.guideWateringSeasons(p.wateringSummerDays, p.wateringWinterDays)],
          badge: p.dormantInWinter ? ('❄️', l10n.guideBadgeDormant) : null,
        ),
        const SizedBox(height: Space.md),

        // Ce qu'on verse, juste après le jour où on le verse : le calcaire du
        // robinet passe inaperçu sur une plante et abîme la suivante. La carte
        // donne l'eau qui convient, et s'ouvre sur les sept eaux jugées une à
        // une.
        _AspectCard(
          emoji: '🚰',
          variant: 2,
          tint: c.waterSoft,
          title: l10n.careWater,
          value: l10n.waterToleranceName(p.water),
          details: [l10n.waterToleranceNote(p.water)],
          onTap: () => showWaterTypesSheet(context, tolerance: p.water, fluorideSensitive: p.fluorideSensitive),
        ),
        const SizedBox(height: Space.md),

        // La température est un besoin de culture, pas une information
        // secondaire à ranger avec la difficulté ou la toxicité.
        if (hasTemperature) ...[
          FloraGroup(
            children: [
              if (p.idealTempMinC != null && p.idealTempMaxC != null)
                _row(
                  '🌡️',
                  l10n.careTemperature,
                  l10n.careTempIdeal(p.idealTempMinC!, p.idealTempMaxC!),
                  subtitle: p.damageBelowC == null ? null : l10n.careTempMin(p.damageBelowC!),
                )
              else if (p.damageBelowC != null)
                _row('🌡️', l10n.careTemperature, l10n.careTempMin(p.damageBelowC!)),
            ],
          ),
          const SizedBox(height: Space.md),
        ],

        // Le pourcentage est celui de l'espèce, pas celui de sa catégorie :
        // entre deux plantes « qui aiment l'air humide », l'une tient à 50 %
        // et l'autre en veut 85. Un salon se juge au mot, une serre au chiffre.
        _AspectCard(
          emoji: '💨',
          variant: 2,
          tint: c.roseSoft,
          title: l10n.careHumidity,
          value: l10n.humidityName(p.humidity),
          details: [
            l10n.careHumidityRange(humidity.$1, humidity.$2),
            l10n.humidityDetail(p.humidity),
            ?l10n.humidityMethodNote(p.humidityMethods),
          ],
        ),
        const SizedBox(height: Space.md),

        // Après les besoins théoriques, cette carte dit si la pièce réelle
        // correspond à la plante lorsqu'un capteur est disponible.
        HomeClimateFitCard(profile: p),

        const SizedBox(height: Space.lg),
        SectionHeader(title: l10n.careHowTo, padding: const EdgeInsets.only(bottom: Space.sm)),

        // Le pot se lit dans l'ordre où on s'en occupe : d'abord le mélange,
        // puis ce qu'on ajoute pendant la croissance, enfin quand le changer.
        _AspectCard(
          emoji: '🪴',
          variant: 1,
          tint: c.terracottaSoft,
          title: l10n.careSoil,
          value: l10n.soilName(p.soil),
          details: [l10n.guideSoilMix(p.soil), ?l10n.guideSoilFreeLine(p)],
          // « Sans substrat » ne dit pas la même chose pour une tillandsie
          // épiphyte et un nymphéa aquatique : le milieu de vie le dit.
          badge: p.growthMedium == GrowthMedium.terrestrial ? null : ('🌿', l10n.growthMediumName(p.growthMedium)),
        ),
        const SizedBox(height: Space.md),

        _AspectCard(
          emoji: '🧪',
          variant: 3,
          tint: c.sageSoft,
          title: l10n.careFertilizing,
          value: p.fertilizingDays == null ? l10n.careNoFertilizer : l10n.careEveryDays(p.fertilizingDays!),
          details: [
            if (p.fertilizerKind case final kind?) l10n.guideFertilizerKind(kind),
            if (p.fertilizingDays != null)
              l10n.fertilizeWindowLabel(
                p.fertilizingWindow.forHemisphere(south: south),
                context.localeTag,
              ),
            ?l10n.guideCalciumNote(p.calciumNeed),
          ],
        ),
        const SizedBox(height: Space.md),

        // Le rapport au pot est ici, puisqu'il dit quand ce jour arrive : une
        // racine qui sort par le fond est un signal chez l'une, l'état normal
        // de l'autre.
        _AspectCard(
          emoji: '🏺',
          variant: 0,
          tint: c.terracottaSoft,
          title: l10n.careRepotting,
          value: l10n.repotLabel(p.repotEveryMonths),
          badge: potBadge == null ? null : ('🫙', potBadge),
          notes: [if (p.repotEveryMonths != null) l10n.potNote(p)],
        ),

        // Le repos des plantes à réserves — crocus, caladium, cyclamen — :
        // période, température et obscurité du rangement. Seule carte crème de
        // la fiche, parce qu'elle est la seule à décrire une absence : plus de
        // feuilles, plus d'eau, plus de lumière.
        if (p.dormancy case final rest?) ...[
          const SizedBox(height: Space.md),
          _AspectCard(
            emoji: '💤',
            variant: 2,
            title: l10n.careRest,
            value: l10n.monthRangeLabel(rest.window.forHemisphere(south: south), context.localeTag),
            details: [l10n.restStorage(rest)],
            notes: [l10n.careRestNote],
          ),
        ],

        // Le tuteur ferme ce qu'on fait au pot : il ne paraît que pour les
        // espèces qui en demandent un, et dit du même coup quand s'en
        // occuper — un tuteur moussu s'humidifie à chaque arrosage, une tige
        // s'attache à mesure qu'elle monte. Sa carte reste crème : les
        // teintes appartiennent aux volets du soin, une de plus les
        // brouillerait.
        if (p.support case final support?) ...[
          const SizedBox(height: Space.md),
          _AspectCard(
            emoji: '🪵',
            variant: 2,
            title: l10n.careSupport,
            value: l10n.supportName(support),
            details: [l10n.supportCare(support)],
          ),
        ],

        // La serre et la floraison sont des conditions particulières : utiles
        // quand elles concernent la plante, mais pas au milieu des besoins de
        // tous les jours.
        if (p.benefitsFromGreenhouse || p.bloom != null) ...[
          const SizedBox(height: Space.lg),
          if (p.benefitsFromGreenhouse)
            _AspectCard(
              emoji: '🏡',
              variant: 1,
              tint: c.sunSoft,
              title: l10n.careGreenhouse,
              value: l10n.guideGreenhouseTitle(p.humidity),
              details: [
                l10n.guideGreenhouseGrowth,
                if (p.humidity == HumidityNeed.low) l10n.guideGreenhouseAir,
                if (p.repotEveryMonths == null) l10n.guideGreenhouseEarly,
              ],
              // Sous serre, l'hygrométrie n'est plus un constat mais un
              // réglage : c'est ici que la plage du besoin devient une
              // consigne.
              notes: [l10n.careGreenhouseHold],
            ),
          if (p.benefitsFromGreenhouse && p.bloom != null) const SizedBox(height: Space.md),
          // La saison en constat, les conditions nommées d'un trait, puis
          // chacune expliquée dessous, dans le même ordre.
          if (p.bloom case final bloom?)
            _AspectCard(
              emoji: '🌸',
              variant: 2,
              tint: c.roseSoft,
              title: l10n.careBloom,
              value: l10n.monthRangeLabel(bloom.window.forHemisphere(south: south), context.localeTag),
              details: [if (bloom.triggers.isNotEmpty) bloom.triggers.map(l10n.bloomName).join(' · ')],
              badge: bloom.indoors ? null : ('🪟', l10n.careBloomOutdoors),
              notes: [for (final t in bloom.triggers) l10n.bloomNote(t)],
            ),
        ],

        const SizedBox(height: Space.lg),
        SectionHeader(title: l10n.detailsSection, padding: const EdgeInsets.only(bottom: Space.sm)),
        FloraGroup(
          children: [
            _row('📈', l10n.careDifficulty, l10n.difficultyName(p.difficulty)),
            _row(
              toxicity.status == Toxicity.toxic ? '☠️' : '🐾',
              l10n.careToxicity,
              l10n.toxicityName(toxicity.status),
              // La provenance porte sur la ligne elle-même : « famille des
              // Araceae · non vérifié pour cette espèce » ne se lit pas comme
              // un fait de l'espèce.
              subtitle: l10n.toxicityProvenance(toxicity) ?? l10n.toxicityNote(toxicity.status),
              danger: toxicity.status == Toxicity.toxic,
            ),
          ],
        ),

        if (tips.isNotEmpty) ...[
          const SizedBox(height: Space.lg),
          SectionHeader(title: l10n.careTips, padding: const EdgeInsets.only(bottom: Space.sm)),
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

        // Ce que le catalogue sait finit ici ; ce qui suit vient de gens qui
        // gardent la même espèce. Deux sections, deux titres : un conseil
        // écrit par quelqu'un ne se donne pas pour une donnée de la fiche.
        CommunityTipsSection(speciesName: speciesName),

        _WatchList(issues: p.issues),

        _LeafSignList(profile: p),

        if (speciesName != null && speciesName!.trim().isNotEmpty)
          _KnownProblems(speciesName: speciesName!, issues: p.issues),

        if (p.propagation.isNotEmpty) ...[
          const SizedBox(height: Space.lg),
          SectionHeader(title: l10n.carePropagation, padding: const EdgeInsets.only(bottom: Space.sm)),
          Wrap(
            spacing: Space.xs,
            runSpacing: Space.xs,
            children: [for (final m in p.propagation) FloraChip(label: l10n.propagationName(m), emoji: '🌱')],
          ),
        ],

        const SizedBox(height: Space.lg),
        // La provenance se tamponne en bas de la feuille : c'est ce que la
        // fiche avoue d'elle-même, et un tampon le dit mieux qu'une ligne.
        Align(alignment: Alignment.centerLeft, child: _ProvenanceStamp(label: l10n.careMatchLabel(care))),
        // La source, quand la fiche a été revue : une estimation ne la porte
        // pas, et le lecteur le voit.
        if (l10n.careSourceNote(p) case final source?) ...[
          const SizedBox(height: 2),
          Text(source, style: context.text.caption),
        ],
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
    return paper ? PaperSheet(child: fiche) : fiche;
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
          style: context.text.callout.copyWith(
            color: danger ? context.colors.danger : context.colors.ink,
            fontWeight: FontWeight.w600,
          ),
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
///
/// Les teintes sont prises. Ce qui se pratique aussi mais n'en a pas — le
/// tuteur — garde la même anatomie sur une carte crème, plutôt que
/// d'emprunter la couleur d'un autre volet.
class _AspectCard extends StatelessWidget {
  const _AspectCard({
    required this.emoji,
    required this.variant,
    required this.title,
    required this.value,
    this.tint,
    this.details = const [],
    this.valueColor,
    this.badge,
    this.notes = const [],
    this.onTap,
  });

  final String emoji;

  /// Gabarit de la tuile d'argile : les volets se suivent, leurs tuiles ne se
  /// ressemblent pas tout à fait.
  final int variant;

  /// La teinte du volet, ou `null` pour une carte crème — le repos, le
  /// tuteur : la tuile d'emoji reprend alors son fond habituel, puisqu'il n'y
  /// a plus de teinte à laquelle se détacher.
  final Color? tint;

  final String title;
  final String value;

  /// Ce qui précise le constat, une ligne par chose : le mélange sous le
  /// substrat, la saison et le calcium sous l'engrais.
  final List<String> details;

  /// Couleur du constat, quand l'accent tient le texte (le bleu de l'eau).
  final Color? valueColor;

  /// Le repère qui ne vaut que pour ce volet : une phrase courte qui décrit
  /// un besoin particulier, jamais un ordre ou un mot isolé.
  final (String, String)? badge;

  /// Ce qu'il faut faire du constat, une phrase par idée : la règle du
  /// rempotage, la dose de la lampe, les conditions d'une floraison.
  final List<String> notes;

  /// Ce que le volet cache, quand il en cache quelque chose : la carte prend
  /// alors un chevron, et se presse comme une ligne de liste.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return MergeSemantics(
      child: FloraCard(
        color: tint,
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EmojiTile(emoji: emoji),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.text.caption.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: context.text.title3.copyWith(color: valueColor ?? c.ink),
                  ),
                  for (final detail in details) ...[
                    const SizedBox(height: 2),
                    Text(detail, style: context.text.callout),
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
            if (onTap != null) ...[
              const SizedBox(width: Space.xs),
              Icon(CupertinoIcons.chevron_right, size: 15, color: c.inkTertiary),
            ],
          ],
        ),
      ),
    );
  }
}

/// La provenance de la fiche, tamponnée au bas de la feuille.
///
/// Le catalogue dit d'où viennent les repères — l'espèce, le genre, la
/// famille, ou des repères généraux ; l'IA, quand elle a complété ; une
/// relecture, quand elle a eu lieu. C'est la seule phrase de la fiche qui
/// parle d'elle-même, alors elle porte un cachet : un cadre d'encre, un peu
/// de travers, tel qu'on le poserait à la main.
class _ProvenanceStamp extends StatelessWidget {
  const _ProvenanceStamp({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Transform.rotate(
      angle: -0.024,
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: Space.xxs),
        decoration: BoxDecoration(
          border: Border.all(color: c.inkSecondary.withValues(alpha: 0.85), width: 1.5),
          borderRadius: BorderRadius.circular(4),
        ),
        // La casse reste celle des ARB : des majuscules feraient épeler le
        // tampon aux lecteurs d'écran.
        child: Text(
          label,
          style: context.text.caption.copyWith(color: c.inkSecondary, fontWeight: FontWeight.w700, letterSpacing: 0.8),
        ),
      ),
    );
  }
}

/// « À surveiller » : ce qui arrive à cette espèce, dit en clair.
///
/// La liste est rangée dans l'ordre de la base des problèmes — ce qui vient
/// de l'eau et de la lumière, les bêtes, puis les champignons —, parce que
/// c'est l'ordre dans lequel on vérifie.
///
/// Elle ne se replie pas, à la différence de « Problèmes connus » : celle-ci
/// est écrite à la main, espèce par espèce, et la plus longue tient en dix
/// lignes. Les cacher derrière un bouton reviendrait à répondre « araignées
/// rouges » à qui ouvre la fiche d'un pothos, alors que les thrips, les
/// cochenilles et les moucherons du terreau y sont pour autant.
///
/// Chaque ligne porte l'image de son souci : la plupart désignent une entrée
/// de la base des deux cents problèmes et en reprennent l'illustration
/// d'argile, les autres le symbole de leur famille. Une cochenille se
/// reconnaît ainsi d'un écran à l'autre — ici, dans l'encyclopédie, dans un
/// diagnostic —, ce qu'une pastille identique sur toutes les lignes ne
/// donnait pas.
class _WatchList extends StatelessWidget {
  const _WatchList({required this.issues});

  final List<CommonIssue> issues;

  @override
  Widget build(BuildContext context) {
    if (issues.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;
    // Tri stable : à famille égale, l'ordre de la fiche est conservé, et
    // c'est celui dans lequel il a été écrit.
    final ordered = [...issues]..sort((a, b) => a.kind.index.compareTo(b.kind.index));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: Space.lg),
        SectionHeader(title: l10n.careIssues, padding: const EdgeInsets.only(bottom: Space.sm)),
        FloraGroup(
          children: [
            for (final i in ordered)
              FloraListRow(
                leading: CommonIssueIcon(issue: i),
                leadingWidth: 40,
                title: l10n.issueName(i),
                dense: true,
                chevron: false,
                titleMaxLines: 2,
              ),
          ],
        ),
      ],
    );
  }
}

/// « Signes sur les feuilles » : l'autre entrée de la fiche.
///
/// On arrive ici avec la plante sous les yeux — elle s'éclaircit, elle brûle,
/// elle se tache au milieu, elle ne grandit plus — et pas avec un nom de
/// champignon. Chaque signe s'ouvre sur ce qui l'explique le plus souvent,
/// un seul à la fois : la liste garde sa hauteur de liste, et ce qu'on vient
/// de lire ne s'éloigne pas de ce qu'on lit.
///
/// Les causes viennent de la fiche de l'espèce, pas d'un mémento général :
/// un cactus ne brûle pas au soleil, une plante qui aime l'air sec ne brunit
/// pas des pointes pour cela, et ces causes-là ne sont pas proposées.
class _LeafSignList extends StatefulWidget {
  const _LeafSignList({required this.profile});

  final CareProfile profile;

  @override
  State<_LeafSignList> createState() => _LeafSignListState();
}

class _LeafSignListState extends State<_LeafSignList> {
  LeafSign? _open;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final readings = LeafSigns.forProfile(widget.profile);
    if (readings.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: Space.lg),
        SectionHeader(title: l10n.careLeafSigns, padding: const EdgeInsets.only(bottom: Space.xxs)),
        Text(l10n.careLeafSignsNote, style: context.text.caption),
        const SizedBox(height: Space.sm),
        FloraGroup(
          children: [
            for (final reading in readings)
              _LeafSignRow(
                reading: reading,
                open: _open == reading.sign,
                onTap: () => setState(() => _open = _open == reading.sign ? null : reading.sign),
              ),
          ],
        ),
      ],
    );
  }
}

/// Un signe, et ses causes quand il est ouvert.
class _LeafSignRow extends StatelessWidget {
  const _LeafSignRow({required this.reading, required this.open, required this.onTap});

  final LeafReading reading;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FloraListRow(
          title: l10n.leafSignName(reading.sign),
          dense: true,
          chevron: false,
          titleMaxLines: 2,
          onTap: onTap,
          // Le chevron pivote vers le bas : c'est le même geste que dans une
          // liste de réglages, et il dit où va le contenu.
          trailing: AnimatedRotation(
            turns: open ? 0.25 : 0,
            duration: Motion.of(context, Motion.micro),
            curve: Motion.easeOut,
            child: Icon(CupertinoIcons.chevron_right, size: 16, color: c.inkTertiary),
          ),
        ),
        AnimatedSize(
          duration: Motion.of(context, Motion.standard),
          curve: Motion.easeOut,
          alignment: Alignment.topCenter,
          child: !open
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final cause in reading.causes)
                        Padding(
                          padding: const EdgeInsets.only(bottom: Space.xxs),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('·', style: context.text.callout.copyWith(color: c.inkTertiary)),
                              const SizedBox(width: Space.xs),
                              Expanded(child: Text(l10n.leafCauseName(cause), style: context.text.callout)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
        ),
      ],
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
        SectionHeader(title: l10n.careKnownProblems, padding: const EdgeInsets.only(bottom: Space.xxs)),
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
                // La fiche nomme le problème ; l'encyclopédie dit ce que la
                // base en sait — sa famille, son étendue, ses hôtes.
                FloraListRow(
                  title: p.nameIn(language),
                  dense: true,
                  titleMaxLines: 2,
                  onTap: () => context.push(Routes.encyclopediaProblem(p.id)),
                ),
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
