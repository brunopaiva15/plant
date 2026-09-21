import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/l10n/species_count_copy.dart';
import '../../../core/utils/search_text.dart';
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

/// Une fiche prête à être cherchée et rangée.
///
/// La clé de tri et le texte où l'on cherche coûtent cher — huit
/// remplacements pour la première, la concaténation des six noms pour le
/// second. Calculés dans le comparateur, ils l'étaient des centaines de
/// milliers de fois à chaque frappe ; ils le sont ici une fois par fiche.
class _ListedSpecies {
  const _ListedSpecies(this.entry, this.sortKey, this.haystack);

  final IrisDetailedSpecies entry;
  final String sortKey;
  final String haystack;
}

/// Le rayon des espèces, rangé une bonne fois : filtrer une liste déjà triée
/// garde son ordre, donc une recherche ne retrie rien.
class _SpeciesShelf {
  const _SpeciesShelf(this.rows, this.names);

  final List<_ListedSpecies> rows;

  /// Les noms déjà montrés, pour que le catalogue étendu ne les répète pas.
  final Set<String> names;
}

final _speciesShelfProvider = Provider.family<_SpeciesShelf, String>((ref, lang) {
  final detailed = ref.watch(_irisDetailedCatalogProvider).value?.entries ??
      [for (final entry in SpeciesCatalog.entries) IrisDetailedSpecies.fromCurated(entry)];

  final rows = [
    for (final e in detailed)
      _ListedSpecies(
        e,
        _alphabeticalSortKey(e.commonName(lang), lang),
        foldSpeciesName('${e.scientificName} ${e.family} ${e.fr} ${e.en} ${e.de} ${e.it}'),
      ),
  ]..sort((a, b) {
      final byAlphabet = a.sortKey.compareTo(b.sortKey);
      if (byAlphabet != 0) return byAlphabet;
      // Deux noms que l'ordre français ne sépare pas — « Aloé » et « Aloe » :
      // l'accent tranche, et le calcul ne coûte que sur ces rares ex æquo.
      return a.entry.commonName(lang).toLowerCase().compareTo(b.entry.commonName(lang).toLowerCase());
    });

  return _SpeciesShelf(rows, {for (final e in detailed) e.scientificName.toLowerCase()});
});

/// Les espèces que l'application connaît : les classes d'Iris et tout ce que
/// le catalogue étendu porte avec un vrai profil d'entretien, puis le reste
/// du catalogue quand une recherche dépasse ce périmètre.
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
    // Elle arrive déjà rangée : une frappe ne fait plus que la filtrer.
    final shelf = ref.watch(_speciesShelfProvider(lang));
    final needle = foldSpeciesName(raw);
    final curated = [
      for (final row in shelf.rows)
        if ((category == null || row.entry.category == category) && (needle.isEmpty || row.haystack.contains(needle)))
          row.entry,
    ];

    // Le catalogue étendu reste réservé à la recherche au-delà d'Iris.
    final index = raw.isEmpty ? null : ref.watch(speciesIndexProvider).value;
    final extended = index == null
        ? const <SpeciesRecord>[]
        : index.search(raw, limit: 30, exclude: shelf.names);

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
        // Sans filtre, le nombre est celui des fiches de l'encyclopédie. Avec
        // un filtre ou une recherche, il décrit ce qui est réellement vu.
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
