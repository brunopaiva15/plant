import 'dart:async';

import 'package:http/http.dart' as http;

import '../config/relay_config.dart';
import '../config/supabase_config.dart';

enum ExternalServiceState {
  operational,
  degraded,
  unavailable,
  unconfigured,
}

class ExternalServiceStatus {
  const ExternalServiceStatus({
    required this.name,
    required this.state,
    this.latency,
    this.httpStatus,
  });

  final String name;
  final ExternalServiceState state;
  final Duration? latency;
  final int? httpStatus;
}

class _Probe {
  const _Probe({
    required this.name,
    required this.uri,
    this.configured = true,
  });

  final String name;
  final Uri uri;
  final bool configured;
}

/// Diagnostic volontairement indépendant des clients métier.
///
/// Il ne transmet aucune donnée utilisateur et ne déclenche aucun endpoint
/// payant : il vérifie seulement que le service HTTPS est joignable. Un 4xx
/// prouve que le serveur répond ; un 429 est signalé comme dégradé et un 5xx
/// comme indisponible.
class ExternalServiceStatusService {
  ExternalServiceStatusService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  static const _timeout = Duration(seconds: 5);

  void close() => _client.close();

  List<_Probe> get _probes => [
        _Probe(
          name: 'Supabase',
          uri: Uri.parse(
            SupabaseConfig.url.isEmpty
                ? 'https://supabase.com'
                : '${SupabaseConfig.url.replaceAll(RegExp(r'/+$'), '')}/rest/v1/',
          ),
          configured: SupabaseConfig.isConfigured,
        ),
        _Probe(
          name: 'Partage public',
          uri: Uri.parse(
            SupabaseConfig.isConfigured
                ? SupabaseConfig.shareBaseUrl
                : 'https://supabase.com',
          ),
          configured: SupabaseConfig.isConfigured,
        ),
        // Pl@ntNet, les AI Services d'Infomaniak et OpenRouter ne sont plus
        // joignables d'ici : leurs clés sont dans le relais, et c'est lui
        // qu'on interroge. Sa route `health` dit du même coup lesquels des
        // trois il peut servir — un secret manquant s'y voit, au lieu
        // d'attendre un échec d'amont trois écrans plus loin.
        _Probe(
          name: 'Relais Auxine',
          uri: Uri.parse(RelayConfig.isConfigured ? '${RelayConfig.baseUrl}/health' : 'https://supabase.com'),
          configured: RelayConfig.isConfigured,
        ),
        _Probe(
          name: 'Open-Meteo · Prévisions',
          uri: Uri.parse('https://api.open-meteo.com/v1/forecast'),
        ),
        _Probe(
          name: 'Open-Meteo · Géocodage',
          uri: Uri.parse('https://geocoding-api.open-meteo.com/v1/search'),
        ),
        _Probe(
          name: 'Open-Meteo · Archives',
          uri: Uri.parse('https://archive-api.open-meteo.com/v1/archive'),
        ),
        _Probe(
          name: 'GBIF',
          uri: Uri.parse('https://api.gbif.org/v1/species/match'),
        ),
        _Probe(
          name: 'Wikimedia Commons',
          uri: Uri.parse('https://commons.wikimedia.org/w/api.php'),
        ),
      ];

  Future<List<ExternalServiceStatus>> checkAll() =>
      Future.wait(_probes.map(_check));

  Future<ExternalServiceStatus> _check(_Probe probe) async {
    if (!probe.configured) {
      return ExternalServiceStatus(
        name: probe.name,
        state: ExternalServiceState.unconfigured,
      );
    }

    final stopwatch = Stopwatch()..start();
    try {
      final request = http.Request('HEAD', probe.uri);
      final response = await _client.send(request).timeout(_timeout);
      stopwatch.stop();
      final code = response.statusCode;
      final state = switch (code) {
        429 => ExternalServiceState.degraded,
        >= 500 => ExternalServiceState.unavailable,
        _ => ExternalServiceState.operational,
      };
      return ExternalServiceStatus(
        name: probe.name,
        state: state,
        latency: stopwatch.elapsed,
        httpStatus: code,
      );
    } on Object {
      stopwatch.stop();
      return ExternalServiceStatus(
        name: probe.name,
        state: ExternalServiceState.unavailable,
        latency: stopwatch.elapsed,
      );
    }
  }
}
