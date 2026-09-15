import '../../domain/species/species_info.dart';

/// Extension du catalogue curaté : 50 espèces validées taxonomiquement
/// avant intégration, réparties entre les grandes catégories de l'app.
abstract final class SpeciesCatalogExpansion {
  static const List<SpeciesCatalogEntry> entries = [
    // ── Plantes d'intérieur ───────────────────────────────────────────────
    SpeciesCatalogEntry('Monstera obliqua', 'Araceae', SpeciesCategory.indoor, fr: 'Monstera obliqua', en: 'Window-leaf monstera', de: 'Löchriges Fensterblatt', it: 'Monstera obliqua'),
    SpeciesCatalogEntry('Monstera standleyana', 'Araceae', SpeciesCategory.indoor, fr: 'Monstera standleyana', en: 'Monstera standleyana', de: 'Monstera standleyana', it: 'Monstera standleyana'),
    SpeciesCatalogEntry('Rhaphidophora tetrasperma', 'Araceae', SpeciesCategory.indoor, fr: 'Mini monstera', en: 'Mini monstera', de: 'Mini-Monstera', it: 'Mini monstera'),
    SpeciesCatalogEntry('Rhaphidophora decursiva', 'Araceae', SpeciesCategory.indoor, fr: 'Rhaphidophora decursiva', en: 'Rhaphidophora decursiva', de: 'Rhaphidophora decursiva', it: 'Rhaphidophora decursiva'),
    SpeciesCatalogEntry('Anthurium warocqueanum', 'Araceae', SpeciesCategory.indoor, fr: 'Anthurium reine', en: 'Queen anthurium', de: 'Königin-Anthurie', it: 'Anthurium regina'),
    SpeciesCatalogEntry('Anthurium forgetii', 'Araceae', SpeciesCategory.indoor, fr: 'Anthurium forgetii', en: 'Anthurium forgetii', de: 'Anthurium forgetii', it: 'Anthurium forgetii'),
    SpeciesCatalogEntry('Alocasia odora', 'Araceae', SpeciesCategory.indoor, fr: 'Alocasia odorant', en: 'Asian taro', de: 'Duftende Alokasie', it: 'Alocasia odorosa'),
    SpeciesCatalogEntry('Syngonium angustatum', 'Araceae', SpeciesCategory.indoor, fr: 'Syngonium étroit', en: 'Five-fingers plant', de: 'Fünffinger-Syngonium', it: 'Singonio a foglie strette'),
    SpeciesCatalogEntry('Peperomia clusiifolia', 'Piperaceae', SpeciesCategory.indoor, fr: 'Pépéromia à feuilles de Clusia', en: 'Red-edge peperomia', de: 'Rotrand-Peperomie', it: 'Peperomia a margine rosso'),
    SpeciesCatalogEntry('Peperomia graveolens', 'Piperaceae', SpeciesCategory.indoor, fr: 'Pépéromia Ruby Glow', en: 'Ruby glow peperomia', de: 'Ruby-Glow-Peperomie', it: 'Peperomia Ruby Glow'),
    SpeciesCatalogEntry('Hoya multiflora', 'Apocynaceae', SpeciesCategory.indoor, fr: 'Hoya multiflora', en: 'Shooting star hoya', de: 'Vielblütige Wachsblume', it: 'Hoya multiflora'),
    SpeciesCatalogEntry('Hoya curtisii', 'Apocynaceae', SpeciesCategory.indoor, fr: 'Hoya curtisii', en: 'Hoya curtisii', de: 'Hoya curtisii', it: 'Hoya curtisii'),
    SpeciesCatalogEntry('Begonia cucullata', 'Begoniaceae', SpeciesCategory.indoor, fr: 'Bégonia cucullata', en: 'Wax begonia', de: 'Wachs-Begonie', it: 'Begonia cucullata'),
    SpeciesCatalogEntry('Goeppertia roseopicta', 'Marantaceae', SpeciesCategory.indoor, fr: 'Calathea roseopicta', en: 'Rose-painted calathea', de: 'Roseopicta-Korbmarante', it: 'Calathea roseopicta'),
    SpeciesCatalogEntry('Goeppertia zebrina', 'Marantaceae', SpeciesCategory.indoor, fr: 'Calathea zébrée', en: 'Zebra plant', de: 'Zebra-Korbmarante', it: 'Calathea zebrina'),

    // ── Succulentes et cactus ─────────────────────────────────────────────
    SpeciesCatalogEntry('Aloe arborescens', 'Asphodelaceae', SpeciesCategory.succulent, fr: 'Aloé arborescent', en: 'Torch aloe', de: 'Baum-Aloe', it: 'Aloe arborescente'),
    SpeciesCatalogEntry('Haworthia cooperi', 'Asphodelaceae', SpeciesCategory.succulent, fr: 'Haworthia de Cooper', en: "Cooper's haworthia", de: 'Cooper-Haworthie', it: 'Haworthia di Cooper'),
    SpeciesCatalogEntry('Haworthiopsis fasciata', 'Asphodelaceae', SpeciesCategory.succulent, fr: 'Haworthia fasciata', en: 'Zebra haworthia', de: 'Zebra-Haworthie', it: 'Haworthia fasciata'),
    SpeciesCatalogEntry('Crassula perforata', 'Crassulaceae', SpeciesCategory.succulent, fr: 'Collier de boutons', en: 'String of buttons', de: 'Knopf-Crassula', it: 'Collana di bottoni'),
    SpeciesCatalogEntry('Kalanchoe tomentosa', 'Crassulaceae', SpeciesCategory.succulent, fr: 'Plante panda', en: 'Panda plant', de: 'Pandapflanze', it: 'Pianta panda'),
    SpeciesCatalogEntry('Echeveria agavoides', 'Crassulaceae', SpeciesCategory.succulent, fr: 'Echeveria agavoides', en: 'Lipstick echeveria', de: 'Agaven-Echeverie', it: 'Echeveria agavoides'),
    SpeciesCatalogEntry('Sedum × rubrotinctum', 'Crassulaceae', SpeciesCategory.succulent, fr: 'Orpin haricot', en: 'Jelly bean plant', de: 'Ampel-Fetthenne', it: 'Sedum fagiolini'),
    SpeciesCatalogEntry('Pachyphytum oviferum', 'Crassulaceae', SpeciesCategory.succulent, fr: 'Plante pierre de lune', en: 'Moonstones', de: 'Mondstein-Sukkulente', it: 'Pietre di luna'),
    SpeciesCatalogEntry('Agave attenuata', 'Asparagaceae', SpeciesCategory.succulent, fr: 'Agave à cou de cygne', en: 'Foxtail agave', de: 'Schwanenhals-Agave', it: 'Agave attenuata'),
    SpeciesCatalogEntry('Opuntia microdasys', 'Cactaceae', SpeciesCategory.succulent, fr: 'Oreilles de lapin', en: 'Bunny ears cactus', de: 'Hasenohrenkaktus', it: 'Cactus orecchie di coniglio'),

    // ── Aromatiques et potager ────────────────────────────────────────────
    SpeciesCatalogEntry('Ocimum tenuiflorum', 'Lamiaceae', SpeciesCategory.herb, fr: 'Basilic sacré', en: 'Holy basil', de: 'Heiliges Basilikum', it: 'Basilico sacro'),
    SpeciesCatalogEntry('Allium ursinum', 'Amaryllidaceae', SpeciesCategory.herb, fr: 'Ail des ours', en: 'Wild garlic', de: 'Bärlauch', it: 'Aglio orsino'),
    SpeciesCatalogEntry('Borago officinalis', 'Boraginaceae', SpeciesCategory.herb, fr: 'Bourrache', en: 'Borage', de: 'Borretsch', it: 'Borragine'),
    SpeciesCatalogEntry('Ipomoea batatas', 'Convolvulaceae', SpeciesCategory.vegetable, fr: 'Patate douce', en: 'Sweet potato', de: 'Süßkartoffel', it: 'Patata dolce'),
    SpeciesCatalogEntry('Cucurbita moschata', 'Cucurbitaceae', SpeciesCategory.vegetable, fr: 'Courge musquée', en: 'Butternut squash', de: 'Moschus-Kürbis', it: 'Zucca moscata'),

    // ── Fruitiers ─────────────────────────────────────────────────────────
    SpeciesCatalogEntry('Psidium guajava', 'Myrtaceae', SpeciesCategory.fruit, fr: 'Goyavier', en: 'Guava', de: 'Guave', it: 'Guava'),
    SpeciesCatalogEntry('Carica papaya', 'Caricaceae', SpeciesCategory.fruit, fr: 'Papayer', en: 'Papaya', de: 'Papaya', it: 'Papaya'),
    SpeciesCatalogEntry('Ananas comosus', 'Bromeliaceae', SpeciesCategory.fruit, fr: 'Ananas', en: 'Pineapple', de: 'Ananas', it: 'Ananas'),
    SpeciesCatalogEntry('Morus alba', 'Moraceae', SpeciesCategory.fruit, fr: 'Mûrier blanc', en: 'White mulberry', de: 'Weißer Maulbeerbaum', it: 'Gelso bianco'),
    SpeciesCatalogEntry('Actinidia arguta', 'Actinidiaceae', SpeciesCategory.fruit, fr: 'Kiwi de Sibérie', en: 'Hardy kiwi', de: 'Mini-Kiwi', it: 'Kiwi siberiano'),

    // ── Fleurs ────────────────────────────────────────────────────────────
    SpeciesCatalogEntry('Hydrangea paniculata', 'Hydrangeaceae', SpeciesCategory.flower, fr: 'Hortensia paniculé', en: 'Panicle hydrangea', de: 'Rispenhortensie', it: 'Ortensia paniculata'),
    SpeciesCatalogEntry('Rosa rugosa', 'Rosaceae', SpeciesCategory.flower, fr: 'Rosier rugueux', en: 'Rugosa rose', de: 'Kartoffel-Rose', it: 'Rosa rugosa'),
    SpeciesCatalogEntry('Viola tricolor', 'Violaceae', SpeciesCategory.flower, fr: 'Pensée sauvage', en: 'Wild pansy', de: 'Wildes Stiefmütterchen', it: 'Viola tricolore'),
    SpeciesCatalogEntry('Iris sibirica', 'Iridaceae', SpeciesCategory.flower, fr: 'Iris de Sibérie', en: 'Siberian iris', de: 'Sibirische Schwertlilie', it: 'Iris sibirica'),
    SpeciesCatalogEntry('Crocus sativus', 'Iridaceae', SpeciesCategory.flower, fr: 'Crocus à safran', en: 'Saffron crocus', de: 'Safran-Krokus', it: 'Croco da zafferano'),
    SpeciesCatalogEntry('Lilium martagon', 'Liliaceae', SpeciesCategory.flower, fr: 'Lis martagon', en: 'Martagon lily', de: 'Türkenbund-Lilie', it: 'Giglio martagone'),
    SpeciesCatalogEntry('Muscari armeniacum', 'Asparagaceae', SpeciesCategory.flower, fr: "Muscari d'Arménie", en: 'Grape hyacinth', de: 'Armenische Traubenhyazinthe', it: 'Muscari armeno'),
    SpeciesCatalogEntry('Cosmos sulphureus', 'Asteraceae', SpeciesCategory.flower, fr: 'Cosmos sulfureux', en: 'Sulphur cosmos', de: 'Schwefel-Kosmee', it: 'Cosmea sulfurea'),
    SpeciesCatalogEntry('Verbena bonariensis', 'Verbenaceae', SpeciesCategory.flower, fr: 'Verveine de Buenos Aires', en: 'Purpletop vervain', de: 'Patagonisches Eisenkraut', it: 'Verbena bonariensis'),
    SpeciesCatalogEntry('Passiflora caerulea', 'Passifloraceae', SpeciesCategory.flower, fr: 'Passiflore bleue', en: 'Blue passionflower', de: 'Blaue Passionsblume', it: 'Passiflora azzurra'),

    // ── Arbres ────────────────────────────────────────────────────────────
    SpeciesCatalogEntry('Acer pseudoplatanus', 'Sapindaceae', SpeciesCategory.tree, fr: 'Érable sycomore', en: 'Sycamore maple', de: 'Berg-Ahorn', it: 'Acero di monte'),
    SpeciesCatalogEntry('Carpinus betulus', 'Betulaceae', SpeciesCategory.tree, fr: 'Charme commun', en: 'European hornbeam', de: 'Hainbuche', it: 'Carpino bianco'),
    SpeciesCatalogEntry('Fraxinus excelsior', 'Oleaceae', SpeciesCategory.tree, fr: 'Frêne commun', en: 'European ash', de: 'Gemeine Esche', it: 'Frassino maggiore'),
    SpeciesCatalogEntry('Larix decidua', 'Pinaceae', SpeciesCategory.tree, fr: "Mélèze d'Europe", en: 'European larch', de: 'Europäische Lärche', it: 'Larice europeo'),
    SpeciesCatalogEntry('Taxus baccata', 'Taxaceae', SpeciesCategory.tree, fr: 'If commun', en: 'European yew', de: 'Europäische Eibe', it: 'Tasso comune'),
  ];
}
