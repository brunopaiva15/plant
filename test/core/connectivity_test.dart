import 'dart:io';

import 'package:flora/core/network/connectivity.dart';
import 'package:flora/core/network/network_failure.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sonde pilotée par le test : elle répond ce qu'on lui dit, et compte les
/// questions.
class _Probe implements Reachability {
  _Probe(this.reachable);

  bool reachable;
  int calls = 0;

  @override
  Future<bool> probe() async {
    calls++;
    return reachable;
  }
}

/// Ce que l'appel protégé fera, et combien de fois il est parti. Une variable
/// de fichier plutôt qu'un champ : les providers ci-dessous sont globaux.
late Future<String> Function() _call;
var _attempts = 0;

/// Un appel réseau passé par la garde, comme le font les écrans.
final _guarded = FutureProvider<String>(retry: noRetry, (ref) {
  ref.watch(connectivityProvider);
  return ref.online(() {
    _attempts++;
    return _call();
  });
});

void main() {
  // Le contrôleur écoute le cycle de vie de l'application : sans binding,
  // `WidgetsBinding.instance` n'existe pas.
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Probe probe;
  late ProviderContainer container;

  ProviderContainer build({bool reachable = true}) {
    probe = _Probe(reachable);
    _attempts = 0;
    _call = () async => 'ok';
    return ProviderContainer(overrides: [reachabilityProvider.overrideWithValue(probe)]);
  }

  tearDown(() => container.dispose());

  /// Laisse le provider se poser et rend son état, une fois vérifié qu'il
  /// s'est bien posé.
  ///
  /// Deux pièges valaient la peine d'être verrouillés ici : Riverpod ne
  /// construit que ce qu'on écoute, et un provider en erreur qu'il réessaie
  /// reste en `AsyncLoading` — son erreur se lit quand même, si bien qu'un
  /// test qui ne regarde que `.error` passe alors que l'écran, lui, tourne
  /// toujours.
  Future<AsyncValue<String>> settle() async {
    container.listen(_guarded, (_, _) {});
    for (var i = 0; i < 8 && container.read(_guarded).isLoading; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    final state = container.read(_guarded);
    expect(state.isLoading, isFalse, reason: 'l\'écran serait resté sur son tourniquet : $state');
    return state;
  }

  group('état du réseau', () {
    test('démarre en ligne, puis la sonde tranche', () async {
      container = build(reachable: false);
      // On n'accuse pas le réseau avant d'avoir regardé : sans cela, chaque
      // lancement s'ouvrirait sur un écran « hors ligne » le temps d'une
      // résolution DNS.
      expect(container.read(connectivityProvider), NetworkStatus.online);
      await container.read(connectivityProvider.notifier).refresh();
      expect(container.read(connectivityProvider), NetworkStatus.offline);
      expect(container.read(isOnlineProvider), isFalse);
    });

    test('les sondes concurrentes n\'en font qu\'une', () async {
      container = build();
      final notifier = container.read(connectivityProvider.notifier);
      final before = probe.calls;
      await Future.wait([notifier.refresh(), notifier.refresh(), notifier.refresh()]);
      expect(probe.calls - before, lessThanOrEqualTo(1));
      expect(container.read(connectivityProvider), NetworkStatus.online);
    });

    test('le réseau qui revient est constaté', () async {
      container = build(reachable: false);
      await container.read(connectivityProvider.notifier).refresh();
      expect(container.read(connectivityProvider), NetworkStatus.offline);

      probe.reachable = true;
      await container.read(connectivityProvider.notifier).refresh();
      expect(container.read(connectivityProvider), NetworkStatus.online);
    });
  });

  group('appel protégé', () {
    test('hors ligne, rien n\'est tenté', () async {
      container = build(reachable: false);
      await container.read(connectivityProvider.notifier).refresh();

      final state = await settle();
      expect(state.hasError, isTrue);
      expect(state.error, isA<OfflineException>());
      // C'est tout l'intérêt : l'écran ne part pas attendre une réponse qui
      // ne viendra pas, il le dit tout de suite.
      expect(_attempts, 0);
    });

    test('une panne réseau confirmée devient un hors-ligne', () async {
      container = build();
      probe.reachable = false;
      _call = () async => throw const SocketException('Failed host lookup: x.test');

      final state = await settle();
      expect(state.hasError, isTrue);
      expect(state.error, isA<OfflineException>());
      expect(_attempts, 1);
      expect(container.read(connectivityProvider), NetworkStatus.offline);
    });

    test('un serveur muet n\'est pas un réseau coupé', () async {
      container = build();
      // La sonde répond : le réseau est là, c'est le serveur qui a refusé.
      // L'erreur d'origine remonte telle quelle, sans quoi l'écran dirait
      // « hors ligne » à quelqu'un qui ne l'est pas.
      _call = () async => throw StateError('permission denied');

      final state = await settle();
      expect(state.hasError, isTrue);
      expect(state.error, isA<StateError>());
      expect(container.read(connectivityProvider), NetworkStatus.online);
    });

    test('une réussite confirme la connexion', () async {
      container = build(reachable: false);
      await container.read(connectivityProvider.notifier).refresh();
      expect(container.read(connectivityProvider), NetworkStatus.offline);

      // Le réseau est revenu : la sonde du réessai le voit, et l'appel part.
      probe.reachable = true;
      await container.read(connectivityProvider.notifier).refresh();
      final state = await settle();
      expect(state.hasValue, isTrue);
      expect(state.value, 'ok');
      expect(container.read(connectivityProvider), NetworkStatus.online);
    });
  });
}
