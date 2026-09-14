/// Noms communs des genres, pour les cas où le modèle reconnaît le genre
/// sans trancher l'espèce.
///
/// « Un érable, espèce incertaine » se comprend ; « *Acer*, espèce
/// incertaine » beaucoup moins. Mais tous les genres n'ont pas de nom
/// commun, et en inventer un serait pire que de n'en pas donner : ceux qui
/// manquent ici s'affichent sous leur nom scientifique, comme le fait
/// iNaturalist pour un taxon sans nom vernaculaire.
///
/// La liste ne vise pas l'exhaustivité. Sur les 808 genres du modèle livré,
/// 260 comptent plusieurs espèces — les seuls qui puissent répondre — et la
/// charge se concentre : 47 en ont cinq ou plus. Ce sont eux qui répondront
/// le plus souvent, et ce sont eux qui sont nommés ici.
///
/// Au singulier, et sans article : c'est un nom, pas une phrase.
abstract final class GenusCatalog {
  /// Genre capitalisé → nom commun par langue.
  static const Map<String, Map<String, String>> names = {
    // ── Arbres et arbustes ────────────────────────────────────────────────
    'Abies': {'fr': 'Sapin', 'en': 'Fir', 'de': 'Tanne', 'it': 'Abete'},
    'Acer': {'fr': 'Érable', 'en': 'Maple', 'de': 'Ahorn', 'it': 'Acero'},
    'Alnus': {'fr': 'Aulne', 'en': 'Alder', 'de': 'Erle', 'it': 'Ontano'},
    'Berberis': {'fr': 'Épine-vinette', 'en': 'Barberry', 'de': 'Berberitze', 'it': 'Crespino'},
    'Cornus': {'fr': 'Cornouiller', 'en': 'Dogwood', 'de': 'Hartriegel', 'it': 'Corniolo'},
    'Cotoneaster': {'fr': 'Cotonéaster', 'en': 'Cotoneaster', 'de': 'Zwergmispel', 'it': 'Cotognastro'},
    'Crataegus': {'fr': 'Aubépine', 'en': 'Hawthorn', 'de': 'Weißdorn', 'it': 'Biancospino'},
    'Fraxinus': {'fr': 'Frêne', 'en': 'Ash', 'de': 'Esche', 'it': 'Frassino'},
    'Juniperus': {'fr': 'Genévrier', 'en': 'Juniper', 'de': 'Wacholder', 'it': 'Ginepro'},
    'Ligustrum': {'fr': 'Troène', 'en': 'Privet', 'de': 'Liguster', 'it': 'Ligustro'},
    'Lonicera': {'fr': 'Chèvrefeuille', 'en': 'Honeysuckle', 'de': 'Heckenkirsche', 'it': 'Caprifoglio'},
    'Magnolia': {'fr': 'Magnolia', 'en': 'Magnolia', 'de': 'Magnolie', 'it': 'Magnolia'},
    'Picea': {'fr': 'Épicéa', 'en': 'Spruce', 'de': 'Fichte', 'it': 'Abete rosso'},
    'Pinus': {'fr': 'Pin', 'en': 'Pine', 'de': 'Kiefer', 'it': 'Pino'},
    'Prunus': {'fr': 'Prunus', 'en': 'Cherry or plum', 'de': 'Prunus', 'it': 'Prunus'},
    'Quercus': {'fr': 'Chêne', 'en': 'Oak', 'de': 'Eiche', 'it': 'Quercia'},
    'Rhododendron': {'fr': 'Rhododendron', 'en': 'Rhododendron', 'de': 'Rhododendron', 'it': 'Rododendro'},
    'Ribes': {'fr': 'Groseillier', 'en': 'Currant', 'de': 'Johannisbeere', 'it': 'Ribes'},
    'Rubus': {'fr': 'Ronce', 'en': 'Bramble', 'de': 'Brombeere', 'it': 'Rovo'},
    'Salix': {'fr': 'Saule', 'en': 'Willow', 'de': 'Weide', 'it': 'Salice'},
    'Spiraea': {'fr': 'Spirée', 'en': 'Spiraea', 'de': 'Spierstrauch', 'it': 'Spirea'},
    'Tilia': {'fr': 'Tilleul', 'en': 'Lime tree', 'de': 'Linde', 'it': 'Tiglio'},
    'Ulmus': {'fr': 'Orme', 'en': 'Elm', 'de': 'Ulme', 'it': 'Olmo'},
    'Viburnum': {'fr': 'Viorne', 'en': 'Viburnum', 'de': 'Schneeball', 'it': 'Viburno'},

    // ── Fruitiers et potager ──────────────────────────────────────────────
    'Allium': {'fr': 'Ail ou oignon', 'en': 'Onion or garlic', 'de': 'Lauch', 'it': 'Aglio o cipolla'},
    'Citrus': {'fr': 'Agrume', 'en': 'Citrus', 'de': 'Zitruspflanze', 'it': 'Agrume'},
    'Solanum': {'fr': 'Solanum', 'en': 'Nightshade', 'de': 'Nachtschatten', 'it': 'Solano'},

    // ── Fleurs et vivaces ─────────────────────────────────────────────────
    'Campanula': {'fr': 'Campanule', 'en': 'Bellflower', 'de': 'Glockenblume', 'it': 'Campanula'},
    'Centaurea': {'fr': 'Centaurée', 'en': 'Knapweed', 'de': 'Flockenblume', 'it': 'Fiordaliso'},
    'Clematis': {'fr': 'Clématite', 'en': 'Clematis', 'de': 'Waldrebe', 'it': 'Clematide'},
    'Epipactis': {'fr': 'Épipactis', 'en': 'Helleborine', 'de': 'Stendelwurz', 'it': 'Elleborina'},
    'Geranium': {'fr': 'Géranium vivace', 'en': 'Cranesbill', 'de': 'Storchschnabel', 'it': 'Geranio'},
    'Hydrangea': {'fr': 'Hortensia', 'en': 'Hydrangea', 'de': 'Hortensie', 'it': 'Ortensia'},
    'Iris': {'fr': 'Iris', 'en': 'Iris', 'de': 'Schwertlilie', 'it': 'Iris'},
    'Lathyrus': {'fr': 'Gesse', 'en': 'Pea', 'de': 'Platterbse', 'it': 'Cicerchia'},
    'Paeonia': {'fr': 'Pivoine', 'en': 'Peony', 'de': 'Pfingstrose', 'it': 'Peonia'},
    'Pelargonium': {'fr': 'Pélargonium', 'en': 'Pelargonium', 'de': 'Pelargonie', 'it': 'Pelargonio'},
    'Potentilla': {'fr': 'Potentille', 'en': 'Cinquefoil', 'de': 'Fingerkraut', 'it': 'Potentilla'},
    'Ranunculus': {'fr': 'Renoncule', 'en': 'Buttercup', 'de': 'Hahnenfuß', 'it': 'Ranuncolo'},
    'Rosa': {'fr': 'Rosier', 'en': 'Rose', 'de': 'Rose', 'it': 'Rosa'},
    'Salvia': {'fr': 'Sauge', 'en': 'Sage', 'de': 'Salbei', 'it': 'Salvia'},

    // ── Succulentes ───────────────────────────────────────────────────────
    'Euphorbia': {'fr': 'Euphorbe', 'en': 'Spurge', 'de': 'Wolfsmilch', 'it': 'Euforbia'},
    'Kalanchoe': {'fr': 'Kalanchoé', 'en': 'Kalanchoe', 'de': 'Kalanchoe', 'it': 'Calancola'},
    'Sedum': {'fr': 'Orpin', 'en': 'Stonecrop', 'de': 'Fetthenne', 'it': 'Borracina'},

    // ── Intérieur ─────────────────────────────────────────────────────────
    'Dracaena': {'fr': 'Dracaena', 'en': 'Dracaena', 'de': 'Drachenbaum', 'it': 'Dracena'},
    'Ficus': {'fr': 'Ficus', 'en': 'Fig', 'de': 'Feige', 'it': 'Ficus'},

    // ── Fougères ──────────────────────────────────────────────────────────
    'Asplenium': {'fr': 'Doradille', 'en': 'Spleenwort', 'de': 'Streifenfarn', 'it': 'Asplenio'},
  };

  /// Le nom commun du genre dans la langue demandée, `null` s'il n'y en a
  /// pas — auquel cas le nom scientifique fait l'affaire, et ne ment pas.
  static String? commonName(String genus, String languageCode) {
    final entry = names[genus];
    if (entry == null) return null;
    final name = entry[languageCode] ?? entry['en'];
    return (name == null || name.isEmpty) ? null : name;
  }
}
