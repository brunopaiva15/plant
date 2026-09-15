import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/l10n/species_count_copy.dart';
import '../../../data/species/iris_detailed_catalog.dart';
import '../../../data/species/iris_detailed_catalog_loader.dart';
import '../../../data/species/species_catalog.dart';
import '../../../data/species/species_index.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/species/species_info.dart';
import 'encyclopedia_screen.dart';

/// Produit une clé de tri adaptée au français afin que les lettres accentuées
/// restent avec leur lettre de base et que la ligature œ soit triée comme oe.
String _alphabeticalSortKey(String value, String languageCode) {
  final lower = value.toLowerCase();
  if (languageCode != 'fr') return lower;

  return lower
      .replaceAll('œ', 'oe')
      .replaceAll('æ', 'ae')
      .replaceAll(RegExp(r'[àáâãäå]'), 'a')
      .replaceAll('ç', 'c')
      .replaceAll(RegExp(r'[èéêë]'), 'e')
      .replaceAll(RegExp(r'[ìíîï]'), 'i')
      .replaceAll(RegExp(r'[ñ]'), 'n')
      .replaceAll(RegExp(r'[òóôõö]'), 'o')
      .replaceAll(RegExp(r'[ùúûü]'), 'u')
      .replaceAll(RegExp(r'[ýÿ]'), 'y');
}

/// La vue détaillée suit directement les classes du modèle embarqué. Le même
/// [SpeciesIndex] sert à enrichir les classes Iris qui ne font pas encore
/// partie du catalogue éditorial, sans charger deux fois le gros TSV.
final _irisDetailedCatalogProvider = FutureProvider<IrisDetailedCatalog>((ref) async {
  final index = await ref.watch(speciesIndexProvider.future);
  return IrisDetailedCatalogLoader().load(index);
});

/// Les espèces que l'application connaît : les 1 444 classes Iris avec leur
/// fiche d'entretien, puis le catalogue étendu quand une recherche dépasse
/// le périmètre du modèle embarqué.
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

    // Le catalogue curaté est disponible immédiatement. Dès que les deux
    // assets hors ligne sont prêts, la liste devient exactement celle d'Iris.
    final detailed = ref.watch(_irisDetailedCatalogProvider).value?.entries ??
        [for (final entry in SpeciesCatalog.entries) IrisDetailedSpecies.fromCurated(entry)];

    final curated = [
      for (final e in detailed)
        if ((category == null || e.category == category) && e.matches(raw)) e,
    ]..sort((a, b) {
        final aName = a.commonName(lang);
        final bName = b.commonName(lang);
        final byAlphabet = _alphabeticalSortKey(aName, lang).compareTo(_alphabeticalSortKey(bName, lang));
        return byAlphabet != 0 ? byAlphabet : aName.toLowerCase().compareTo(bName.toLowerCase());
      });

    // Le catalogue étendu reste réservé à la recherche au-delà d'Iris.
    final index = raw.isEmpty ? null : ref.watch(speciesIndexProvider).value;
    final detailedNames = {for (final e in detailed) e.scientificName.toLowerCase()};
    final extended = index == null
        ? const <SpeciesRecord>[]
        : index.search(raw, limit: 30, exclude: detailedNames);

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
        // Sans filtre, le nombre suit model.json : aujourd'hui 1 444 classes.
        // Avec un filtre ou une recherche, il décrit ce qui est réellement vu.
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
                emoji: curated[i].category?.emoji ?? '🌿',
                vernacular: curated[i].vernacularName(lang),
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
                vernacular: extended[i].vernacularName(lang),
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
  const _SpeciesRow({required this.emoji, required this.vernacular, required this.scientificName, required this.family});

  final String emoji;

  /// Le nom courant dans la langue de l'application, ou `null` quand cette
  /// espèce n'en a pas : le nom scientifique titre alors la ligne, et le
  /// sous-titre garde la famille pour lui seul plutôt que de le répéter.
  final String? vernacular;

  final String scientificName;
  final String family;

  @override
  Widget build(BuildContext context) {
    final displayVernacular = vernacular == null ? null : capitalizeSpeciesDisplayName(vernacular!);
    final displayScientificName = capitalizeSpeciesDisplayName(scientificName);
    final subtitle = displayVernacular == null
        ? (family.isEmpty ? null : family)
        : (family.isEmpty ? displayScientificName : '$displayScientificName · $family');
    return FloraCard(
      padding: EdgeInsets.zero,
      clip: true,
      child: FloraListRow(
        leading: Text(emoji, style: const TextStyle(fontSize: 18)),
        title: displayVernacular ?? displayScientificName,
        titleMaxLines: 2,
        subtitle: subtitle,
        onTap: () => context.push(Routes.encyclopediaSpecies(scientificName)),
      ),
    );
  }
}
