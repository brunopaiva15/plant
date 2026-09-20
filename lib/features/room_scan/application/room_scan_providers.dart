import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../domain/room/room_plan_parser.dart';
import '../../../domain/room/room_scan.dart';
import '../../../domain/room/scanned_room.dart';

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
}

final roomScanControllerProvider = NotifierProvider<RoomScanController, bool>(RoomScanController.new);
