import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models/models.dart';
import '../../locations/presentation/location_edit_sheet.dart';

/// Jardin : arborescence des emplacements avec le nombre de plantes.
/// Inventaire et calendrier rejoindront cet onglet en Phase 2.
class GardenScreen extends ConsumerWidget {
  const GardenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final tree = ref.watch(locationTreeProvider);
    final nodes = tree.value ?? const <LocationNode>[];
    final count = ref.watch(activePlantCountProvider).value ?? 0;
    return LargeTitlePage(
      title: l10n.gardenTitle,
      trailing: FloraIconButton(icon: CupertinoIcons.plus, semanticLabel: l10n.newLocationTitle, onPressed: () => showLocationEditSheet(context)),
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
