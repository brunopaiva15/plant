import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../domain/care/care_guide.dart';
import '../../../domain/models/models.dart';
import '../../../domain/repositories/repositories.dart';
import '../../../domain/room/placement.dart';
import '../../../domain/room/room_fit_advisor.dart';
import '../../../domain/room/room_plan_parser.dart';
import '../../../domain/room/room_scan.dart';
import '../../../domain/room/scanned_room.dart';
import '../../plants/application/plant_providers.dart';

/// Les relevés du jardin, du plus récent au plus ancien.
final roomScansProvider = StreamProvider<List<RoomScan>>((ref) => ref.watch(roomScanRepositoryProvider).watchAll());

/// L'appareil peut-il relever ? Le drapeau, la plateforme, puis le LiDAR,
/// demandé une fois au canal.
final roomScanAvailableProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(roomScanServiceProvider);
  if (!service.isSupported) return false;
  return (await service.support()).lidar;
});

/// L'appartement entier, pièce après pièce : iOS 17 et un LiDAR.
final roomScanStructureAvailableProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(roomScanServiceProvider);
  if (!service.isSupported) return false;
  final support = await service.support();
  return support.lidar && support.structure;
});

/// Les repères posés à la main sur un relevé.
final roomMarkersProvider = StreamProvider.family<List<RoomMarker>, String>((ref, scanId) => ref.watch(roomScanRepositoryProvider).watchMarkers(scanId));

/// La pièce lue depuis son fichier ; `null` si le fichier manque.
final scannedRoomProvider = FutureProvider.family<ScannedRoom?, String>((ref, scanId) async {
  final scan = (ref.watch(roomScansProvider).value ?? const []).where((s) => s.id == scanId).firstOrNull;
  if (scan == null) return null;
  final json = await ref.watch(roomScanStoreProvider).read(scan.filePath);
  if (json == null) return null;
  return RoomPlanParser.parse(json, northOffsetDeg: scan.northOffsetDeg);
});

/// La pièce telle qu'on la juge : dehors — un relevé lié à un emplacement
/// extérieur, balcon ou terrasse —, ses ouvertures éclairent comme des
/// fenêtres ; dedans, la pièce telle quelle.
final roomForFitProvider = Provider.family<ScannedRoom?, String>((ref, scanId) {
  final room = ref.watch(scannedRoomProvider(scanId)).value;
  if (room == null) return null;
  final scan = (ref.watch(roomScansProvider).value ?? const []).where((s) => s.id == scanId).firstOrNull;
  final location = (ref.watch(locationsProvider).value ?? const []).where((l) => l.id == scan?.locationId).firstOrNull;
  return (location?.isOutdoor ?? false) ? room.asOutdoor() : room;
});

/// Une pièce avec ses orientations de fenêtre : la confirmée d'abord, la
/// boussole sinon.
final roomDirectionsProvider = Provider.family<List<CardinalDirection?>, String>((ref, scanId) {
  final room = ref.watch(roomForFitProvider(scanId));
  if (room == null) return const [];
  final markers = ref.watch(roomMarkersProvider(scanId)).value ?? const [];
  return windowDirections(room, markers);
});

/// Ce qui habille chaque fenêtre, d'après les repères.
final roomDressingsProvider = Provider.family<List<WindowDressing>, String>((ref, scanId) {
  final room = ref.watch(roomForFitProvider(scanId));
  if (room == null) return const [];
  final markers = ref.watch(roomMarkersProvider(scanId)).value ?? const [];
  return windowDressings(room, markers);
});

/// La pièce lue place par place, une fois pour toutes les fiches : la
/// lumière selon la latitude du lieu de la météo, les radiateurs posés.
/// `null` tant que le fichier n'est pas lu.
final roomSurveyProvider = Provider.family<RoomSurvey?, String>((ref, scanId) {
  final room = ref.watch(roomForFitProvider(scanId));
  if (room == null) return null;
  final markers = ref.watch(roomMarkersProvider(scanId)).value ?? const [];
  return RoomFitAdvisor.survey(
    room,
    southern: ref.watch(southernHemisphereProvider),
    directions: windowDirections(room, markers),
    dressings: windowDressings(room, markers),
    latitude: ref.watch(preferencesProvider.select((p) => p.weatherPlace?.latitude)),
    heaters: heaterPoints(markers),
  );
});

/// Une plante du jardin et ce que la pièce vaut pour elle ; et, si elle est
/// posée sur le plan, ce que vaut la place où elle est aujourd'hui.
class PlantRoomFit {
  const PlantRoomFit({required this.plant, required this.fit, this.current});

