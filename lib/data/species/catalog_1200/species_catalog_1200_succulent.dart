import '../../../domain/species/species_info.dart';

/// Ajouts Iris 8 pour le palier 1 200 (succulentes et cactus).
abstract final class SpeciesCatalog1200Succulent {
  static const List<SpeciesCatalogEntry> entries = [
    SpeciesCatalogEntry("Agave attenuata", "Asparagaceae", SpeciesCategory.succulent),
    SpeciesCatalogEntry("Aloe arborescens", "Asphodelaceae", SpeciesCategory.succulent),
    SpeciesCatalogEntry("Aloe maculata", "Asphodelaceae", SpeciesCategory.succulent),
    SpeciesCatalogEntry("Astrophytum myriostigma", "Cactaceae", SpeciesCategory.succulent),
    SpeciesCatalogEntry("Austrocylindropuntia subulata", "Cactaceae", SpeciesCategory.succulent),
    SpeciesCatalogEntry("Carpobrotus acinaciformis", "Aizoaceae", SpeciesCategory.succulent),
    SpeciesCatalogEntry("Crassula perforata", "Crassulaceae", SpeciesCategory.succulent),
    SpeciesCatalogEntry("Delosperma cooperi", "Aizoaceae", SpeciesCategory.succulent),
    SpeciesCatalogEntry("Echeveria agavoides", "Crassulaceae", SpeciesCategory.succulent),
    SpeciesCatalogEntry("Echinopsis oxygona", "Cactaceae", SpeciesCategory.succulent),
    SpeciesCatalogEntry("Echinopsis pachanoi", "Cactaceae", SpeciesCategory.succulent),
  ];
}
