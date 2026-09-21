import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../core/config/relay_config.dart';
import '../../domain/identification/identification_context.dart';
import '../../domain/identification/plant_identifier.dart';
import '../../domain/species/species_info.dart';

/// Adaptateur Pl@ntNet (https://my.plantnet.org), par le relais.
///
/// La clé appartient à l'éditeur, pas à l'utilisateur : l'identification en
/// ligne fait partie de l'application, personne n'a à créer de compte chez un
/// tiers pour s'en servir. Elle ne voyage plus dans le binaire pour autant —
/// c'est la fonction Edge `relay` qui la tient et signe la requête
/// (`docs/19-relais-des-cles.md`). D'ici, il ne part que les photos et la
/// langue.
class PlantNetIdentifier implements PlantIdentifier {
  PlantNetIdentifier({Uri? endpoint, http.Client? client})
      : endpoint = endpoint ?? RelayConfig.route('identify'),
        _client = client ?? http.Client();

  final Uri endpoint;
  final http.Client _client;

  @override
  bool get isConfigured => endpoint.hasAuthority;

  @override
  Future<List<IdentificationCandidate>> identify(List<File> images,
          {String? language, IdentificationContext context = IdentificationContext.unknown}) async {
    if (!isConfigured) throw const IdentificationException('missing relay');
    // La langue est le seul réglage qui parte d'ici. Le relais y ajoute la
    // clé et `include-related-images`, qui rend pour chaque espèce proposée
    // quelques photos de référence de la base Pl@ntNet — elles ne coûtent ni
    // appel ni quota de plus, c'est la même requête, et donnent à la liste de
    // quoi se reconnaître à l'œil plutôt qu'au nom latin.
    final uri = endpoint.replace(queryParameters: {'lang': language ?? 'en'});
    final request = http.MultipartRequest('POST', uri);
    for (final image in images) {
      request.files.add(await http.MultipartFile.fromPath('images', image.path));
      request.fields['organs'] = 'auto';
    }
    final response = await http.Response.fromStream(await _client.send(request)).timeout(const Duration(seconds: 30));
    if (response.statusCode == 404) return const [];
    if (response.statusCode != 200) throw IdentificationException('http ${response.statusCode}');
    return parse(response.body);
  }

  /// Extrait les candidats de la réponse JSON de Pl@ntNet.
  static List<IdentificationCandidate> parse(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final results = (json['results'] as List?) ?? const [];
    return [
      for (final r in results.cast<Map<String, dynamic>>())
        IdentificationCandidate(
          scientificName: (r['species']?['scientificNameWithoutAuthor'] ?? r['species']?['scientificName'] ?? '') as String,
          commonName: ((r['species']?['commonNames'] as List?)?.cast<String>().firstOrNull),
          score: ((r['score'] as num?) ?? 0).toDouble(),
          image: _referenceImage(r['images'] as List?),
        ),
    ].where((c) => c.scientificName.isNotEmpty).toList();
  }

  /// La première photo de référence exploitable, en petit. Pl@ntNet rend
  /// trois tailles (`s`, `m`, `o`) : la vignette d'une ligne de liste se
  /// contente de la plus petite, et l'originale pèserait cent fois trop.
  /// L'auteur et la licence voyagent avec elle — une photo affichée sans
  /// son crédit n'a rien à faire dans l'application — et celles qu'on n'a
  /// pas le droit de montrer sont écartées ici, quitte à laisser GBIF
  /// illustrer l'espèce à leur place.
  static SpeciesImage? _referenceImage(List? images) {
    for (final image in (images ?? const []).cast<Map<String, dynamic>>()) {
      final sizes = image['url'] as Map<String, dynamic>?;
      final url = (sizes?['s'] ?? sizes?['m'] ?? sizes?['o']) as String?;
      if (url == null || !url.startsWith('http')) continue;
      final candidate = SpeciesImage(url: url, license: image['license'] as String?, rightsHolder: image['author'] as String?);
      if (candidate.isFreelyDisplayable) return candidate;
    }
    return null;
  }
}
