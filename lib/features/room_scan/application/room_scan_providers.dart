import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../domain/care/care_guide.dart';
import '../../../domain/care/care_profile.dart';
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

/// Le relevé qui décrit un emplacement, le plus récent s'il y en a
/// plusieurs ; `null` quand la pièce n'est pas relevée.
final roomScanForLocationProvider = Provider.family<RoomScan?, String>((ref, locationId) {
  final scans = ref.watch(roomScansProvider).value ?? const <RoomScan>[];
  return scans.where((s) => s.locationId == locationId).firstOrNull;
});

/// Ce qu'un relevé peut dire à son emplacement, quand celui-ci ne le dit
/// pas encore : l'orientation de la plus grande fenêtre, la lumière la
/// plus fréquente au sol. `null` quand tout est déjà renseigné, ou quand
/// le relevé n'a rien à proposer.
class RoomFillSuggestion {
  const RoomFillSuggestion({this.orientation, this.light});

  final CardinalDirection? orientation;
  final LightNeed? light;
}

final roomFillSuggestionProvider = Provider.family<RoomFillSuggestion?, String>((ref, scanId) {
  final scan = (ref.watch(roomScansProvider).value ?? const <RoomScan>[]).where((s) => s.id == scanId).firstOrNull;
  final location = (ref.watch(locationsProvider).value ?? const <Location>[]).where((l) => l.id == scan?.locationId).firstOrNull;
  final room = ref.watch(roomForFitProvider(scanId));
  if (scan == null || location == null || room == null) return null;
  final directions = ref.watch(roomDirectionsProvider(scanId));
  CardinalDirection? mainDirection;
  var mainArea = 0.0;
  for (var i = 0; i < room.windows.length && i < directions.length; i++) {
    if (directions[i] != null && room.windows[i].area > mainArea) {
      mainArea = room.windows[i].area;
      mainDirection = directions[i];
    }
  }
  final orientation = location.orientation == null ? mainDirection : null;
  final light = location.light == null ? ref.watch(roomSurveyProvider(scanId))?.typicalLight : null;
  if (orientation == null && light == null) return null;
  return RoomFillSuggestion(orientation: orientation, light: light);
});

/// La pièce lue depuis son fichier ; `null` si le fichier manque.
final scannedRoomProvider = FutureProvider.family<ScannedRoom?, String>((ref, scanId) async {
  final scan = (ref.watch(roomScansProvider).value ?? const []).where((s) => s.id == scanId).firstOrNull;
  if (scan == null) return null;
  final json = await ref.watch(roomScanStoreProvider).read(scan.filePath);
  if (json == null) return null;
  return RoomPlanParser.parse(json, northOffsetDeg: scan.northOffsetDeg);
});

