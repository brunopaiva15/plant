import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../application/room_scan_providers.dart';
import 'room_scan_detail_sheet.dart';
import 'room_scan_labels.dart';

/// Relever une pièce, d'où qu'on parte — Profil, ou la fiche d'un
/// emplacement : une phrase avant le relevé du système (ce qui va se
/// passer, et que rien ne quitte l'appareil), le relevé, puis sa feuille.
/// [locationId] lie la pièce d'emblée à l'emplacement d'où l'on vient.
/// [structure] enchaîne les pièces de l'appartement.
Future<void> startRoomScan(BuildContext context, WidgetRef ref, {String? locationId, bool structure = false}) async {
  final l10n = context.l10n;
  final go = await showAdaptiveConfirm(
    context,
    title: l10n.roomScanBeforeTitle,
    message: structure ? '${l10n.roomScanBeforeText}\n\n${l10n.roomScanStructureHint}' : l10n.roomScanBeforeText,
    confirmLabel: l10n.continueLabel,
    cancelLabel: l10n.cancel,
  );
  if (!go || !context.mounted) return;
  final controller = ref.read(roomScanControllerProvider.notifier);
  final outcome = structure
      ? await controller.scanStructure(
          nameFor: (section, i) => section == null ? l10n.roomScanRoomNumber(i + 1) : l10n.sectionName(section),
          nextRoomLabel: l10n.roomScanNextRoom,
        )
      : await controller.scan(nameFor: (section) => section == null ? l10n.roomScanDefaultName : l10n.sectionName(section), locationId: locationId);
  if (!context.mounted) return;
  if (outcome.cancelled) return;
  if (outcome.scan == null) {
    ref.read(toastProvider.notifier).show(ToastData(message: [l10n.roomScanFailed, ?outcome.error].join(' '), emoji: '📐'));
    return;
  }
  Haptics.success();
  await showRoomScanDetail(context, scanId: outcome.scan!.id);
}
