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

  /// Libellé court de licence (« CC BY-NC 4.0 »).
  String? get licenseLabel {
    final l = license;
    if (l == null) return null;
    final m = RegExp(r'licenses/([a-z-]+)/([0-9.]+)').firstMatch(l);
    if (m == null) return l;
    return 'CC ${m.group(1)!.toUpperCase()} ${m.group(2)}';
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
abstract class SpeciesService {
  Future<List<SpeciesSuggestion>> suggest(String query, {String? languageCode});
  Future<SpeciesInfo?> lookup(String scientificName);
  Future<SpeciesInfo?> byKey(int key);
}
