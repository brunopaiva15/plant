import 'package:flutter/widgets.dart';

import '../../../core/l10n/care_labels.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/care/care_profile.dart';
import '../../../domain/species/species_info.dart';
import '../application/care_environment_spec.dart';
import 'care_environment_scene.dart';

/// Le héros de la fiche d'entretien : le diorama « emplacement idéal » et
/// ses callouts, avant le détail des besoins.
///
/// La scène résume l'endroit où la plante serait bien — lumière, fenêtre,
/// climat — ; les cartes en dessous restent la référence. Elle ne montre que
/// ce que la fiche sait : pas de température sans plage connue, rien sur
/// l'air tant le rapport de l'espèce aux courants d'air n'est pas renseigné.
class CareEnvironmentHero extends StatefulWidget {
  const CareEnvironmentHero({
    super.key,
    required this.profile,
    this.speciesName,
    this.family,
    this.category,
  });

  final CareProfile profile;

  /// Nom scientifique, quand il est connu : la silhouette s'y rattache.
  final String? speciesName;
  final String? family;

  /// La catégorie d'usage, quand le catalogue la connaît : elle départage
  /// la scène entre la pièce et dehors.
  final SpeciesCategory? category;

  @override
  State<CareEnvironmentHero> createState() => _CareEnvironmentHeroState();
}

class _CareEnvironmentHeroState extends State<CareEnvironmentHero> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precache();
  }

  @override
  void didUpdateWidget(CareEnvironmentHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    _precache();
  }

  /// Les deux images de la scène sont locales et petites ; les précharger
  /// évite que le diorama se pose en deux temps au premier affichage.
  void _precache() {
    final spec = _spec;
    precacheImage(AssetImage(spec.backdropAsset), context);
    precacheImage(AssetImage(spec.plantAsset), context);
    if (spec.hasHumidifier) {
      precacheImage(
        AssetImage('assets/care_scene/props/humidifier.webp'),
        context,
      );
    }
    if (spec.airflow == AirflowPreference.sheltered) {
      precacheImage(AssetImage('assets/care_scene/props/vent.webp'), context);
    }
  }

  CareEnvironmentVisualSpec get _spec => careEnvironmentSpec(
    profile: widget.profile,
    speciesName: widget.speciesName,
    family: widget.family,
    category: widget.category,
  );

  @override
  Widget build(BuildContext context) {
    final spec = _spec;
    final l10n = context.l10n;

    final callouts = <(String, String)>[
      ('☀️', l10n.lightName(spec.light)),
      (
        '💨',
        l10n.careEnvHumidity(spec.humidityRange.$1, spec.humidityRange.$2),
      ),
      if (spec.tempRange case final r?)
        ('🌡️', l10n.careEnvTempRange(r.$1, r.$2))
      else if (spec.tempFloorC case final t?)
        ('🌡️', l10n.careEnvTempMin(t)),
      if (spec.airflow == AirflowPreference.sheltered)
        ('🌬️', l10n.careAirflowSheltered)
      else if (spec.airflow == AirflowPreference.ventilated)
        ('🌬️', l10n.careAirflowVentilated),
    ];

    // La description lue par les lecteurs d'écran : la scène en une phrase,
    // limitée à ce qui est réellement montré.
    final details = <String>[
      l10n.lightName(spec.light),
      l10n.humidityName(spec.humidity),
      if (spec.tempRange case final r?)
        l10n.careEnvSemanticTemp(r.$1, r.$2)
      else if (spec.tempFloorC case final t?)
        l10n.careEnvSemanticTempMin(t),
      if (spec.airflow == AirflowPreference.sheltered)
        l10n.careAirflowSheltered
      else if (spec.airflow == AirflowPreference.ventilated)
        l10n.careAirflowVentilated,
    ];

    // À forte échelle de texte, les puces passent sous la scène : superposées,
    // elles finiraient par couvrir le diorama ou par rogner.
    final superpose = MediaQuery.textScalerOf(context).scale(16) <= 26;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: l10n.careEnvTitle,
          padding: const EdgeInsets.only(bottom: Space.sm),
        ),
        Semantics(
          container: true,
          label: '${l10n.careEnvTitle} : ${details.join(', ')}.',
          child: CareEnvironmentScene(
            spec: spec,
            callouts: superpose ? callouts : const [],
          ),
        ),
        if (!superpose) ...[
          const SizedBox(height: Space.sm),
          ExcludeSemantics(
            child: Wrap(
              spacing: Space.xs,
              runSpacing: Space.xs,
              children: [
                for (final (emoji, label) in callouts)
                  FloraChip(emoji: emoji, label: label),
              ],
            ),
          ),
        ],
        const SizedBox(height: Space.lg),
      ],
    );
  }
}
