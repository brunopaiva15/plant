import 'package:flora/features/account/application/sign_in_availability.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_auth_repository.dart';

/// La connexion que chaque appareil propose. Une seule par système, et
/// aucune qui n'existe pas : un Android sans client OAuth reste local.
void main() {
  SignInMethod? on(TargetPlatform platform, {bool remote = true, String clientId = ''}) {
    debugDefaultTargetPlatformOverride = platform;
    try {
      return platformSignInMethod(FakeAuthRepository(remote: remote), googleClientId: clientId);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  }

  test('iPhone et iPad : Apple', () {
    expect(on(TargetPlatform.iOS), SignInMethod.apple);
    expect(on(TargetPlatform.iOS, clientId: 'client'), SignInMethod.apple, reason: 'le client Google ne change rien sur iPhone');
  });

  test('Android : Google dès que le client OAuth est renseigné', () {
    expect(on(TargetPlatform.android), isNull);
    expect(on(TargetPlatform.android, clientId: 'client'), SignInMethod.google);
  });

  test('sans backend, aucune connexion', () {
    expect(on(TargetPlatform.iOS, remote: false), isNull);
    expect(on(TargetPlatform.android, remote: false, clientId: 'client'), isNull);
  });

  test('ailleurs, aucune connexion', () {
    expect(on(TargetPlatform.macOS, clientId: 'client'), isNull);
    expect(on(TargetPlatform.linux, clientId: 'client'), isNull);
  });
}
