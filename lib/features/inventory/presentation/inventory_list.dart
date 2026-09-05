import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/care/care_engine.dart';
import '../../../domain/models/models.dart';
import '../application/inventory_export.dart';
import 'inventory_item_sheet.dart';

final inventoryProvider = StreamProvider.autoDispose<List<InventoryItem>>((ref) => ref.watch(inventoryRepositoryProvider).watchAll());
final inventoryGroupsProvider = StreamProvider.autoDispose<List<InventoryGroup>>((ref) => ref.watch(inventoryRepositoryProvider).watchGroups());

/// Tag choisi comme filtre de l'inventaire (`null` = tous).
class InventoryTagFilter extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? tag) => state = tag;
}

final inventoryTagFilterProvider = NotifierProvider<InventoryTagFilter, String?>(InventoryTagFilter.new);

/// Articles sélectionnés pour un export ou une planche de QR.
class InventorySelection extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void toggle(String id) => state = state.contains(id) ? ({...state}..remove(id)) : {...state, id};
  void clear() => state = const {};
}

final inventorySelectionProvider = NotifierProvider<InventorySelection, Set<String>>(InventorySelection.new);

/// Une section de la liste : un groupe personnalisé, ou une catégorie intégrée.
class _Section {
  const _Section(this.key, this.emoji, this.label, this.items, {this.category});

  final String key;
  final String emoji;
  final String label;
  final List<InventoryItem> items;
  final InventoryCategory? category;
}

/// Inventaire groupé : nom, quantité restante, [−] [+].
class InventorySlivers extends ConsumerWidget {
  const InventorySlivers({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final items = ref.watch(inventoryProvider);
    final all = items.value ?? const <InventoryItem>[];
    final groups = ref.watch(inventoryGroupsProvider).value ?? const <InventoryGroup>[];
    final tagFilter = ref.watch(inventoryTagFilterProvider);
    final selection = ref.watch(inventorySelectionProvider);

    if (items.hasValue && all.isEmpty) {
      return SliverCentered(
          child: EmptyState(emoji: '🧰', title: l10n.noInventoryTitle, subtitle: l10n.noInventorySubtitle, actionLabel: l10n.newItem, onAction: () => showInventoryItemSheet(context)),
      );
    }

    final list = tagFilter == null ? all : all.where((i) => i.tags.contains(tagFilter)).toList();
    final allTags = (all.expand((i) => i.tags).toSet().toList()..sort());
    final sections = _sections(context, list, groups);
    final low = all.where((i) => i.isLow).length;

    return SliverMainAxisGroup(
      slivers: [
        if (low > 0)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.xs),
              child: DueBadge(emoji: '⚠️', label: l10n.lowStockItems(low), status: DueStatus.overdue),
            ),
          ),
        if (allTags.isNotEmpty)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: Space.page),
                children: [
                  for (final tag in allTags) ...[
                    FloraChip(
                      label: tag,
                      emoji: '🏷️',
                      selected: tagFilter == tag,
                      onTap: () => ref.read(inventoryTagFilterProvider.notifier).set(tagFilter == tag ? null : tag),
                    ),
                    const SizedBox(width: Space.xs),
                  ],
                ],
              ),
            ),
          ),
        if (selection.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Space.page, Space.sm, Space.page, 0),
              child: FloraCard(
                color: context.colors.sageSoft,
                padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.xs),
                child: Row(
                  children: [
                    Expanded(child: Text(l10n.itemsSelected(selection.length), style: context.text.callout.copyWith(fontWeight: FontWeight.w600))),
                    FloraButton(
                      label: l10n.exportCsv,
                      style: FloraButtonStyle.ghost,
                      size: FloraButtonSize.small,
                      onPressed: () => shareInventoryCsv(context, all.where((i) => selection.contains(i.id)).toList()),
                    ),
                    FloraButton(
                      label: l10n.labels,
                      style: FloraButtonStyle.ghost,
                      size: FloraButtonSize.small,
                      onPressed: () => shareInventoryLabels(context, all.where((i) => selection.contains(i.id)).toList()),
                    ),
                    FloraIconButton(
                      icon: CupertinoIcons.xmark,
                      semanticLabel: l10n.cancel,
                      size: 30,
                      filled: false,
                      onPressed: ref.read(inventorySelectionProvider.notifier).clear,
                    ),
                  ],
                ),
              ),
            ),
          ),
        for (final section in sections) ...[
          SliverToBoxAdapter(
            child: SectionHeader(
              title: '${section.emoji}  ${section.label}',
              actionLabel: l10n.add,
              onAction: () => showInventoryItemSheet(context, category: section.category, groupId: section.category == null ? section.key : null),
              padding: const EdgeInsets.fromLTRB(Space.page, Space.lg, Space.page, Space.sm),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: Space.page),
            sliver: SliverToBoxAdapter(
              child: FloraGroup(children: [for (final item in section.items) _ItemRow(item: item)]),
            ),
          ),
        ],
      ],
    );
  }

  /// Groupes personnalisés d'abord, dans leur ordre, puis les catégories
  /// intégrées encore utilisées, puis les articles sans groupe.
  static List<_Section> _sections(BuildContext context, List<InventoryItem> items, List<InventoryGroup> groups) {
    final l10n = context.l10n;
    final byGroup = <String, List<InventoryItem>>{};
    final byCategory = <InventoryCategory, List<InventoryItem>>{};
    final knownGroups = {for (final g in groups) g.id};
    for (final i in items) {
      if (i.groupId != null && knownGroups.contains(i.groupId)) {
        byGroup.putIfAbsent(i.groupId!, () => []).add(i);
      } else {
        byCategory.putIfAbsent(i.category, () => []).add(i);
      }
    }
    return [
      for (final g in groups)
        if (byGroup[g.id] case final list? when list.isNotEmpty) _Section(g.id, g.emoji, g.label, list),
      for (final e in byCategory.entries) _Section(e.key.key, e.key.emoji, l10n.categoryName(e.key), e.value, category: e.key),
    ];
  }
}

