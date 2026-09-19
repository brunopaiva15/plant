import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/jev_config.dart';

class JevDecisionException implements Exception {
  const JevDecisionException(this.message);

  final String message;

  @override
  String toString() => 'JevDecisionException: $message';
}

/// Client minimal de l'endpoint OpenRouter Decisions utilisé par Jev.
///
/// Jev ne génère pas de texte : il reçoit un état structuré et des questions
/// typées, puis rend leurs probabilités. Le workflow reste entièrement dans
/// Auxine.
class JevDecisionService {
  JevDecisionService({http.Client? client})
      : _client = client ?? http.Client(),
        _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;

  /// Le budget vient de l'appelant : c'est lui qui sait combien de temps
  /// l'interface peut attendre, et deux durées pour un même appel finissent
  /// toujours par diverger.
  Future<Map<String, dynamic>> decide({
    required Object state,
    required Map<String, dynamic> questions,
    required Duration timeout,
  }) async {
    if (!JevConfig.isConfigured) {
      throw const JevDecisionException('OPENROUTER_API_KEY manquante');
    }

    final response = await _client
        .post(
          Uri.parse(JevConfig.endpoint),
          headers: {
            'Authorization': 'Bearer ${JevConfig.apiKey.trim()}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': JevConfig.model,
            'state': state,
            'questions': questions,
          }),
        )
        .timeout(
          timeout,
          onTimeout: () => throw const JevDecisionException('délai dépassé'),
        );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw JevDecisionException(
        'OpenRouter HTTP ${response.statusCode}: ${response.body}',
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
