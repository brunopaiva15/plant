import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/room/room_scan.dart';
import '../../../domain/room/scanned_room.dart';
import '../../locations/presentation/location_picker_sheet.dart';
import '../application/room_scan_providers.dart';
import 'room_plan_painter.dart';
import 'room_scan_labels.dart';

/// La feuille d'un relevé : son plan, son nom, l'emplacement qu'il décrit,
/// l'orientation de ses fenêtres, et de quoi le supprimer.
Future<void> showRoomScanDetail(BuildContext context, {required String scanId}) =>
    showFloraSheet<void>(context, scrollable: true, builder: (ctx) => _RoomScanDetailBody(scanId: scanId));

class _RoomScanDetailBody extends ConsumerStatefulWidget {
  const _RoomScanDetailBody({required this.scanId});

  final String scanId;

  @override
  ConsumerState<_RoomScanDetailBody> createState() => _RoomScanDetailBodyState();
}

class _RoomScanDetailBodyState extends ConsumerState<_RoomScanDetailBody> {
  final _name = TextEditingController();
  bool _seeded = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _rename(RoomScan scan) async {
    final name = _name.text.trim();
    if (name.isEmpty || name == scan.name) return;
    await ref.read(roomScanRepositoryProvider).update(scan.copyWith(name: name));
  }

  Future<void> _pickLocation(RoomScan scan) async {
    final choice = await showLocationPicker(context, selectedId: scan.locationId);
    if (choice == null) return;
    await ref.read(roomScanRepositoryProvider).update(scan.copyWith(locationId: () => choice.id));
    Haptics.light();
  }

  /// Huit points cardinaux dans une feuille d'actions : la boussole propose,
  /// la main confirme.
  Future<void> _pickOrientation(RoomScan scan, ScannedRoom room, int index) async {
    final l10n = context.l10n;
    final w = room.windows[index];
    await showAdaptiveActionSheet(
      context,
      title: l10n.roomScanWindowN(index + 1),
      cancelLabel: l10n.cancel,
      actions: [
        for (final d in CardinalDirection.values)
          SheetAction(
            label: l10n.directionName(d),
            onPressed: () async {
              await ref.read(roomScanRepositoryProvider).setWindowOrientation(scan.id, index, d, x: w.center.x, z: w.center.z);
              Haptics.success();
            },
          ),
      ],
    );
  }

  Future<void> _delete(RoomScan scan) async {
    final l10n = context.l10n;
    final ok = await showAdaptiveConfirm(context, title: l10n.roomScanDelete, message: l10n.roomScanDeleteConfirm, confirmLabel: l10n.delete, cancelLabel: l10n.cancel, destructive: true);
    if (!ok || !mounted) return;
    await ref.read(roomScanControllerProvider.notifier).delete(scan);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final scan = (ref.watch(roomScansProvider).value ?? const <RoomScan>[]).where((s) => s.id == widget.scanId).firstOrNull;
    if (scan == null) return const SizedBox.shrink();
    if (!_seeded) {
      _name.text = scan.name;
      _seeded = true;
    }
    final room = ref.watch(scannedRoomProvider(scan.id)).value;
    final markers = ref.watch(roomMarkersProvider(scan.id)).value ?? const <RoomMarker>[];
    final location = (ref.watch(locationsProvider).value ?? const []).where((l) => l.id == scan.locationId).firstOrNull;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(title: scan.name),
          if (room != null)
            FloraCard(
              padding: EdgeInsets.zero,
              clip: true,
              child: AspectRatio(
                aspectRatio: 1.25,
                child: CustomPaint(painter: RoomPlanPainter(room: room, colors: c, numberStyle: context.text.caption)),
              ),
            ),
          const SizedBox(height: Space.md),
          FloraGroup(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.xs),
                child: FloraTextField(
                  controller: _name,
                  hint: l10n.roomScanName,
                  textInputAction: TextInputAction.done,
                  textCapitalization: TextCapitalization.words,
                  onSubmitted: (_) => _rename(scan),
                ),
              ),
              FloraListRow(
                leading: const Text('📍', style: TextStyle(fontSize: 18)),
                title: l10n.roomScanLinkedLocation,
                trailing: Text(location?.name ?? l10n.none, style: context.text.callout.copyWith(color: c.inkSecondary)),
                chevron: true,
                onTap: () => _pickLocation(scan),
              ),
            ],
          ),
          if (room != null && room.windows.isNotEmpty) ...[
            const SizedBox(height: Space.lg),
            FloraGroup(
              header: l10n.roomScanWindows,
              footer: l10n.roomScanOrientationHelp,
              children: [
                for (var i = 0; i < room.windows.length; i++)
                  _windowRow(scan, room, markers, i),
              ],
            ),
          ],
          const SizedBox(height: Space.lg),
          FloraGroup(
            children: [
              FloraListRow(title: l10n.roomScanDelete, destructive: true, chevron: false, onTap: () => _delete(scan)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _windowRow(RoomScan scan, ScannedRoom room, List<RoomMarker> markers, int i) {
    final l10n = context.l10n;
    final confirmed = markers.where((m) => m.kind == RoomMarkerKind.windowOrientation && m.windowIndex == i).firstOrNull?.orientation;
    final compass = room.windowDirection(room.windows[i]);
    final direction = confirmed ?? compass;
    return FloraListRow(
      leading: const Text('🪟', style: TextStyle(fontSize: 18)),
      title: l10n.roomScanWindowN(i + 1),
      subtitle: direction == null
          ? l10n.roomScanWindowUnknown
          : '${l10n.directionName(direction)} · ${confirmed != null ? l10n.roomScanWindowConfirmed : l10n.roomScanWindowFromCompass}',
      chevron: true,
      onTap: () => _pickOrientation(scan, room, i),
    );
  }
}
