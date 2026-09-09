import '../../core/utils/search_text.dart';

/// Une espèce candidate lors de la saisie (suggestion GBIF).
class SpeciesSuggestion {
  const SpeciesSuggestion({required this.key, required this.scientificName, this.family, this.commonName});

  final int key;
  final String scientificName;
  final String? family;
  final String? commonName;
}

/// Une image d'observation, avec attribution (licence, auteur).
class SpeciesImage {
  const SpeciesImage({required this.url, this.license, this.rightsHolder, this.country});

  final String url;
  final String? license;
  final String? rightsHolder;
  final String? country;

  /// Les termes Creative Commons de la photo, réduits à leur code : « by »,
  /// « by-sa », « by-nc », ou « 0 » pour le domaine public. GBIF les donne
  /// par une URL, Pl@ntNet en clair (« cc-by-sa ») ; `null` quand la source
  /// n'a rien dit, ou nomme autre chose qu'une licence Creative Commons.
  String? get _terms {
    final l = license?.trim().toLowerCase();
    if (l == null || l.isEmpty) return null;
    if (l.contains('publicdomain')) return '0';
    final url = RegExp(r'licenses/([a-z-]+)/').firstMatch(l);
    if (url != null) return url.group(1);
    return RegExp(r'^cc-?(by[a-z-]*|0)$').firstMatch(l)?.group(1);
  }

  /// Libellé court de licence (« CC BY-NC 4.0 »).
  String? get licenseLabel {
    final l = license;
    if (l == null) return null;
    final terms = _terms;
    if (terms == null) return l;
    if (terms == '0') return 'CC0';
    final version = RegExp(r'licenses/[a-z-]+/([0-9.]+)').firstMatch(l.toLowerCase())?.group(1);
    return version == null ? 'CC ${terms.toUpperCase()}' : 'CC ${terms.toUpperCase()} $version';
  }

  /// Peut-on la montrer dans l'application ? Le domaine public et
  /// l'attribution simple, oui ; le « pas d'usage commercial » (NC) et le
  /// « pas de modification » (ND), non — l'application est un produit, et
  /// docs/09 § 4.1 tient déjà cette règle pour le jeu d'entraînement. Une
  /// photo dont on ignore la licence n'est pas une photo libre : sans
  /// mention, on s'abstient.
  bool get isFreelyDisplayable {
    final terms = _terms?.split('-');
    return terms != null && !terms.contains('nc') && !terms.contains('nd');
  }
}

/// Fiche espèce sourcée (GBIF) : taxonomie, noms communs, images, lien.
class SpeciesInfo {
  const SpeciesInfo({
    required this.key,
    required this.scientificName,
    required this.canonicalName,
    this.authorship,
    this.rank,
    this.status,
    this.kingdom,
    this.order,
    this.family,
    this.genus,
    this.commonNames = const {},
    this.images = const [],
  });

  final int key;
  final String scientificName;
  final String canonicalName;
  final String? authorship;
  final String? rank;
  final String? status;
  final String? kingdom;
  final String? order;
  final String? family;
  final String? genus;

  /// Noms communs par langue ISO 639-3 (`fra`, `eng`, `deu`, `ita`).
  final Map<String, List<String>> commonNames;
  final List<SpeciesImage> images;

  String get gbifUrl => 'https://www.gbif.org/species/$key';

  /// Noms communs pour une langue de l'app (`fr` → `fra`).
  List<String> commonNamesFor(String languageCode) => commonNames[_iso3(languageCode)] ?? const [];

  static String _iso3(String code) => switch (code) { 'fr' => 'fra', 'de' => 'deu', 'it' => 'ita', _ => 'eng' };

  SpeciesInfo copyWith({Map<String, List<String>>? commonNames, List<SpeciesImage>? images}) => SpeciesInfo(
        key: key,
        scientificName: scientificName,
        canonicalName: canonicalName,
        authorship: authorship,
        rank: rank,
        status: status,
        kingdom: kingdom,
        order: order,
        family: family,
        genus: genus,
        commonNames: commonNames ?? this.commonNames,
        images: images ?? this.images,
      );
}

/// Service d'information sur les espèces. Implémentation : GBIF (sans clé).
/// Une page de résultats de recherche (liste complète, défilement infini).
class SpeciesSearchPage {
  const SpeciesSearchPage({required this.results, required this.endOfRecords, this.total});

  final List<SpeciesSuggestion> results;
  final bool endOfRecords;
  final int? total;
}

/// Catégorie d'usage d'une espèce du catalogue intégré.
enum SpeciesCategory {
  indoor('🪴'),
  succulent('🌵'),
  herb('🌿'),
  vegetable('🥕'),
  fruit('🍋'),
  flower('🌸'),
  tree('🌳');

  const SpeciesCategory(this.emoji);

  final String emoji;
}

/// Entrée du catalogue intégré : disponible hors ligne, noms communs dans
/// les quatre langues de l'app.
class SpeciesCatalogEntry {
  const SpeciesCatalogEntry(this.scientificName, this.family, this.category, {required this.fr, required this.en, required this.de, required this.it});

  final String scientificName;
  final String family;
  final SpeciesCategory category;
  final String fr;
  final String en;
  final String de;
  final String it;

  String commonName(String languageCode) => switch (languageCode) { 'fr' => fr, 'de' => de, 'it' => it, _ => en };

  /// Recherche sans accents ni casse : « erable » doit trouver « Érable »,
  /// et « edelweiss » l'« Edelweiß ».
  bool matches(String query) {
    final q = foldSpeciesName(query);
    if (q.isEmpty) return true;
    return foldSpeciesName('$scientificName $fr $en $de $it $family').contains(q);
  }

  SpeciesSuggestion toSuggestion(String languageCode) => SpeciesSuggestion(key: 0, scientificName: scientificName, family: family, commonName: commonName(languageCode));
}

abstract class SpeciesService {
  Future<List<SpeciesSuggestion>> suggest(String query, {String? languageCode});

  /// Recherche paginée dans la base complète (GBIF : ~400 000 espèces de plantes).
  Future<SpeciesSearchPage> search(String query, {int offset = 0, int limit = 30, String? languageCode});
  Future<SpeciesInfo?> lookup(String scientificName);
  Future<SpeciesInfo?> byKey(int key);

  /// Une seule photo, pour une vignette de liste. Bien plus léger que
  /// [lookup] — qui charge aussi la taxonomie et tous les noms communs —
  /// parce qu'une liste de cinq candidats l'appelle cinq fois. Rend `null`
  /// plutôt que d'échouer : une vignette absente n'empêche pas de choisir.
  Future<SpeciesImage?> thumbnail(String scientificName);
}
