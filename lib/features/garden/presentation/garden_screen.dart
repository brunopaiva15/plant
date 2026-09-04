import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models/models.dart';
import '../../calendar/presentation/calendar_view.dart';
import '../../calendar/presentation/event_categories_sheet.dart';
import '../../calendar/presentation/event_sheet.dart';
import '../../inventory/application/inventory_export.dart';
import '../../inventory/presentation/inventory_groups_sheet.dart';
import '../../inventory/presentation/inventory_item_sheet.dart';
import '../../inventory/presentation/inventory_list.dart';
import '../../locations/presentation/location_edit_sheet.dart';
import '../../tasks/presentation/task_sheet.dart';
import '../../tasks/presentation/tasks_view.dart';

enum GardenSection { locations, tasks, inventory, calendar }

class GardenSectionController extends Notifier<GardenSection> {
  @override
  GardenSection build() => GardenSection.locations;
  void set(GardenSection s) => state = s;
}

final gardenSectionProvider = NotifierProvider<GardenSectionController, GardenSection>(GardenSectionController.new);

/// Jardin : emplacements, inventaire et calendrier derrière un contrôle segmenté.
class GardenScreen extends ConsumerWidget {
  const GardenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final section = ref.watch(gardenSectionProvider);
    final trailing = switch (section) {
      GardenSection.locations => FloraIconButton(icon: CupertinoIcons.plus, semanticLabel: l10n.newLocationTitle, onPressed: () => showLocationEditSheet(context)),
      GardenSection.tasks => FloraIconButton(icon: CupertinoIcons.plus, semanticLabel: l10n.newTask, onPressed: () => showTaskSheet(context)),
      GardenSection.inventory => FloraIconButton(icon: CupertinoIcons.plus, semanticLabel: l10n.newItem, onPressed: () => _inventoryMenu(context, ref)),
      GardenSection.calendar => FloraIconButton(icon: CupertinoIcons.plus, semanticLabel: l10n.newEvent, onPressed: () => _calendarMenu(context)),
    };
    return LargeTitlePage(
      title: l10n.gardenTitle,
      trailing: trailing,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.md),
            child: AdaptiveSegmented<GardenSection>(
              segments: {
                GardenSection.locations: l10n.gardenLocations,
                GardenSection.tasks: l10n.gardenTasks,
                GardenSection.inventory: l10n.gardenInventory,
                GardenSection.calendar: l10n.gardenCalendar,
              },
              value: section,
              onChanged: (s) => ref.read(gardenSectionProvider.notifier).set(s),
            ),
          ),
        ),
        switch (section) {
          GardenSection.locations => const _LocationsSlivers(),
          GardenSection.tasks => const TasksSlivers(),
          GardenSection.inventory => const InventorySlivers(),
          GardenSection.calendar => const CalendarSlivers(),
        },
      ],
    );
  }
}

/// Bouton « + » de l'inventaire : nouvel article, ou gestion des groupes.
Future<void> _inventoryMenu(BuildContext context, WidgetRef ref) async {
  final l10n = context.l10n;
  final items = ref.read(inventoryProvider).value ?? const <InventoryItem>[];
  await showAdaptiveActionSheet(
    context,
    actions: [
      SheetAction(label: l10n.newItem, onPressed: () => showInventoryItemSheet(context)),
      SheetAction(label: l10n.manageGroups, onPressed: () => showInventoryGroupsSheet(context)),
      if (items.isNotEmpty) SheetAction(label: l10n.exportCsv, onPressed: () => shareInventoryCsv(context, items)),
    ],
    cancelLabel: l10n.cancel,
  );
}

/// Bouton « + » du calendrier : nouvel événement, ou gestion des catégories.
Future<void> _calendarMenu(BuildContext context) async {
  final l10n = context.l10n;
  await showAdaptiveActionSheet(
    context,
    actions: [
      SheetAction(label: l10n.newEvent, onPressed: () => showEventSheet(context)),
      SheetAction(label: l10n.manageEventCategories, onPressed: () => showEventCategoriesSheet(context)),
    ],
    cancelLabel: l10n.cancel,
  );
}

class _LocationsSlivers extends ConsumerWidget {
  const _LocationsSlivers();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final tree = ref.watch(locationTreeProvider);
    final nodes = tree.value ?? const <LocationNode>[];
    final count = ref.watch(activePlantCountProvider).value ?? 0;
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.md),
            child: Text(l10n.plantCount(count), style: context.text.callout),
          ),
        ),
        if (tree.hasValue && nodes.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: EmptyState(emoji: '🏡', title: l10n.noLocationsTitle, subtitle: l10n.noLocationsSubtitle, actionLabel: l10n.newLocationTitle, onAction: () => showLocationEditSheet(context)),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: Space.page),
            sliver: SliverList.separated(
              itemCount: nodes.length,
              separatorBuilder: (_, _) => const SizedBox(height: Space.sm),
              itemBuilder: (context, i) => _LocationCard(node: nodes[i]),
            ),
          ),
      ],
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.node});

  final LocationNode node;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    return FloraCard(
      padding: EdgeInsets.zero,
      clip: true,
      child: Column(
        children: [
          FloraListRow(
            leading: EmojiTile(emoji: node.location.icon, background: c.sageSoft),
            title: node.location.name,
            subtitle: l10n.plantCount(node.totalPlantCount),
            onTap: () => context.push(Routes.location(node.location.id)),
          ),
          for (final child in node.children) ...[
            Divider(height: 1, thickness: 0.5, indent: 60, color: c.line),
            Padding(
              padding: const EdgeInsets.only(left: Space.lg),
              child: FloraListRow(
                leading: Text(child.location.icon, style: const TextStyle(fontSize: 20)),
                title: child.location.name,
                subtitle: l10n.plantCount(child.totalPlantCount),
                dense: true,
                onTap: () => context.push(Routes.location(child.location.id)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
