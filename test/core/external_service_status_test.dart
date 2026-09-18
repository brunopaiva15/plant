import 'package:flora/core/network/external_service_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('classe correctement les probes HTTP sans envoyer de données métier',
      () async {
    final seen = <http.BaseRequest>[];
    final client = MockClient((request) async {
      seen.add(request);
      return switch (request.url.host) {
        'api.open-meteo.com' => http.Response('', 204),
        'geocoding-api.open-meteo.com' => http.Response('', 429),
        'archive-api.open-meteo.com' => http.Response('', 503),
        'api.gbif.org' => http.Response('', 405),
        'commons.wikimedia.org' => http.Response('', 200),
        _ => http.Response('', 204),
      };
    });

    final service = ExternalServiceStatusService(client: client);
    final statuses = await service.checkAll();
    service.close();

    ExternalServiceStatus named(String name) =>
        statuses.firstWhere((status) => status.name == name);

    expect(
      named('Open-Meteo · Prévisions').state,
      ExternalServiceState.operational,
    );
    expect(
      named('Open-Meteo · Géocodage').state,
      ExternalServiceState.degraded,
    );
    expect(
      named('Open-Meteo · Archives').state,
      ExternalServiceState.unavailable,
    );
    expect(named('GBIF').state, ExternalServiceState.operational);
    expect(
      named('Wikimedia Commons').state,
      ExternalServiceState.operational,
    );

    // Le diagnostic n'envoie jamais de corps, de photo ou de données plante.
    expect(seen, isNotEmpty);
    expect(seen.every((request) => request.method == 'HEAD'), isTrue);
    expect(
      seen.whereType<http.Request>().every((request) => request.body.isEmpty),
      isTrue,
    );
  });
}
