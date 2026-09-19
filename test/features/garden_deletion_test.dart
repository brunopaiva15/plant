import 'package:drift/native.dart';
import 'package:flora/app/providers.dart';
import 'package:flora/data/db/database.dart';
import 'package:flora/data/services/preferences_service.dart';
import 'package:flora/domain/auth/auth_repository.dart';
import 'package:flora/domain/sharing/garden_collaboration.dart';
import 'package:flora/features/account/application/garden_deletion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes/fake_auth_repository.dart';

/// Supprimer un jardin. Le cas qui l'a demandé : on se déconnecte, on
/// désinstalle, on réinstalle, on se reconnecte — l'installation neuve a créé
/// un jardin vide, et les plantes sont restées dans celui d'avant. Le vide se
/// supprime, et l'appareil adopte celui qu'on rouvre : sans cela il resterait
/// accroché à un jardin qui n'existe plus, et n'enverrait plus rien.
///
/// Un jardin supprimé ne laisse rien derrière lui : ni lignes, ni envois en
/// attente — ceux-ci iraient supprimer là-bas, une par une, des lignes déjà
/// parties avec leur jardin.

class _FakeCollaboration extends UnavailableCollaborationService {
  final deleted = <String>[];

  @override
  bool get isAvailable => true;

  @override
  Future<void> deleteGarden(String gardenId) async => deleted.add(gardenId);
}

/// Un compte lié : sans lui, il n'y a qu'un jardin, celui de l'appareil.
const _account = AppUser(id: 'u', displayName: '', isLocal: false);

class _RemoteAuth extends FakeAuthRepository {
  _RemoteAuth() : super(remote: true);

  @override
  AppUser? get currentUser => _account;

  @override
  Stream<AppUser?> watchUser() => Stream.value(_account);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FloraDatabase db;
  final now = DateTime(2026, 6, 1);

  /// Deux jardins : « g1 », celui de l'appareil, et « g2 », celui du compte,
  /// avec ses plantes.
  setUp(() async {
    db = FloraDatabase(NativeDatabase.memory());
    for (final id in ['g1', 'g2']) {
      await db.into(db.gardens).insert(GardensCompanion.insert(id: id, ownerId: 'u', name: 'home', createdAt: now, updatedAt: now));
      await db.into(db.locations).insert(LocationsCompanion.insert(id: 'l-$id', gardenId: id, name: 'Salon', icon: '🛋️', createdAt: now, updatedAt: now));
    }
  });

  tearDown(() => db.close());

  Future<void> addPlant(String id, String gardenId) async {
    await db.into(db.plants).insert(PlantsCompanion.insert(id: id, gardenId: gardenId, name: 'Monstera', createdAt: now, updatedAt: now));
    await db.into(db.plantPhotos).insert(PlantPhotosCompanion.insert(
          id: 'photo-$id',
          plantId: id,
          filePath: '$id.jpg',
          thumbPath: '${id}_thumb.jpg',
          width: 100,
          height: 100,
          takenAt: now,
          createdAt: now,
        ));
    await db.into(db.plantActions).insert(PlantActionsCompanion.insert(id: 'action-$id', plantId: id, typeKey: 'water', occurredAt: now, createdAt: now));
    await db.into(db.tags).insert(TagsCompanion.insert(id: 'tag-$id', gardenId: gardenId, name: 'Intérieur', createdAt: now));
    await db.into(db.plantTags).insert(PlantTagsCompanion.insert(plantId: id, tagId: 'tag-$id'));
    await db.enqueueSync('plants', id, 'upsert', const {});
    await db.enqueueSync('plant_photos', 'photo-$id', 'upsert', const {});
    await db.enqueueSync('plant_actions', 'action-$id', 'upsert', const {});
    await db.enqueueSync('tags', 'tag-$id', 'upsert', const {});
    await db.enqueueSync('plant_tags', '$id/tag-$id', 'upsert', const {});
  }

  Future<List<String>> queued() async => (await db.select(db.syncOutbox).get()).map((o) => o.entityId).toList();

