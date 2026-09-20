import 'dart:convert';
import 'dart:io';

import 'package:flora/domain/care/care_profile.dart';
import 'package:flora/domain/room/room_light_model.dart';
import 'package:flora/domain/room/room_plan_parser.dart';
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

  test("un meuble haut cache la fenêtre, un meuble bas non", () {
    ScannedRoom withObject(double height) => ScannedRoom(
          walls: room.walls,
          windows: room.windows,
          doors: const [],
          openings: const [],
          objects: [RoomObject(category: 'storage', center: const RoomPoint(-1.0, 0.3), along: const RoomPoint(0, 1), width: 1.0, length: 0.4, height: height, bottomY: 0)],
          northOffsetDeg: 90,
        );
    expect(RoomLightModel.lightAt(withObject(2.0), const RoomPoint(0.16, 0.3)), LightNeed.shade);
    expect(RoomLightModel.lightAt(withObject(0.2), const RoomPoint(0.16, 0.3)), LightNeed.brightIndirect);
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
