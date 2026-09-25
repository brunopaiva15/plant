import 'dart:convert';
import 'dart:typed_data';

import 'package:flora/core/network/app_attest.dart';
import 'package:flora/core/network/play_integrity.dart';
import 'package:flora/core/network/relay_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Une enclave de papier : elle rend ce qu'on lui dit de rendre, et compte ce
/// qu'on lui a demandé.
class FakeAttest extends AppAttest {
  FakeAttest({this.supported = true, this.failAssertionWith});

  final bool supported;

  /// Le code d'erreur qu'Apple rendrait à la prochaine assertion, une fois.
  String? failAssertionWith;

  int keys = 0;
  int attestations = 0;
  int assertions = 0;

  @override
  Future<bool> get isSupported async => supported;

  @override
  Future<String> generateKey() async {
    keys++;
    return 'clé-$keys';
  }

  @override
  Future<Uint8List> attest(String keyId, String challenge) async {
    attestations++;
    return Uint8List.fromList(utf8.encode('attestation:$keyId:$challenge'));
  }

  @override
  Future<Uint8List> assertion(String keyId, String challenge) async {
    assertions++;
    final code = failAssertionWith;
    if (code != null) {
      failAssertionWith = null;
      throw AppAttestException(code);
    }
    return Uint8List.fromList(utf8.encode('assertion:$keyId:$challenge'));
  }
}

/// Un Play Store de papier : il rend un jeton qui dit ce qu'il scelle.
class FakeIntegrity extends PlayIntegrity {
  FakeIntegrity({this.supported = true, this.failWith});

  final bool supported;

  /// Le code d'erreur que Google Play rendrait, à chaque demande.
  final String? failWith;

  final List<String> hashes = [];

  @override
  Future<bool> get isSupported async => supported;

  @override
  Future<String> token(String requestHash) async {
    final code = failWith;
    if (code != null) throw PlayIntegrityException(code);
    hashes.add(requestHash);
    return 'jeton-play:$requestHash';
  }
}

class MemoryKeyStore implements RelayKeyStore {
  MemoryKeyStore([this.keyId, this.installId]);

  @override
  String? keyId;

  @override
  String? installId;

  @override
  Future<void> setKeyId(String? value) async => keyId = value;

  @override
  Future<void> setInstallId(String value) async => installId = value;
}

/// Un relais de papier. Rend les défis et les jetons, et garde la trace de ce
/// qui lui a été demandé.
class FakeRelay {
  final List<String> routes = [];
  final List<Map<String, dynamic>> payloads = [];
  final List<String> bearers = [];

  /// Ce que la route de travail répond ; 401 pour éprouver l'oubli du jeton.
  int workStatus = 200;

  /// Vrai quand le relais a oublié cet appareil : `attest/session` répond 404.
  bool forgetsDevice = false;

  /// Vrai quand Google dit que ce binaire ne vient pas de Google Play.
  bool refusesVerdict = false;

  int challenges = 0;
  int tokens = 0;

  http.Client get client => MockClient((request) async {
        final route = request.url.path.replaceFirst(RegExp(r'^/'), '');
        routes.add(route);
        final auth = request.headers['authorization'];
        if (auth != null) bearers.add(auth);

        if (route.startsWith('attest/')) {
          payloads.add(request.body.isEmpty ? {} : jsonDecode(request.body) as Map<String, dynamic>);
        }

        switch (route) {
          case 'attest/challenge':
            challenges++;
            return http.Response(jsonEncode({'challenge': 'défi-$challenges', 'expiresIn': 300}), 200);
          case 'attest/session':
            if (forgetsDevice) return http.Response(jsonEncode({'error': 'appareil inconnu'}), 404);
            tokens++;
            return http.Response(jsonEncode({'token': 'jeton-$tokens', 'expiresIn': 3600}), 200);
          case 'attest/integrity':
            if (refusesVerdict) return http.Response(jsonEncode({'error': 'verdict refusé'}), 401);
            tokens++;
            return http.Response(jsonEncode({'token': 'jeton-$tokens', 'expiresIn': 3600}), 200);
          case 'attest/register':
          case 'attest/dev':
            tokens++;
            return http.Response(jsonEncode({'token': 'jeton-$tokens', 'expiresIn': 3600}), 200);
          default:
            return http.Response('{}', workStatus);
        }
      });
}

