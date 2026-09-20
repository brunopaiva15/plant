import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/care/care_guide.dart';
import '../application/room_scan_providers.dart';
import 'room_fit_sheet.dart';
import 'room_scan_labels.dart';

/// Sous le diorama d'une fiche d'entretien : « Où la poser », quand au
/// moins une pièce est relevée. Le diorama montre l'idéal ; le relevé
/// montre le réel (docs/13, « Idéal et réel »). Pour une plante du jardin
/// déjà posée sur un plan, la ligne dit sa place, et la feuille s'ouvre
/// sur sa pièce. Absent sans relevé, absent sans LiDAR, absent sans le
/// drapeau.
class RoomFitEntry extends ConsumerWidget {
  const RoomFitEntry({super.key, required this.care, this.plantId, this.plantName});

  final ResolvedCare care;

  /// La plante du jardin, quand la fiche est la sienne : elle peut alors
  /// choisir sa place sur le plan.
  final String? plantId;
  final String? plantName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    if (!(ref.watch(roomScanAvailableProvider).value ?? false)) return const SizedBox.shrink();
    final scans = ref.watch(roomScansProvider).value ?? const [];
    if (scans.isEmpty) return const SizedBox.shrink();
    final generic = care.match == CareMatch.generic || care.match == CareMatch.category;
    final place = plantId == null ? null : ref.watch(plantRoomPlaceProvider(plantId!));
    final spot = place?.spot;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.md),
      child: FloraGroup(
        children: [
          FloraListRow(
            leading: const Text('📐', style: TextStyle(fontSize: 18)),
            title: l10n.placementTitle,
            subtitle: spot == null ? l10n.placementRoomsCount(scans.length) : '${place!.scan.name} · ${l10n.spotLine(spot)}',
            chevron: true,
            onTap: () => showRoomFit(context, profile: care.profile, generic: generic, plantId: plantId, plantName: plantName, initialScanId: place?.scan.id),
          ),
        ],
      ),
    );
  }
}
