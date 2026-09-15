import '../../../domain/species/species_info.dart';
import 'species_catalog_1200_edible.dart';
import 'species_catalog_1200_flower_a.dart';
import 'species_catalog_1200_flower_b.dart';
import 'species_catalog_1200_flower_c.dart';
import 'species_catalog_1200_indoor.dart';
import 'species_catalog_1200_succulent.dart';
import 'species_catalog_1200_tree.dart';

/// Les 200 classes Iris 8 ajoutées entre 1 000 et 1 200 fiches.
abstract final class SpeciesCatalog1200 {
  static const List<SpeciesCatalogEntry> entries = [
    ...SpeciesCatalog1200FlowerA.entries,
    ...SpeciesCatalog1200FlowerB.entries,
    ...SpeciesCatalog1200FlowerC.entries,
    ...SpeciesCatalog1200Tree.entries,
    ...SpeciesCatalog1200Indoor.entries,
    ...SpeciesCatalog1200Succulent.entries,
    ...SpeciesCatalog1200Edible.entries,
  ];
}
