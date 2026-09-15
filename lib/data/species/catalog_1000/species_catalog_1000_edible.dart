import '../../../domain/species/species_info.dart';

/// Espèces alimentaires et utiles ajoutées pour le palier 1 000, présentes dans Iris 8.
abstract final class SpeciesCatalog1000Edible {
  static const List<SpeciesCatalogEntry> entries = [
    SpeciesCatalogEntry('Euterpe oleracea', 'Arecaceae', SpeciesCategory.fruit, fr: 'Acai', en: 'Açaí', de: 'Acai', it: 'Açai'),
    SpeciesCatalogEntry('Fagopyrum esculentum', 'Polygonaceae', SpeciesCategory.vegetable, fr: 'Sarrasin', en: 'Buckwheat plant', de: 'Echter Buchweizen', it: 'Grano Saraceno'),
    SpeciesCatalogEntry('Ferula assa-foetida', 'Apiaceae', SpeciesCategory.herb, fr: 'Peucedanum hooshe', en: 'Hing', de: 'Asant', it: 'Assa fetida'),
    SpeciesCatalogEntry('Galega officinalis', 'Fabaceae', SpeciesCategory.herb, fr: 'Galéga officinal', en: 'Professor-weed', de: 'Geißraute', it: 'Erba ruta delle capre'),
    SpeciesCatalogEntry('Garcinia mangostana', 'Clusiaceae', SpeciesCategory.fruit, fr: 'Mangoustanier', en: 'Mangostan', de: 'Mangostane', it: 'Mangostano'),
    SpeciesCatalogEntry('Glycine max', 'Fabaceae', SpeciesCategory.vegetable, fr: 'Soja', en: 'Soybean', de: 'Sojabohne', it: 'Soia'),
    SpeciesCatalogEntry('Glycyrrhiza glabra', 'Fabaceae', SpeciesCategory.herb, fr: 'Réglisse', en: 'Liquorice', de: 'Echtes Süßholz', it: 'Liquirizia'),
    SpeciesCatalogEntry('Hovenia dulcis', 'Rhamnaceae', SpeciesCategory.fruit, fr: 'Raisinier de Chine', en: 'Japanese raisin tree', de: 'Japanischer Rosinenbaum', it: 'Albero dell\'uva passa'),
    SpeciesCatalogEntry('Ilex paraguariensis', 'Aquifoliaceae', SpeciesCategory.herb, fr: 'Thé du Brésil', en: 'Yerba mate', de: 'Mate-Strauch', it: 'Yerba mate'),
    SpeciesCatalogEntry('Neptunia oleracea', 'Fabaceae', SpeciesCategory.vegetable, fr: 'Neptunie potagère', en: 'Water Mimosa', de: 'Wassermimose', it: 'Mimosa d\'acqua'),
    SpeciesCatalogEntry('Panicum miliaceum', 'Poaceae', SpeciesCategory.vegetable, fr: 'Millet commun', en: 'Broomcorn millet', de: 'Rispenhirse', it: 'Miglio'),
    SpeciesCatalogEntry('Phaseolus lunatus', 'Fabaceae', SpeciesCategory.vegetable, fr: 'Haricot de Lima', en: 'Sieva bean', de: 'Limabohne', it: 'Fagiolo di Lima'),
    SpeciesCatalogEntry('Phalaris canariensis', 'Poaceae', SpeciesCategory.vegetable, fr: 'Alpiste', en: 'Annual canarygrass', de: 'Kanariengras', it: 'Scagliola'),
    SpeciesCatalogEntry('Pimenta dioica', 'Myrtaceae', SpeciesCategory.herb, fr: 'Piment de la Jamaïque', en: 'Allspice', de: 'Pimentpflanze', it: 'Pepe della Giamaica'),
    SpeciesCatalogEntry('Pistacia vera', 'Anacardiaceae', SpeciesCategory.fruit, fr: 'Pistachier', en: 'Pistachio', de: 'Pistazie', it: 'Pistacchio'),
    SpeciesCatalogEntry('Sclerocarya birrea', 'Anacardiaceae', SpeciesCategory.fruit, fr: 'Marula', en: 'Marula', de: 'Marula-Baum', it: 'Marula'),
    SpeciesCatalogEntry('Sesamum indicum', 'Pedaliaceae', SpeciesCategory.herb, fr: 'Sésame', en: 'Sesame', de: 'Sesam', it: 'Sesamo'),
    SpeciesCatalogEntry('Theobroma grandiflorum', 'Malvaceae', SpeciesCategory.fruit, fr: 'Cupuaçu', en: 'Copoasu', de: 'Cupuaçu', it: 'Cupuaçu'),
    SpeciesCatalogEntry('Rhus coriaria', 'Anacardiaceae', SpeciesCategory.herb, fr: 'Sumac des corroyeurs', en: 'Sicilian sumac', de: 'Gewürzsumach', it: 'Sommaco'),
    SpeciesCatalogEntry('Vigna angularis', 'Fabaceae', SpeciesCategory.vegetable, fr: 'Haricot azuki', en: 'Adzuki bean', de: 'Adzukibohne', it: 'Azuki'),
    SpeciesCatalogEntry('Vigna radiata', 'Fabaceae', SpeciesCategory.vegetable, fr: 'Haricot mungo', en: 'Mung bean', de: 'Mungbohne', it: 'Fagiolo indiano verde'),
    SpeciesCatalogEntry('Trapa natans', 'Lythraceae', SpeciesCategory.vegetable, fr: 'Mâcre nageante', en: 'Jesuit\'s nut', de: 'Wassernuss', it: 'Castagna d\'acqua'),
    SpeciesCatalogEntry('Vicia sativa', 'Fabaceae', SpeciesCategory.vegetable, fr: 'Vesce commune', en: 'Common Vetch', de: 'Futterwicke', it: 'Veccia'),
    SpeciesCatalogEntry('Ribes aureum', 'Grossulariaceae', SpeciesCategory.fruit, fr: 'Gadellier doré', en: 'Golden currant', de: 'Gold-Johannisbeere'),
    SpeciesCatalogEntry('Ribes alpinum', 'Grossulariaceae', SpeciesCategory.fruit, fr: 'Groseillier des alpes', en: 'Alpine currant', de: 'Alpen-Johannisbeere', it: 'Ribes alpino'),
  ];
}
