import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/room/room_scan.dart';
import '../application/room_scan_providers.dart';
import 'room_scan_detail_sheet.dart';
import 'room_scan_flow.dart';

/// Profil › Relevé de la maison : les pièces relevées, et de quoi en relever
/// une. Chaque ligne s'ouvre sur la feuille du relevé — nom, emplacement,
/// fenêtres, suppression. La même pièce se relève aussi depuis la fiche de
/// son emplacement, dans Jardin ; ici, c'est la vue d'ensemble.
class RoomScanSettingsScreen extends ConsumerWidget {
  const RoomScanSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scans = ref.watch(roomScansProvider).value ?? const <RoomScan>[];
    final available = ref.watch(roomScanAvailableProvider);
    final busy = ref.watch(roomScanControllerProvider);
    final locations = {for (final l in ref.watch(locationsProvider).value ?? const []) l.id: l};
    final canScan = available.value ?? false;
    return FloraPage(
      title: l10n.roomScan,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.roomScanHint, style: context.text.callout),
          const SizedBox(height: Space.lg),
          if (scans.isEmpty)
            EmptyState(emoji: '📐', title: l10n.roomScanEmptyTitle, subtitle: l10n.roomScanEmptySubtitle, compact: true)
          else
            FloraGroup(
              header: l10n.roomScanRooms,
              children: [
                for (final s in scans)
                  FloraListRow(
                    leading: Text(_emoji(s), style: const TextStyle(fontSize: 18)),
                    title: s.name,
                    subtitle: [
                      l10n.roomScanArea(s.floorAreaM2.toStringAsFixed(0)),
                      if (locations[s.locationId] case final loc?) loc.name,
                      l10n.roomScanCapturedOn(DateFormat.yMMMd(context.localeTag).format(s.capturedAt)),
                    ].join(' · '),
                    chevron: true,
                    onTap: () => showRoomScanDetail(context, scanId: s.id),
                  ),
              ],
            ),
          const SizedBox(height: Space.lg),
          if (busy)
            const Padding(padding: EdgeInsets.all(Space.md), child: Center(child: AdaptiveProgress()))
          else if (canScan) ...[
            FloraButton(label: l10n.roomScanStart, icon: CupertinoIcons.viewfinder, expand: true, onPressed: () => startRoomScan(context, ref)),
            // L'appartement entier, pièce après pièce : iOS 17 sait assembler.
            if (ref.watch(roomScanStructureAvailableProvider).value ?? false)
              Padding(
                padding: const EdgeInsets.only(top: Space.xs),
                child: FloraButton(label: l10n.roomScanStartStructure, icon: CupertinoIcons.square_grid_2x2, style: FloraButtonStyle.ghost, expand: true, onPressed: () => startRoomScan(context, ref, structure: true)),
              ),
          ] else if (available.hasValue)
            // Un appareil sans LiDAR : la raison, plutôt qu'un bouton mort.
            Text(l10n.roomScanNoLidar, style: context.text.caption),
        ],
      ),
    );
  }

  static String _emoji(RoomScan s) => switch (s.section) {
        null => '📐',
        _ when s.section!.isHumid => '🚿',
        _ => '🛋️',
      };
}
