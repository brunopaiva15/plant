import '../../../domain/species/species_info.dart';

/// Espèces alimentaires et utiles ajoutées pour le palier 1 000, présentes dans Iris 8.
abstract final class SpeciesCatalog1000Edible {
  static const List<SpeciesCatalogEntry> entries = [
    SpeciesCatalogEntry("Euterpe oleracea", "Arecaceae", SpeciesCategory.fruit),
    SpeciesCatalogEntry("Fagopyrum esculentum", "Polygonaceae", SpeciesCategory.vegetable),
    SpeciesCatalogEntry("Ferula assa-foetida", "Apiaceae", SpeciesCategory.herb),
    SpeciesCatalogEntry("Galega officinalis", "Fabaceae", SpeciesCategory.herb),
    SpeciesCatalogEntry("Garcinia mangostana", "Clusiaceae", SpeciesCategory.fruit),
    SpeciesCatalogEntry("Glycine max", "Fabaceae", SpeciesCategory.vegetable),
    SpeciesCatalogEntry("Glycyrrhiza glabra", "Fabaceae", SpeciesCategory.herb),
    SpeciesCatalogEntry("Hovenia dulcis", "Rhamnaceae", SpeciesCategory.fruit),
    SpeciesCatalogEntry("Ilex paraguariensis", "Aquifoliaceae", SpeciesCategory.herb),
    SpeciesCatalogEntry("Neptunia oleracea", "Fabaceae", SpeciesCategory.vegetable),
    SpeciesCatalogEntry("Panicum miliaceum", "Poaceae", SpeciesCategory.vegetable),
    SpeciesCatalogEntry("Phaseolus lunatus", "Fabaceae", SpeciesCategory.vegetable),
    SpeciesCatalogEntry("Phalaris canariensis", "Poaceae", SpeciesCategory.vegetable),
    SpeciesCatalogEntry("Pimenta dioica", "Myrtaceae", SpeciesCategory.herb),
    SpeciesCatalogEntry("Pistacia vera", "Anacardiaceae", SpeciesCategory.fruit),
    SpeciesCatalogEntry("Sclerocarya birrea", "Anacardiaceae", SpeciesCategory.fruit),
    SpeciesCatalogEntry("Sesamum indicum", "Pedaliaceae", SpeciesCategory.herb),
    SpeciesCatalogEntry("Theobroma grandiflorum", "Malvaceae", SpeciesCategory.fruit),
    SpeciesCatalogEntry("Rhus coriaria", "Anacardiaceae", SpeciesCategory.herb),
    SpeciesCatalogEntry("Vigna angularis", "Fabaceae", SpeciesCategory.vegetable),
    SpeciesCatalogEntry("Vigna radiata", "Fabaceae", SpeciesCategory.vegetable),
    SpeciesCatalogEntry("Trapa natans", "Lythraceae", SpeciesCategory.vegetable),
    SpeciesCatalogEntry("Vicia sativa", "Fabaceae", SpeciesCategory.vegetable),
    SpeciesCatalogEntry("Ribes aureum", "Grossulariaceae", SpeciesCategory.fruit),
    SpeciesCatalogEntry("Ribes alpinum", "Grossulariaceae", SpeciesCategory.fruit),
  ];
}
