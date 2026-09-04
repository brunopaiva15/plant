import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/utils/dates.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models/models.dart';
import '../application/dashboard_providers.dart';

/// Journal global : tout ce qui s'est passé dans le jardin, dans l'ordre.
class ActivityLogScreen extends ConsumerWidget {
  const ActivityLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final entries = ref.watch(activityLogProvider);
    if (entries.isEmpty) {
      return FloraPage(
        title: l10n.activityLogTitle,
        child: Padding(
          padding: const EdgeInsets.only(top: Space.huge),
          child: EmptyState(emoji: '📜', title: l10n.activityLogTitle, subtitle: l10n.activityEmpty, compact: true),
        ),
      );
    }
    // Les jours servent de repères : une entête par journée, comme l'agenda.
    final byDay = <DateTime, List<ActivityEntry>>{};
    for (final e in entries) {
      byDay.putIfAbsent(e.at.dateOnly, () => []).add(e);
    }
    return FloraPage(
      title: l10n.activityLogTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final day in byDay.entries) ...[
            Padding(
              padding: const EdgeInsets.only(left: Space.xxs, bottom: Space.xs),
              child: Text(Dates.relativeDay(context, day.key), style: context.text.title3),
            ),
            FloraGroup(children: [for (final e in day.value) _ActivityRow(entry: e)]),
            const SizedBox(height: Space.lg),
          ],
        ],
      ),
    );
  }
}

class _ActivityRow extends ConsumerWidget {
  const _ActivityRow({required this.entry});

  final ActivityEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final types = ref.watch(actionTypeByKeyProvider);
    final custom = entry.typeKey == null ? null : types[entry.typeKey!];

    final (emoji, title) = switch (entry.kind) {
      ActivityKind.action => (
          custom?.emoji ?? CareKind.fromKey(entry.typeKey ?? '')?.emoji ?? '✓',
          l10n.kindDone(entry.typeKey ?? '', custom: custom),
        ),
      ActivityKind.plantAdded => ('🌱', l10n.activityPlantAdded),
      ActivityKind.plantArchived => ('📦', l10n.activityPlantArchived),
      ActivityKind.locationNote => ('📝', l10n.activityLocationNote),
      ActivityKind.taskDone => ('📋', l10n.activityTaskDone),
    };
    // Sous-titre : la plante concernée, le texte libre, puis l'heure.
    final parts = <String>[
      if (entry.plantName != null) entry.plantName!,
      if (entry.text != null && entry.text!.trim().isNotEmpty) entry.text!.trim(),
      Dates.time(context, entry.at),
    ];

    return FloraListRow(
      leading: entry.thumbPath != null
          ? ClipRRect(borderRadius: BorderRadius.circular(10), child: SizedBox(width: 32, height: 32, child: PlantImage(relativePath: entry.thumbPath, cacheWidth: 96)))
          : EmojiTile(emoji: emoji, size: 32, background: c.surfaceMuted),
      title: title,
      subtitle: parts.join(' · '),
      trailing: entry.thumbPath == null ? null : Text(emoji, style: const TextStyle(fontSize: 16)),
      chevron: false,
      dense: true,
      onTap: entry.plantId == null ? null : () => context.push(Routes.plant(entry.plantId!)),
    );
  }
}
