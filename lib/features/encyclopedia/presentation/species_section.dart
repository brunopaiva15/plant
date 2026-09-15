import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/l10n/species_count_copy.dart';
import '../../../data/species/species_catalog.dart';
import '../../../data/species/species_index.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/species/species_info.dart';
import 'encyclopedia_screen.dart';

/// Les espèces que l'application connaît : le catalogue trié à la main, qui
/// a une fiche d'entretien, puis le catalogue étendu quand on cherche.
class SpeciesSlivers extends ConsumerWidget {
  const SpeciesSlivers({super.key, required this.query, required this.category, required this.onCategory});

  final String query;
  final SpeciesCategory? category;
  final ValueChanged<SpeciesCategory?> onCategory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;
    final raw = query.trim();

    final curated = [
      for (final e in SpeciesCatalog.entries)
        if ((category == null || e.category == category) && e.matches(raw)) e,
    ]..sort((a, b) => a.commonName(lang).toLowerCase().compareTo(b.commonName(lang).toLowerCase()));

    // Le catalogue étendu ne sert qu'à la recherche : il n'a pas de
    // catégories, et quarante mille lignes ne se parcourent pas. Il n'est
    // donc chargé qu'au premier mot tapé, comme dans le sélecteur d'espèce.
    final index = raw.isEmpty ? null : ref.watch(speciesIndexProvider).value;
    final extended = index == null
        ? const <SpeciesRecord>[]
        : index.search(raw, limit: 30, exclude: {for (final e in curated) e.scientificName.toLowerCase()});

    final visibleCount = curated.length + extended.length;
    final countLabel = raw.isEmpty
        ? l10n.encyclopediaDetailedSpeciesCount(curated.length)
        : l10n.encyclopediaSearchResultCount(visibleCount);

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: EncyclopediaFilterRow<SpeciesCategory>(
            options: [
              (null, l10n.speciesCatAll),
              (SpeciesCategory.indoor, l10n.speciesCatIndoor),
              (SpeciesCategory.succulent, l10n.speciesCatSucculent),
              (SpeciesCategory.herb, l10n.speciesCatHerb),
              (SpeciesCategory.vegetable, l10n.speciesCatVegetable),
              (SpeciesCategory.fruit, l10n.speciesCatFruit),
              (SpeciesCategory.flower, l10n.speciesCatFlower),
              (SpeciesCategory.tree, l10n.speciesCatTree),
            ],
            value: category,
            onChanged: onCategory,
          ),
        ),
        // Au repos, ce nombre décrit bien le catalogue éditorial avec ses
        // fiches détaillées. Pendant une recherche il devient le nombre de
        // résultats visibles, car le catalogue étendu est plafonné à trente.
        SliverToBoxAdapter(child: EncyclopediaCount(countLabel)),
        if (curated.isEmpty && extended.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(Space.page),
              child: EmptyState(emoji: '🌱', title: l10n.speciesNoResults, subtitle: l10n.noResultsSubtitle, compact: true),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.lg),
            sliver: SliverList.separated(
              itemCount: curated.length,
              separatorBuilder: (_, _) => const SizedBox(height: Space.xs),
              itemBuilder: (context, i) => _SpeciesRow(
                emoji: curated[i].category.emoji,
                name: curated[i].commonName(lang),
                scientificName: curated[i].scientificName,
                family: curated[i].family,
              ),
            ),
          ),
        if (extended.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: SectionHeader(title: l10n.speciesMoreOffline, padding: const EdgeInsets.fromLTRB(Space.page, Space.sm, Space.page, Space.xs)),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.lg),
            sliver: SliverList.separated(
              itemCount: extended.length,
              separatorBuilder: (_, _) => const SizedBox(height: Space.xs),
              itemBuilder: (context, i) => _SpeciesRow(
                emoji: '🌿',
                name: extended[i].commonName(lang),
                scientificName: extended[i].scientificName,
                family: extended[i].family,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SpeciesRow extends StatelessWidget {
  const _SpeciesRow({required this.emoji, required this.name, required this.scientificName, required this.family});

  final String emoji;
  final String name;
  final String scientificName;
  final String family;

  @override
  Widget build(BuildContext context) {
    return FloraCard(
      padding: EdgeInsets.zero,
      clip: true,
      child: FloraListRow(
        leading: Text(emoji, style: const TextStyle(fontSize: 18)),
        title: name,
        titleMaxLines: 2,
        subtitle: family.isEmpty ? scientificName : '$scientificName · $family',
        onTap: () => context.push(Routes.encyclopediaSpecies(scientificName)),
      ),
    );
  }
}
