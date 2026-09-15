import '../../domain/species/species_info.dart';
import 'species_catalog_expansion_500.dart' as catalog500;
import 'catalog_650/species_catalog_650_flower.dart';
import 'catalog_650/species_catalog_650_fruit.dart';
import 'catalog_650/species_catalog_650_herb.dart';
import 'catalog_650/species_catalog_650_indoor.dart';
import 'catalog_650/species_catalog_650_succulent.dart';
import 'catalog_650/species_catalog_650_tree.dart';
import 'catalog_650/species_catalog_650_vegetable.dart';

/// Extensions du catalogue curaté.
///
/// Le palier historique jusqu'à 500 espèces est conservé séparément ;
/// les ajouts 500 → 650 sont découpés par catégorie pour garder des fichiers
/// courts et faciles à maintenir.
abstract final class SpeciesCatalogExpansion {
  static const List<SpeciesCatalogEntry> entries = [
    ...catalog500.SpeciesCatalogExpansion.entries,
    ...SpeciesCatalog650Indoor.entries,
    ...SpeciesCatalog650Succulent.entries,
    ...SpeciesCatalog650Herb.entries,
    ...SpeciesCatalog650Vegetable.entries,
    ...SpeciesCatalog650Fruit.entries,
    ...SpeciesCatalog650Flower.entries,
    ...SpeciesCatalog650Tree.entries,
  ];
}
