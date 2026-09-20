import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/haptics.dart';
import '../../../core/l10n/care_labels.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/care/care_profile.dart';
import '../../../domain/models/models.dart';
import '../../../domain/room/room_scan.dart';
import '../application/room_scan_providers.dart';
import 'room_plan_painter.dart';
import 'room_scan_detail_sheet.dart';
import 'room_scan_flow.dart';
import 'room_scan_labels.dart';

/// Sur la fiche d'un emplacement, sous ses conditions : la pièce relevée
/// qui le décrit — son plan, ses fenêtres, les plantes posées dessus —, et
/// ce que le relevé peut lui apprendre. Sans relevé, de quoi relever la
/// pièce d'ici, liée d'emblée. Absent sans LiDAR : la pièce ne se relève
/// pas, la fiche n'en parle pas.
class LocationRoomSection extends ConsumerWidget {
  const LocationRoomSection({super.key, required this.location});

  final Location location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    if (!(ref.watch(roomScanAvailableProvider).value ?? false)) return const SizedBox.shrink();
    final scan = ref.watch(roomScanForLocationProvider(location.id));
    if (scan == null) {
      if (ref.watch(roomScanControllerProvider)) {
        return const Padding(padding: EdgeInsets.only(bottom: Space.xl), child: Center(child: AdaptiveProgress()));
      }
      return Padding(
        padding: const EdgeInsets.only(bottom: Space.xl),
        child: FloraGroup(
          children: [
            FloraListRow(
              leading: const Text('📐', style: TextStyle(fontSize: 18)),
              title: l10n.roomScanThisRoom,
              subtitle: l10n.roomScanThisRoomHint,
              chevron: true,
              onTap: () => startRoomScan(context, ref, locationId: location.id),
            ),
          ],
        ),
      );
    }
    final c = context.colors;
    final room = ref.watch(roomForFitProvider(scan.id));
    final markers = ref.watch(roomMarkersProvider(scan.id)).value ?? const <RoomMarker>[];
    final plants = plantPoints(markers);
    final suggestion = ref.watch(roomFillSuggestionProvider(scan.id));
    void open() => showRoomScanDetail(context, scanId: scan.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.xl),
      child: FloraGroup(
        children: [
          // Le plan d'abord : c'est lui qu'on reconnaît, avant tout chiffre.
          if (room != null)
            Pressable(
              onTap: open,
              scale: 1,
              child: AspectRatio(
                aspectRatio: 2.2,
                child: CustomPaint(
                  painter: RoomPlanPainter(room: room, heaters: heaterPoints(markers), plants: plants.values.toList(), colors: c, numberStyle: context.text.caption),
                ),
              ),
            ),
          FloraListRow(
            leading: const Text('📐', style: TextStyle(fontSize: 18)),
            title: l10n.roomScanRoomPlan,
            subtitle: [
              if (room != null) l10n.roomScanWindowsCount(room.windows.length),
              l10n.roomScanPlantsOnPlanCount(plants.length),
              l10n.roomScanCapturedOn(DateFormat.yMMMd(context.localeTag).format(scan.capturedAt)),
            ].join(' · '),
            chevron: true,
            onTap: open,
          ),
          if (suggestion != null) RoomFillLocationRow(scan: scan, location: location, suggestion: suggestion),
        ],
      ),
    );
  }
}

/// « Renseigner l'emplacement » : l'orientation de la plus grande fenêtre
/// et la lumière la plus fréquente au sol, proposées à un emplacement qui
/// ne les a pas encore. La même ligne sur la fiche de l'emplacement et sur
/// la feuille du relevé ; le parent ne la pose que s'il y a une
/// [suggestion].
class RoomFillLocationRow extends ConsumerWidget {
  const RoomFillLocationRow({super.key, required this.scan, required this.location, required this.suggestion});

  final RoomScan scan;
  final Location location;
  final RoomFillSuggestion suggestion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final orientation = suggestion.orientation == null ? null : _capitalize(l10n.directionName(suggestion.orientation!));
    final light = suggestion.light;
    return FloraListRow(
      leading: const Text('✍️', style: TextStyle(fontSize: 18)),
      title: l10n.roomScanFillLocation,
      subtitle: l10n.roomScanFillLocationDetail(orientation ?? location.orientation ?? '—', l10n.lightName(light ?? lightNeedFromCode(location.light) ?? LightNeed.indirect)),
      chevron: false,
      onTap: () async {
        await ref.read(roomScanControllerProvider.notifier).fillLocation(location, orientation: orientation, light: light == null ? null : lightCodeFor(light));
        if (!context.mounted) return;
        ref.read(toastProvider.notifier).show(ToastData(message: l10n.roomScanLocationFilled, emoji: '📍'));
        Haptics.success();
      },
    );
  }

  static String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
