import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../domain/identification/plant_identifier.dart';

/// Adaptateur Pl@ntNet (https://my.plantnet.org). La clé est fournie par l'utilisateur.
class PlantNetIdentifier implements PlantIdentifier {
  PlantNetIdentifier(this.apiKey, {http.Client? client}) : _client = client ?? http.Client();

  final String apiKey;
  final http.Client _client;

  static const _endpoint = 'https://my-api.plantnet.org/v2/identify/all';

  @override
  bool get isConfigured => apiKey.trim().isNotEmpty;

  @override
  Future<List<IdentificationCandidate>> identify(List<File> images, {String? language}) async {
    if (!isConfigured) throw const IdentificationException('missing api key');
    final uri = Uri.parse(_endpoint).replace(queryParameters: {'api-key': apiKey.trim(), 'lang': language ?? 'en', 'include-related-images': 'false'});
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
        ),
    ].where((c) => c.scientificName.isNotEmpty).toList();
  }
}
