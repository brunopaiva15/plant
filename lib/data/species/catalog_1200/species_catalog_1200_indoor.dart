import '../../../domain/species/species_info.dart';

/// Ajouts Iris 8 pour le palier 1 200 (plantes d'intérieur et fougères).
abstract final class SpeciesCatalog1200Indoor {
  static const List<SpeciesCatalogEntry> entries = [
    SpeciesCatalogEntry('Adiantum capillus-veneris', 'Pteridaceae', SpeciesCategory.indoor, fr: 'Capillaire de Montpellier', en: 'Common maidenhair fern', de: 'Frauenhaarfarn'),
    SpeciesCatalogEntry('Asparagus aethiopicus', 'Asparagaceae', SpeciesCategory.indoor, fr: 'Asperge de Sprenger', en: 'Sprenger\'s asparagus', de: 'Sprenger-Spargel'),
    SpeciesCatalogEntry('Asparagus densiflorus', 'Asparagaceae', SpeciesCategory.indoor, fr: 'Asperge ornementale', en: 'Cwebe asparagus fern', de: 'Zier-Spargel'),
    SpeciesCatalogEntry('Asparagus setaceus', 'Asparagaceae', SpeciesCategory.indoor, fr: 'Asperge plumeuse', en: 'Common asparagus fern', de: 'Feder-Spargel'),
    SpeciesCatalogEntry('Asplenium ruta-muraria', 'Aspleniaceae', SpeciesCategory.indoor, fr: 'Rue des murailles', en: 'Wall-rue', de: 'Mauerraute', it: 'Ruta di muro'),
    SpeciesCatalogEntry('Asplenium scolopendrium', 'Aspleniaceae', SpeciesCategory.indoor, fr: 'Scolopendre', en: 'Hart\'s tonguefern', de: 'Hirschzungenfarn'),
    SpeciesCatalogEntry('Asplenium septentrionale', 'Aspleniaceae', SpeciesCategory.indoor, fr: 'Doradille du nord', en: 'Forked spleenwort', de: 'Nordischer Streifenfarn', it: 'Asplenio settentrionale'),
    SpeciesCatalogEntry('Asplenium trichomanes', 'Aspleniaceae', SpeciesCategory.indoor, fr: 'Fausse capillaire', en: 'Maidenhair Spleenwort', de: 'Braunstieliger Streifenfarn', it: 'Asplenio'),
    SpeciesCatalogEntry('Cyperus alternifolius', 'Cyperaceae', SpeciesCategory.indoor, fr: 'Faux papyrus', en: 'Umbrella papyrus', de: 'Zyperngras', it: 'Falso papiro'),
    SpeciesCatalogEntry('Dicksonia antarctica', 'Dicksoniaceae', SpeciesCategory.indoor, fr: 'Fougère arborescente', en: 'Soft Tree-fern', de: 'Australischer Baumfarn', it: 'Felce arborea'),
    SpeciesCatalogEntry('Dionaea muscipula', 'Droseraceae', SpeciesCategory.indoor, fr: 'Dionée attrape-mouche', en: 'Venus flytrap', de: 'Venusfliegenfalle', it: 'Dionea'),
    SpeciesCatalogEntry('Dryopteris carthusiana', 'Dryopteridaceae', SpeciesCategory.indoor, fr: 'Dryoptéris des chartreux', en: 'Narrow buckler-fern', de: 'Gewöhnlicher Dornfarn', it: 'Felce a scudo stretto'),
    SpeciesCatalogEntry('Dryopteris filix-mas', 'Dryopteridaceae', SpeciesCategory.indoor, fr: 'Fougère mâle', en: 'Male fern', de: 'Echter Wurmfarn', it: 'Felce maschio'),
    SpeciesCatalogEntry('Dryopteris tavelii', 'Dryopteridaceae', SpeciesCategory.indoor),
    SpeciesCatalogEntry('Encephalartos altensteinii', 'Zamiaceae', SpeciesCategory.indoor, en: 'Breadtree'),
    SpeciesCatalogEntry('Encephalartos villosus', 'Zamiaceae', SpeciesCategory.indoor, en: 'Ground Cycad'),
  ];
}
