import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models/models.dart';
import '../../attachments/presentation/attachments_section.dart' show showRenameSheet;
import '../../plants/application/plant_providers.dart';
import '../application/archive_providers.dart';

/// Nom des archives : celui de l'utilisateur, sinon le libellé traduit.
String archiveTitle(BuildContext context, String custom) => custom.trim().isEmpty ? context.l10n.archives : custom.trim();

/// « Anciennes plantes » : recherche, tri, navigation par année, deux vues.
class ArchiveScreen extends ConsumerStatefulWidget {
  const ArchiveScreen({super.key});

  @override
  ConsumerState<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends ConsumerState<ArchiveScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _sortLabel(AppLocalizations l10n, ArchiveSort sort) => switch (sort) {
        ArchiveSort.archivedDesc => l10n.archiveSortArchivedDesc,
        ArchiveSort.archivedAsc => l10n.archiveSortArchivedAsc,
        ArchiveSort.name => l10n.archiveSortName,
        ArchiveSort.longestKept => l10n.archiveSortLongestKept,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final all = ref.watch(archivedPlantsProvider).value ?? const <PlantSummary>[];
    final plants = ref.watch(filteredArchiveProvider);
    final filter = ref.watch(archiveFilterProvider);
    final years = ref.watch(archiveYearsProvider);
    final grid = ref.watch(archiveGridProvider);
    final name = archiveTitle(context, ref.watch(preferencesProvider).archiveName);

    final searchField = isCupertino(context)
        ? CupertinoSearchTextField(
            controller: _search,
            placeholder: l10n.searchArchives,
            backgroundColor: c.surfaceMuted,
            style: context.text.body,
            onChanged: ref.read(archiveFilterProvider.notifier).setQuery,
          )
        : FloraTextField(
            controller: _search,
            hint: l10n.searchArchives,
            prefix: Icon(CupertinoIcons.search, size: 20, color: c.inkTertiary),
            onChanged: ref.read(archiveFilterProvider.notifier).setQuery,
            textCapitalization: TextCapitalization.none,
          );

    return LargeTitlePage(
      title: name,
      searchField: all.isEmpty ? null : searchField,
      trailing: all.isEmpty
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloraIconButton(
                  icon: grid ? CupertinoIcons.list_bullet : CupertinoIcons.square_grid_2x2,
                  semanticLabel: grid ? l10n.archiveSortName : l10n.archives,
                  onPressed: () => ref.read(archiveGridProvider.notifier).set(!grid),
                ),
                const SizedBox(width: Space.xs),
                FloraIconButton(
                  icon: CupertinoIcons.arrow_up_arrow_down,
                  semanticLabel: l10n.sortBy,
                  onPressed: () => showAdaptiveActionSheet(
                    context,
                    title: l10n.sortBy,
                    cancelLabel: l10n.cancel,
                    actions: [
                      for (final sort in ArchiveSort.values)
                        SheetAction(label: _sortLabel(l10n, sort), onPressed: () => ref.read(archiveFilterProvider.notifier).setSort(sort)),
                    ],
                  ),
                ),
              ],
            ),
      slivers: [
        if (all.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: EmptyState(emoji: '🍂', title: l10n.noArchivesTitle, subtitle: l10n.noArchivesSubtitle, compact: true)),
          )
        else ...[
          if (years.length > 1)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: Space.page),
                  children: [
                    FloraChip(label: l10n.allYears, selected: filter.year == null, onTap: () => ref.read(archiveFilterProvider.notifier).setYear(null)),
                    const SizedBox(width: Space.xs),
                    for (final year in years) ...[
                      FloraChip(
                        label: '$year',
                        selected: filter.year == year,
                        onTap: () => ref.read(archiveFilterProvider.notifier).setYear(filter.year == year ? null : year),
                      ),
                      const SizedBox(width: Space.xs),
                    ],
                  ],
                ),
              ),
            ),
          if (plants.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(Space.page),
                child: Text(l10n.noArchiveMatch, style: context.text.callout, textAlign: TextAlign.center),
              ),
            )
          else if (grid)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(Space.page, Space.sm, Space.page, Space.xl),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: Space.sm, crossAxisSpacing: Space.sm, childAspectRatio: 0.78),
                itemCount: plants.length,
                itemBuilder: (context, i) => _ArchiveCard(summary: plants[i]),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(Space.page, Space.sm, Space.page, Space.xl),
              sliver: SliverToBoxAdapter(
                child: FloraGroup(children: [for (final s in plants) _ArchiveRow(summary: s)]),
              ),
            ),
        ],
      ],
    );
  }
}