  group('purgeGarden', () {
    test('un jardin supprimé ne laisse ni lignes ni envois en attente', () async {
      await addPlant('p1', 'g1');
      await addPlant('p2', 'g2');
      await db.enqueueSync('gardens', 'g1', 'upsert', const {});

      await db.purgeGarden('g1');

      expect(await (db.select(db.gardens)..where((g) => g.id.equals('g1'))).getSingleOrNull(), isNull);
      expect((await db.select(db.plants).get()).map((p) => p.id), ['p2']);
      expect((await db.select(db.plantPhotos).get()).map((p) => p.id), ['photo-p2']);
      expect((await db.select(db.plantActions).get()).map((a) => a.id), ['action-p2']);
      expect((await db.select(db.tags).get()).map((t) => t.id), ['tag-p2']);
      expect((await db.select(db.plantTags).get()).map((t) => t.plantId), ['p2']);
      expect((await db.select(db.locations).get()).map((l) => l.id), ['l-g2']);
      expect(await queued(), ['p2', 'photo-p2', 'action-p2', 'tag-p2', 'p2/tag-p2']);
    });

    test('le jardin voisin garde ses lignes', () async {
      await addPlant('p2', 'g2');

      await db.purgeGarden('g1');

      expect(await (db.select(db.gardens)..where((g) => g.id.equals('g2'))).getSingleOrNull(), isNotNull);
      expect((await db.select(db.plants).get()), hasLength(1));
    });
  });

  group('gardenIsEmpty', () {
    test('les emplacements de départ ne comptent pas : personne ne les a mis', () async {
      expect(await gardenIsEmpty(db, 'g1'), isTrue);
    });

    test('une plante suffit à le remplir', () async {
      await addPlant('p1', 'g1');
      expect(await gardenIsEmpty(db, 'g1'), isFalse);
    });

    test('un article d\'inventaire aussi', () async {
      await db.into(db.inventoryItems).insert(InventoryItemsCompanion.insert(
            id: 'i1',
            gardenId: 'g1',
            name: 'Terreau',
            categoryKey: 'soil',
            createdAt: now,
            updatedAt: now,
          ));
      expect(await gardenIsEmpty(db, 'g1'), isFalse);
    });
  });

  group('deleteGarden', () {
    late PreferencesService prefs;
    late _FakeCollaboration collaboration;

    setUp(() async {
      SharedPreferences.setMockInitialValues({'user_id': 'u', 'garden_id': 'g1'});
      prefs = await PreferencesService.load();
      collaboration = _FakeCollaboration();
    });

    /// Un `WidgetRef` de laboratoire : le geste part d'un écran.
    Future<(ProviderContainer, WidgetRef)> open(WidgetTester tester) async {
      final container = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db),
        preferencesServiceProvider.overrideWithValue(prefs),
        collaborationServiceProvider.overrideWithValue(collaboration),
        authRepositoryProvider.overrideWithValue(_RemoteAuth()),
      ]);
      addTearDown(container.dispose);
      late WidgetRef ref;
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: Consumer(builder: (context, widgetRef, _) {
          ref = widgetRef;
          return const SizedBox();
        }),
      ));
      return (container, ref);
    }

    testWidgets("le jardin de l'appareil supprimé, l'appareil adopte celui qu'on ouvre", (tester) async {
      await addPlant('p2', 'g2');
      final (container, ref) = await open(tester);

      await deleteGarden(ref, gardenId: 'g1', openInstead: 'g2', ownInstead: 'g2');
      await tester.pump();

      expect(collaboration.deleted, ['g1'], reason: 'la suppression se décide sur le serveur');
      expect(prefs.gardenId, 'g2');
      expect(container.read(gardenIdProvider), 'g2');
      expect(await (db.select(db.gardens)..where((g) => g.id.equals('g1'))).getSingleOrNull(), isNull);
      expect((await db.select(db.plants).get()).map((p) => p.id), ['p2']);
    });

    testWidgets("un autre jardin supprimé laisse celui de l'appareil en place", (tester) async {
      await addPlant('p2', 'g2');
      final (container, ref) = await open(tester);

      await deleteGarden(ref, gardenId: 'g2', openInstead: 'g1', ownInstead: 'g1');
      await tester.pump();

      expect(prefs.gardenId, 'g1');
      expect(container.read(gardenIdProvider), 'g1');
      expect(await db.select(db.plants).get(), isEmpty);
    });

    testWidgets("sans jardin à nous parmi ceux qui restent, l'appareil s'en crée un neuf", (tester) async {
      final (container, ref) = await open(tester);

      await deleteGarden(ref, gardenId: 'g1', openInstead: 'g2');
      await tester.pump();

      expect(prefs.gardenId, isNot('g1'));
      expect(prefs.gardenId, isNot('g2'), reason: 'la ligne d\'un jardin partagé appartient à quelqu\'un d\'autre');
      expect(container.read(gardenIdProvider), 'g2');
      final fresh = await (db.select(db.gardens)..where((g) => g.id.equals(prefs.gardenId!))).getSingleOrNull();
      expect(fresh, isNotNull);
      expect(fresh!.ownerId, 'u');
    });
  });
}
