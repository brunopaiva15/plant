import 'dart:io';

import 'package:drift/native.dart';
import 'package:flora/app/providers.dart';
import 'package:flora/data/db/database.dart';
import 'package:flora/data/services/preferences_service.dart';
import 'package:flora/data/services/room_scan_service.dart';
import 'package:flora/domain/repositories/repositories.dart';
import 'package:flora/domain/room/scanned_room.dart';
import 'package:flora/features/plants/application/plant_providers.dart';
import 'package:flora/features/room_scan/application/room_scan_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Le relevé vit avec le jardin : une pièce relevée depuis la fiche d'un
/// emplacement lui est liée d'emblée, une pièce reconnue va à l'emplacement
/// qui porte son nom, et la fiche d'une plante sait où elle est posée — ou
/// où elle irait dans la pièce de son emplacement.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FloraDatabase db;
  late Directory root;
  late ProviderContainer c;

  setUp(() async {
    db = FloraDatabase(NativeDatabase.memory());
    final now = DateTime(2026, 9, 20);
    await db.into(db.gardens).insert(GardensCompanion.insert(id: 'g1', ownerId: 'u', name: 'home', createdAt: now, updatedAt: now));
    root = await Directory.systemTemp.createTemp('rooms');
    SharedPreferences.setMockInitialValues({});
    final prefs = await PreferencesService.load();
    c = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      gardenIdProvider.overrideWithValue('g1'),
      preferencesServiceProvider.overrideWithValue(prefs),
      roomScanStoreProvider.overrideWithValue(RoomScanStore(root: root)),
      roomScanServiceProvider.overrideWithValue(_FixtureRoomScanService()),
    ]);
    // Les flux se lisent tout au long : un provider dérivé ne voit une
    // liste qu'à travers un abonné.
    c.listen(roomScansProvider, (_, _) {});
    c.listen(locationsProvider, (_, _) {});
  });

  tearDown(() async {
    c.dispose();
    await db.close();
    await root.delete(recursive: true);
  });

  RoomScanController controller() => c.read(roomScanControllerProvider.notifier);
  String nameFor(RoomSectionLabel? s) => s == RoomSectionLabel.livingRoom ? 'Salon' : 'Pièce';

  /// Attend que tout ce qui se lit en flux soit lu, puis rend la valeur.
  Future<T> settled<T>(Provider<T> provider, {List<String> scanIds = const [], List<String> plantIds = const []}) async {
    final sub = c.listen(provider, (_, _) {});
    await c.read(roomScansProvider.future);
    await c.read(locationsProvider.future);
    for (final id in scanIds) {
      await c.read(scannedRoomProvider(id).future);
      await c.read(roomMarkersProvider(id).future);
    }
    for (final id in plantIds) {
      await c.read(plantSummaryProvider(id).future);
    }
    await Future<void>.delayed(Duration.zero);
    final value = c.read(provider);
    sub.close();
    return value;
  }

  test("relevée depuis la fiche d'un emplacement, la pièce lui est liée", () async {
    final salon = await c.read(locationRepositoryProvider).create(name: 'Salon', icon: '🛋️');
    final outcome = await controller().scan(nameFor: nameFor, locationId: salon.id);
    expect(outcome.scan?.locationId, salon.id);
    expect(await settled(roomScanForLocationProvider(salon.id)), isNotNull);
  });

  test("une pièce reconnue va d'elle-même à l'emplacement qui porte son nom", () async {
    final salon = await c.read(locationRepositoryProvider).create(name: 'salon', icon: '🛋️');
    await c.read(locationRepositoryProvider).create(name: 'Cuisine', icon: '🍳');
    await c.read(locationsProvider.future);
    final first = await controller().scan(nameFor: nameFor);
    expect(first.scan?.name, 'Salon');
    expect(first.scan?.locationId, salon.id, reason: 'la casse ne compte pas');
    // Une seconde pièce du même nom ne prend pas la place de la première.
    await c.read(roomScansProvider.future);
    await Future<void>.delayed(Duration.zero);
    final second = await controller().scan(nameFor: nameFor);
    expect(second.scan?.locationId, isNull);
  });

  test('deux emplacements du même nom : rien ne se lie, la main décide', () async {
    await c.read(locationRepositoryProvider).create(name: 'Salon', icon: '🛋️');
    await c.read(locationRepositoryProvider).create(name: 'Salon', icon: '🖥️');
    await c.read(locationsProvider.future);
    final outcome = await controller().scan(nameFor: nameFor);
    expect(outcome.scan?.locationId, isNull);
  });

  test("la place d'une plante : sa pièce, posée ou non, et rien hors de la maison relevée", () async {
    final salon = await c.read(locationRepositoryProvider).create(name: 'Salon', icon: '🛋️');
    final chambre = await c.read(locationRepositoryProvider).create(name: 'Chambre', icon: '🛏️');
    final plants = c.read(plantRepositoryProvider);
    final monstera = await plants.create(NewPlant(name: 'Monstera', speciesName: 'Monstera deliciosa', locationId: salon.id));
    final inconnue = await plants.create(NewPlant(name: 'Inconnue', locationId: salon.id));
    final ailleurs = await plants.create(NewPlant(name: 'Ailleurs', speciesName: 'Monstera deliciosa', locationId: chambre.id));
    final scan = (await controller().scan(nameFor: nameFor, locationId: salon.id)).scan!;

    // Dans un emplacement relevé, sans être posée : la pièce dit où elle irait.
    var place = await settled<PlantRoomPlace?>(plantRoomPlaceProvider(monstera.id), scanIds: [scan.id], plantIds: [monstera.id]);
    expect(place, isNotNull);
    expect(place!.scan.id, scan.id);
    expect(place.onPlan, isFalse);
    expect(place.generic, isFalse);
    expect(place.fit, isNotNull);
    expect(place.fit!.placements, isNotEmpty);
    expect(place.betterElsewhere, isFalse);

    // Sans espèce : la pièce, mais rien à juger.
    final generic = await settled<PlantRoomPlace?>(plantRoomPlaceProvider(inconnue.id), scanIds: [scan.id], plantIds: [inconnue.id]);
    expect(generic, isNotNull);
    expect(generic!.generic, isTrue);
    expect(generic.fit, isNull);

    // Hors de toute pièce relevée : rien.
    expect(await settled<PlantRoomPlace?>(plantRoomPlaceProvider(ailleurs.id), scanIds: [scan.id], plantIds: [ailleurs.id]), isNull);

    // Posée sur le plan, elle est jugée là où elle est.
    final room = (await c.read(scannedRoomProvider(scan.id).future))!;
    final best = place.fit!.placements.first.point;
    await controller().placePlant(scan.id, monstera.id, best, locationId: scan.locationId);
    place = await settled<PlantRoomPlace?>(plantRoomPlaceProvider(monstera.id), scanIds: [scan.id], plantIds: [monstera.id]);
    expect(place!.onPlan, isTrue);
    expect(place.current, isNotNull);
    expect(place.current!.score, place.fit!.placements.first.score);
    expect(place.betterElsewhere, isFalse);
    expect(room.windows, isNotEmpty);

    // Posée au fond, loin de la fenêtre, une plante de lumière vive serait
    // mieux ailleurs : la fiche le dit.
    final (minX, minZ, maxX, maxZ) = room.bounds;
    final far = _farthestFromWindow(room, place.fit!.all.map((p) => p.point).toList());
    await controller().placePlant(scan.id, monstera.id, far);
    place = await settled<PlantRoomPlace?>(plantRoomPlaceProvider(monstera.id), scanIds: [scan.id], plantIds: [monstera.id]);
    expect(place!.onPlan, isTrue);
    expect(place.betterElsewhere, isTrue, reason: 'au fond (${far.x}, ${far.z}) dans [$minX..$maxX]×[$minZ..$maxZ]');
  });

  test("ce que le relevé propose à l'emplacement, et plus rien une fois renseigné", () async {
    final salon = await c.read(locationRepositoryProvider).create(name: 'Salon', icon: '🛋️');
    final scan = (await controller().scan(nameFor: nameFor, locationId: salon.id)).scan!;
    final suggestion = await settled(roomFillSuggestionProvider(scan.id), scanIds: [scan.id]);
    expect(suggestion, isNotNull);
    expect(suggestion!.orientation, CardinalDirection.south);
    expect(suggestion.light, isNotNull);

    final location = (await c.read(locationsProvider.future)).single;
    await controller().fillLocation(location, orientation: 'Sud', light: 'high');
    await c.read(locationsProvider.future);
    await Future<void>.delayed(Duration.zero);
    final filled = (await c.read(locationsProvider.future)).single;
    expect(filled.orientation, 'Sud');
    expect(filled.light, 'high');
    expect(await settled(roomFillSuggestionProvider(scan.id), scanIds: [scan.id]), isNull);
  });
}

/// Le point évalué le plus loin de la première fenêtre : là où une plante
/// de lumière vive manque de jour.
RoomPoint _farthestFromWindow(ScannedRoom room, List<RoomPoint> candidates) {
  final w = room.windows.first.center;
  candidates.sort((a, b) => b.distanceTo(w).compareTo(a.distanceTo(w)));
  return candidates.first;
}

/// Un relevé de laboratoire : la pièce du diorama, écrite là où on le
/// demande, la fenêtre au sud.
class _FixtureRoomScanService implements RoomScanService {
  @override
  bool get isSupported => true;

  @override
  Future<RoomScanSupport> support() async => const RoomScanSupport(lidar: true, sections: true, structure: true);

  @override
  Future<RoomScanResult?> scan({required String toPath}) async {
    await File('test/domain/fixtures/roomplan_diorama.json').copy(toPath);
    return RoomScanResult(paths: [toPath], northOffsetDeg: 90);
  }

  @override
  Future<RoomScanResult?> scanStructure({required String toDirectory, required String nextRoomLabel}) async => null;
}
