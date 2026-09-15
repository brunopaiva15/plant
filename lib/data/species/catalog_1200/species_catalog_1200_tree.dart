import '../../../domain/species/species_info.dart';

/// Ajouts Iris 8 pour le palier 1 200 (arbres et arbustes).
abstract final class SpeciesCatalog1200Tree {
  static const List<SpeciesCatalogEntry> entries = [
    SpeciesCatalogEntry('Aesculus × carnea', 'Sapindaceae', SpeciesCategory.tree, fr: 'Marronnier rouge', en: 'Red horse-chestnut', de: 'Rotblühende Rosskastanie', it: 'Ippocastano rosso'),
    SpeciesCatalogEntry('Apoplanesia paniculata', 'Fabaceae', SpeciesCategory.tree),
    SpeciesCatalogEntry('Aucuba japonica', 'Garryaceae', SpeciesCategory.tree, fr: 'Aucuba du Japon', en: 'Japanese aucuba', de: 'Japanische Aukube', it: 'Aucuba'),
    SpeciesCatalogEntry('Bauhinia variegata', 'Fabaceae', SpeciesCategory.tree, fr: 'Arbre à orchidées', en: 'Orchid tree', de: 'Orchideenbaum', it: 'Albero delle orchidee'),
    SpeciesCatalogEntry('Berberis aquifolium', 'Berberidaceae', SpeciesCategory.tree, fr: 'Mahonia à feuilles de houx', en: 'Oregon grape', de: 'Mahonie', it: 'Mahonia'),
    SpeciesCatalogEntry('Berberis bealei', 'Berberidaceae', SpeciesCategory.tree, fr: 'Mahonia de Beale', en: 'Beale\'s barberry'),
    SpeciesCatalogEntry('Berberis darwinii', 'Berberidaceae', SpeciesCategory.tree, fr: 'Épine-vinette de Darwin', en: 'Darwin\'s barberry', de: 'Darwins Berberitze'),
    SpeciesCatalogEntry('Berberis julianae', 'Berberidaceae', SpeciesCategory.tree, fr: 'Épine-vinette de Julianne', en: 'Chinese barberry', de: 'Julianes Berberitze'),
    SpeciesCatalogEntry('Berberis thunbergii', 'Berberidaceae', SpeciesCategory.tree, fr: 'Berbéris de Thunberg', en: 'Japanese barberry', de: 'Thunberg-Berberitze'),
    SpeciesCatalogEntry('Berberis × hortensis', 'Berberidaceae', SpeciesCategory.tree),
    SpeciesCatalogEntry('Brachychiton acerifolius', 'Malvaceae', SpeciesCategory.tree, fr: 'Brachychiton à feuilles d\'érable', en: 'Illawarra Flame Tree'),
    SpeciesCatalogEntry('Brachychiton populneus', 'Malvaceae', SpeciesCategory.tree, fr: 'Brachychiton à feuilles de peuplier', en: 'Kurrajong', de: 'Pappelblättriger Brachychiton'),
    SpeciesCatalogEntry('Broussonetia papyrifera', 'Moraceae', SpeciesCategory.tree, fr: 'Mûrier à papier', en: 'Paper mulberry', de: 'Papiermaulbeerbaum', it: 'Gelso da carta'),
    SpeciesCatalogEntry('Buddleja davidii', 'Scrophulariaceae', SpeciesCategory.tree, fr: 'Buddleia de David', en: 'Butterfly-bush', de: 'Schmetterlingsflieder'),
    SpeciesCatalogEntry('Callicarpa dichotoma', 'Lamiaceae', SpeciesCategory.tree, fr: 'Arbre aux bonbons', en: 'Early Amethyst'),
    SpeciesCatalogEntry('Cananga odorata', 'Annonaceae', SpeciesCategory.tree, fr: 'Ylang-ylang', en: 'Ylang-ylang tree', de: 'Ylang-Ylang', it: 'Ylang ylang'),
    SpeciesCatalogEntry('Caragana arborescens', 'Fabaceae', SpeciesCategory.tree, fr: 'Caraganier de Sibérie', en: 'Siberian peashrub', de: 'Gemeiner Erbsenstrauch'),
    SpeciesCatalogEntry('Clerodendrum trichotomum', 'Lamiaceae', SpeciesCategory.tree, fr: 'Arbre du clergé', en: 'Harlequin gataxon comlorybower'),
    SpeciesCatalogEntry('Colutea arborescens', 'Fabaceae', SpeciesCategory.tree, fr: 'Baguenaudier', en: 'Bladder senna', de: 'Gelber Blasenstrauch', it: 'Vescicaria'),
    SpeciesCatalogEntry('Corypha umbraculifera', 'Arecaceae', SpeciesCategory.tree, fr: 'Tallipot', en: 'Talipot palm', de: 'Talipot-Palme', it: 'Palma talipot'),
    SpeciesCatalogEntry('Cotoneaster × suecicus', 'Rosaceae', SpeciesCategory.tree, fr: 'Cotonéaster de Suède'),
    SpeciesCatalogEntry('Cupressus × leylandii', 'Cupressaceae', SpeciesCategory.tree, fr: 'Cyprès de Leyland', en: 'Leyland cypress', de: 'Leyland-Zypresse', it: 'Cipresso di Leyland'),
    SpeciesCatalogEntry('Cybistax antisyphilitica', 'Bignoniaceae', SpeciesCategory.tree, fr: 'Yangua tinctoria', en: 'Yangua tinctoria', de: 'Yangua tinctoria', it: 'Yangua tinctoria'),
    SpeciesCatalogEntry('Dasiphora fruticosa', 'Rosaceae', SpeciesCategory.tree, fr: 'Potentille arbustive', en: 'Shrubby Cinquefoil', de: 'Fingerstrauch'),
    SpeciesCatalogEntry('Davidia involucrata', 'Nyssaceae', SpeciesCategory.tree, fr: 'Arbre aux mouchoirs', en: 'Dove-tree', de: 'Taschentuchbaum'),
    SpeciesCatalogEntry('Deutzia scabra', 'Hydrangeaceae', SpeciesCategory.tree, fr: 'Deutzie rugueuse', en: 'Fuzzy pride-of-Rochester', de: 'Raue Deutzie'),
    SpeciesCatalogEntry('Duranta erecta', 'Verbenaceae', SpeciesCategory.tree, fr: 'Vanillier de Cayenne', en: 'Pigeon Berry'),
    SpeciesCatalogEntry('Edgeworthia chrysantha', 'Thymelaeaceae', SpeciesCategory.tree, fr: 'Buisson à papier', en: 'Oriental paperbush', de: 'Mitsumata', it: 'Arbusto della carta'),
    SpeciesCatalogEntry('Elaeagnus angustifolia', 'Elaeagnaceae', SpeciesCategory.tree, fr: 'Olivier de Bohême', en: 'Oleaster', de: 'Schmalblättrige Ölweide'),
    SpeciesCatalogEntry('Elaeagnus pungens', 'Elaeagnaceae', SpeciesCategory.tree, fr: 'Chalef piquant', en: 'Thorny olive', de: 'Dornige Ölweide'),
    SpeciesCatalogEntry('Elaeis guineensis', 'Arecaceae', SpeciesCategory.tree, fr: 'Palmier à huile', en: 'African Oil Palm', de: 'Ölpalme', it: 'Palma da olio'),
  ];
}
