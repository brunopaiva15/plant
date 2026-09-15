import '../../../domain/species/species_info.dart';
import 'species_catalog_650_flower.dart';
import 'species_catalog_650_fruit.dart';
import 'species_catalog_650_herb.dart';
import 'species_catalog_650_indoor.dart';
import 'species_catalog_650_succulent.dart';
import 'species_catalog_650_tree.dart';
import 'species_catalog_650_vegetable.dart';

/// Palier 500 → 650, découpé par catégorie.
abstract final class SpeciesCatalog650 {
  static const List<SpeciesCatalogEntry> entries = [
    ...SpeciesCatalog650Indoor.entries,
    ...SpeciesCatalog650Succulent.entries,
    ...SpeciesCatalog650Herb.entries,
    ...SpeciesCatalog650Vegetable.entries,
    ...SpeciesCatalog650Fruit.entries,
    ...SpeciesCatalog650Flower.entries,
    ...SpeciesCatalog650Tree.entries,
  ];
}
