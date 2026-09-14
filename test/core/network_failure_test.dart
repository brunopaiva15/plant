import 'dart:async';
import 'dart:io';

import 'package:flora/core/network/network_failure.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

/// Ce qui sépare « pas de réseau » de « le serveur a refusé ». L'application
/// ne dit pas la même chose dans les deux cas : l'un s'attend, l'autre se
/// corrige.
void main() {
  group('panne réseau', () {
    test('les exceptions de dart:io et de http en sont', () {
      expect(isNetworkFailure(const SocketException('Failed host lookup: x.test')), isTrue);
      expect(isNetworkFailure(TimeoutException('too slow', const Duration(seconds: 20))), isTrue);
      expect(isNetworkFailure(http.ClientException('Connection closed before full header was received')), isTrue);
    });

    test('un client qui enveloppe la panne se reconnaît à son message', () {
      // Les clients Supabase jettent leurs propres types ; l'originale ne
      // survit que dans le texte.
      expect(isNetworkFailure(_Wrapped('AuthRetryableFetchException: offline')), isTrue);
      expect(isNetworkFailure(_Wrapped('ClientException with SocketException: Network is unreachable')), isTrue);
    });

    test('un refus du serveur n\'en est pas un', () {
      expect(isNetworkFailure(_Wrapped('PostgrestException(message: permission denied for table shared_links)')), isFalse);
      expect(isNetworkFailure(_Wrapped('invalid_code')), isFalse);
      expect(isNetworkFailure(StateError('sharing unavailable')), isFalse);
    });
  });

  test('le délai laisse passer une connexion lente sans attendre sans fin', () {
    expect(networkTimeout.inSeconds, greaterThanOrEqualTo(10));
    expect(networkTimeout.inMinutes, lessThanOrEqualTo(1));
  });
}

class _Wrapped implements Exception {
  _Wrapped(this.text);

  final String text;

  @override
  String toString() => text;
}