class _ItemRow extends ConsumerWidget {
  const _ItemRow({required this.item});

  final InventoryItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final selection = ref.watch(inventorySelectionProvider);
    final selecting = selection.isNotEmpty;
    final selected = selection.contains(item.id);
    final step = item.unit == 'ml' ? 50.0 : item.unit == 'g' ? 50.0 : 1.0;

    Widget stepButton(IconData icon, double delta, bool enabled) => Pressable(
          onTap: enabled
              ? () {
                  Haptics.selection();
                  ref.read(inventoryRepositoryProvider).adjustQuantity(item.id, delta);
                }
              : null,
          enabled: enabled,
          haptic: false,
          scale: 0.85,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: c.surfaceMuted, shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: c.ink),
          ),
        );

    final parts = <String>[
      l10n.remaining(l10n.formatQuantity(item.quantity, item.unit)),
      if (item.isLow) l10n.lowStock,
      ...item.tags,
    ];

    return FloraListRow(
      title: item.name,
      subtitle: parts.join(' · '),
      leading: selecting
          ? Icon(selected ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle, size: 22, color: selected ? c.sage : c.inkTertiary)
          : (item.isLow ? Icon(CupertinoIcons.exclamationmark_circle_fill, size: 20, color: c.terracotta) : Text(item.category.emoji, style: const TextStyle(fontSize: 18))),
      trailing: selecting
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                stepButton(CupertinoIcons.minus, -step, item.quantity > 0),
                const SizedBox(width: Space.xs),
                stepButton(CupertinoIcons.plus, step, true),
              ],
            ),
      onTap: () => selecting ? ref.read(inventorySelectionProvider.notifier).toggle(item.id) : showInventoryItemSheet(context, existing: item),
      onLongPress: () {
        Haptics.light();
        ref.read(inventorySelectionProvider.notifier).toggle(item.id);
      },
      chevron: false,
    );
  }
}
