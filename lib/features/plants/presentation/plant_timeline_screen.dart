import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models/models.dart';
import '../application/plant_providers.dart';
import 'timeline_row.dart';

/// Journal complet d'une plante.
class PlantTimelineScreen extends ConsumerWidget {
  const PlantTimelineScreen({super.key, required this.plantId});

  final String plantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final actions = ref.watch(plantActionsProvider(plantId)).value ?? const <PlantAction>[];
    final photos = {for (final p in ref.watch(plantPhotosProvider(plantId)).value ?? const <PlantPhoto>[]) p.id: p};
    final groups = groupByDay(context, actions);
    return FloraPage(
      title: l10n.history,
      child: actions.isEmpty
          ? EmptyState(emoji: '📖', title: l10n.noHistoryTitle, subtitle: l10n.noHistorySubtitle, compact: true)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (label, items) in groups) ...[
                  TimelineDayLabel(label),
                  for (final (i, a) in items.indexed)
                    TimelineRow(
                      action: a,
                      photo: a.photoId == null ? null : photos[a.photoId],
                      isLast: i == items.length - 1,
                      onPhotoTap: () => context.push(Routes.plantGallery(plantId)),
                    ),
                  const SizedBox(height: Space.lg),
                ],
              ],
            ),
    );
  }
}
