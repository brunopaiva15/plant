import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/l10n/care_labels.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/care/care_guide.dart';
import '../../../domain/care/care_profile.dart';
import '../../../domain/models/models.dart';
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
    final care = ref.watch(careGuideProvider).resolve(plant?.speciesName);
    return FloraPage(
      title: l10n.careGuide,
      child: CareGuideBody(care: care, plantName: plant?.name, location: location),
    );
  }
}

/// Corps de la fiche, réutilisable en sheet (création de plante, espèce).
class CareGuideBody extends StatelessWidget {
  const CareGuideBody({super.key, required this.care, this.plantName, this.location, this.header});

  final ResolvedCare care;
  final String? plantName;
  final Location? location;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final p = care.profile;
    final now = DateTime.now();
    final actualLight = _lightOf(location);
    final currentDays = p.wateringDaysFor(now.month, actualLight: actualLight);

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
              subtitle: p.fertilizingDays == null ? null : l10n.fertilizeWindowLabel(p.fertilizingWindow, context.localeTag),
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
          FloraGroup(children: [for (final i in p.issues) FloraListRow(leading: const Text('👀', style: TextStyle(fontSize: 16)), title: l10n.issueName(i), dense: true, chevron: false)]),
        ],

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
        Text(care.isSpecific ? l10n.careDisclaimer : l10n.careMatchNote, style: context.text.caption),
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
  static LightNeed? _lightOf(Location? location) => switch (location?.light) {
        'high' => LightNeed.someSun,
        'medium' => LightNeed.brightIndirect,
        'low' => LightNeed.lowLight,
        _ => null,
      };
}
