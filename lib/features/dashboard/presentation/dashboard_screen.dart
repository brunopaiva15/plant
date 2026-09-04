import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models/models.dart';
import '../application/dashboard_providers.dart';

/// Tableau de bord : les chiffres du jardin, ce qui va mal, et ce qui bouge.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final stats = ref.watch(gardenStatsProvider);
    final warnings = ref.watch(plantWarningsProvider);
    final recent = ref.watch(recentPlantsProvider);
    final mode = ref.watch(recentPlantsModeProvider);

    return FloraPage(
      title: l10n.dashboardTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StatsGrid(stats: stats),
          const SizedBox(height: Space.lg),
          SectionHeader(title: l10n.warningsSection, padding: const EdgeInsets.only(bottom: Space.sm)),
          if (warnings.isEmpty)
            FloraCard(
              child: Row(
                children: [
                  const EmojiTile(emoji: '🌿', size: 40),
                  const SizedBox(width: Space.md),
                  Expanded(child: Text(l10n.noWarnings, style: context.text.callout)),
                ],
              ),
            )
          else
            FloraGroup(children: [for (final w in warnings.take(8)) _WarningRow(warning: w)]),
          if (recent.isNotEmpty) ...[
            const SizedBox(height: Space.lg),
            Row(
              children: [
                Expanded(child: Text(l10n.recentPlantsSection, style: context.text.title3)),
                AdaptiveSegmented<RecentPlantsMode>(
                  segments: {RecentPlantsMode.added: l10n.recentAdded, RecentPlantsMode.updated: l10n.recentUpdated},
                  value: mode,
                  onChanged: (m) => ref.read(recentPlantsModeProvider.notifier).set(m),
                ),
              ],
            ),
            const SizedBox(height: Space.sm),
            SizedBox(height: 132, child: _RecentCarousel(plants: recent)),
          ],
          const SizedBox(height: Space.lg),
          FloraGroup(
            children: [
              FloraListRow(
                leading: const EmojiTile(emoji: '📜', size: 34),
                title: l10n.activityLogTitle,
                onTap: () => context.push(Routes.activityLog),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Grille de chiffres : deux par ligne, sans graphique inutile.
class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final GardenStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tiles = <({String emoji, String label, String value})>[
      (emoji: '🪴', label: l10n.statPlants, value: '${stats.plants}'),
      (emoji: '🌿', label: l10n.statSpecies, value: '${stats.species}'),
      (emoji: '🏡', label: l10n.statLocations, value: '${stats.locations}'),
      (emoji: '💧', label: l10n.statWateringsThisMonth, value: '${stats.wateringsThisMonth}'),
      (emoji: '✓', label: l10n.statActionsThisMonth, value: '${stats.actionsThisMonth}'),
      (emoji: '⏰', label: l10n.statNeedingCare, value: '${stats.needingCare}'),
      if (stats.openTasks > 0) (emoji: '📋', label: l10n.statOpenTasks, value: '${stats.openTasks}'),
      if (stats.lowStock > 0) (emoji: '⚠️', label: l10n.statLowStock, value: '${stats.lowStock}'),
      if (stats.favorites > 0) (emoji: '⭐', label: l10n.statFavorites, value: '${stats.favorites}'),
      if (stats.archived > 0) (emoji: '📦', label: l10n.statArchived, value: '${stats.archived}'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < tiles.length; i += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _StatTile(tile: tiles[i])),
                const SizedBox(width: Space.sm),
                // Une ligne impaire garde sa moitié vide plutôt que d'étirer
                // la dernière tuile sur toute la largeur.
                Expanded(child: i + 1 < tiles.length ? _StatTile(tile: tiles[i + 1]) : const SizedBox.shrink()),
              ],
            ),
          ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.tile});

  final ({String emoji, String label, String value}) tile;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return FloraCard(
      padding: const EdgeInsets.all(Space.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(tile.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: Space.xs),
          Text(tile.value, style: context.text.title2),
          Text(tile.label, style: context.text.caption.copyWith(color: c.inkSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _WarningRow extends StatelessWidget {
  const _WarningRow({required this.warning});

  final PlantWarning warning;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final (emoji, label, color) = switch (warning.reason) {
      WarningReason.sick => ('🩹', l10n.warningSick, c.danger),
      WarningReason.watch => ('👀', l10n.warningWatch, c.terracotta),
      WarningReason.overdue => ('⏰', l10n.warningOverdue(warning.overdueDays), c.terracotta),
    };
    return FloraListRow(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(width: 34, height: 34, child: PlantImage(relativePath: warning.plant.thumbPath, cacheWidth: 102)),
      ),
      title: warning.plant.plant.name,
      subtitle: label,
      subtitleColor: color,
      trailing: Text(emoji, style: const TextStyle(fontSize: 18)),
      chevron: false,
      onTap: () => context.push(Routes.plant(warning.plant.plant.id)),
    );
  }
}

class _RecentCarousel extends StatelessWidget {
  const _RecentCarousel({required this.plants});

  final List<PlantSummary> plants;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: plants.length,
      separatorBuilder: (_, _) => const SizedBox(width: Space.sm),
      itemBuilder: (context, i) {
        final p = plants[i];
        return Pressable(
          onTap: () => context.push(Routes.plant(p.plant.id)),
          scale: 0.96,
          child: SizedBox(
            width: 96,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: Radii.largeAll,
                  child: SizedBox(width: 96, height: 96, child: PlantImage(relativePath: p.thumbPath, cacheWidth: 288)),
                ),
                const SizedBox(height: Space.xxs),
                Text(p.plant.name, style: context.text.caption.copyWith(color: c.ink), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        );
      },
    );
  }
}
