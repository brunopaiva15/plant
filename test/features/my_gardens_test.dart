import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flora/app/providers.dart';
import 'package:flora/data/db/database.dart';
import 'package:flora/domain/auth/auth_repository.dart';
import 'package:flora/domain/sharing/garden_collaboration.dart';
import 'package:flora/features/account/application/membership_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_auth_repository.dart';

/// La liste des jardins se relit du serveur, et recopie en base ce qu'il
/// renvoie. Un renommage, lui, s'écrit d'abord en local et part en file de
/// synchronisation : entre les deux, le serveur porte encore l'ancien nom.
/// C'est le nom local qui doit tenir tant que l'envoi n'a pas eu lieu — sinon
/// le renommage disparaît de l'écran, de la base, et la synchro repart avec
/// l'ancien nom.

const _account = AppUser(id: 'u', displayName: '', isLocal: false);

/// Un compte lié : sans cela, la liste des jardins reste sur l'appareil.
class _RemoteAuth extends FakeAuthRepository {
  _RemoteAuth() : super(remote: true);

  @override
  AppUser? get currentUser => _account;

  @override
  Stream<AppUser?> watchUser() => Stream.value(_account);
}

/// Le serveur, qui ne connaît que ce qu'on lui a déjà envoyé.
class _FakeCollaboration extends UnavailableCollaborationService {
  _FakeCollaboration(this.name);

  String name;

  @override
  bool get isAvailable => true;

  @override
  Future<List<GardenAccess>> gardens() async => [GardenAccess(id: 'g1', name: name, role: GardenRole.owner, ownerId: 'u')];
}

void main() {
  // La liste des jardins regarde la connectivité depuis qu'elle sait dire
  // « hors ligne », et le contrôleur de réseau s'inscrit auprès de
  // WidgetsBinding. Sans liaison, il n'y a pas d'instance à qui s'inscrire.
  TestWidgetsFlutterBinding.ensureInitialized();

  late FloraDatabase db;
  late _FakeCollaboration collaboration;

  setUp(() async {
    db = FloraDatabase(NativeDatabase.memory());
    collaboration = _FakeCollaboration('home');
    final now = DateTime.now();
    await db.into(db.gardens).insert(GardensCompanion.insert(id: 'g1', ownerId: 'u', name: 'home', createdAt: now, updatedAt: now));
  });

  tearDown(() => db.close());

  Future<ProviderContainer> open() async {
    final c = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      collaborationServiceProvider.overrideWithValue(collaboration),
      authRepositoryProvider.overrideWithValue(_RemoteAuth()),
      gardenIdProvider.overrideWithValue('g1'),
    ]);
    addTearDown(c.dispose);
    // La liste ne lit le compte qu'une fois le flux parti : sans compte, elle
    // retomberait sur la branche hors ligne et ne prouverait rien.
    await c.read(currentUserProvider.future);
    return c;
  }

  /// Ce qu'écrit l'écran « Mes jardins » quand on renomme.
  Future<void> rename(String value) => db.transaction(() async {
        await (db.update(db.gardens)..where((g) => g.id.equals('g1')))
            .write(GardensCompanion(name: Value(value), updatedAt: Value(DateTime.now())));
        await db.enqueueSync('gardens', 'g1', 'upsert', const {});
      });

  Future<String> storedName() async => (await (db.select(db.gardens)..where((g) => g.id.equals('g1'))).getSingle()).name;

  test('un renommage pas encore envoyé tient devant le nom du serveur', () async {
    await rename('Le balcon');
    final c = await open();

    final gardens = await c.read(myGardensProvider.future);

    expect(gardens.single.name, 'Le balcon');
    expect(await storedName(), 'Le balcon');
  });

  test('sans écriture en attente, le nom du serveur fait foi', () async {
    collaboration.name = 'Chez Laura';
    final c = await open();

    final gardens = await c.read(myGardensProvider.future);

    expect(gardens.single.name, 'Chez Laura');
    expect(await storedName(), 'Chez Laura');
  });

  test('le nom local cesse de primer une fois la file vidée', () async {
    await rename('Le balcon');
    // La synchro a poussé le renommage et vidé la file ; depuis, le
    // propriétaire a renommé le jardin depuis un autre appareil.
    await db.delete(db.syncOutbox).go();
    collaboration.name = 'La véranda';
    final c = await open();

    final gardens = await c.read(myGardensProvider.future);

    expect(gardens.single.name, 'La véranda');
    expect(await storedName(), 'La véranda');
  });
}
