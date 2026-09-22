import 'dart:convert';
import 'dart:io';

import 'package:flora/domain/room/room_plan_parser.dart';
import 'package:flora/domain/room/scanned_room.dart';
import 'package:flutter_test/flutter_test.dart';

/// Le lecteur du JSON de RoomPlan ne lit que ce que le modèle de lumière
/// consomme, et tolère le reste : un champ absent vaut une liste vide, une
/// surface illisible est ignorée, jamais une erreur.
void main() {
  Map<String, Object?> fixture() =>
      Map<String, Object?>.from(jsonDecode(File('test/domain/fixtures/roomplan_diorama.json').readAsStringSync()) as Map);

  test('la pièce du diorama se lit : murs, fenêtre, porte, table, sol, section', () {
    final room = RoomPlanParser.parse(fixture());
    expect(room.walls, hasLength(4));
    expect(room.windows, hasLength(1));
    expect(room.doors, hasLength(1));
    expect(room.openings, isEmpty);
    expect(room.objects.map((o) => o.category), ['table']);
    expect(room.floorPolygon, hasLength(4));
    expect(room.section, RoomSectionLabel.livingRoom);
    expect(room.floorAreaM2, closeTo(4.2 * 3.6, 1e-6));
    expect(room.floorY, closeTo(0, 1e-6));
  });

  test("la fenêtre garde son appui, sa hauteur et son mur", () {
    final w = RoomPlanParser.parse(fixture()).windows.single;
    expect(w.bottomY, closeTo(0.75, 1e-6));
    expect(w.topY, closeTo(2.25, 1e-6));
    expect(w.width, 1.5);
    expect(w.parentId, 'WALL_LEFT');
    expect(w.center.x, closeTo(-2.1, 1e-6));
    // Sur le mur −x, la largeur court le long de z et la normale le long de x.
    expect(w.along.x.abs(), lessThan(1e-6));
    expect(w.normal.x.abs(), closeTo(1, 1e-6));
  });

  test("la normale intérieure regarde vers le milieu de la pièce", () {
    final room = RoomPlanParser.parse(fixture());
    final inward = room.inwardNormal(room.windows.single);
    expect(inward.x, closeTo(1, 1e-6));
    expect(room.contains(const RoomPoint(0, 0)), isTrue);
    expect(room.contains(const RoomPoint(3, 0)), isFalse);
  });

  test("le cap d'une direction, puis l'orientation d'une fenêtre par le nord mesuré", () {
    expect(ScannedRoom.headingOf(const RoomPoint(0, -1)), closeTo(0, 1e-9));
    expect(ScannedRoom.headingOf(const RoomPoint(1, 0)), closeTo(90, 1e-9));
    expect(ScannedRoom.headingOf(const RoomPoint(0, 1)), closeTo(180, 1e-9));
    expect(ScannedRoom.headingOf(const RoomPoint(-1, 0)), closeTo(270, 1e-9));
    final south = RoomPlanParser.parse(fixture(), northOffsetDeg: 90);
    expect(south.windowDirection(south.windows.single), CardinalDirection.south);
    final west = RoomPlanParser.parse(fixture(), northOffsetDeg: 0);
    expect(west.windowDirection(west.windows.single), CardinalDirection.west);
  });

  test('un JSON vide donne une pièce vide, pas une erreur', () {
    final room = RoomPlanParser.parse(const {});
    expect(room.walls, isEmpty);
    expect(room.windows, isEmpty);
    expect(room.section, isNull);
    expect(room.floorAreaM2, 0);
  });

  test('une surface sans transformation ou sans dimensions est ignorée, les autres restent', () {
    final json = fixture();
    json['windows'] = [
      {'category': {'window': {}}, 'dimensions': [1, 1, 0]},
      {'category': {'window': {}}, 'transform': [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 1, 0, 1]},
      ...(json['windows'] as List),
    ];
    expect(RoomPlanParser.parse(json).windows, hasLength(1));
  });

  test('les catégories se lisent en chaîne comme en dictionnaire, et la matrice en colonnes imbriquées', () {
    final json = fixture();
    json['objects'] = [
      {
        'category': 'storage',
        'dimensions': [0.8, 1.9, 0.4],
        'transform': [
          [1, 0, 0, 0],
          [0, 1, 0, 0],
          [0, 0, 1, 0],
          [1.5, 0.95, 1.2, 1],
        ],
      },
    ];
    final o = RoomPlanParser.parse(json).objects.single;
    expect(o.category, 'storage');
    expect(o.center, const RoomPoint(1.5, 1.2));
    expect(o.topY, closeTo(1.9, 1e-6));
    expect(o.contains(const RoomPoint(1.6, 1.1)), isTrue);
  });

  test("un vide dont l'appui est au-dessus du sol est une fenêtre, un passage non", () {
    // RoomPlan range dans les ouvertures ce qu'il n'a pas reconnu comme
    // fenêtre : un trou à quatre-vingt-dix centimètres du sol ne se
    // traverse pas, et la pièce le lit comme une fenêtre. Le passage, lui,
    // part du sol et reste une ouverture.
    final json = fixture();
    json['openings'] = [
      {
        'identifier': 'OPENING_HIGH',
        'parentIdentifier': 'WALL_RIGHT',
        'category': {'opening': <String, Object?>{}},
        'dimensions': [1.4, 1.2, 0.0],
        'transform': roomPlanTransform(x: 2.1, y: 1.5, z: 0.5, yawDeg: 90),
      },
      {
        'identifier': 'DOORWAY',
        'parentIdentifier': 'WALL_BACK',
        'category': {'opening': <String, Object?>{}},
        'dimensions': [0.9, 2.1, 0.0],
        'transform': roomPlanTransform(x: -1.0, y: 1.05, z: 1.8),
      },
    ];
    final room = RoomPlanParser.parse(json);
    expect(room.openings.single.id, 'DOORWAY');
    // Elle vient après la fenêtre du relevé : les rangs du JSON tiennent.
    expect(room.windows.map((w) => w.id), ['WINDOW_1', 'OPENING_HIGH']);
    final w = room.windows.last;
    expect(w.kind, RoomSurfaceKind.window);
    expect(w.bottomY, closeTo(0.9, 1e-6));
    expect(w.width, 1.4);
    expect(w.parentId, 'WALL_RIGHT');
    expect(w.byHand, isFalse);
  });

  test('la section retenue est la plus proche du milieu des murs', () {
    final json = fixture();
    json['sections'] = [
      {'label': 'kitchen', 'center': [9, 0, 9]},
      {'label': 'bedroom', 'center': [0.1, 0, 0.1]},
      {'label': 'unknownLabel', 'center': [0, 0, 0]},
    ];
    expect(RoomPlanParser.parse(json).section, RoomSectionLabel.bedroom);
  });

  test('roomPlanTransform pose la largeur, le haut et la normale', () {
    final t = roomPlanTransform(x: 1, y: 2, z: 3, yawDeg: 90);
    expect(t[12], 1);
    expect(t[13], 2);
    expect(t[14], 3);
    expect(t[0], closeTo(0, 1e-9));
    expect(t[2], closeTo(-1, 1e-9));
    expect(t[8], closeTo(1, 1e-9));
  });
}
