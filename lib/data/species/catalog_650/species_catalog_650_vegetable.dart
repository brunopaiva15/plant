import '../../../domain/species/species_info.dart';

/// Espèces potagères ajoutées pour le palier 650, toutes présentes dans Iris 8.
abstract final class SpeciesCatalog650Vegetable {
  static const List<SpeciesCatalogEntry> entries = [
    SpeciesCatalogEntry('Amaranthus cruentus', 'Amaranthaceae', SpeciesCategory.vegetable, fr: 'Amarante rouge', en: 'Red amaranth', de: 'Roter Amarant', it: 'Amaranto rosso'),
    SpeciesCatalogEntry('Chenopodium quinoa', 'Amaranthaceae', SpeciesCategory.vegetable, fr: 'Quinoa', en: 'Quinoa', de: 'Quinoa', it: 'Quinoa'),
    SpeciesCatalogEntry('Cucumis metuliferus', 'Cucurbitaceae', SpeciesCategory.vegetable, fr: 'Kiwano', en: 'Kiwano', de: 'Kiwano', it: 'Kiwano'),
    SpeciesCatalogEntry('Lablab purpureus', 'Fabaceae', SpeciesCategory.vegetable, fr: 'Dolique d\'Égypte', en: 'Hyacinth bean', de: 'Helmbohne', it: 'Fagiolo giacinto'),
    SpeciesCatalogEntry('Manihot esculenta', 'Euphorbiaceae', SpeciesCategory.vegetable, fr: 'Manioc', en: 'Cassava', de: 'Maniok', it: 'Manioca'),
    SpeciesCatalogEntry('Sechium edule', 'Cucurbitaceae', SpeciesCategory.vegetable, fr: 'Chayote', en: 'Chayote', de: 'Chayote', it: 'Chayote'),
    SpeciesCatalogEntry('Sorghum bicolor', 'Poaceae', SpeciesCategory.vegetable, fr: 'Sorgho', en: 'Sorghum', de: 'Sorghumhirse', it: 'Sorgo'),
    SpeciesCatalogEntry('Setaria italica', 'Poaceae', SpeciesCategory.vegetable, fr: 'Millet des oiseaux', en: 'Foxtail millet', de: 'Kolbenhirse', it: 'Miglio'),
    SpeciesCatalogEntry('Triticum aestivum', 'Poaceae', SpeciesCategory.vegetable, fr: 'Blé tendre', en: 'Bread wheat', de: 'Weichweizen', it: 'Grano tenero'),
    SpeciesCatalogEntry('Hordeum vulgare', 'Poaceae', SpeciesCategory.vegetable, fr: 'Orge', en: 'Barley', de: 'Gerste', it: 'Orzo'),
  ];
}
