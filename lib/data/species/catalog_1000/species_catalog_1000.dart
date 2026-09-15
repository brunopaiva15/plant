import '../../../domain/species/species_info.dart';
import 'species_catalog_1000_edible.dart';
import 'species_catalog_1000_flower_a.dart';
import 'species_catalog_1000_flower_b.dart';
import 'species_catalog_1000_herb.dart';
import 'species_catalog_1000_tree.dart';

/// Agrégateur du palier 800 → 1 000.
abstract final class SpeciesCatalog1000 {
  static const List<SpeciesCatalogEntry> entries = [
    ...SpeciesCatalog1000FlowerA.entries,
    ...SpeciesCatalog1000FlowerB.entries,
    ...SpeciesCatalog1000Tree.entries,
    ...SpeciesCatalog1000Herb.entries,
    ...SpeciesCatalog1000Edible.entries,
  ];
}
