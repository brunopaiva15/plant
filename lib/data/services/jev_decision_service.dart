import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/relay_config.dart';

class JevDecisionException implements Exception {
  const JevDecisionException(this.message);

  final String message;

  @override
  String toString() => 'JevDecisionException: $message';
}

/// Client minimal de l'endpoint OpenRouter Decisions utilisé par Jev, par le
/// relais.
///
/// Jev ne génère pas de texte : il reçoit un état structuré et des questions
/// typées, puis rend leurs probabilités. Le workflow reste entièrement dans
/// Auxine.
///
/// La clé OpenRouter ne part pas d'ici : elle est dans la fonction Edge
/// `relay`, qui choisit aussi le modèle (`docs/19-relais-des-cles.md`).
class JevDecisionService {
  JevDecisionService({Uri? endpoint, http.Client? client})
      : endpoint = endpoint ?? RelayConfig.route('decide'),
        _client = client ?? http.Client(),
        _ownsClient = client == null;

  final Uri endpoint;
  final http.Client _client;
  final bool _ownsClient;

  bool get isConfigured => endpoint.hasAuthority;

  /// Le budget vient de l'appelant : c'est lui qui sait combien de temps
  /// l'interface peut attendre, et deux durées pour un même appel finissent
  /// toujours par diverger.
  Future<Map<String, dynamic>> decide({
    required Object state,
    required Map<String, dynamic> questions,
    required Duration timeout,
  }) async {
    if (!isConfigured) {
      throw const JevDecisionException('relais non configuré');
    }

    final response = await _client
        .post(
          endpoint,
          headers: const {'Content-Type': 'application/json'},
          // Le modèle est choisi par le relais : il décide du prix, et en
          // changer ne doit pas demander de repasser par l'App Store.
          body: jsonEncode({'state': state, 'questions': questions}),
        )
        .timeout(
          timeout,
          onTimeout: () => throw const JevDecisionException('délai dépassé'),
        );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw JevDecisionException(
        'relais HTTP ${response.statusCode}: ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const JevDecisionException('réponse JSON inattendue');
    }
    return decoded;
  }

  /// Ferme le client que le service a ouvert lui-même. Un client prêté
  /// appartient à l'appelant, qui le referme quand il en a fini.
  void close() {
    if (_ownsClient) _client.close();
  }
}
