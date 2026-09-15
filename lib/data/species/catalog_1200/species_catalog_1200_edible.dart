import '../../../domain/species/species_info.dart';

/// Ajouts Iris 8 pour le palier 1 200 (aromatiques, légumes et fruitiers).
abstract final class SpeciesCatalog1200Edible {
  static const List<SpeciesCatalogEntry> entries = [
    SpeciesCatalogEntry('Arctium tomentosum', 'Asteraceae', SpeciesCategory.herb, fr: 'Bardane tomenteuse', en: 'Woolly burdock', de: 'Filz-Klette', it: 'Bardana lanuta'),
    SpeciesCatalogEntry('Artemisia absinthium', 'Asteraceae', SpeciesCategory.herb, fr: 'Absinthe', en: 'Wormwood', de: 'Wermut', it: 'Assenzio'),
    SpeciesCatalogEntry('Boehmeria nivea', 'Urticaceae', SpeciesCategory.herb, fr: 'Ramie', en: 'Ramie', de: 'Ramie', it: 'Ramiè'),
    SpeciesCatalogEntry('Coleus amboinicus', 'Lamiaceae', SpeciesCategory.herb, fr: 'Origan cubain', en: 'Cuban oregano', de: 'Jamaika-Thymian', it: 'Origano cubano'),
    SpeciesCatalogEntry('Coleus neochilus', 'Lamiaceae', SpeciesCategory.herb),
    SpeciesCatalogEntry('Elettaria cardamomum', 'Zingiberaceae', SpeciesCategory.herb, fr: 'Cardamome aromatique', en: 'Cardamom', de: 'Grüner Kardamom', it: 'Cardamomo'),
    SpeciesCatalogEntry('Avena sativa', 'Poaceae', SpeciesCategory.vegetable, fr: 'Avoine cultivée', en: 'Oats', de: 'Hafer'),
    SpeciesCatalogEntry('Cynara scolymus', 'Asteraceae', SpeciesCategory.vegetable, fr: 'Artichaut', en: 'Artichoke plant', de: 'Artischocke', it: 'Carciofo'),
    SpeciesCatalogEntry('Aronia melanocarpa', 'Rosaceae', SpeciesCategory.fruit, fr: 'Aronie à fruits noirs', en: 'Black chokeberry', de: 'Schwarze Apfelbeere'),
    SpeciesCatalogEntry('Aronia mitschurinii', 'Rosaceae', SpeciesCategory.fruit, fr: 'Aronia', en: 'Chokeberry', de: 'Apfelbeere', it: 'Aronia'),
    SpeciesCatalogEntry('Artocarpus altilis', 'Moraceae', SpeciesCategory.fruit, fr: 'Arbre à pain', en: 'Breadfruit', de: 'Brotfruchtbaum', it: 'Albero del pane'),
    SpeciesCatalogEntry('Citrus trifoliata', 'Rutaceae', SpeciesCategory.fruit, fr: 'Oranger trifolié', en: 'Trifoliate orange', de: 'Dreiblättrige Orange', it: 'Arancio trifogliato'),
    SpeciesCatalogEntry('Dimocarpus longan', 'Sapindaceae', SpeciesCategory.fruit, fr: 'Longanier', en: 'Longan', de: 'Longan', it: 'Longan'),
    SpeciesCatalogEntry('Diospyros lotus', 'Ebenaceae', SpeciesCategory.fruit, fr: 'Plaqueminier lotier', en: 'Date plum', de: 'Lotuspflaume'),
  ];
}
