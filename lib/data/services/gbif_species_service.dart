import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/species/species_info.dart';

/// GBIF — Global Biodiversity Information Facility (https://techdocs.gbif.org).
/// Gratuit, sans clé. Les images proviennent des observations (iNaturalist…)
/// et sont affichées avec leur licence et leur auteur.
class GbifSpeciesService implements SpeciesService {
  GbifSpeciesService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _base = 'api.gbif.org';

  /// Clé GBIF du règne Plantae : limite les résultats aux plantes.
  static const plantaeKey = 6;

  /// Les licences d'occurrence qu'on s'autorise à afficher. GBIF n'en
  /// normalise que quatre ; les deux autres sont CC BY-NC et « non
  /// précisée », que l'application ne montre pas (docs/09 § 4.1).
  static const _displayableLicenses = ['CC0_1_0', 'CC_BY_4_0'];

  final _cache = <int, SpeciesInfo>{};

  /// Vignettes déjà cherchées, par nom scientifique. Une entrée `null` dit
  /// « cette espèce n'a pas de photo », et évite de le redemander.
  final _thumbnails = <String, SpeciesImage?>{};

  @override
  Future<List<SpeciesSuggestion>> suggest(String query, {String? languageCode}) async {
    final q = query.trim();
    if (q.length < 3) return const [];
    final uri = Uri.https(_base, '/v1/species/search', {
      'q': q,
      'rank': 'SPECIES',
      'highertaxonKey': '$plantaeKey',
      'status': 'ACCEPTED',
      'limit': '8',
    });
    final res = await _client.get(uri).timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) return const [];
    return parseSuggestions(res.body, languageCode: languageCode);
  }

  @override
  Future<SpeciesSearchPage> search(String query, {int offset = 0, int limit = 30, String? languageCode}) async {
    final q = query.trim();
    if (q.length < 2) return const SpeciesSearchPage(results: [], endOfRecords: true, total: 0);
    final uri = Uri.https(_base, '/v1/species/search', {
      'q': q,
      'rank': 'SPECIES',
      'highertaxonKey': '$plantaeKey',
      'status': 'ACCEPTED',
      'limit': '$limit',
      'offset': '$offset',
    });
    final res = await _client.get(uri).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) throw Exception('GBIF ${res.statusCode}');
    return parseSearchPage(res.body, languageCode: languageCode);
  }

  static SpeciesSearchPage parseSearchPage(String body, {String? languageCode}) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    return SpeciesSearchPage(
      results: parseSuggestions(body, languageCode: languageCode),
      endOfRecords: (json['endOfRecords'] as bool?) ?? true,
      total: json['count'] as int?,
    );
  }

  @override
  Future<SpeciesInfo?> lookup(String scientificName) async {
    final key = await _matchKey(scientificName);
    return key == null ? null : byKey(key);
  }

  /// La clé GBIF d'un nom scientifique, ou `null` si la base ne le connaît
  /// pas. Passer par `match` plutôt que d'interroger directement les
  /// occurrences fait le travail que nous ne saurions pas faire : accorder
  /// un synonyme, une graphie d'auteur, une sous-espèce, au nom accepté.
  Future<int?> _matchKey(String scientificName) async {
    final name = scientificName.trim();
    if (name.isEmpty) return null;
    final uri = Uri.https(_base, '/v1/species/match', {'name': name, 'kingdom': 'Plantae'});
    final res = await _client.get(uri).timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) return null;
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final key = json['usageKey'] as int?;
    return (json['matchType'] as String?) == 'NONE' ? null : key;
  }

  @override
  Future<SpeciesImage?> thumbnail(String scientificName) async {
    final name = scientificName.trim();
    if (name.isEmpty) return null;
    // Une espèce déjà vue ne repart pas sur le réseau : la feuille
    // d'identification se rouvre souvent sur les mêmes candidats, et une
    // vignette n'a pas à se payer deux fois.
    if (_thumbnails.containsKey(name)) return _thumbnails[name];
    try {
      final key = await _matchKey(name);
      if (key == null) return _thumbnails[name] = null;
      // La fiche espèce a pu passer par là : ses photos font l'affaire.
      if (_cache[key]?.images.where((i) => i.isFreelyDisplayable).firstOrNull case final known?) {
        return _thumbnails[name] = known;
      }
      // Le filtre de licence porte sur l'occurrence ; celui de
      // [SpeciesImage.isFreelyDisplayable] porte sur le média lui-même, qui
      // peut différer. Le premier évite de rapatrier ce qu'on jettera, le
      // second est la garantie.
      final res = await _client
          .get(Uri.https(_base, '/v1/occurrence/search', {
            'taxonKey': '$key',
            'mediaType': 'StillImage',
            'license': _displayableLicenses,
            'limit': '5',
          }))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      return _thumbnails[name] = parseOccurrenceImages(res.body).where((i) => i.isFreelyDisplayable).firstOrNull;
    } on Object {
      // Réseau coupé, GBIF indisponible : on ne mémorise rien, la prochaine
      // ouverture retentera. Le nom reste lisible sans sa photo.
      return null;
    }
  }

  @override
  Future<SpeciesInfo?> byKey(int key) async {
    if (_cache[key] case final cached?) return cached;
    final taxonRes = await _client.get(Uri.https(_base, '/v1/species/$key')).timeout(const Duration(seconds: 12));
    if (taxonRes.statusCode != 200) return null;
    var info = parseTaxon(taxonRes.body);
    // Noms communs et images : facultatifs, jamais bloquants.
    try {
      final names = await _client.get(Uri.https(_base, '/v1/species/$key/vernacularNames', {'limit': '200'})).timeout(const Duration(seconds: 12));
      if (names.statusCode == 200) info = info.copyWith(commonNames: parseVernacular(names.body));
    } catch (_) {}
    try {
      final occ = await _client
          .get(Uri.https(_base, '/v1/occurrence/search', {'taxonKey': '$key', 'mediaType': 'StillImage', 'limit': '6'}))
          .timeout(const Duration(seconds: 12));
      if (occ.statusCode == 200) info = info.copyWith(images: parseOccurrenceImages(occ.body));
    } catch (_) {}
    return _cache[key] = info;
  }

  static List<SpeciesSuggestion> parseSuggestions(String body, {String? languageCode}) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final results = (json['results'] as List? ?? const []).cast<Map<String, dynamic>>();
    final iso3 = switch (languageCode) { 'fr' => 'fra', 'de' => 'deu', 'it' => 'ita', _ => 'eng' };
    final seen = <String>{};
    final out = <SpeciesSuggestion>[];
    for (final r in results) {
      final name = (r['canonicalName'] ?? r['scientificName']) as String?;
      final key = r['key'] as int?;
      if (name == null || key == null || !seen.add(name)) continue;
      final vern = (r['vernacularNames'] as List? ?? const []).cast<Map<String, dynamic>>();
      final common = vern.where((v) => v['language'] == iso3).map((v) => v['vernacularName'] as String?).whereType<String>().firstOrNull;
      out.add(SpeciesSuggestion(key: key, scientificName: name, family: r['family'] as String?, commonName: common));
    }
    return out;
  }

  static SpeciesInfo parseTaxon(String body) {
    final j = jsonDecode(body) as Map<String, dynamic>;
    return SpeciesInfo(
      key: j['key'] as int,
      scientificName: (j['scientificName'] as String?) ?? '',
      canonicalName: (j['canonicalName'] as String?) ?? (j['scientificName'] as String?) ?? '',
      authorship: j['authorship'] as String?,
      rank: j['rank'] as String?,
      status: j['taxonomicStatus'] as String?,
      kingdom: j['kingdom'] as String?,
      order: j['order'] as String?,
      family: j['family'] as String?,
      genus: j['genus'] as String?,
    );
  }

  static Map<String, List<String>> parseVernacular(String body) {
    final j = jsonDecode(body) as Map<String, dynamic>;
    final out = <String, List<String>>{};
    for (final v in (j['results'] as List? ?? const []).cast<Map<String, dynamic>>()) {
      final lang = v['language'] as String?;
      final name = v['vernacularName'] as String?;
      if (lang == null || name == null) continue;
      final list = out.putIfAbsent(lang, () => []);
      if (!list.any((n) => n.toLowerCase() == name.toLowerCase())) list.add(name);
    }
    return out;
  }

  static List<SpeciesImage> parseOccurrenceImages(String body) {
    final j = jsonDecode(body) as Map<String, dynamic>;
    final out = <SpeciesImage>[];
    for (final o in (j['results'] as List? ?? const []).cast<Map<String, dynamic>>()) {
      for (final m in (o['media'] as List? ?? const []).cast<Map<String, dynamic>>()) {
        final url = m['identifier'] as String?;
        if (url == null || !url.startsWith('http')) continue;
        out.add(SpeciesImage(url: url, license: m['license'] as String?, rightsHolder: m['rightsHolder'] as String?, country: o['country'] as String?));
        break;
      }
    }
    return out;
  }
}