  final PlantSummary plant;
  final RoomFit fit;
  final Placement? current;

  /// Une autre place lui irait nettement mieux : la meilleure dépasse celle
  /// d'aujourd'hui d'au moins un quart.
  bool get betterElsewhere {
    final now = current;
    final best = fit.placements.firstOrNull;
    return now != null && best != null && best.score - now.score >= RoomFitAdvisor.betterByAtLeast;
  }
}

/// Les plantes posées sur le plan d'un relevé, lues là où elles sont.
final roomPlantSpotsProvider = Provider.family<Map<String, SurveyedSpot>, String>((ref, scanId) {
  final room = ref.watch(roomForFitProvider(scanId));
  if (room == null) return const {};
  final markers = ref.watch(roomMarkersProvider(scanId)).value ?? const [];
  final directions = windowDirections(room, markers);
  final dressings = windowDressings(room, markers);
  final heaters = heaterPoints(markers);
  final southern = ref.watch(southernHemisphereProvider);
  final latitude = ref.watch(preferencesProvider.select((p) => p.weatherPlace?.latitude));
  return {
    for (final e in plantPoints(markers).entries)
      e.key: RoomFitAdvisor.spotAt(room, e.value, southern: southern, directions: directions, dressings: dressings, latitude: latitude, heaters: heaters),
  };
});

/// « Qui serait bien ici » : les plantes du jardin dont l'espèce est
/// connue, classées par leur meilleure place dans la pièce. Une fiche
/// générique ne se classe pas — sans l'espèce, la lumière demandée n'est
/// pas connue.
final roomPlantFitsProvider = Provider.family<List<PlantRoomFit>, String>((ref, scanId) {
  final survey = ref.watch(roomSurveyProvider(scanId));
  if (survey == null) return const [];
  final plants = ref.watch(plantSummariesProvider(const PlantFilter())).value ?? const <PlantSummary>[];
  final guide = ref.watch(careGuideProvider);
  final family = speciesFamilyLookupIn(ref);
  final spots = ref.watch(roomPlantSpotsProvider(scanId));
  final out = <PlantRoomFit>[];
  for (final p in plants) {
    final species = p.plant.speciesName;
    if (species == null || species.isEmpty) continue;
    final care = guide.resolve(species, family: family(species));
    if (care.match == CareMatch.generic || care.match == CareMatch.category) continue;
    final spot = spots[p.plant.id];
    out.add(PlantRoomFit(
      plant: p,
      fit: RoomFitAdvisor.placeIn(care.profile, survey),
      current: spot == null ? null : RoomFitAdvisor.judge(care.profile, spot, humidRoom: survey.humidRoom),
    ));
  }
  out.sort((a, b) {
    final byScore = (b.fit.all.firstOrNull?.score ?? 0).compareTo(a.fit.all.firstOrNull?.score ?? 0);
    return byScore != 0 ? byScore : a.plant.plant.name.toLowerCase().compareTo(b.plant.plant.name.toLowerCase());
  });
  return out;
});

/// Ce que le relevé a donné, ou pourquoi il n'a rien donné.
class RoomScanOutcome {
  const RoomScanOutcome({this.scan, this.error});

  final RoomScan? scan;
  final String? error;

  bool get cancelled => scan == null && error == null;
}

/// Relever une pièce : un fichier réservé, le canal ouvert, puis la ligne
/// en base avec ce que le JSON dit de la pièce.
class RoomScanController extends Notifier<bool> {
  @override
  bool build() => false;

  Future<RoomScanOutcome> scan({required String Function(RoomSectionLabel? section) nameFor}) async {
    if (state) return const RoomScanOutcome();
    state = true;
    try {
      final store = ref.read(roomScanStoreProvider);
      final id = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
      final path = await store.newPath(id);
      final result = await ref.read(roomScanServiceProvider).scan(toPath: path);
      if (result == null) return const RoomScanOutcome();
      if (!result.succeeded) return RoomScanOutcome(error: result.error);
      final relative = store.relativeOf(result.path!);
      final json = await store.read(relative);
      final room = json == null ? null : RoomPlanParser.parse(json, northOffsetDeg: result.northOffsetDeg);
      final scan = await ref.read(roomScanRepositoryProvider).create(
            name: nameFor(room?.section),
            filePath: relative,
            capturedAt: DateTime.now(),
            northOffsetDeg: result.northOffsetDeg,
            floorAreaM2: room?.floorAreaM2 ?? 0,
            section: room?.section,
          );
      return RoomScanOutcome(scan: scan);
    } finally {
      state = false;
    }
  }