void main() {
  late FakeRelay relay;
  var now = DateTime.utc(2026, 9, 21, 12);

  setUp(() {
    relay = FakeRelay();
    now = DateTime.utc(2026, 9, 21, 12);
  });

  RelayClient build({FakeAttest? attest, FakeIntegrity? integrity, MemoryKeyStore? store, String devToken = ''}) => RelayClient(
        baseUrl: 'https://relais.test',
        store: store ?? MemoryKeyStore(),
        attest: attest ?? FakeAttest(),
        integrity: integrity ?? FakeIntegrity(supported: false),
        devToken: devToken,
        inner: relay.client,
        clock: () => now,
      );

  Future<http.Response> work(RelayClient client) => client.post(Uri.parse('https://relais.test/ai'), body: '{}');

  group("l'entrée du relais", () {
    test('un appareil neuf se fait attester, puis porte son jeton', () async {
      final attest = FakeAttest();
      final store = MemoryKeyStore();
      await work(build(attest: attest, store: store));

      expect(relay.routes, ['attest/challenge', 'attest/register', 'ai']);
      expect(attest.attestations, 1);
      expect(relay.bearers.last, 'Bearer jeton-1');
      // L'identifiant de la clé est gardé : Apple refuse d'attester deux fois
      // la même, en refaire une à chaque lancement butera sur ses limites.
      expect(store.keyId, 'clé-1');
    });

    test('la poignée de main sert pour les requêtes suivantes', () async {
      final attest = FakeAttest();
      final client = build(attest: attest);
      await work(client);
      await work(client);
      await work(client);

      expect(relay.tokens, 1);
      expect(attest.attestations, 1);
      expect(relay.routes.where((r) => r == 'ai'), hasLength(3));
    });

    test('des appels simultanés n’en déclenchent qu’une', () async {
      final attest = FakeAttest();
      final client = build(attest: attest);
      await Future.wait([work(client), work(client), work(client)]);

      expect(relay.challenges, 1);
      expect(attest.attestations, 1);
    });

    test('une clé déjà attestée signe un défi au lieu de repartir d’Apple', () async {
      final attest = FakeAttest();
      await work(build(attest: attest, store: MemoryKeyStore('clé-gardée')));

      expect(relay.routes, ['attest/challenge', 'attest/session', 'ai']);
      expect(attest.attestations, 0);
      expect(attest.assertions, 1);
      // L'assertion porte sur le défi que le relais vient de délivrer, et sur
      // lui seul : c'est ce qui fait qu'elle ne se rejoue pas.
      expect(relay.payloads.last['challenge'], 'défi-1');
      expect(utf8.decode(base64Decode(relay.payloads.last['assertion'] as String)), contains('défi-1'));
    });
  });

  group('ce qui se répare tout seul', () {
    test('un appareil que le relais a oublié se réenregistre', () async {
      relay.forgetsDevice = true;
      final attest = FakeAttest();
      final store = MemoryKeyStore('clé-gardée');
      await work(build(attest: attest, store: store));

      expect(relay.routes, ['attest/challenge', 'attest/session', 'attest/challenge', 'attest/register', 'ai']);
      // La clé de l'enclave est encore bonne, mais Apple refuse d'attester
      // deux fois la même : il en faut une neuve.
      expect(store.keyId, 'clé-1');
    });

    test("une clé qu'Apple ne reconnaît plus se refait", () async {
      final attest = FakeAttest(failAssertionWith: 'invalid_key');
      final store = MemoryKeyStore('clé-perdue');
      await work(build(attest: attest, store: store));

      expect(attest.attestations, 1);
      expect(store.keyId, 'clé-1');
    });

    test('un jeton proche de son terme est renouvelé avant de servir', () async {
      final client = build();
      await work(client);
      expect(relay.tokens, 1);

      // Cinquante-huit minutes plus tard, il reste moins que la marge.
      now = now.add(const Duration(minutes: 58));
      await work(client);
      expect(relay.tokens, 2);
    });

    test('un refus du relais fait oublier le jeton', () async {
      final client = build();
      relay.workStatus = 401;
      await work(client);
      expect(relay.tokens, 1);

      // La tentative suivante repart d'une poignée de main, sans attendre le
      // terme : le jeton n'a plus cours.
      relay.workStatus = 200;
      await work(client);
      expect(relay.tokens, 2);
    });
  });

  group('là où il n’y a pas d’enclave', () {
    test('le laissez-passer de développement ouvre la porte', () async {
      final attest = FakeAttest(supported: false);
      await work(build(attest: attest, devToken: 'mot-de-passe'));

      expect(relay.routes, ['attest/dev', 'ai']);
      expect(relay.payloads.single['token'], 'mot-de-passe');
      expect(attest.keys, 0);
    });

    test('sans enclave ni laissez-passer, rien ne part', () async {
      final client = build(attest: FakeAttest(supported: false));
      await expectLater(work(client), throwsA(isA<RelayException>().having((e) => e.code, 'code', 'unavailable')));
      expect(relay.routes, isEmpty);
    });
  });

  group('Android', () {
    RelayClient android({FakeIntegrity? integrity, MemoryKeyStore? store, String devToken = ''}) => build(
          attest: FakeAttest(supported: false),
          integrity: integrity ?? FakeIntegrity(),
          store: store,
          devToken: devToken,
        );

    test('Play Integrity scelle le défi et l’installation, puis ouvre la porte', () async {
      final integrity = FakeIntegrity();
      final store = MemoryKeyStore();
      await work(android(integrity: integrity, store: store));

      expect(relay.routes, ['attest/challenge', 'attest/integrity', 'ai']);
      expect(relay.bearers.last, 'Bearer jeton-1');
      // Un identifiant d'installation est tiré au sort et gardé : c'est lui
      // que le relais compte dans ses quotas.
      final installId = store.installId!;
      expect(installId, matches(RegExp(r'^[A-Za-z0-9_-]{43}$')));
      final payload = relay.payloads.last;
      expect(payload['installId'], installId);
      expect(payload['challenge'], 'défi-1');
      // Le jeton scelle le condensé que le relais recalculera.
      expect(integrity.hashes.single, RelayClient.integrityHash('défi-1', installId));
      expect(payload['token'], 'jeton-play:${integrity.hashes.single}');
    });

    test("l'identifiant d'installation se garde d'une poignée de main à l'autre", () async {
      final store = MemoryKeyStore(null, 'installation-gardée');
      final client = android(store: store);
      await work(client);
      now = now.add(const Duration(hours: 2));
      await work(client);

      expect(relay.tokens, 2);
      expect(relay.payloads.where((p) => p.containsKey('installId')).map((p) => p['installId']).toSet(), {'installation-gardée'});
    });

    test('le condensé est celui que le relais recalcule', () {
      // Même calcul que `integrityRequestHash` côté relais : SHA-256 de
      // « défi.installation », en hexadécimal.
      expect(RelayClient.integrityHash('abc', 'xyz'), '8806d08be1da6bafefb3c5a7fa0f9f70cda3b288246021f6f9f5050ad3457063');
      expect(RelayClient.integrityHash('abc', 'xyz'), isNot(RelayClient.integrityHash('abc', 'xyw')));
    });

    test('un binaire que Google Play ne reconnaît pas passe par le laissez-passer', () async {
      relay.refusesVerdict = true;
      await work(android(devToken: 'mot-de-passe'));

      expect(relay.routes, ['attest/challenge', 'attest/integrity', 'attest/dev', 'ai']);
    });

    test('sans laissez-passer, le refus remonte', () async {
      relay.refusesVerdict = true;
      await expectLater(work(android()), throwsA(isA<RelayException>().having((e) => e.code, 'code', 'refused')));
      expect(relay.routes, ['attest/challenge', 'attest/integrity']);
    });

    test('un Play Store absent rend le relais indisponible, sans rien envoyer au relais', () async {
      await expectLater(
        work(android(integrity: FakeIntegrity(failWith: '-2'))),
        throwsA(isA<RelayException>().having((e) => e.code, 'code', 'unavailable')),
      );
      expect(relay.routes, ['attest/challenge']);
    });

    test('un émulateur sans Play Store passe par le laissez-passer', () async {
      await work(android(integrity: FakeIntegrity(failWith: '-2'), devToken: 'mot-de-passe'));
      expect(relay.routes, ['attest/challenge', 'attest/dev', 'ai']);
    });

    test('sans projet Play Integrity, le laissez-passer reste le chemin', () async {
      await work(android(integrity: FakeIntegrity(supported: false), devToken: 'mot-de-passe'));
      expect(relay.routes, ['attest/dev', 'ai']);
    });
  });
}
