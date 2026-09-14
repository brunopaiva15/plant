// Diagnostic temporaire : lequel des quatre pas de « Mes jardins » pend ?
// À supprimer dès que la cause est connue.
import 'dart:async';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flora/app/providers.dart';
import 'package:flora/core/network/connectivity.dart';
import 'package:flora/data/db/database.dart';
import 'package:flora/domain/auth/auth_repository.dart';
import 'package:flora/domain/sharing/garden_collaboration.dart';
import 'package:flora/features/account/application/membership_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_auth_repository.dart';

const _account = AppUser(id: 'u', displayName: '', isLocal: false);

class _RemoteAuth extends FakeAuthRepository {
  _RemoteAuth() : super(remote: true);

  @override
  AppUser? get currentUser => _account;

  @override
  Stream<AppUser?> watchUser() => Stream.value(_account);
}

class _FakeCollaboration extends UnavailableCollaborationService {
  _FakeCollaboration(this.name);

  String name;

  @override
  bool get isAvailable => true;

  @override
  Future<List<GardenAccess>> gardens() async =>
      [GardenAccess(id: 'g1', name: name, role: GardenRole.owner, ownerId: 'u')];
}

Future<String> essai(String quoi, Future<dynamic> Function() f) async {
  try {
    final v = await f().timeout(const Duration(seconds: 3));
    return '$quoi → OK ($v)';
  } on TimeoutException {
    return '$quoi → PEND';
  } catch (e) {
    return '$quoi → ERREUR ${e.runtimeType} : $e';
  }
}

void main() {
  test('quel pas pend', () async {
    final db = FloraDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final now = DateTime.now();
    await db.into(db.gardens).insert(
        GardensCompanion.insert(id: 'g1', ownerId: 'u', name: 'home', createdAt: now, updatedAt: now));

    final c = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      collaborationServiceProvider.overrideWithValue(_FakeCollaboration('home')),
      authRepositoryProvider.overrideWithValue(_RemoteAuth()),
      gardenIdProvider.overrideWithValue('g1'),
    ]);
    addTearDown(c.dispose);

    final lignes = <String>[
      await essai('1. flux brut du faux depot', () => c.read(authRepositoryProvider).watchUser().first),
      await essai('2. currentUserProvider.future', () => c.read(currentUserProvider.future)),
      await essai('3. connectivityProvider', () async => c.read(connectivityProvider)),
      await essai('4. myGardensProvider.future', () => c.read(myGardensProvider.future)),
    ];
    // ignore: avoid_print
    print('\n===== DIAGNOSTIC =====\n${lignes.join('\n')}\n======================\n');
  }, timeout: const Timeout(Duration(seconds: 60)));
}
