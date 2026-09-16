import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/species/species_info.dart';

/// Wikimedia Commons (https://commons.wikimedia.org/w/api.php) : la
/// médiathèque, où l'on photographie la plante cultivée — la distribution que
/// GBIF, qui ne relaie que des observations de terrain, ne donne pas
/// (docs/09 § 4.4). Sans clé, et complémentaire de [GbifSpeciesService] :
/// GBIF reste la référence des noms.
class WikimediaSpeciesService implements SpeciesImageSource {
  WikimediaSpeciesService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _base = 'commons.wikimedia.org';

  /// MediaWiki demande un agent identifiable ; un agent générique ou absent
  /// se fait refuser. Il porte le nom de l'app et le dépôt du projet.
  static const _userAgent = 'Auxine/1.0 (https://github.com/brunopaiva15/plant)';

  /// Formats que Flutter sait peindre. Commons héberge aussi des SVG, des PDF
  /// et des TIFF, que `Image.network` ne lirait pas.
  static const _photoFormats = {'image/jpeg', 'image/png', 'image/webp'};

  /// Combien de photos on garde au plus, une fois les filtres passés.
  static const _max = 6;

  /// Une catégorie ne contient pas que des photographies : planches
  /// botaniques du XIX<sup>e</sup>, scans d'herbier, cartes de répartition,
  /// schémas. La fiche veut une plante vivante ; le filtre porte sur le titre,
  /// grossier et assumé comme au connecteur du jeu de données (docs/09 § 4.4).
  static final _notAPhoto = RegExp(
    r'\b(illustration|drawing|dessin|zeichnung|engraving|gravure|lithograph|'
    r'botanical\s+plate|planche|k[öo]hler|flora\s+von|flora\s+of|'
    r'herbarium|herbier|specimen|holotype|isotype|lectotype|type\s+sheet|'
    r'distribution\s+map|carte|diagram|schema|logo|icon|stamp|timbre|'
    r'coat\s+of\s+arms|chromolith)\b',
    caseSensitive: false,
  );

  final _cache = <String, List<SpeciesImage>>{};

  @override
  Future<List<SpeciesImage>> photos(String scientificName) async {
    final name = scientificName.trim();
    if (name.isEmpty) return const [];
    if (_cache[name] case final cached?) return cached;
    try {
      final uri = Uri.https(_base, '/w/api.php', {
        'action': 'query',
        'format': 'json',
        'formatversion': '2',
        // La recherche porte sur le titre : les photos d'une espèce le portent
        // presque toujours, et on écarte d'emblée les fichiers qui la citent
        // seulement dans leur description.
        'generator': 'search',
        'gsrsearch': 'intitle:"$name"',
        'gsrnamespace': '6',
        'gsrlimit': '${_max * 2}',
        'prop': 'imageinfo',
        'iiprop': 'url|extmetadata|mime',
        // Les originaux montent à plusieurs dizaines de mégaoctets ; la
        // vignette suffit à l'écran et épargne la bande passante.
        'iiurlwidth': '640',
      });
      final res = await _client.get(uri, headers: const {'User-Agent': _userAgent}).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return const [];
      return _cache[name] = parsePhotos(res.body).take(_max).toList();
    } on Object {
      // Un complément décoratif ne fait pas échouer la fiche : les photos
      // GBIF restent, et la prochaine ouverture retentera.
      return const [];
    }
  }

  static List<SpeciesImage> parsePhotos(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final pages = (((json['query'] as Map<String, dynamic>?)?['pages']) as List? ?? const []).cast<Map<String, dynamic>>();
    final seen = <String>{};
    final out = <SpeciesImage>[];
    for (final page in pages) {
      final title = page['title'] as String?;
      if (title == null || _notAPhoto.hasMatch(title)) continue;
      final info = ((page['imageinfo'] as List? ?? const []).cast<Map<String, dynamic>>()).firstOrNull;
      if (info == null || !_photoFormats.contains(info['mime'])) continue;
      final url = (info['thumburl'] ?? info['url']) as String?;
      if (url == null || !url.startsWith('http') || !seen.add(url)) continue;
      final meta = (info['extmetadata'] as Map?)?.cast<String, dynamic>() ?? const {};
      // L'URL de licence est plus sûre que le libellé : « CC BY 3.0 us » ou
      // « CC-BY 4.0 Int » se lisent mal, l'URL jamais.
      final license = _metadata(meta['LicenseUrl']) ?? _metadata(meta['LicenseShortName']);
      final image = SpeciesImage(url: url, license: license, rightsHolder: _plain(_metadata(meta['Artist'])));
      if (image.isFreelyDisplayable) out.add(image);
    }
    return out;
  }

  /// La `value` d'une entrée `extmetadata`, ou `null` quand elle est vide.
  static String? _metadata(Object? entry) {
    final value = (entry as Map?)?['value'];
    return value is String && value.trim().isNotEmpty ? value : null;
  }

  /// L'auteur arrive en HTML (un lien vers la page utilisateur, le plus
  /// souvent). Le crédit veut un nom, pas un fragment de page.
  static String? _plain(String? html) {
    if (html == null) return null;
    final text = html
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return text.isEmpty ? null : text;
  }
}
