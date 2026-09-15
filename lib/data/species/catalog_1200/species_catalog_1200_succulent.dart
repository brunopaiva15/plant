import '../../../domain/species/species_info.dart';

/// Ajouts Iris 8 pour le palier 1 200 (succulentes et cactus).
abstract final class SpeciesCatalog1200Succulent {
  static const List<SpeciesCatalogEntry> entries = [
    SpeciesCatalogEntry('Austrocylindropuntia subulata', 'Cactaceae', SpeciesCategory.succulent, fr: 'Aiguille d\'Ève', en: 'Eve\'s Pin'),
    SpeciesCatalogEntry('Delosperma cooperi', 'Aizoaceae', SpeciesCategory.succulent, fr: 'Délosperma rose', en: 'Pink Carpet'),
    SpeciesCatalogEntry('Echinopsis oxygona', 'Cactaceae', SpeciesCategory.succulent, fr: 'Cactus oursin'),
    SpeciesCatalogEntry('Echinopsis pachanoi', 'Cactaceae', SpeciesCategory.succulent, fr: 'San Pedro', en: 'San Pedro', de: 'San-Pedro-Kaktus', it: 'San Pedro'),
  ];
}