  /// L'appartement, pièce après pièce : un dossier, un fichier par pièce,
  /// une ligne par pièce, toutes sous le même identifiant de structure.
  Future<RoomScanOutcome> scanStructure({required String Function(RoomSectionLabel? section, int index) nameFor, required String nextRoomLabel}) async {
    if (state) return const RoomScanOutcome();
    state = true;
    try {
      final store = ref.read(roomScanStoreProvider);
      final id = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
      final dir = await store.newDirectory(id);
      final result = await ref.read(roomScanServiceProvider).scanStructure(toDirectory: dir, nextRoomLabel: nextRoomLabel);
      if (result == null) return const RoomScanOutcome();
      if (!result.succeeded) return RoomScanOutcome(error: result.error);
      RoomScan? first;
      for (var i = 0; i < result.paths.length; i++) {
        final relative = store.relativeOf(result.paths[i]);
        final json = await store.read(relative);
        final room = json == null ? null : RoomPlanParser.parse(json, northOffsetDeg: result.northOffsetDeg);
        final scan = await ref.read(roomScanRepositoryProvider).create(
              name: nameFor(room?.section, i),
              filePath: relative,
              capturedAt: DateTime.now(),
              northOffsetDeg: result.northOffsetDeg,
              floorAreaM2: room?.floorAreaM2 ?? 0,
              section: room?.section,
              structureId: id,
            );
        first ??= scan;
      }
      return RoomScanOutcome(scan: first);
    } finally {
      state = false;
    }
  }

  Future<void> delete(RoomScan scan) async {
    await ref.read(roomScanRepositoryProvider).delete(scan.id);
    await ref.read(roomScanStoreProvider).delete(scan.filePath);
  }

  /// Une plante posée sur le plan : une seule place par plante et par
  /// relevé, la nouvelle remplace l'ancienne.
  Future<void> placePlant(String scanId, String plantId, RoomPoint at, {String? locationId}) async {
    final repo = ref.read(roomScanRepositoryProvider);
    final markers = await repo.watchMarkers(scanId).first;
    for (final m in markers) {
      if (m.kind == RoomMarkerKind.plant && m.plantId == plantId) await repo.removeMarker(m.id);
    }
    await repo.addMarker(scanId, RoomMarkerKind.plant, x: at.x, z: at.z, plantId: plantId);
    // La place choisie vaut déménagement : si le relevé décrit un
    // emplacement, la plante y va.
    if (locationId != null) await ref.read(plantRepositoryProvider).moveToLocation([plantId], locationId);
  }

  /// Un radiateur, posé contre le mur le plus proche du doigt.
  Future<void> addHeater(String scanId, ScannedRoom room, RoomPoint at) async {
    final p = room.snapToWall(at);
    await ref.read(roomScanRepositoryProvider).addMarker(scanId, RoomMarkerKind.heater, x: p.x, z: p.z);
  }

  Future<void> removeMarker(String id) => ref.read(roomScanRepositoryProvider).removeMarker(id);

  /// Ce qui habille une fenêtre : un repère au plus par fenêtre, le nouveau
  /// remplace l'ancien, et « sans rideau » les retire.
  Future<void> setWindowDressing(String scanId, int windowIndex, WindowDressing dressing, {required double x, required double z}) async {
    final repo = ref.read(roomScanRepositoryProvider);
    for (final m in await repo.watchMarkers(scanId).first) {
      if ((m.kind == RoomMarkerKind.windowSheer || m.kind == RoomMarkerKind.windowDrawn) && m.windowIndex == windowIndex) await repo.removeMarker(m.id);
    }
    final kind = switch (dressing) {
      WindowDressing.none => null,
      WindowDressing.sheer => RoomMarkerKind.windowSheer,
      WindowDressing.drawn => RoomMarkerKind.windowDrawn,
    };
    if (kind != null) await repo.addMarker(scanId, kind, x: x, z: z, windowIndex: windowIndex);
  }

  /// Renseigne l'orientation et la lumière d'un emplacement d'après le
  /// relevé, sans toucher à ce qui est déjà rempli.
  Future<void> fillLocation(Location location, {String? orientation, String? light}) async {
    final next = location.copyWith(
      orientation: location.orientation == null && orientation != null ? () => orientation : null,
      light: location.light == null && light != null ? () => light : null,
    );
    await ref.read(locationRepositoryProvider).update(next);
  }
}

final roomScanControllerProvider = NotifierProvider<RoomScanController, bool>(RoomScanController.new);