/// La pièce telle qu'on la juge : les fenêtres ajoutées à la main à la
/// suite de celles du relevé, puis, dehors — un relevé lié à un emplacement
/// extérieur, balcon ou terrasse —, les ouvertures qui éclairent comme des
/// fenêtres ; dedans, la pièce telle quelle.
final roomForFitProvider = Provider.family<ScannedRoom?, String>((ref, scanId) {
  final scanned = ref.watch(scannedRoomProvider(scanId)).value;
  if (scanned == null) return null;
  final markers = ref.watch(roomMarkersProvider(scanId)).value ?? const <RoomMarker>[];
  final room = scanned.withWindows(handWindows(scanned, markers));
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

/// « Le jardin dans cette pièce » : les plantes du jardin dont l'espèce est
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

/// La place d'une plante dans la maison relevée, vue depuis sa fiche.
///
/// Posée sur un plan, elle est jugée là où elle est ([spot], [current]) et
/// la pièce lui propose sa meilleure place ([fit]). Pas posée, mais dans un
/// emplacement relevé : la pièce est celle de l'emplacement, et [fit] dit
/// où elle irait. Une fiche générique ne juge rien : [spot] reste, [current]
/// et [fit] sont nuls.
class PlantRoomPlace {
  const PlantRoomPlace({required this.scan, required this.profile, required this.generic, this.spot, this.current, this.fit});

  final RoomScan scan;

  /// La fiche de la plante, telle que « Où la poser » la juge.
  final CareProfile profile;

  /// Une fiche générique ne demande aucune lumière précise : pas de place.
  final bool generic;

  /// La place d'aujourd'hui sur le plan, lue sans fiche : sa lumière, sa
  /// fenêtre.
  final SurveyedSpot? spot;

  /// La même, jugée pour la fiche de la plante.
  final Placement? current;
  final RoomFit? fit;

  bool get onPlan => spot != null;

  /// Une autre place lui irait nettement mieux.
  bool get betterElsewhere {
    final now = current;
    final best = fit?.placements.firstOrNull;
    return now != null && best != null && best.score - now.score >= RoomFitAdvisor.betterByAtLeast;
  }
}

/// La place d'une plante du jardin : le plan où elle est posée, sinon le
/// relevé de son emplacement ; rien quand la maison n'est pas relevée
/// autour d'elle.
final plantRoomPlaceProvider = Provider.autoDispose.family<PlantRoomPlace?, String>((ref, plantId) {
  final scans = ref.watch(roomScansProvider).value ?? const <RoomScan>[];
  if (scans.isEmpty) return null;
  final plant = ref.watch(plantSummaryProvider(plantId)).value?.plant;
  if (plant == null) return null;
  // Le plan où elle est posée d'abord ; à défaut, celui de son emplacement.
  RoomScan? placed;
  for (final s in scans) {
    if (plantPoints(ref.watch(roomMarkersProvider(s.id)).value ?? const []).containsKey(plantId)) {
      placed = s;
      break;
    }
  }
  final scan = placed ?? (plant.locationId == null ? null : ref.watch(roomScanForLocationProvider(plant.locationId!)));
  if (scan == null) return null;
  final spot = placed == null ? null : ref.watch(roomPlantSpotsProvider(scan.id))[plantId];
  final species = plant.speciesName;
  final care = ref.watch(careGuideProvider).resolve(species, family: speciesFamilyLookupIn(ref)(species));
  final generic = species == null || species.isEmpty || care.match == CareMatch.generic || care.match == CareMatch.category;
  final survey = generic ? null : ref.watch(roomSurveyProvider(scan.id));
  if (survey == null) return PlantRoomPlace(scan: scan, profile: care.profile, generic: generic, spot: spot);
  return PlantRoomPlace(
    scan: scan,
    profile: care.profile,
    generic: false,
    spot: spot,
    current: spot == null ? null : RoomFitAdvisor.judge(care.profile, spot, humidRoom: survey.humidRoom),
    fit: RoomFitAdvisor.placeIn(care.profile, survey),
  );
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

  /// Relever une pièce. [locationId] la lie d'emblée à un emplacement —
  /// le relevé lancé depuis la fiche d'un emplacement décrit celui-là.
  /// Sans lui, la pièce se lie d'elle-même à l'emplacement qui porte son
  /// nom : une pièce reconnue comme « Salon » va au Salon du jardin.
  Future<RoomScanOutcome> scan({required String Function(RoomSectionLabel? section) nameFor, String? locationId}) async {
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
      // La pièce s'appelle comme l'emplacement qu'elle décrit — « Cuisine »
      // relevée depuis la Cuisine est la Cuisine ; le type reconnu par
      // RoomPlan ne sert de nom qu'à une pièce qui ne décrit rien.
      final proposed = nameFor(room?.section);
      final linked = locationId ?? _locationNamed(proposed);
      final scan = await ref.read(roomScanRepositoryProvider).create(
            name: _locationName(linked) ?? proposed,
            filePath: relative,
            capturedAt: DateTime.now(),
            northOffsetDeg: result.northOffsetDeg,
            floorAreaM2: room?.floorAreaM2 ?? 0,
            section: room?.section,
            locationId: linked,
          );
      return RoomScanOutcome(scan: scan);
    } finally {
      state = false;
    }
  }

  /// L'appartement, pièce après pièce : un dossier, un fichier par pièce,
  /// une ligne par pièce, toutes sous le même identifiant de structure.
  /// Chaque pièce se lie à l'emplacement qui porte son nom, s'il existe.
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
      final linked = <String>{};
      for (var i = 0; i < result.paths.length; i++) {
        final relative = store.relativeOf(result.paths[i]);
        final json = await store.read(relative);
        final room = json == null ? null : RoomPlanParser.parse(json, northOffsetDeg: result.northOffsetDeg);
        final name = nameFor(room?.section, i);
        final locationId = _locationNamed(name, taken: linked);
        if (locationId != null) linked.add(locationId);
        final scan = await ref.read(roomScanRepositoryProvider).create(
              name: name,
              filePath: relative,
              capturedAt: DateTime.now(),
              northOffsetDeg: result.northOffsetDeg,
              floorAreaM2: room?.floorAreaM2 ?? 0,
              section: room?.section,
              structureId: id,
              locationId: locationId,
            );
        first ??= scan;
      }
      return RoomScanOutcome(scan: first);
    } finally {
      state = false;
    }
  }

  /// Le nom d'un emplacement du jardin, quand il y en a un.
  String? _locationName(String? locationId) =>
      locationId == null ? null : (ref.read(locationsProvider).value ?? const <Location>[]).where((l) => l.id == locationId).firstOrNull?.name;

  /// L'emplacement du jardin qui porte ce nom, à la casse près ; le
  /// premier sans relevé, pour ne pas mettre deux pièces sur le même. Rien
  /// si le nom est ambigu ou inconnu : lier se fait alors à la main.
  String? _locationNamed(String name, {Set<String> taken = const {}}) {
    final wanted = name.trim().toLowerCase();
    if (wanted.isEmpty) return null;
    final locations = ref.read(locationsProvider).value ?? const <Location>[];
    final matches = locations.where((l) => l.name.trim().toLowerCase() == wanted).toList();
    if (matches.length != 1) return null;
    final id = matches.single.id;
    final described = taken.contains(id) || (ref.read(roomScansProvider).value ?? const <RoomScan>[]).any((s) => s.locationId == id);
    return described ? null : id;
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

  /// Une fenêtre que le relevé a manquée : le point touché et la taille
  /// dite ; c'est [ScannedRoom.handWindowAt] qui la couche sur le mur.
  Future<void> addWindow(String scanId, RoomPoint at, HandWindow size) async {
    await ref.read(roomScanRepositoryProvider).addMarker(scanId, RoomMarkerKind.of(size), x: at.x, z: at.z);
  }

  /// La retirer : son repère, et ce qui tenait à son rang.
  Future<void> removeWindow(String scanId, RoomMarker marker, int windowIndex) =>
      ref.read(roomScanRepositoryProvider).removeWindow(marker.id, scanId: scanId, windowIndex: windowIndex);

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
