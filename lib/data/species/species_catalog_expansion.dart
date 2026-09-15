import '../../domain/species/species_info.dart';
import 'species_catalog_expansion_500.dart' as catalog500;
import 'catalog_650/species_catalog_650.dart';
import 'catalog_800/species_catalog_800.dart';
import 'catalog_1000/species_catalog_1000.dart';
import 'catalog_1200/species_catalog_1200.dart';
import 'species_catalog_iris_only.dart';

/// Extensions du catalogue curaté.
///
/// Le palier historique jusqu'à 500 espèces reste isolé ; les ajouts suivants
/// sont regroupés par palier puis découpés par catégorie. Le dernier bloc
/// n'est pas un palier : ce sont les classes d'Iris qu'aucun catalogue ne
/// nommait.
abstract final class SpeciesCatalogExpansion {
  static const List<SpeciesCatalogEntry> entries = [
    ...catalog500.SpeciesCatalogExpansion.entries,
    ...SpeciesCatalog650.entries,
    ...SpeciesCatalog800.entries,
    ...SpeciesCatalog1000.entries,
    ...SpeciesCatalog1200.entries,
    ...SpeciesCatalogIrisOnly.entries,
  ];
}
