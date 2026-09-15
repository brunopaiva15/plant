import '../../../domain/species/species_info.dart';

/// Ajouts Iris 8 pour le palier 1 200 (aromatiques, légumes et fruitiers).
abstract final class SpeciesCatalog1200Edible {
  static const List<SpeciesCatalogEntry> entries = [
    SpeciesCatalogEntry("Aegopodium podagraria", "Apiaceae", SpeciesCategory.herb),
    SpeciesCatalogEntry("Agastache foeniculum", "Lamiaceae", SpeciesCategory.herb),
    SpeciesCatalogEntry("Arctium tomentosum", "Asteraceae", SpeciesCategory.herb),
    SpeciesCatalogEntry("Artemisia absinthium", "Asteraceae", SpeciesCategory.herb),
    SpeciesCatalogEntry("Boehmeria nivea", "Urticaceae", SpeciesCategory.herb),
    SpeciesCatalogEntry("Cichorium intybus", "Asteraceae", SpeciesCategory.herb),
    SpeciesCatalogEntry("Coleus amboinicus", "Lamiaceae", SpeciesCategory.herb),
    SpeciesCatalogEntry("Coleus neochilus", "Lamiaceae", SpeciesCategory.herb),
    SpeciesCatalogEntry("Elettaria cardamomum", "Zingiberaceae", SpeciesCategory.herb),
    SpeciesCatalogEntry("Amaranthus cruentus", "Amaranthaceae", SpeciesCategory.vegetable),
    SpeciesCatalogEntry("Avena sativa", "Poaceae", SpeciesCategory.vegetable),
    SpeciesCatalogEntry("Cynara scolymus", "Asteraceae", SpeciesCategory.vegetable),
    SpeciesCatalogEntry("Anacardium occidentale", "Anacardiaceae", SpeciesCategory.fruit),
    SpeciesCatalogEntry("Ananas comosus", "Bromeliaceae", SpeciesCategory.fruit),
    SpeciesCatalogEntry("Aronia melanocarpa", "Rosaceae", SpeciesCategory.fruit),
    SpeciesCatalogEntry("Aronia mitschurinii", "Rosaceae", SpeciesCategory.fruit),
    SpeciesCatalogEntry("Artocarpus altilis", "Moraceae", SpeciesCategory.fruit),
    SpeciesCatalogEntry("Carissa macrocarpa", "Apocynaceae", SpeciesCategory.fruit),
    SpeciesCatalogEntry("Carya illinoinensis", "Juglandaceae", SpeciesCategory.fruit),
    SpeciesCatalogEntry("Citrus deliciosa", "Rutaceae", SpeciesCategory.fruit),
    SpeciesCatalogEntry("Citrus medica", "Rutaceae", SpeciesCategory.fruit),
    SpeciesCatalogEntry("Citrus myrtifolia", "Rutaceae", SpeciesCategory.fruit),
    SpeciesCatalogEntry("Citrus trifoliata", "Rutaceae", SpeciesCategory.fruit),
    SpeciesCatalogEntry("Citrus × aurantifolia", "Rutaceae", SpeciesCategory.fruit),
    SpeciesCatalogEntry("Citrus × aurantium", "Rutaceae", SpeciesCategory.fruit),
    SpeciesCatalogEntry("Citrus × bergamia", "Rutaceae", SpeciesCategory.fruit),
    SpeciesCatalogEntry("Cormus domestica", "Rosaceae", SpeciesCategory.fruit),
    SpeciesCatalogEntry("Cornus mas", "Cornaceae", SpeciesCategory.fruit),
    SpeciesCatalogEntry("Cucumis metuliferus", "Cucurbitaceae", SpeciesCategory.fruit),
    SpeciesCatalogEntry("Dimocarpus longan", "Sapindaceae", SpeciesCategory.fruit),
    SpeciesCatalogEntry("Diospyros lotus", "Ebenaceae", SpeciesCategory.fruit),
  ];
}
