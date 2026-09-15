import '../../../domain/species/species_info.dart';

/// Arbres ajoutés pour le palier 650, tous présents dans Iris 8.
abstract final class SpeciesCatalog650Tree {
  static const List<SpeciesCatalogEntry> entries = [
    SpeciesCatalogEntry('Abies alba', 'Pinaceae', SpeciesCategory.tree, fr: 'Sapin blanc', en: 'Silver fir', de: 'Weiß-Tanne', it: 'Abete bianco'),
    SpeciesCatalogEntry('Abies concolor', 'Pinaceae', SpeciesCategory.tree, fr: 'Sapin du Colorado', en: 'White fir', de: 'Colorado-Tanne', it: 'Abete del Colorado'),
    SpeciesCatalogEntry('Abies koreana', 'Pinaceae', SpeciesCategory.tree, fr: 'Sapin de Corée', en: 'Korean fir', de: 'Korea-Tanne', it: 'Abete coreano'),
    SpeciesCatalogEntry('Abies pinsapo', 'Pinaceae', SpeciesCategory.tree, fr: 'Sapin d\'Espagne', en: 'Spanish fir', de: 'Spanische Tanne', it: 'Abete di Spagna'),
    SpeciesCatalogEntry('Acer ginnala', 'Sapindaceae', SpeciesCategory.tree, fr: 'Érable de l\'Amour', en: 'Amur maple', de: 'Amur-Ahorn', it: 'Acero dell\'Amur'),
    SpeciesCatalogEntry('Acer griseum', 'Sapindaceae', SpeciesCategory.tree, fr: 'Érable à écorce de papier', en: 'Paperbark maple', de: 'Zimt-Ahorn', it: 'Acero grigio'),
    SpeciesCatalogEntry('Acer rubrum', 'Sapindaceae', SpeciesCategory.tree, fr: 'Érable rouge', en: 'Red maple', de: 'Rot-Ahorn', it: 'Acero rosso'),
    SpeciesCatalogEntry('Acer saccharum', 'Sapindaceae', SpeciesCategory.tree, fr: 'Érable à sucre', en: 'Sugar maple', de: 'Zucker-Ahorn', it: 'Acero da zucchero'),
    SpeciesCatalogEntry('Acacia dealbata', 'Fabaceae', SpeciesCategory.tree, fr: 'Mimosa d\'hiver', en: 'Silver wattle', de: 'Silber-Akazie', it: 'Mimosa'),
    SpeciesCatalogEntry('Ailanthus altissima', 'Simaroubaceae', SpeciesCategory.tree, fr: 'Ailante', en: 'Tree of heaven', de: 'Götterbaum', it: 'Ailanto'),
    SpeciesCatalogEntry('Albizia julibrissin', 'Fabaceae', SpeciesCategory.tree, fr: 'Arbre à soie', en: 'Persian silk tree', de: 'Seidenbaum', it: 'Albero della seta'),
    SpeciesCatalogEntry('Alnus incana', 'Betulaceae', SpeciesCategory.tree, fr: 'Aulne blanc', en: 'Grey alder', de: 'Grau-Erle', it: 'Ontano bianco'),
    SpeciesCatalogEntry('Araucaria araucana', 'Araucariaceae', SpeciesCategory.tree, fr: 'Désespoir des singes', en: 'Monkey puzzle tree', de: 'Andentanne', it: 'Araucaria del Cile'),
    SpeciesCatalogEntry('Aesculus hippocastanum', 'Sapindaceae', SpeciesCategory.tree, fr: 'Marronnier d\'Inde', en: 'Horse chestnut', de: 'Rosskastanie', it: 'Ippocastano'),
    SpeciesCatalogEntry('Calocedrus decurrens', 'Cupressaceae', SpeciesCategory.tree, fr: 'Calocèdre', en: 'Incense cedar', de: 'Weihrauchzeder', it: 'Cedro dell\'incenso'),
    SpeciesCatalogEntry('Catalpa bignonioides', 'Bignoniaceae', SpeciesCategory.tree, fr: 'Catalpa commun', en: 'Southern catalpa', de: 'Trompetenbaum', it: 'Catalpa'),
    SpeciesCatalogEntry('Cedrus atlantica', 'Pinaceae', SpeciesCategory.tree, fr: 'Cèdre de l\'Atlas', en: 'Atlas cedar', de: 'Atlas-Zeder', it: 'Cedro dell\'Atlante'),
    SpeciesCatalogEntry('Cedrus deodara', 'Pinaceae', SpeciesCategory.tree, fr: 'Cèdre de l\'Himalaya', en: 'Deodar cedar', de: 'Himalaya-Zeder', it: 'Cedro deodara'),
    SpeciesCatalogEntry('Cedrus libani', 'Pinaceae', SpeciesCategory.tree, fr: 'Cèdre du Liban', en: 'Cedar of Lebanon', de: 'Libanon-Zeder', it: 'Cedro del Libano'),
    SpeciesCatalogEntry('Celtis australis', 'Cannabaceae', SpeciesCategory.tree, fr: 'Micocoulier de Provence', en: 'European nettle tree', de: 'Südlicher Zürgelbaum', it: 'Bagolaro'),
    SpeciesCatalogEntry('Cercis siliquastrum', 'Fabaceae', SpeciesCategory.tree, fr: 'Arbre de Judée', en: 'Judas tree', de: 'Judasbaum', it: 'Albero di Giuda'),
    SpeciesCatalogEntry('Chamaecyparis lawsoniana', 'Cupressaceae', SpeciesCategory.tree, fr: 'Cyprès de Lawson', en: 'Lawson cypress', de: 'Lawson-Scheinzypresse', it: 'Cipresso di Lawson'),
    SpeciesCatalogEntry('Chamaecyparis obtusa', 'Cupressaceae', SpeciesCategory.tree, fr: 'Cyprès hinoki', en: 'Hinoki cypress', de: 'Hinoki-Scheinzypresse', it: 'Cipresso hinoki'),
    SpeciesCatalogEntry('Cornus kousa', 'Cornaceae', SpeciesCategory.tree, fr: 'Cornouiller du Japon', en: 'Kousa dogwood', de: 'Japanischer Blumen-Hartriegel', it: 'Corniolo giapponese'),
    SpeciesCatalogEntry('Corylus colurna', 'Betulaceae', SpeciesCategory.tree, fr: 'Noisetier de Byzance', en: 'Turkish hazel', de: 'Baum-Hasel', it: 'Nocciolo turco'),
    SpeciesCatalogEntry('Cryptomeria japonica', 'Cupressaceae', SpeciesCategory.tree, fr: 'Cèdre du Japon', en: 'Japanese cedar', de: 'Sicheltanne', it: 'Criptomeria'),
    SpeciesCatalogEntry('Cupressus macrocarpa', 'Cupressaceae', SpeciesCategory.tree, fr: 'Cyprès de Monterey', en: 'Monterey cypress', de: 'Monterey-Zypresse', it: 'Cipresso di Monterey'),
    SpeciesCatalogEntry('Larix kaempferi', 'Pinaceae', SpeciesCategory.tree, fr: 'Mélèze du Japon', en: 'Japanese larch', de: 'Japanische Lärche', it: 'Larice giapponese'),
    SpeciesCatalogEntry('Liquidambar styraciflua', 'Altingiaceae', SpeciesCategory.tree, fr: 'Copalme d\'Amérique', en: 'Sweetgum', de: 'Amberbaum', it: 'Liquidambar'),
    SpeciesCatalogEntry('Metasequoia glyptostroboides', 'Cupressaceae', SpeciesCategory.tree, fr: 'Métaséquoia', en: 'Dawn redwood', de: 'Urweltmammutbaum', it: 'Metasequoia'),
  ];
}
