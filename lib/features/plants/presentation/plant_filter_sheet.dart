import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models/models.dart';
import '../../../domain/repositories/repositories.dart';
import '../application/plant_providers.dart';

/// Filtres et tri de la collection, discrets et réversibles.
Future<void> showPlantFilterSheet(BuildContext context) => showFloraSheet<void>(context, scrollable: true, builder: (_) => const _FilterBody());

class _FilterBody extends ConsumerWidget {
  const _FilterBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final filter = ref.watch(plantFilterProvider);
    final ctrl = ref.read(plantFilterProvider.notifier);
    final prefs = ref.watch(preferencesProvider);
    final locations = ref.watch(locationsProvider).value ?? const <Location>[];
    final tags = ref.watch(tagsProvider).value ?? const <Tag>[];
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetHeader(
            title: l10n.filters,
            trailing: filter.hasActiveFilters
                ? Pressable(onTap: ctrl.clear, scale: 0.95, child: Text(l10n.clearFilters, style: context.text.caption.copyWith(color: context.colors.sage, fontWeight: FontWeight.w600), textAlign: TextAlign.end))
                : null,
          ),
          AdaptiveSegmented<bool>(
            segments: {true: l10n.gridView, false: l10n.listView},
            value: prefs.gridView,
            onChanged: (v) => ref.read(preferencesProvider.notifier).setGridView(v),
          ),
          const SizedBox(height: Space.lg),
          Text(l10n.sortBy, style: context.text.caption),
          const SizedBox(height: Space.xs),
          Wrap(
            spacing: Space.xs,
            runSpacing: Space.xs,
            children: [
              for (final s in PlantSort.values)
                FloraChip(
                  label: switch (s) { PlantSort.name => l10n.sortName, PlantSort.nextCare => l10n.sortNextCare, PlantSort.recentlyAdded => l10n.sortRecent },
                  selected: filter.sort == s,
                  onTap: () => ctrl.update((f) => f.copyWith(sort: s)),
                ),
            ],
          ),
          const SizedBox(height: Space.lg),
          Wrap(
            spacing: Space.xs,
            runSpacing: Space.xs,
            children: [
              FloraChip(emoji: '💧', label: l10n.filterNeedsAttention, selected: filter.needsAttention, onTap: () => ctrl.update((f) => f.copyWith(needsAttention: !f.needsAttention))),
              FloraChip(emoji: '❤️', label: l10n.filterFavorites, selected: filter.favoritesOnly, onTap: () => ctrl.update((f) => f.copyWith(favoritesOnly: !f.favoritesOnly))),
            ],
          ),
          if (locations.isNotEmpty) ...[
            const SizedBox(height: Space.lg),
            Text(l10n.filterLocation, style: context.text.caption),
            const SizedBox(height: Space.xs),
            Wrap(
              spacing: Space.xs,
              runSpacing: Space.xs,
              children: [
                for (final l in locations)
                  FloraChip(
                    emoji: l.icon,
                    label: l.name,
                    selected: filter.locationId == l.id,
                    onTap: () => ctrl.update((f) => f.copyWith(locationId: () => f.locationId == l.id ? null : l.id)),
                  ),
              ],
            ),
          ],
          if (tags.isNotEmpty) ...[
            const SizedBox(height: Space.lg),
            Text(l10n.tags, style: context.text.caption),
            const SizedBox(height: Space.xs),
            Wrap(
              spacing: Space.xs,
              runSpacing: Space.xs,
              children: [
                for (final t in tags)
                  FloraChip(label: t.name, selected: filter.tagId == t.id, onTap: () => ctrl.update((f) => f.copyWith(tagId: () => f.tagId == t.id ? null : t.id))),
              ],
            ),
          ],
          const SizedBox(height: Space.md),
        ],
      ),
    );
  }
}
