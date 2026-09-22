import 'dart:convert';
import 'dart:io';

import 'package:flora/domain/care/care_profile.dart';
import 'package:flora/domain/room/room_light_model.dart';
import 'package:flora/domain/room/room_plan_parser.dart';
import 'package:flora/domain/room/room_scan.dart';
import 'package:flora/domain/room/scanned_room.dart';
import 'package:flutter_test/flutter_test.dart';

/// Le modèle de lumière est calibré sur la pièce du diorama : les six
/// emplacements de la scène (`tool/care_scene/common.py`, `SLOTS`) rendent
/// leurs six crans, du fond de la pièce jusque dans la tache de soleil. Le
/// modèle est ainsi l'inverse de `slotFor` sur la pièce de référence, et un
/// seuil déplacé à la main casse ce test avant de casser une fiche.
void main() {
  late ScannedRoom room;

  setUpAll(() {
    final json = jsonDecode(File('test/domain/fixtures/roomplan_diorama.json').readAsStringSync()) as Map;
    // La fenêtre est sur le mur −x : sa normale dehors pointe vers −x, cap
    // 270 dans le repère ; le nord à 90 la fait donner au sud.
    room = RoomPlanParser.parse(Map<String, Object?>.from(json), northOffsetDeg: 90);
  });

  // Les six emplacements du diorama, (x, y) Blender lus (x, z) ici.
  const slots = <LightNeed, RoomPoint>{
    LightNeed.shade: RoomPoint(1.15, 0.85),
    LightNeed.lowLight: RoomPoint(0.82, 0.79),
    LightNeed.indirect: RoomPoint(0.49, 0.73),
    LightNeed.brightIndirect: RoomPoint(0.16, 0.67),
    LightNeed.someSun: RoomPoint(-0.17, 0.61),
    LightNeed.fullSun: RoomPoint(-0.50, 0.55),
  };

  test('la fenêtre du diorama donne au sud', () {
    expect(room.windows, hasLength(1));
    expect(room.windowDirection(room.windows.single), CardinalDirection.south);
  });

  test('les six emplacements du diorama rendent leurs six crans', () {
    for (final entry in slots.entries) {
      expect(RoomLightModel.lightAt(room, entry.value), entry.key, reason: '${entry.value}');
    }
  });

  test("l'apport décroît strictement du soleil au fond de la pièce", () {
    final totals = [for (final p in slots.values) RoomLightModel.sample(room, p, height: RoomLightModel.potHeight, southern: false).total];
    for (var i = 1; i < totals.length; i++) {
      expect(totals[i], greaterThan(totals[i - 1]));
    }
  });

  test("dans l'hémisphère sud, la même fenêtre donne au nord et la tache disparaît", () {
    final light = RoomLightModel.lightAt(room, slots[LightNeed.fullSun]!, southern: true);
    expect(light, isNot(LightNeed.fullSun));
    expect(light.index, lessThanOrEqualTo(LightNeed.brightIndirect.index));
  });

  test('une orientation confirmée prime sur la boussole', () {
    final north = RoomLightModel.lightAt(room, slots[LightNeed.fullSun]!, directions: const [CardinalDirection.north]);
    expect(north, isNot(LightNeed.fullSun));
    expect(RoomLightModel.lightAt(room, slots[LightNeed.fullSun]!, directions: const [CardinalDirection.south]), LightNeed.fullSun);
  });

  test("sans nord, une fenêtre compte pour l'est ou l'ouest, sans soleil", () {
    final blind = RoomPlanParser.parse(
      Map<String, Object?>.from(jsonDecode(File('test/domain/fixtures/roomplan_diorama.json').readAsStringSync()) as Map),
    );
    expect(blind.windowDirection(blind.windows.single), isNull);
    expect(RoomLightModel.lightAt(blind, slots[LightNeed.fullSun]!), LightNeed.brightIndirect);
  });

  test('un mur entre le point et la fenêtre la cache', () {
    // Une cloison au milieu de la pièce, parallèle à la fenêtre.
    final walled = ScannedRoom(
      walls: [
        ...room.walls,
        const RoomSurface(kind: RoomSurfaceKind.wall, center: RoomPoint(0, 0), along: RoomPoint(0, 1), normal: RoomPoint(1, 0), width: 3.6, height: 2.7, bottomY: 0),
      ],
      windows: room.windows,
      doors: const [],
      openings: const [],
      objects: const [],
      northOffsetDeg: 90,
    );
    expect(RoomLightModel.lightAt(walled, const RoomPoint(1.0, 0.5)), LightNeed.shade);
    expect(RoomLightModel.lightAt(walled, const RoomPoint(-1.0, 0.5)), LightNeed.fullSun);
  });

  test("une armoire cache la fenêtre, un bureau non", () {
    ScannedRoom withObject(double height) => ScannedRoom(
          walls: room.walls,
          windows: room.windows,
          doors: const [],
          openings: const [],
          objects: [RoomObject(category: 'storage', center: const RoomPoint(-1.0, 0.3), along: const RoomPoint(0, 1), width: 1.0, length: 0.4, height: height, bottomY: 0)],
          northOffsetDeg: 90,
        );
    expect(RoomLightModel.lightAt(withObject(2.0), const RoomPoint(0.16, 0.3)), LightNeed.shade);
    // La visée monte du pot au milieu de la vitre : un bureau de 75 cm
    // passe dessous, et la lumière lui passe au-dessus.
    expect(RoomLightModel.lightAt(withObject(0.75), const RoomPoint(0.16, 0.3)), LightNeed.brightIndirect);
    expect(RoomLightModel.lightAt(withObject(0.2), const RoomPoint(0.16, 0.3)), LightNeed.brightIndirect);
    // Le même bureau, collé à la vitre, la cache : là, la visée est haute.
    final against = ScannedRoom(
      walls: room.walls,
      windows: room.windows,
      doors: const [],
      openings: const [],
      objects: [RoomObject(category: 'storage', center: const RoomPoint(-1.9, 0.3), along: const RoomPoint(0, 1), width: 1.0, length: 0.4, height: 1.6, bottomY: 0)],
      northOffsetDeg: 90,
    );
    expect(RoomLightModel.lightAt(against, const RoomPoint(0.16, 0.3)), LightNeed.shade);
  });

  test("un bureau collé à la vitre ombre le sol derrière lui, sans le noircir", () {
    // Un bureau de 75 cm contre la fenêtre, et un pot à un mètre d'elle :
    // le jour lui arrive toujours — la visée passe au-dessus du bureau —,
    // mais le rayon du soleil, lui, s'arrête sur le bureau.
    final desk = ScannedRoom(
      walls: room.walls,
      windows: room.windows,
      doors: const [],
      openings: const [],
      objects: [RoomObject(category: 'table', center: const RoomPoint(-1.8, 0.4), along: const RoomPoint(0, 1), width: 1.0, length: 0.4, height: 0.75, bottomY: 0)],
      northOffsetDeg: 90,
    );
    const behind = RoomPoint(-1.1, 0.45);
    expect(RoomLightModel.lightAt(room, behind), LightNeed.fullSun);
    expect(RoomLightModel.lightAt(desk, behind), LightNeed.brightIndirect);
  });

  test("une fenêtre ajoutée à la main éclaire comme celles du relevé", () {
    // La même pièce dont le relevé aurait manqué la fenêtre — un rideau
    // tiré devant : sans elle, le fond de la pièce est dans l'ombre.
    final missed = ScannedRoom(walls: room.walls, windows: const [], doors: const [], openings: const [], objects: const [], northOffsetDeg: 90);
    expect(RoomLightModel.lightAt(missed, slots[LightNeed.fullSun]!), LightNeed.shade);
    final added = missed.handWindowAt(const RoomPoint(-2.0, 0.3), HandWindow.wide);
    expect(added, isNotNull);
    // Elle se couche sur le mur le plus proche, à sa largeur, et prend son
    // orientation : le mur −x du diorama donne au sud.
    expect(added!.center.x, closeTo(-2.1, 1e-9));
    expect(added.center.z, closeTo(0.3, 1e-9));
    expect(added.width, closeTo(2.2, 1e-9));
    expect(added.byHand, isTrue);
    final fixed = missed.withWindows([added]);
    expect(fixed.windows, hasLength(1));
    expect(fixed.windowDirection(added), CardinalDirection.south);
    expect(RoomLightModel.lightAt(fixed, slots[LightNeed.fullSun]!), LightNeed.fullSun);
    expect(RoomLightModel.lightAt(fixed, slots[LightNeed.shade]!).index, greaterThan(LightNeed.shade.index));
  });

  test("une fenêtre posée sur un vide en prend les mesures, et le vide lui cède la place", () {
    // Le relevé a pris la baie du mur −x pour un vide : au ras du sol, il
    // n'est pas relu comme une fenêtre, et c'est la main qui le dit. Le
    // doigt vise le vide, la fenêtre s'y couche à ses mesures — pas à
    // celles de la taille demandée —, et le trou cesse d'être un trou.
    const bay = RoomSurface(
      kind: RoomSurfaceKind.opening,
      center: RoomPoint(-2.1, 0.3),
      along: RoomPoint(0, 1),
      normal: RoomPoint(1, 0),
      width: 2.4,
      height: 2.2,
      bottomY: 0,
      id: 'BAY',
      parentId: 'WALL_LEFT',
    );
    final missed = ScannedRoom(walls: room.walls, windows: const [], doors: const [], openings: const [bay], objects: const [], northOffsetDeg: 90);
    expect(RoomLightModel.isDrafty(missed, const RoomPoint(-1.5, 0.3)), isTrue);
    final added = missed.handWindowAt(const RoomPoint(-2.0, 0.3), HandWindow.standard);
    expect(added, isNotNull);
    expect(added!.width, 2.4);
    expect(added.height, 2.2);
    expect(added.bottomY, 0);
    expect(added.byHand, isTrue);
    final fixed = missed.withWindows([added]);
    expect(fixed.windows.single.id, 'BAY');
    expect(fixed.openings, isEmpty);
    expect(RoomLightModel.isDrafty(fixed, const RoomPoint(-1.5, 0.3)), isFalse);
    expect(RoomLightModel.lightAt(fixed, slots[LightNeed.fullSun]!), LightNeed.fullSun);
    // Dehors, le vide n'éclaire pas une seconde fois.
    expect(fixed.asOutdoor().windows, hasLength(1));
  });

  test("le doigt qui vise le mur plein pose une fenêtre à sa taille", () {
    const bay = RoomSurface(
      kind: RoomSurfaceKind.opening,
      center: RoomPoint(-2.1, 1.2),
      along: RoomPoint(0, 1),
      normal: RoomPoint(1, 0),
      width: 0.9,
      height: 2.2,
      bottomY: 0,
      id: 'BAY',
    );
    final missed = ScannedRoom(walls: room.walls, windows: const [], doors: const [], openings: const [bay], objects: const [], northOffsetDeg: 90);
    // Le même mur, mais à un mètre et demi du vide : c'est le mur qui porte.
    final added = missed.handWindowAt(const RoomPoint(-2.0, -0.6), HandWindow.small);
    expect(added, isNotNull);
    expect(added!.width, HandWindow.small.width);
    expect(added.center.z, closeTo(-0.6, 1e-9));
    expect(added.bottomY, closeTo(HandWindow.small.sill, 1e-9));
    expect(missed.withWindows([added]).openings, hasLength(1));
  });

  test("les fenêtres de la main viennent après celles du relevé", () {
    final now = DateTime(2026);
    RoomMarker window(String id, RoomMarkerKind kind, double x) =>
        RoomMarker(id: id, scanId: 's', kind: kind, x: x, z: 0.3, createdAt: now, updatedAt: now);
    final markers = [window('a', RoomMarkerKind.windowWide, -2.0), window('b', RoomMarkerKind.windowSmall, 2.0)];
    final full = room.withWindows(handWindows(room, markers));
    expect(full.windows, hasLength(3));
    expect(full.windows.map((w) => w.byHand), [false, true, true]);
    // Le rang d'une fenêtre du relevé ne bouge pas : son orientation et son
    // rideau restent les siens.
    expect(windowDirections(full, markers), [CardinalDirection.south, CardinalDirection.south, CardinalDirection.north]);
    expect(handWindowMarkerAt(full, markers, 0), isNull);
    expect(handWindowMarkerAt(full, markers, 1)?.id, 'a');
    expect(handWindowMarkerAt(full, markers, 2)?.id, 'b');
  });

  test('la latitude allonge ou raccourcit la tache de soleil', () {
    // Sans lieu, 45° : la tache porte aussi loin que la fenêtre est haute.
    expect(RoomLightModel.sunElevationFor(null), 45);
    expect(RoomLightModel.sunReach(room, room.windows.single), closeTo(2.25, 1e-9));
    // À Paris, le soleil de mi-saison est plus bas : la tache va plus loin,
    // et l'emplacement « à côté » du diorama passe dans le bord de la tache.
    expect(RoomLightModel.sunElevationFor(48.9), closeTo(41.1, 1e-9));
    expect(RoomLightModel.sunReach(room, room.windows.single, sunElevationDeg: 41.1), greaterThan(2.5));
    expect(RoomLightModel.lightAt(room, slots[LightNeed.brightIndirect]!, sunElevationDeg: 41.1), LightNeed.someSun);
    // Sous les tropiques, le soleil est haut : la tache reste au pied de la fenêtre.
    expect(RoomLightModel.sunElevationFor(-10), 75);
    expect(RoomLightModel.lightAt(room, slots[LightNeed.someSun]!, sunElevationDeg: 75), LightNeed.brightIndirect);
    // La latitude sud se lit comme la nord : c'est l'hémisphère qui inverse les fenêtres, pas la latitude.
    expect(RoomLightModel.sunElevationFor(-48.9), RoomLightModel.sunElevationFor(48.9));
  });

  test("un voilage divise la lumière par deux et ôte le soleil direct, un rideau tiré par trois", () {
    final sun = slots[LightNeed.fullSun]!;
    expect(RoomLightModel.lightAt(room, sun, dressings: const [WindowDressing.sheer]), LightNeed.someSun);
    expect(RoomLightModel.lightAt(room, sun, dressings: const [WindowDressing.drawn]), isNot(isIn([LightNeed.fullSun, LightNeed.someSun])));
    final bare = RoomLightModel.sample(room, slots[LightNeed.brightIndirect]!, height: RoomLightModel.potHeight, southern: false).total;
    final sheer = RoomLightModel.sample(room, slots[LightNeed.brightIndirect]!, height: RoomLightModel.potHeight, southern: false, dressings: const [WindowDressing.sheer]).total;
    final drawn = RoomLightModel.sample(room, slots[LightNeed.brightIndirect]!, height: RoomLightModel.potHeight, southern: false, dressings: const [WindowDressing.drawn]).total;
    expect(sheer, closeTo(bare / 2, 1e-9));
    expect(drawn, closeTo(bare / 3, 1e-9));
  });

  test("un balcon : le côté ouvert éclaire comme une fenêtre, et rien n'y est un courant d'air", () {
    final balcony = ScannedRoom(
      walls: room.walls.where((w) => w.center.x > -2).toList(),
      windows: const [],
      doors: room.doors,
      openings: const [
        RoomSurface(kind: RoomSurfaceKind.opening, center: RoomPoint(-2.1, 0), along: RoomPoint(0, 1), normal: RoomPoint(1, 0), width: 3.6, height: 2.7, bottomY: 0),
      ],
      objects: const [],
      northOffsetDeg: 90,
    ).asOutdoor();
    expect(balcony.windows, hasLength(1));
    expect(balcony.doors, isEmpty);
    expect(RoomLightModel.lightAt(balcony, const RoomPoint(-1.0, 0.0)), LightNeed.fullSun);
    expect(RoomLightModel.isDrafty(balcony, const RoomPoint(1.0, -1.2)), isFalse);
  });

  test("l'air bouge à moins d'un mètre d'une porte", () {
    expect(RoomLightModel.isDrafty(room, const RoomPoint(1.0, -1.2)), isTrue);
    expect(RoomLightModel.isDrafty(room, const RoomPoint(-1.0, 1.0)), isFalse);
  });

  test('le point cardinal le plus proche d’un cap', () {
    expect(CardinalDirection.fromBearing(0), CardinalDirection.north);
    expect(CardinalDirection.fromBearing(359), CardinalDirection.north);
    expect(CardinalDirection.fromBearing(23), CardinalDirection.northEast);
    expect(CardinalDirection.fromBearing(-90), CardinalDirection.west);
    expect(CardinalDirection.fromBearing(202), CardinalDirection.south);
    expect(CardinalDirection.fromBearing(210), CardinalDirection.southWest);
  });
}
