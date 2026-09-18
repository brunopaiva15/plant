import 'dart:async';

import 'package:http/http.dart' as http;

import '../config/diagnosis_config.dart';
import '../config/identification_config.dart';
import '../config/jev_config.dart';
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
    required this.description,
    required this.state,
    this.latency,
    this.httpStatus,
  });

  final String name;
  final String description;
  final ExternalServiceState state;
  final Duration? latency;
  final int? httpStatus;
}

class _Probe {
  const _Probe({
    required this.name,
    required this.description,
    required this.uri,
    this.configured = true,
  });

  final String name;
  final String description;
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

  List<_Probe> get _probes => [
        _Probe(
          name: 'Supabase',
          description: 'Compte, synchronisation, communauté',
          uri: Uri.parse(
            SupabaseConfig.url.isEmpty
                ? 'https://supabase.com'
                : SupabaseConfig.url,
          ),
          configured: SupabaseConfig.isConfigured,
        ),
        _Probe(
          name: 'Partage public',
          description: 'Liens et pages de partage',
          uri: Uri.parse(
            SupabaseConfig.isConfigured
                ? SupabaseConfig.shareBaseUrl
                : 'https://supabase.com',
          ),
          configured: SupabaseConfig.isConfigured,
        ),
        _Probe(
          name: 'OpenRouter · Jev',
          description: 'Décision produit sur les scans Iris ambigus',
          uri: Uri.parse('https://openrouter.ai'),
          configured: JevConfig.isConfigured,
        ),
        _Probe(
          name: 'Pl@ntNet',
          description: 'Recherche d’identification en ligne',
          uri: Uri.parse('https://my-api.plantnet.org'),
          configured: IdentificationConfig.isConfigured,
        ),
        _Probe(
          name: 'Infomaniak AI',
          description: 'Diagnostic, soins, boutures et recherche',
          uri: Uri.parse('https://api.infomaniak.com'),
          configured: DiagnosisConfig.isConfigured,
        ),
        _Probe(
          name: 'Open-Meteo',
          description: 'Météo, géocodage et climat',
          uri: Uri.parse('https://api.open-meteo.com'),
        ),
        _Probe(
          name: 'GBIF',
          description: 'Taxonomie et photos d’espèces',
          uri: Uri.parse('https://api.gbif.org'),
        ),
        _Probe(
          name: 'Wikimedia Commons',
          description: 'Photos complémentaires d’espèces',
          uri: Uri.parse('https://commons.wikimedia.org'),
        ),
      ];

  Future<List<ExternalServiceStatus>> checkAll() =>
      Future.wait(_probes.map(_check));

  Future<ExternalServiceStatus> _check(_Probe probe) async {
    if (!probe.configured) {
      return ExternalServiceStatus(
        name: probe.name,
        description: probe.description,
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
        description: probe.description,
        state: state,
        latency: stopwatch.elapsed,
        httpStatus: code,
      );
    } on Object {
      stopwatch.stop();
      return ExternalServiceStatus(
        name: probe.name,
        description: probe.description,
        state: ExternalServiceState.unavailable,
        latency: stopwatch.elapsed,
      );
    }
  }
}
