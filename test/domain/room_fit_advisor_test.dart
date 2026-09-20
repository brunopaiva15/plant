import 'dart:convert';
import 'dart:io';

import 'package:flora/domain/care/care_profile.dart';
import 'package:flora/domain/room/placement.dart';
import 'package:flora/domain/room/room_fit_advisor.dart';
import 'package:flora/domain/room/room_plan_parser.dart';
import 'package:flora/domain/room/scanned_room.dart';
import 'package:flutter_test/flutter_test.dart';

/// Le conseil est pur : une fiche, une pièce, des places classées. La
/// lumière se juge contre le plancher et l'idéal de la fiche ; l'air qui
/// bouge et la pièce d'eau ne comptent que si la fiche a un avis.
void main() {
  late ScannedRoom room;

  ScannedRoom load({double? north = 90}) {
    final json = jsonDecode(File('test/domain/fixtures/roomplan_diorama.json').readAsStringSync()) as Map;
    return RoomPlanParser.parse(Map<String, Object?>.from(json), northOffsetDeg: north);
  }

  setUpAll(() => room = load());

  CareProfile profile({
    LightNeed light = LightNeed.brightIndirect,
    LightNeed? tolerance,
    HumidityNeed humidity = HumidityNeed.average,
    AirflowPreference? airflow,
  }) =>
      CareProfile(
        wateringSummerDays: 7,
        wateringWinterDays: 14,
        light: light,
        lightTolerance: tolerance,
        humidity: humidity,
        airflow: airflow,
        difficulty: CareDifficulty.easy,
        soil: SoilKind.standard,
      );

  test('une plante de lumière vive trouve sa place à côté de la tache, pas dedans', () {
    final fit = RoomFitAdvisor.place(profile(light: LightNeed.brightIndirect, tolerance: LightNeed.indirect), room);
    expect(fit.verdict, RoomFitVerdict.good);
    expect(fit.placements, isNotEmpty);
    expect(fit.placements.length, lessThanOrEqualTo(RoomFitAdvisor.maxPlacements));
    for (final p in fit.placements) {
      expect(p.score, 1);
      expect(p.light, isIn([LightNeed.brightIndirect, LightNeed.indirect]));
    }
  });

  test('un cactus va dans le soleil, et la place dit la fenêtre sud', () {
    final fit = RoomFitAdvisor.place(profile(light: LightNeed.fullSun, tolerance: LightNeed.someSun), room);
    expect(fit.verdict, RoomFitVerdict.good);
    final first = fit.placements.first;
    expect(first.light, LightNeed.fullSun);
    expect(first.windowDirection, CardinalDirection.south);
    expect(first.windowDistance, lessThan(2.5));
  });

  test("une fougère évite le soleil, et l'idéal passe avant le toléré", () {
    final fit = RoomFitAdvisor.place(profile(light: LightNeed.lowLight, tolerance: LightNeed.shade), room);
    expect(fit.verdict, RoomFitVerdict.good);
    for (final p in fit.placements) {
      expect(p.light.index, lessThanOrEqualTo(LightNeed.lowLight.index));
    }
    expect(fit.placements.first.light, LightNeed.lowLight);
    expect(fit.all.any((p) => p.light == LightNeed.shade && p.score == 1), isTrue);
  });

  test("une plante d'ombre finit au fond, loin des fenêtres", () {
    final fit = RoomFitAdvisor.place(profile(light: LightNeed.shade), room);
    expect(fit.verdict, RoomFitVerdict.good);
    expect(fit.placements.first.light, LightNeed.shade);
    expect(fit.placements.first.deepInRoom, isTrue);
  });

  test("les places retenues sont des zones distinctes, à plus de 60 cm l'une de l'autre", () {
    final fit = RoomFitAdvisor.place(profile(light: LightNeed.indirect, tolerance: LightNeed.lowLight), room);
    for (var i = 0; i < fit.placements.length; i++) {
      for (var j = i + 1; j < fit.placements.length; j++) {
        expect(fit.placements[i].point.distanceTo(fit.placements[j].point), greaterThanOrEqualTo(RoomFitAdvisor.zoneRadius));
      }
    }
  });

  test("le plein soleil exigé derrière une fenêtre au nord : rien ne convient, trop sombre", () {
    // Le nord à 270 : la normale dehors de la fenêtre (cap 270) donne au nord.
    final northRoom = load(north: 270);
    final fit = RoomFitAdvisor.place(profile(light: LightNeed.fullSun, tolerance: LightNeed.fullSun), northRoom);
    expect(fit.verdict, RoomFitVerdict.unsuitable);
    expect(fit.shortfall, RoomFitShortfall.tooDark);
    expect(fit.placements, isEmpty);
    expect(fit.all, isNotEmpty);
  });

  test("un cran sous le plancher vaut la moitié, deux crans rien ; au-dessus de l'idéal, 0,6 puis 0,2", () {
    final p = profile(light: LightNeed.brightIndirect, tolerance: LightNeed.indirect);
    double s(LightNeed l) => RoomFitAdvisor.score(p, light: l, drafty: false, humidRoom: false);
    expect(s(LightNeed.brightIndirect), 1);
    expect(s(LightNeed.indirect), 1);
    expect(s(LightNeed.lowLight), 0.5);
    expect(s(LightNeed.shade), 0);
    expect(s(LightNeed.someSun), 0.6);
    expect(s(LightNeed.fullSun), 0.2);
  });

  test("le courant d'air ne compte que si la fiche a un avis", () {
    double s(AirflowPreference? a) => RoomFitAdvisor.score(profile(airflow: a), light: LightNeed.brightIndirect, drafty: true, humidRoom: false);
    expect(s(null), 1);
    expect(s(AirflowPreference.normal), 1);
    expect(s(AirflowPreference.sheltered), 0.5);
    expect(s(AirflowPreference.ventilated), 1);
  });

  test("la pièce d'eau aide qui veut l'air humide, gêne qui le veut sec", () {
    double s(HumidityNeed h) => RoomFitAdvisor.score(profile(humidity: h), light: LightNeed.brightIndirect, drafty: false, humidRoom: true);
    expect(s(HumidityNeed.high), 1);
    expect(s(HumidityNeed.average), 1);
    expect(s(HumidityNeed.low), closeTo(0.7, 1e-9));
  });

  test('la table est une place, et une place à hauteur de table', () {
    final fit = RoomFitAdvisor.place(profile(light: LightNeed.indirect, tolerance: LightNeed.lowLight), room);
    expect(fit.all.any((p) => p.surface == PlacementSurface.table), isTrue);
    expect(fit.all.any((p) => p.surface == PlacementSurface.sill), isTrue);
  });

  test('une pièce sans mur ne donne rien', () {
    final empty = ScannedRoom(walls: const [], windows: const [], doors: const [], openings: const [], objects: const []);
    expect(RoomFitAdvisor.place(profile(), empty).placements, isEmpty);
  });
}
