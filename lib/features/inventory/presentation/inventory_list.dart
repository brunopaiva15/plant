import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/care/care_engine.dart';
import '../../../domain/models/models.dart';
import 'inventory_item_sheet.dart';

final inventoryProvider = StreamProvider.autoDispose<List<InventoryItem>>((ref) => ref.watch(inventoryRepositoryProvider).watchAll());

/// Inventaire groupé par catégorie : nom, quantité restante, [−] [+].
class InventorySlivers extends ConsumerWidget {
  const InventorySlivers({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final items = ref.watch(inventoryProvider);
    final list = items.value ?? const <InventoryItem>[];
    if (items.hasValue && list.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: EmptyState(emoji: '🧰', title: l10n.noInventoryTitle, subtitle: l10n.noInventorySubtitle, actionLabel: l10n.newItem, onAction: () => showInventoryItemSheet(context)),
        ),
      );
    }
    final groups = <InventoryCategory, List<InventoryItem>>{};
    for (final i in list) {
      groups.putIfAbsent(i.category, () => []).add(i);
    }
    final low = list.where((i) => i.isLow).length;
    return SliverMainAxisGroup(
      slivers: [
        if (low > 0)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.xs),
              child: DueBadge(emoji: '⚠️', label: l10n.lowStockItems(low), status: DueStatus.overdue),
            ),
          ),
        for (final entry in groups.entries) ...[
          SliverToBoxAdapter(
            child: SectionHeader(
              title: '${entry.key.emoji}  ${l10n.categoryName(entry.key)}',
              actionLabel: l10n.add,
              onAction: () => showInventoryItemSheet(context, category: entry.key),
              padding: const EdgeInsets.fromLTRB(Space.page, Space.lg, Space.page, Space.sm),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: Space.page),
            sliver: SliverToBoxAdapter(
              child: FloraGroup(children: [for (final item in entry.value) _ItemRow(item: item)]),
            ),
          ),
        ],
      ],
    );
  }
}

class _ItemRow extends ConsumerWidget {
  const _ItemRow({required this.item});

  final InventoryItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
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
    return FloraListRow(
      title: item.name,
      subtitle: item.isLow ? '${l10n.remaining(l10n.formatQuantity(item.quantity, item.unit))} · ${l10n.lowStock}' : l10n.remaining(l10n.formatQuantity(item.quantity, item.unit)),
      leading: item.isLow ? Icon(CupertinoIcons.exclamationmark_circle_fill, size: 20, color: c.terracotta) : Text(item.category.emoji, style: const TextStyle(fontSize: 18)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          stepButton(CupertinoIcons.minus, -step, item.quantity > 0),
          const SizedBox(width: Space.xs),
          stepButton(CupertinoIcons.plus, step, true),
        ],
      ),
      onTap: () => showInventoryItemSheet(context, existing: item),
      chevron: false,
    );
  }
}
