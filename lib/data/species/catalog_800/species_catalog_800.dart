import '../../../domain/species/species_info.dart';
import 'species_catalog_800_flower.dart';
import 'species_catalog_800_tree.dart';

/// Palier 650 → 800.
///
/// Les 150 entrées de ce palier correspondent directement à des classes Iris 8.
abstract final class SpeciesCatalog800 {
  static const List<SpeciesCatalogEntry> entries = [
    ...SpeciesCatalog800Flower.entries,
    ...SpeciesCatalog800Tree.entries,
  ];
}
