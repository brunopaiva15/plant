import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models/models.dart';

/// Carte de grille : grande photo, nom, emplacement, prochain soin.
class PlantGridCard extends ConsumerWidget {
  const PlantGridCard({super.key, required this.summary, required this.onTap, this.onLongPress, this.selected = false, this.selecting = false});

  final PlantSummary summary;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool selected;
  final bool selecting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l10n = context.l10n;
    final now = DateTime.now();
    final custom = summary.nextDueTypeKey == null ? null : ref.watch(actionTypeByKeyProvider)[summary.nextDueTypeKey!];
    final emoji = custom?.emoji ?? CareKind.fromKey(summary.nextDueTypeKey ?? '')?.emoji;
    return Pressable(
      onTap: onTap,
      onLongPress: onLongPress,
      scale: 0.97,
      child: AnimatedContainer(
        duration: Motion.of(context, Motion.standard),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: Radii.largeAll,
          border: Border.all(color: selected ? c.sage : Colors.transparent, width: 2),
          boxShadow: c.isDark ? null : Shadows.soft(c.shadow),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(6),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(18)),
                      child: PlantImage(relativePath: summary.thumbPath, cacheWidth: 480, heroTag: 'plant-${summary.plant.id}'),
                    ),
                  ),
                  if (summary.plant.isFavorite && !selecting)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(color: c.surface.withValues(alpha: 0.9), shape: BoxShape.circle),
                        child: Icon(CupertinoIcons.heart_fill, size: 14, color: c.rose),
                      ),
                    ),
                  if (selecting)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: AnimatedContainer(
                        duration: Motion.of(context, Motion.micro),
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: selected ? c.sage : c.surface.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          border: Border.all(color: selected ? c.sage : c.line, width: 1.5),
                        ),
                        child: selected ? Icon(CupertinoIcons.checkmark_alt, size: 15, color: c.onSage) : null,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.sm, Space.xs, Space.sm, Space.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(summary.plant.name, style: context.text.title3, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(summary.locationName ?? summary.plant.speciesName ?? '', style: context.text.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: Space.xs),
                  if (summary.nextDueAt != null && emoji != null)
                    DueBadge(emoji: emoji, label: l10n.dueLabel(summary.nextDueAt, now), status: summary.dueStatus(now), compact: true)
                  else
                    const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ligne de liste (mode liste) : miniature, nom, emplacement, prochain soin.
class PlantListRow extends ConsumerWidget {
  const PlantListRow({super.key, required this.summary, required this.onTap, this.onLongPress, this.selected = false, this.selecting = false});

  final PlantSummary summary;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool selected;
  final bool selecting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l10n = context.l10n;
    final now = DateTime.now();
    final custom = summary.nextDueTypeKey == null ? null : ref.watch(actionTypeByKeyProvider)[summary.nextDueTypeKey!];
    final emoji = custom?.emoji ?? CareKind.fromKey(summary.nextDueTypeKey ?? '')?.emoji;
    return FloraCard(
      onTap: onTap,
      onLongPress: onLongPress,
      padding: const EdgeInsets.all(Space.xs),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(width: 60, height: 60, child: PlantImage(relativePath: summary.thumbPath, cacheWidth: 180, heroTag: 'plant-${summary.plant.id}')),
          ),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(summary.plant.name, style: context.text.title3, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(summary.locationName ?? summary.plant.speciesName ?? '', style: context.text.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: Space.xs),
          if (selecting)
            AnimatedContainer(
              duration: Motion.of(context, Motion.micro),
              width: 26,
              height: 26,
              margin: const EdgeInsets.only(right: Space.xs),
              decoration: BoxDecoration(color: selected ? c.sage : Colors.transparent, shape: BoxShape.circle, border: Border.all(color: selected ? c.sage : c.line, width: 1.5)),
              child: selected ? Icon(CupertinoIcons.checkmark_alt, size: 15, color: c.onSage) : null,
            )
          else if (summary.nextDueAt != null && emoji != null)
            DueBadge(emoji: emoji, label: l10n.dueLabel(summary.nextDueAt, now), status: summary.dueStatus(now), compact: true),
          const SizedBox(width: Space.xs),
        ],
      ),
    );
  }
}
