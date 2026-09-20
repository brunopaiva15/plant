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

/// Une pièce avec ses orientations de fenêtre : la confirmée d'abord, la
/// boussole sinon.
final roomDirectionsProvider = Provider.family<List<CardinalDirection?>, String>((ref, scanId) {
  final room = ref.watch(scannedRoomProvider(scanId)).value;
  if (room == null) return const [];
  final markers = ref.watch(roomMarkersProvider(scanId)).value ?? const [];
  return windowDirections(room, markers);
});

/// La pièce lue place par place, une fois pour toutes les fiches : la
/// lumière selon la latitude du lieu de la météo, les radiateurs posés.
/// `null` tant que le fichier n'est pas lu.
final roomSurveyProvider = Provider.family<RoomSurvey?, String>((ref, scanId) {
  final room = ref.watch(scannedRoomProvider(scanId)).value;
  if (room == null) return null;
  final markers = ref.watch(roomMarkersProvider(scanId)).value ?? const [];
  return RoomFitAdvisor.survey(
    room,
    southern: ref.watch(southernHemisphereProvider),
    directions: windowDirections(room, markers),
    latitude: ref.watch(preferencesProvider.select((p) => p.weatherPlace?.latitude)),
    heaters: heaterPoints(markers),
  );
});

/// Une plante du jardin et ce que la pièce vaut pour elle.
class PlantRoomFit {
  const PlantRoomFit({required this.plant, required this.fit});

  final PlantSummary plant;
  final RoomFit fit;
}

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
  final out = <PlantRoomFit>[];
  for (final p in plants) {
    final species = p.plant.speciesName;
    if (species == null || species.isEmpty) continue;
    final care = guide.resolve(species, family: family(species));
    if (care.match == CareMatch.generic || care.match == CareMatch.category) continue;
    out.add(PlantRoomFit(plant: p, fit: RoomFitAdvisor.placeIn(care.profile, survey)));
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

  Future<void> delete(RoomScan scan) async {
    await ref.read(roomScanRepositoryProvider).delete(scan.id);
    await ref.read(roomScanStoreProvider).delete(scan.filePath);
  }

  /// Un radiateur, posé contre le mur le plus proche du doigt.
  Future<void> addHeater(String scanId, ScannedRoom room, RoomPoint at) async {
    final p = room.snapToWall(at);
    await ref.read(roomScanRepositoryProvider).addMarker(scanId, RoomMarkerKind.heater, x: p.x, z: p.z);
  }

  Future<void> removeMarker(String id) => ref.read(roomScanRepositoryProvider).removeMarker(id);

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