/// Sous-titre commun aux deux vues : date d'archivage, raison, durée gardée.
String _subtitle(BuildContext context, PlantSummary s) {
  final l10n = context.l10n;
  final days = daysKept(s);
  return [
    if (s.plant.archivedAt != null) l10n.archivedOn(Dates.dayYear(context, s.plant.archivedAt!)),
    if (s.plant.archiveReason != null) reasonLabel(l10n, s.plant.archiveReason!),
    if (days >= 365) l10n.keptForYears(days ~/ 365) else if (days > 0) l10n.keptForDays(days),
  ].join(' · ');
}

String reasonLabel(AppLocalizations l10n, String key) => switch (key) {
      'died' => l10n.reasonDied,
      'given' => l10n.reasonGiven,
      'sold' => l10n.reasonSold,
      _ => l10n.reasonOther,
    };

/// Actions d'une plante archivée : restaurer, ou supprimer définitivement.
Future<void> showArchiveActions(BuildContext context, WidgetRef ref, PlantSummary s) {
  final l10n = context.l10n;
  return showAdaptiveActionSheet(
    context,
    title: s.plant.name,
    cancelLabel: l10n.cancel,
    actions: [
      SheetAction(
        label: l10n.restore,
        icon: CupertinoIcons.arrow_uturn_left,
        onPressed: () async {
          await ref.read(plantRepositoryProvider).restore([s.plant.id]);
          Haptics.success();
          ref.read(toastProvider.notifier).show(ToastData(message: l10n.plantRestored(s.plant.name), emoji: '🌱'));
        },
      ),
      SheetAction(
        label: l10n.deleteForever,
        icon: CupertinoIcons.trash,
        destructive: true,
        onPressed: () async {
          final ok = await showAdaptiveConfirm(context, title: l10n.deleteForever, message: l10n.deleteForeverConfirm, confirmLabel: l10n.delete, cancelLabel: l10n.cancel, destructive: true);
          if (!ok) return;
          await ref.read(plantRepositoryProvider).deleteForever(s.plant.id);
          Haptics.warning();
        },
      ),
    ],
  );
}

class _ArchiveRow extends ConsumerWidget {
  const _ArchiveRow({required this.summary});

  final PlantSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloraListRow(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(width: 44, height: 44, child: PlantImage(relativePath: summary.thumbPath, remoteUrl: summary.thumbUrl, cacheWidth: 132)),
      ),
      title: summary.plant.name,
      subtitle: _subtitle(context, summary),
      chevron: false,
      onTap: () => showArchiveActions(context, ref, summary),
    );
  }
}

class _ArchiveCard extends ConsumerWidget {
  const _ArchiveCard({required this.summary});

  final PlantSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    return Pressable(
      onTap: () => showArchiveActions(context, ref, summary),
      scale: 0.97,
      child: FloraCard(
        padding: EdgeInsets.zero,
        clip: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: PlantImage(relativePath: summary.thumbPath, remoteUrl: summary.thumbUrl, cacheWidth: 400)),
            Padding(
              padding: const EdgeInsets.all(Space.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(summary.plant.name, style: context.text.callout.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(_subtitle(context, summary), style: context.text.caption.copyWith(color: c.inkSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Réglage du nom des archives, appelé depuis les Réglages.
Future<void> editArchiveName(BuildContext context, WidgetRef ref) async {
  final l10n = context.l10n;
  final current = ref.read(preferencesProvider).archiveName;
  final name = await showRenameSheet(context, title: l10n.archiveNameTitle, hint: l10n.archiveNameHint, initial: current);
  if (name == null) return;
  await ref.read(preferencesProvider.notifier).setArchiveName(name);
}
