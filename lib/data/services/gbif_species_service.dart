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

  final _cache = <int, SpeciesInfo>{};

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
  Future<SpeciesInfo?> lookup(String scientificName) async {
    final name = scientificName.trim();
    if (name.isEmpty) return null;
    final uri = Uri.https(_base, '/v1/species/match', {'name': name, 'kingdom': 'Plantae'});
    final res = await _client.get(uri).timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) return null;
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final key = json['usageKey'] as int?;
    final matchType = json['matchType'] as String?;
    if (key == null || matchType == 'NONE') return null;
    return byKey(key);
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
