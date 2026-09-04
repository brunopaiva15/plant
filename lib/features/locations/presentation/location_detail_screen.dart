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
import '../../actions/application/care_actions.dart';
import '../../attachments/presentation/attachments_section.dart' show showRenameSheet;
import '../../../data/services/photo_storage_service.dart';
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
            if (plants.isNotEmpty)
              SheetAction(
                label: l10n.careAllPlants,
                icon: CupertinoIcons.drop,
                onPressed: () => _careAll(context, ref, plants.map((p) => p.plant.id).toList()),
              ),
            SheetAction(label: l10n.locationPhoto, icon: CupertinoIcons.camera, onPressed: () => _photoMenu(context, ref, location)),
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
          if (location.thumbPath != null) ...[
            ClipRRect(
              borderRadius: Radii.largeAll,
              child: AspectRatio(aspectRatio: 16 / 9, child: PlantImage(relativePath: location.thumbPath, placeholderEmoji: location.icon)),
            ),
            const SizedBox(height: Space.md),
          ],
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
          if (location.notes != null) ...[
            const SizedBox(height: Space.lg),
            Text(l10n.locationNotes, style: context.text.caption),
            const SizedBox(height: Space.xs),
            FloraCard(child: MarkdownText(location.notes!)),
          ],
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
          const SizedBox(height: Space.xl),
          _LocationLog(locationId: locationId),
        ],
      ),
    );
  }
}

/// Applique un soin à toutes les plantes de l'emplacement.
Future<void> _careAll(BuildContext context, WidgetRef ref, List<String> plantIds) async {
  final l10n = context.l10n;
  await showAdaptiveActionSheet(
    context,
    cancelLabel: l10n.cancel,
    actions: [
      SheetAction(label: l10n.waterAllHere, icon: CupertinoIcons.drop, onPressed: () => ref.read(careActionsProvider).logMany(context, plantIds: plantIds, typeKey: CareKind.watering.key)),
      SheetAction(label: l10n.fertilizeAllHere, icon: CupertinoIcons.drop_triangle, onPressed: () => ref.read(careActionsProvider).logMany(context, plantIds: plantIds, typeKey: CareKind.fertilizing.key)),
      SheetAction(label: l10n.repotAllHere, icon: CupertinoIcons.arrow_2_squarepath, onPressed: () => ref.read(careActionsProvider).logMany(context, plantIds: plantIds, typeKey: CareKind.repotting.key)),
    ],
  );
}

/// Choisit ou retire la photo d'illustration de l'emplacement.
Future<void> _photoMenu(BuildContext context, WidgetRef ref, Location location) async {
  final l10n = context.l10n;
  Future<void> pick(PhotoSource source) async {
    final stored = await ref.read(photoStorageProvider).pick(source);
    if (stored == null) return;
    // L'ancienne photo est effacée : un emplacement n'en garde qu'une.
    final previous = location.photoPath;
    final previousThumb = location.thumbPath;
    await ref.read(locationRepositoryProvider).update(location.copyWith(photoPath: () => stored.filePath, thumbPath: () => stored.thumbPath));
    if (previous != null && previousThumb != null) await ref.read(photoStorageProvider).deleteFiles(previous, previousThumb);
    Haptics.success();
  }

  await showAdaptiveActionSheet(
    context,
    cancelLabel: l10n.cancel,
    actions: [
      SheetAction(label: l10n.camera, icon: CupertinoIcons.camera, onPressed: () => pick(PhotoSource.camera)),
      SheetAction(label: l10n.gallery, icon: CupertinoIcons.photo, onPressed: () => pick(PhotoSource.gallery)),
      if (location.photoPath != null)
        SheetAction(
          label: l10n.removeLocationPhoto,
          icon: CupertinoIcons.trash,
          destructive: true,
          onPressed: () async {
            final path = location.photoPath!;
            final thumb = location.thumbPath!;
            await ref.read(locationRepositoryProvider).update(location.copyWith(photoPath: () => null, thumbPath: () => null));
            await ref.read(photoStorageProvider).deleteFiles(path, thumb);
            Haptics.warning();
          },
        ),
    ],
  );
}

/// Journal de l'emplacement.
class _LocationLog extends ConsumerWidget {
  const _LocationLog({required this.locationId});

  final String locationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final entries = ref.watch(_locationLogProvider(locationId)).value ?? const <LocationLogEntry>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: l10n.locationLog, actionLabel: l10n.add, onAction: () => _edit(context, ref), padding: EdgeInsets.zero),
        if (entries.isEmpty)
          FloraCard(
            child: FloraListRow(
              leading: const Text('📓', style: TextStyle(fontSize: 18)),
              title: l10n.noLogEntries,
              subtitle: l10n.logEntryHint,
              onTap: () => _edit(context, ref),
            ),
          )
        else
          FloraGroup(
            children: [
              for (final e in entries)
                FloraListRow(
                  leading: const Text('📓', style: TextStyle(fontSize: 18)),
                  title: e.content,
                  titleMaxLines: 3,
                  subtitle: Dates.dayYear(context, e.createdAt),
                  chevron: false,
                  onTap: () => _edit(context, ref, existing: e),
                ),
            ],
          ),
      ],
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, {LocationLogEntry? existing}) async {
    final l10n = context.l10n;
    final repo = ref.read(locationRepositoryProvider);
    final text = await showRenameSheet(
      context,
      title: existing == null ? l10n.addLogEntry : l10n.editLogEntry,
      hint: l10n.logEntryHint,
      initial: existing?.content,
    );
    if (text == null) return;
    if (text.isEmpty) {
      if (existing == null || !context.mounted) return;
      final ok = await showAdaptiveConfirm(context, title: l10n.confirmDeleteLogEntry, confirmLabel: l10n.delete, cancelLabel: l10n.cancel, destructive: true);
      if (ok) await repo.deleteLogEntry(existing.id);
      return;
    }
    if (existing == null) {
      await repo.addLogEntry(locationId, text);
    } else {
      await repo.editLogEntry(existing.id, text);
    }
    Haptics.success();
  }
}

final _locationLogProvider =
    StreamProvider.autoDispose.family<List<LocationLogEntry>, String>((ref, id) => ref.watch(locationRepositoryProvider).watchLog(id));

final _locationProvider = StreamProvider.autoDispose.family<Location?, String>((ref, id) => ref.watch(locationRepositoryProvider).watch(id));
