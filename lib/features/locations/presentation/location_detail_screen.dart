import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models/models.dart';
import '../../../domain/repositories/repositories.dart';
import '../../plants/application/plant_providers.dart';
import '../../plants/presentation/create_plant_flow.dart';
import '../../plants/presentation/plant_card.dart';
import 'location_edit_sheet.dart';

/// Fiche emplacement : conditions et plantes qui s'y trouvent.
class LocationDetailScreen extends ConsumerWidget {
  const LocationDetailScreen({super.key, required this.locationId});

  final String locationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final location = ref.watch(_locationProvider(locationId)).value;
    final plants = ref.watch(plantSummariesProvider(PlantFilter(locationId: locationId))).value ?? const <PlantSummary>[];
    if (location == null) return Scaffold(backgroundColor: c.canvas, body: const Center(child: AdaptiveProgress()));

    final conditions = <String>[
      if (location.light != null) '${l10n.light} · ${switch (location.light) { 'low' => l10n.lightLow, 'medium' => l10n.lightMedium, _ => l10n.lightHigh }}',
      if (location.orientation != null) '${l10n.orientation} · ${location.orientation}',
    ];

    return FloraPage(
      title: location.name,
      trailing: FloraIconButton(
        icon: CupertinoIcons.ellipsis,
        semanticLabel: l10n.more,
        onPressed: () => showAdaptiveActionSheet(
          context,
          cancelLabel: l10n.cancel,
          actions: [
            SheetAction(label: l10n.addPlant, icon: CupertinoIcons.plus, onPressed: () => startCreatePlantFlow(context, ref, locationId: locationId)),
            SheetAction(label: l10n.editLocation, icon: CupertinoIcons.pencil, onPressed: () => showLocationEditSheet(context, existing: location)),
            SheetAction(
              label: l10n.deleteLocation,
              icon: CupertinoIcons.trash,
              destructive: true,
              onPressed: () async {
                final ok = await showAdaptiveConfirm(context, title: l10n.deleteLocation, message: l10n.deleteLocationHint, confirmLabel: l10n.delete, cancelLabel: l10n.cancel, destructive: true);
                if (!ok) return;
                await ref.read(locationRepositoryProvider).delete(locationId);
                Haptics.warning();
                if (context.mounted) context.pop();
              },
            ),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              EmojiTile(emoji: location.icon, size: 56, background: c.sageSoft),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.plantCount(plants.length), style: context.text.title3),
                    for (final line in conditions) Text(line, style: context.text.caption),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.xl),
          if (plants.isEmpty)
            EmptyState(emoji: '🪴', title: l10n.noPlantsHereTitle, subtitle: l10n.noPlantsHereSubtitle, actionLabel: l10n.addPlant, onAction: () => startCreatePlantFlow(context, ref, locationId: locationId), compact: true)
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 220, mainAxisSpacing: Space.sm, crossAxisSpacing: Space.sm, childAspectRatio: 0.72),
              itemCount: plants.length,
              itemBuilder: (context, i) => PlantGridCard(summary: plants[i], onTap: () => context.push(Routes.plant(plants[i].plant.id))),
            ),
        ],
      ),
    );
  }
}

final _locationProvider = StreamProvider.autoDispose.family<Location?, String>((ref, id) => ref.watch(locationRepositoryProvider).watch(id));
