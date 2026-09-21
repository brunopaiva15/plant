import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/care_labels.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../application/room_scan_providers.dart';
import 'room_fit_sheet.dart';
import 'room_scan_labels.dart';

/// Sur la fiche d'une plante, sous « Comment en prendre soin » : sa place dans
/// la maison relevée. Posée sur un plan, la pièce et le repère, la lumière
/// qu'elle y reçoit, et « mieux ailleurs » quand une place la dépasse
/// nettement. Pas posée, mais dans un emplacement relevé : « Où la poser »,
/// avec la meilleure place de sa pièce. Rien sans relevé autour d'elle, et
/// rien pour une fiche générique qui n'est pas posée : il n'y a pas de
/// lumière à lui comparer.
class PlantPlaceCard extends ConsumerWidget {
  const PlantPlaceCard({super.key, required this.plantId, required this.plantName});

  final String plantId;
  final String plantName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final place = ref.watch(plantRoomPlaceProvider(plantId));
    if (place == null || (!place.onPlan && place.fit == null)) return const SizedBox.shrink();
    final (String title, String subtitle) = switch (place) {
      PlantRoomPlace(spot: final spot?, current: final now?) => (
          '${place.scan.name} · ${l10n.spotLine(spot)}',
          place.betterElsewhere ? l10n.roomScanPlantBetterAt(l10n.lightName(now.light), l10n.placementLine(place.fit!.placements.first)) : l10n.roomScanPlantWellPlaced(l10n.lightName(now.light)),
        ),
      PlantRoomPlace(spot: final spot?) => ('${place.scan.name} · ${l10n.spotLine(spot)}', l10n.lightName(spot.light)),
      PlantRoomPlace(fit: final fit?) => (
          l10n.placementTitle,
          '${place.scan.name} · ${fit.placements.isEmpty ? (fit.shortfall == null ? l10n.verdictLine(fit.verdict) : l10n.shortfallLine(fit.shortfall!)) : l10n.placementLine(fit.placements.first)}',
        ),
      _ => (l10n.placementTitle, place.scan.name),
    };
    return FloraCard(
      onTap: () => showRoomFit(context, profile: place.profile, generic: place.generic, plantId: plantId, plantName: plantName, initialScanId: place.scan.id),
      padding: const EdgeInsets.all(Space.md),
      child: Row(
        children: [
          EmojiTile(emoji: '📐', size: 44, background: place.betterElsewhere ? c.sunSoft : c.sageSoft),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.title3, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(subtitle, style: context.text.caption, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Icon(CupertinoIcons.chevron_right, size: 16, color: c.inkTertiary),
        ],
      ),
    );
  }
}
