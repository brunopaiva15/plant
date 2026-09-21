import 'package:drift/native.dart';
import 'package:flora/data/db/database.dart';
import 'package:flora/data/repositories/room_scan_repository_impl.dart';
import 'package:flora/domain/room/room_scan.dart';
import 'package:flora/domain/room/scanned_room.dart';
import 'package:flutter_test/flutter_test.dart';

/// Les relevés en base : une ligne par pièce, des repères à part, et rien
/// dans l'outbox.
void main() {
  late FloraDatabase db;
  late DriftRoomScanRepository repo;
  const garden = 'g1';

  setUp(() {
    db = FloraDatabase(NativeDatabase.memory());
    repo = DriftRoomScanRepository(db, garden);
  });

  tearDown(() => db.close());

  test('créer, lister du plus récent au plus ancien, relire', () async {
    final a = await repo.create(name: 'Salon', filePath: 'a.json', capturedAt: DateTime(2026, 9, 1), northOffsetDeg: 90, floorAreaM2: 15.1, section: RoomSectionLabel.livingRoom);
    final b = await repo.create(name: 'Cuisine', filePath: 'b.json', capturedAt: DateTime(2026, 9, 2));
    final all = await repo.watchAll().first;
    expect(all.map((s) => s.id), [b.id, a.id]);
    final read = await repo.watch(a.id).first;
    expect(read?.name, 'Salon');
    expect(read?.northOffsetDeg, 90);
    expect(read?.floorAreaM2, 15.1);
    expect(read?.section, RoomSectionLabel.livingRoom);
    expect(b.section, isNull);
    expect(b.northOffsetDeg, isNull);
  });

  test("le nom et l'emplacement se changent, le reste tient", () async {
    final a = await repo.create(name: 'Pièce', filePath: 'a.json', capturedAt: DateTime(2026, 9, 1), northOffsetDeg: 45);
    await repo.update(a.copyWith(name: 'Bureau', locationId: () => 'loc1'));
    final read = (await repo.watch(a.id).first)!;
    expect(read.name, 'Bureau');
    expect(read.locationId, 'loc1');
    expect(read.northOffsetDeg, 45);
    expect(read.filePath, 'a.json');
    await repo.update(read.copyWith(locationId: () => null));
    expect((await repo.watch(a.id).first)!.locationId, isNull);
  });

  test("l'orientation d'une fenêtre se pose, se remplace, s'efface", () async {
    final a = await repo.create(name: 'Salon', filePath: 'a.json', capturedAt: DateTime(2026, 9, 1));
    await repo.setWindowOrientation(a.id, 0, CardinalDirection.south, x: -2.1, z: 0.3);
    await repo.setWindowOrientation(a.id, 1, CardinalDirection.east, x: 0, z: 1.8);
    var markers = await repo.watchMarkers(a.id).first;
    expect(markers, hasLength(2));
    expect(markers.first.kind, RoomMarkerKind.windowOrientation);
    expect(markers.first.orientation, CardinalDirection.south);
    expect(markers.first.windowIndex, 0);

    await repo.setWindowOrientation(a.id, 0, CardinalDirection.southWest, x: -2.1, z: 0.3);
    markers = await repo.watchMarkers(a.id).first;
    expect(markers, hasLength(2));
    expect(markers.where((m) => m.windowIndex == 0).single.orientation, CardinalDirection.southWest);

    await repo.setWindowOrientation(a.id, 0, null, x: -2.1, z: 0.3);
    markers = await repo.watchMarkers(a.id).first;
    expect(markers.map((m) => m.windowIndex), [1]);
  });

  test('un radiateur se pose et se retire, sans toucher aux fenêtres', () async {
    final a = await repo.create(name: 'Salon', filePath: 'a.json', capturedAt: DateTime(2026, 9, 1));
    await repo.setWindowOrientation(a.id, 0, CardinalDirection.south, x: -2.1, z: 0.3);
    final h = await repo.addMarker(a.id, RoomMarkerKind.heater, x: 1.0, z: -1.7);
    expect(h.kind, RoomMarkerKind.heater);
    expect(heaterPoints(await repo.watchMarkers(a.id).first), [const RoomPoint(1.0, -1.7)]);
    await repo.removeMarker(h.id);
    final left = await repo.watchMarkers(a.id).first;
    expect(heaterPoints(left), isEmpty);
    expect(left.map((m) => m.kind), [RoomMarkerKind.windowOrientation]);
  });

  test('un radiateur se colle au mur le plus proche', () {
    final room = ScannedRoom(
      walls: const [
        RoomSurface(kind: RoomSurfaceKind.wall, center: RoomPoint(0, -2), along: RoomPoint(1, 0), normal: RoomPoint(0, 1), width: 4, height: 2.7, bottomY: 0),
      ],
      windows: const [],
      doors: const [],
      openings: const [],
      objects: const [],
    );
    expect(room.snapToWall(const RoomPoint(0.5, -1.7)), const RoomPoint(0.5, -2));
    expect(room.snapToWall(const RoomPoint(0.5, 0)), const RoomPoint(0.5, 0));
  });

  test("les pièces d'un appartement partagent leur identifiant de structure", () async {
    final a = await repo.create(name: 'Salon', filePath: 'flat/0.json', capturedAt: DateTime(2026, 9, 1), structureId: 'flat');
    final b = await repo.create(name: 'Cuisine', filePath: 'flat/1.json', capturedAt: DateTime(2026, 9, 1), structureId: 'flat');
    final c = await repo.create(name: 'Bureau', filePath: 'c.json', capturedAt: DateTime(2026, 9, 2));
    final all = await repo.watchAll().first;
    expect(all.where((s) => s.structureId == 'flat').map((s) => s.id), containsAll([a.id, b.id]));
    expect(all.where((s) => s.id == c.id).single.structureId, isNull);
  });

  test('une plante posée sur le plan se retrouve par son identifiant', () async {
    final a = await repo.create(name: 'Salon', filePath: 'a.json', capturedAt: DateTime(2026, 9, 1));
    await repo.addMarker(a.id, RoomMarkerKind.plant, x: 0.5, z: -0.5, plantId: 'p1');
    await repo.addMarker(a.id, RoomMarkerKind.heater, x: 2, z: 0);
    final points = plantPoints(await repo.watchMarkers(a.id).first);
    expect(points, {'p1': const RoomPoint(0.5, -0.5)});
  });

  test("un voilage ou un rideau se lit fenêtre par fenêtre", () async {
    final a = await repo.create(name: 'Salon', filePath: 'a.json', capturedAt: DateTime(2026, 9, 1));
    await repo.addMarker(a.id, RoomMarkerKind.windowSheer, x: 0, z: 0, windowIndex: 0);
    await repo.addMarker(a.id, RoomMarkerKind.windowDrawn, x: 0, z: 0, windowIndex: 2);
    final room = ScannedRoom(
      walls: const [],
      windows: const [
        RoomSurface(kind: RoomSurfaceKind.window, center: RoomPoint(0, 0), along: RoomPoint(1, 0), normal: RoomPoint(0, 1), width: 1, height: 1, bottomY: 1),
        RoomSurface(kind: RoomSurfaceKind.window, center: RoomPoint(1, 0), along: RoomPoint(1, 0), normal: RoomPoint(0, 1), width: 1, height: 1, bottomY: 1),
        RoomSurface(kind: RoomSurfaceKind.window, center: RoomPoint(2, 0), along: RoomPoint(1, 0), normal: RoomPoint(0, 1), width: 1, height: 1, bottomY: 1),
      ],
      doors: const [],
      openings: const [],
      objects: const [],
    );
    expect(windowDressings(room, await repo.watchMarkers(a.id).first), [WindowDressing.sheer, WindowDressing.none, WindowDressing.drawn]);
  });

  test('une fenêtre ajoutée à la main porte sa taille dans son genre', () async {
    final a = await repo.create(name: 'Salon', filePath: 'a.json', capturedAt: DateTime(2026, 9, 1));
    final w = await repo.addMarker(a.id, RoomMarkerKind.windowWide, x: -2.0, z: 0.3);
    expect(w.kind.handWindow, HandWindow.wide);
    expect(RoomMarkerKind.of(HandWindow.small), RoomMarkerKind.windowSmall);
    expect(handWindowMarkers(await repo.watchMarkers(a.id).first).map((m) => m.id), [w.id]);
  });

  test('retirer une fenêtre de la main fait descendre les rangs au-dessus', () async {
    final a = await repo.create(name: 'Salon', filePath: 'a.json', capturedAt: DateTime(2026, 9, 1));
    // Une fenêtre au relevé (rang 0), deux ajoutées à la main (rangs 1 et 2).
    await repo.setWindowOrientation(a.id, 0, CardinalDirection.south, x: 0, z: 0);
    await repo.addMarker(a.id, RoomMarkerKind.windowStandard, x: -2.0, z: 0.3);
    await repo.addMarker(a.id, RoomMarkerKind.windowSmall, x: 2.0, z: 0.3);
    await repo.setWindowOrientation(a.id, 1, CardinalDirection.east, x: -2.0, z: 0.3);
    await repo.addMarker(a.id, RoomMarkerKind.windowDrawn, x: 2.0, z: 0.3, windowIndex: 2);

    // Le rang d'une fenêtre de la main est sa place dans la liste des
    // repères : c'est celle-là qu'on retire.
    final hands = handWindowMarkers(await repo.watchMarkers(a.id).first);
    expect(hands, hasLength(2));
    await repo.removeWindow(hands.first.id, scanId: a.id, windowIndex: 1);
    final left = await repo.watchMarkers(a.id).first;
    expect(handWindowMarkers(left).map((m) => m.id), [hands.last.id]);
    // Son orientation part avec elle ; le rideau de la suivante la suit,
    // et la fenêtre du relevé garde son rang.
    expect(left.where((m) => m.kind == RoomMarkerKind.windowOrientation).map((m) => m.windowIndex), [0]);
    expect(left.where((m) => m.kind == RoomMarkerKind.windowDrawn).single.windowIndex, 1);
  });

  test('supprimer retire le relevé et ses repères', () async {
    final a = await repo.create(name: 'Salon', filePath: 'a.json', capturedAt: DateTime(2026, 9, 1));
    await repo.setWindowOrientation(a.id, 0, CardinalDirection.south, x: 0, z: 0);
    await repo.delete(a.id);
    expect(await repo.watchAll().first, isEmpty);
    expect(await repo.watch(a.id).first, isNull);
    expect(await repo.watchMarkers(a.id).first, isEmpty);
  });

  test("un autre jardin ne voit pas ces relevés, et rien ne part dans l'outbox", () async {
    await repo.create(name: 'Salon', filePath: 'a.json', capturedAt: DateTime(2026, 9, 1));
    expect(await DriftRoomScanRepository(db, 'g2').watchAll().first, isEmpty);
    expect(await db.select(db.syncOutbox).get(), isEmpty);
  });

  test('les orientations confirmées priment sur la boussole, fenêtre par fenêtre', () {
    final room = ScannedRoom(
      walls: const [
        RoomSurface(kind: RoomSurfaceKind.wall, center: RoomPoint(-2, 0), along: RoomPoint(0, 1), normal: RoomPoint(1, 0), width: 4, height: 2.7, bottomY: 0),
        RoomSurface(kind: RoomSurfaceKind.wall, center: RoomPoint(2, 0), along: RoomPoint(0, 1), normal: RoomPoint(1, 0), width: 4, height: 2.7, bottomY: 0),
      ],
      windows: const [
        RoomSurface(kind: RoomSurfaceKind.window, center: RoomPoint(-2, 0), along: RoomPoint(0, 1), normal: RoomPoint(1, 0), width: 1, height: 1, bottomY: 1),
        RoomSurface(kind: RoomSurfaceKind.window, center: RoomPoint(2, 0), along: RoomPoint(0, 1), normal: RoomPoint(1, 0), width: 1, height: 1, bottomY: 1),
      ],
      doors: const [],
      openings: const [],
      objects: const [],
      northOffsetDeg: 90,
    );
    final now = DateTime(2026);
    final markers = [
      RoomMarker(id: 'm', scanId: 's', kind: RoomMarkerKind.windowOrientation, x: 2, z: 0, windowIndex: 1, orientation: CardinalDirection.east, createdAt: now, updatedAt: now),
    ];
    expect(windowDirections(room, markers), [CardinalDirection.south, CardinalDirection.east]);
    expect(windowDirections(room, const []), [CardinalDirection.south, CardinalDirection.north]);
  });
}
