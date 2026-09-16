import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/l10n/finder_labels.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/utils/scientific_name.dart';
import '../../../data/species/species_catalog.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/species/species_info.dart';
import '../../plants/presentation/create_plant_flow.dart';
import '../../qr/presentation/species_qr_sheet.dart';
import '../../species/presentation/care_guide_screen.dart';
import '../../species/presentation/species_sheet.dart';

/// La fiche d'une espèce, lue depuis l'encyclopédie plutôt que depuis une
/// plante qu'on possède.
///
/// C'est la même fiche d'entretien que celle d'une plante du jardin, à ceci
/// près qu'elle n'est complétée par personne : le catalogue répond ou avoue
/// qu'il ne connaît que le genre, et la provenance est écrite en bas comme
/// ailleurs. La question à l'IA reste réservée aux plantes qu'on a vraiment,
/// où elle sert à faire quelque chose.
class EncyclopediaSpeciesPage extends ConsumerWidget {
  const EncyclopediaSpeciesPage({super.key, required this.scientificName});

  final String scientificName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;
    if (scientificName.trim().isEmpty) {
      // Une adresse tronquée : mieux vaut le dire qu'ouvrir une fiche
      // générique sans nom au-dessus.
      return FloraPage(
        title: l10n.encyclopediaTitle,
        child: Padding(
          padding: const EdgeInsets.only(top: Space.huge),
          child: EmptyState(
            emoji: '🌱',
            title: l10n.speciesNoResults,
            compact: true,
          ),
        ),
      );
    }
    // La liste de l'encyclopédie résout de la même façon : le nom de la
    // classe d'abord, puis le nom sous lequel l'app connaît le mieux la
    // plante. Sans quoi la fiche ouverte depuis la liste serait plus pauvre
    // que la ligne qui y menait.
    final accepted = acceptedSpeciesName(
      normalizeScientificName(scientificName),
    );
    final index = ref.watch(speciesIndexProvider).value;
    final entry =
        SpeciesCatalog.find(scientificName) ?? SpeciesCatalog.find(accepted);
    final record = index?.find(scientificName) ?? index?.find(accepted);
    final family = entry?.family ?? record?.family;
    // La catégorie n'est pas passée : le catalogue trouve lui-même celle de
    // ses propres entrées, et une espèce du catalogue étendu n'en a pas.
    final care = ref
        .watch(careGuideProvider)
        .resolve(
          scientificName,
          family: family == null || family.isEmpty ? null : family,
        );
    // Le nom courant de la langue de l'application titre la page ; à défaut,
    // le nom scientifique, qui est de toute façon écrit juste dessous.
    final common = entry?.vernacularName(lang) ?? record?.vernacularName(lang);
    final displayScientificName = capitalizeSpeciesDisplayName(scientificName);
    final displayName = common == null
        ? displayScientificName
        : capitalizeSpeciesDisplayName(common);

    return FloraPage(
      title: displayName,
      child: CareGuideBody(
        care: care,
        speciesName: scientificName,
        category: entry?.category,
        header: _Header(
          scientificName: scientificName,
          displayName: displayName,
          family: family,
          category: entry?.category,
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({
    required this.scientificName,
    required this.displayName,
    required this.family,
    required this.category,
  });

  final String scientificName;
  final String displayName;
  final String? family;
  final SpeciesCategory? category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          capitalizeSpeciesDisplayName(scientificName),
          style: context.text.title3.copyWith(fontStyle: FontStyle.italic),
        ),
        if (family != null && family!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text('${l10n.speciesFamily} · $family', style: context.text.caption),
        ],
        // La catégorie vient du catalogue trié à la main ; le catalogue
        // étendu n'en a pas, et la puce ne paraît alors pas.
        if (category case final cat?) ...[
          const SizedBox(height: Space.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: FloraChip(
              label: l10n.speciesCategoryName(cat),
              emoji: cat.emoji,
            ),
          ),
        ],
        const SizedBox(height: Space.sm),
        Row(
          children: [
            Expanded(
              child: FloraButton(
                label: l10n.speciesInfo,
                icon: CupertinoIcons.info,
                style: FloraButtonStyle.tonal,
                size: FloraButtonSize.small,
                expand: true,
                onPressed: () =>
                    showSpeciesSheet(context, scientificName: scientificName),
              ),
            ),
            const SizedBox(width: Space.xs),
            Expanded(
              child: FloraButton(
                label: l10n.addPlant,
                icon: CupertinoIcons.plus,
                style: FloraButtonStyle.tonal,
                size: FloraButtonSize.small,
                expand: true,
                onPressed: () => startCreatePlantFlow(
                  context,
                  ref,
                  speciesName: scientificName,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.xs),
        FloraButton(
          label: l10n.qrCode,
          icon: CupertinoIcons.qrcode,
          style: FloraButtonStyle.tonal,
          size: FloraButtonSize.small,
          expand: true,
          onPressed: () => showSpeciesQrSheet(
            context,
            scientificName: scientificName,
            displayName: displayName,
          ),
        ),
        const SizedBox(height: Space.lg),
      ],
    );
  }
}
