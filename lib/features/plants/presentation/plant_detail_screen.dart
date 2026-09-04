import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/observability/observability.dart';
import '../../../data/services/photo_storage_service.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/care/care_engine.dart';
import '../../../domain/models/models.dart';
import '../../actions/application/care_actions.dart';
import '../../actions/presentation/add_action_sheet.dart';
import '../../tasks/application/task_providers.dart';
import '../../tasks/presentation/task_row.dart';
import '../../tasks/presentation/task_sheet.dart';
import '../../actions/presentation/add_note_sheet.dart';
import '../../locations/presentation/location_picker_sheet.dart';
import '../application/plant_providers.dart';
import 'create_plant_flow.dart';
import 'edit_plant_sheet.dart';
import 'measurements_section.dart';
import 'plant_tags_sheet.dart';
import '../../identification/presentation/identification_sheet.dart';
import '../../qr/presentation/plant_qr_sheet.dart';
import '../../diagnosis/presentation/diagnosis_sheet.dart';
import '../../species/presentation/species_sheet.dart';
import 'timeline_row.dart';

/// La fiche plante : photo immersive, prochains soins, actions rapides,
/// historique récent, croissance, informations, boutures.
class PlantDetailScreen extends ConsumerStatefulWidget {
  const PlantDetailScreen({super.key, required this.plantId});

  final String plantId;

  @override
  ConsumerState<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends ConsumerState<PlantDetailScreen> {
  final Set<String> _justDone = {};

  String get id => widget.plantId;

  Future<void> _quick(String typeKey, String plantName) async {
    if (typeKey == CareKind.photo.key) return _addPhoto();
    if (typeKey == CareKind.note.key) return showAddNoteSheet(context, plantId: id, plantName: plantName);
    if (typeKey == CareKind.measurement.key) return showAddActionSheet(context, plantId: id, plantName: plantName, initialTypeKey: typeKey);
    setState(() => _justDone.add(typeKey));
    await ref.read(careActionsProvider).logQuick(context, plantId: id, plantName: plantName, typeKey: typeKey);
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (mounted) setState(() => _justDone.remove(typeKey));
  }

  Future<void> _addPhoto() {
    final l10n = context.l10n;
    return showAdaptiveActionSheet(
      context,
      cancelLabel: l10n.cancel,
      actions: [
        SheetAction(label: l10n.camera, icon: CupertinoIcons.camera, onPressed: () => ref.read(careActionsProvider).addPhoto(context, plantId: id, source: PhotoSource.camera)),
        SheetAction(label: l10n.gallery, icon: CupertinoIcons.photo, onPressed: () => ref.read(careActionsProvider).addPhoto(context, plantId: id, source: PhotoSource.gallery)),
      ],
    );
  }

  Future<void> _menu(Plant plant) async {
    final l10n = context.l10n;
    await showAdaptiveActionSheet(
      context,
      cancelLabel: l10n.cancel,
      actions: [
        SheetAction(label: l10n.editPlant, icon: CupertinoIcons.pencil, onPressed: () => showEditPlantSheet(context, plant: plant)),
        SheetAction(
          label: plant.isFavorite ? l10n.unfavorite : l10n.favorite,
          icon: plant.isFavorite ? CupertinoIcons.heart_slash : CupertinoIcons.heart,
          onPressed: () => _toggleFavorite(plant),
        ),
        SheetAction(label: l10n.schedule, icon: CupertinoIcons.clock, onPressed: () => context.push(Routes.plantSchedule(id))),
        SheetAction(label: l10n.newTask, icon: CupertinoIcons.checkmark_square, onPressed: () => showTaskSheet(context, plantId: id)),
        SheetAction(label: l10n.qrCode, icon: CupertinoIcons.qrcode, onPressed: () => showPlantQrSheet(context, plant: plant)),
        if (ref.read(plantIdentifierProvider).isConfigured && plant.primaryPhotoId != null)
          SheetAction(label: l10n.identify, icon: CupertinoIcons.sparkles, onPressed: () => _identify(plant)),
        if (ref.read(plantDiagnoserProvider).isConfigured)
          SheetAction(label: l10n.diagnosisTitle, icon: CupertinoIcons.bandage, onPressed: () => showDiagnosisSheet(context, plant: plant)),
        SheetAction(label: l10n.tags, icon: CupertinoIcons.tag, onPressed: () => showPlantTagsSheet(context, plantId: id)),
        SheetAction(
          label: l10n.move,
          icon: CupertinoIcons.location,
          onPressed: () async {
            final choice = await showLocationPicker(context, selectedId: plant.locationId);
            if (choice != null) await ref.read(plantRepositoryProvider).moveToLocation([id], choice.id);
          },
        ),
        SheetAction(label: l10n.createCutting, icon: CupertinoIcons.leaf_arrow_circlepath, onPressed: () => startCreatePlantFlow(context, ref, parentPlantId: id, parentName: plant.name, locationId: plant.locationId)),
        SheetAction(label: l10n.archivePlant, icon: CupertinoIcons.archivebox, destructive: true, onPressed: () => _archive(plant)),
      ],
    );
  }

  Future<void> _identify(Plant plant) async {
    final photos = ref.read(plantPhotosProvider(id)).value ?? const <PlantPhoto>[];
    final primary = photos.where((p) => p.id == plant.primaryPhotoId).firstOrNull ?? photos.firstOrNull;
    if (primary == null) return;
    final path = await ref.read(photoStorageProvider).absolutePath(primary.filePath);
    if (!mounted) return;
    final candidate = await showIdentificationSheet(context, absoluteImagePath: path);
    if (candidate == null || !mounted) return;
    await ref.read(plantRepositoryProvider).update(plant.copyWith(speciesName: () => candidate.scientificName));
    if (mounted) ref.read(toastProvider.notifier).show(ToastData(message: context.l10n.speciesSet, emoji: '🔬'));
  }

  Future<void> _toggleFavorite(Plant plant) async {
    Haptics.selection();
    await ref.read(plantRepositoryProvider).setFavorite(id, !plant.isFavorite);
  }

  Future<void> _archive(Plant plant) async {
    final l10n = context.l10n;
    final reasons = {'died': l10n.reasonDied, 'given': l10n.reasonGiven, 'sold': l10n.reasonSold, 'other': l10n.reasonOther};
    await showAdaptiveActionSheet(
      context,
      title: l10n.archiveReasonTitle,
      cancelLabel: l10n.cancel,
      actions: [
        for (final e in reasons.entries)
          SheetAction(
            label: e.value,
            onPressed: () async {
              await ref.read(plantRepositoryProvider).archive([id], reason: e.key);
              Haptics.warning();
              ref.read(analyticsProvider).track(AnalyticsEvents.plantArchived, {'reason': e.key});
              ref.read(toastProvider.notifier).show(ToastData(
                message: l10n.plantArchived(plant.name),
                emoji: '🗂',
                undoLabel: l10n.undo,
                onUndo: () => ref.read(plantRepositoryProvider).restore([id]),
              ));
              if (mounted) context.pop();
            },
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final summary = ref.watch(plantSummaryProvider(id)).value;
    if (summary == null) {
      return Scaffold(backgroundColor: c.canvas, body: const Center(child: AdaptiveProgress()));
    }
    final plant = summary.plant;
    final photos = ref.watch(plantPhotosProvider(id)).value ?? const <PlantPhoto>[];
    final primary = photos.where((p) => p.id == plant.primaryPhotoId).firstOrNull ?? photos.firstOrNull;
    final top = MediaQuery.paddingOf(context).top;
    final width = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: c.canvas,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverAppBar(
            expandedHeight: primary == null ? width * 0.62 : width * 1.05,
            pinned: true,
            stretch: true,
            backgroundColor: c.canvas,
            surfaceTintColor: Colors.transparent,
            automaticallyImplyLeading: false,
            leadingWidth: 64,
            leading: Padding(
              padding: const EdgeInsets.only(left: Space.sm),
              child: Center(child: FloraIconButton(icon: isCupertino(context) ? CupertinoIcons.chevron_left : Icons.arrow_back_rounded, semanticLabel: l10n.back, onPressed: () => context.pop())),
            ),
            actions: [
              FloraIconButton(icon: plant.isFavorite ? CupertinoIcons.heart_fill : CupertinoIcons.heart, color: plant.isFavorite ? c.rose : null, semanticLabel: l10n.favorite, onPressed: () => _toggleFavorite(plant)),
              const SizedBox(width: Space.xs),
              FloraIconButton(icon: CupertinoIcons.ellipsis, semanticLabel: l10n.more, onPressed: () => _menu(plant)),
              const SizedBox(width: Space.sm),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Pressable(
                onTap: primary == null ? _addPhoto : () => context.push(Routes.plantGallery(id)),
                scale: 1,
                haptic: false,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PlantImage(relativePath: primary?.filePath ?? summary.thumbPath, cacheWidth: 1200, heroTag: 'plant-$id', placeholderEmoji: '🪴'),
                    if (primary == null)
                      Align(
                        alignment: const Alignment(0, 0.55),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.xs),
                          decoration: BoxDecoration(color: c.surface.withValues(alpha: 0.9), borderRadius: Radii.fullAll),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(CupertinoIcons.camera_fill, size: 16, color: c.sage),
                              const SizedBox(width: 6),
                              Text(l10n.addPhoto, style: context.text.caption.copyWith(color: c.sage, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [c.canvas.withValues(alpha: 0), c.canvas.withValues(alpha: 0), c.canvas], stops: const [0, 0.7, 1]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            toolbarHeight: 56,
            collapsedHeight: 56 + (top > 0 ? 0 : 0),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plant.name, style: context.text.title1),
                  if (plant.speciesName != null) ...[
                    const SizedBox(height: 2),
                    Pressable(
                      onTap: () => showSpeciesSheet(context, scientificName: plant.speciesName!),
                      scale: 0.98,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(child: Text(plant.speciesName!, style: context.text.callout.copyWith(fontStyle: FontStyle.italic, color: c.sage), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          const SizedBox(width: 4),
                          Icon(CupertinoIcons.info_circle, size: 14, color: c.sage),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (summary.locationName != null) summary.locationName!,
                      if (plant.acquiredAt != null) l10n.sinceDate(Dates.monthYear(context, plant.acquiredAt!)),
                    ].join(' · '),
                    style: context.text.caption,
                  ),
                  if (summary.tags.isNotEmpty || plant.health != PlantHealth.healthy) ...[
                    const SizedBox(height: Space.sm),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (plant.health != PlantHealth.healthy)
                          DueBadge(emoji: plant.health == PlantHealth.sick ? '🤒' : '👀', label: l10n.healthName(plant.health), status: plant.health == PlantHealth.sick ? DueStatus.overdue : DueStatus.today, compact: true),
                        for (final t in summary.tags) DueBadge(emoji: '🏷️', label: t, status: DueStatus.upcoming, compact: true),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          _NextCare(plantId: id, plantName: plant.name),
          _QuickActions(onTap: (key) => _quick(key, plant.name), justDone: _justDone),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Space.page, Space.lg, Space.page, 0),
              child: FloraButton(label: l10n.addAction, icon: CupertinoIcons.plus, expand: true, onPressed: () => showAddActionSheet(context, plantId: id, plantName: plant.name)),
            ),
          ),
          _CareGuideCard(plantId: id, speciesName: plant.speciesName),
          _PlantTasks(plantId: id),
          _RecentHistory(plantId: id),
          _Growth(plantId: id, photos: photos, onAdd: _addPhoto),
          MeasurementsSection(plantId: id, plantName: plant.name),
          _Info(summary: summary),
          _Cuttings(plantId: id, plant: plant),
          const SliverPadding(padding: EdgeInsets.only(bottom: Space.huge)),
        ],
      ),
    );
  }
}

class _NextCare extends ConsumerStatefulWidget {
  const _NextCare({required this.plantId, required this.plantName});

  final String plantId;
  final String plantName;

  @override
  ConsumerState<_NextCare> createState() => _NextCareState();
}

class _NextCareState extends ConsumerState<_NextCare> {
  final Set<String> _done = {};

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final now = DateTime.now();
    final schedules = (ref.watch(plantSchedulesProvider(widget.plantId)).value ?? const <CareSchedule>[]).where((s) => s.enabled && s.nextDueAt != null).toList();
    final types = ref.watch(actionTypeByKeyProvider);
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: l10n.nextCare, actionLabel: l10n.schedule, onAction: () => context.push(Routes.plantSchedule(widget.plantId))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.page),
            child: schedules.isEmpty
                ? FloraCard(
                    child: FloraListRow(
                      leading: const Text('⏰', style: TextStyle(fontSize: 18)),
                      title: l10n.noSchedule,
                      subtitle: l10n.addRoutine,
                      onTap: () => context.push(Routes.plantSchedule(widget.plantId)),
                    ),
                  )
                : FloraCard(
                    padding: const EdgeInsets.symmetric(vertical: Space.xxs),
                    child: Column(
                      children: [
                        for (final (i, s) in schedules.indexed) ...[
                          if (i > 0) Divider(height: 1, thickness: 0.5, indent: 64, color: c.line),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: Space.xs),
                            child: Row(
                              children: [
                                EmojiTile(emoji: types[s.typeKey]?.emoji ?? '✓', background: c.softFor(s.typeKey)),
                                const SizedBox(width: Space.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(l10n.kindName(s.typeKey, custom: types[s.typeKey]), style: context.text.title3),
                                      Text(
                                        l10n.dueLabel(s.nextDueAt, now),
                                        style: context.text.caption.copyWith(
                                          color: switch (CareEngine.status(s.nextDueAt, now)) { DueStatus.overdue => c.terracotta, DueStatus.today => c.water, _ => c.inkSecondary },
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                CompletableButton(
                                  label: l10n.kindVerb(s.typeKey, custom: types[s.typeKey]),
                                  doneLabel: l10n.kindDone(s.typeKey, custom: types[s.typeKey]),
                                  done: _done.contains(s.id),
                                  compact: true,
                                  color: c.strongFor(s.typeKey),
                                  onPressed: () async {
                                    setState(() => _done.add(s.id));
                                    await ref.read(careActionsProvider).logQuick(context, plantId: widget.plantId, plantName: widget.plantName, typeKey: s.typeKey);
                                    await Future<void>.delayed(const Duration(milliseconds: 1400));
                                    if (mounted) setState(() => _done.remove(s.id));
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Accès à la fiche d'entretien, avec le repère d'arrosage du moment.
class _CareGuideCard extends ConsumerWidget {
  const _CareGuideCard({required this.plantId, required this.speciesName});

  final String plantId;
  final String? speciesName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final care = ref.watch(careGuideProvider).resolve(speciesName);
    final days = care.profile.wateringDaysFor(DateTime.now().month);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.page, Space.lg, Space.page, 0),
        child: FloraCard(
          onTap: () => context.push(Routes.plantCare(plantId)),
          padding: const EdgeInsets.all(Space.md),
          child: Row(
            children: [
              EmojiTile(emoji: '📖', size: 44, background: c.sageSoft),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.careHowTo, style: context.text.title3),
                    const SizedBox(height: 2),
                    Text(l10n.careWateringNow(days), style: context.text.caption),
                  ],
                ),
              ),
              Icon(CupertinoIcons.chevron_right, size: 16, color: c.inkTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tâches libres liées à cette plante.
class _PlantTasks extends ConsumerWidget {
  const _PlantTasks({required this.plantId});

  final String plantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final tasks = ref.watch(plantTasksProvider(plantId)).value ?? const <FreeTask>[];
    final open = tasks.where((t) => !t.done).toList();
    if (open.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: l10n.tasks, actionLabel: l10n.add, onAction: () => showTaskSheet(context, plantId: plantId)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.page),
            child: FloraGroup(children: [for (final t in open) TaskRow(key: ValueKey(t.id), task: t, showPlant: false, dense: true)]),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends ConsumerWidget {
  const _QuickActions({required this.onTap, required this.justDone});

  final ValueChanged<String> onTap;
  final Set<String> justDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final types = ref.watch(actionTypesProvider).value ?? const <ActionType>[];
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: Space.lg),
        child: SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Space.page),
            itemCount: types.length,
            separatorBuilder: (_, _) => const SizedBox(width: Space.xxs),
            itemBuilder: (context, i) {
              final t = types[i];
              final done = justDone.contains(t.key);
              return QuickActionChip(
                emoji: done ? '✓' : t.emoji,
                label: done ? l10n.kindDone(t.key, custom: t) : l10n.kindName(t.key, custom: t),
                background: done ? c.sageSoft : c.softFor(t.key),
                onTap: () => onTap(t.key),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RecentHistory extends ConsumerWidget {
  const _RecentHistory({required this.plantId});

  final String plantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final actions = ref.watch(plantActionsProvider(plantId)).value ?? const <PlantAction>[];
    final photos = {for (final p in ref.watch(plantPhotosProvider(plantId)).value ?? const <PlantPhoto>[]) p.id: p};
    final recent = actions.take(5).toList();
    final groups = groupByDay(context, recent);
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: l10n.history, actionLabel: actions.length > 5 ? l10n.seeFullHistory : null, onAction: () => context.push(Routes.plantTimeline(plantId))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.page),
            child: recent.isEmpty
                ? FloraCard(child: EmptyState(emoji: '📖', title: l10n.noHistoryTitle, subtitle: l10n.noHistorySubtitle, compact: true))
                : FloraCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final (gi, g) in groups.indexed) ...[
                          TimelineDayLabel(g.$1),
                          for (final (i, a) in g.$2.indexed)
                            TimelineRow(
                              action: a,
                              photo: a.photoId == null ? null : photos[a.photoId],
                              isLast: gi == groups.length - 1 && i == g.$2.length - 1,
                              onPhotoTap: () => context.push(Routes.plantGallery(plantId)),
                            ),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Growth extends StatelessWidget {
  const _Growth({required this.plantId, required this.photos, required this.onAdd});

  final String plantId;
  final List<PlantPhoto> photos;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: l10n.growth, actionLabel: photos.isEmpty ? null : l10n.seeAll, onAction: () => context.push(Routes.plantGallery(plantId))),
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: Space.page),
              children: [
                Pressable(
                  onTap: onAdd,
                  scale: 0.95,
                  semanticLabel: l10n.addPhoto,
                  child: Container(
                    width: 92,
                    margin: const EdgeInsets.only(right: Space.xs),
                    decoration: BoxDecoration(color: c.sageSoft, borderRadius: Radii.mediumAll),
                    child: Icon(CupertinoIcons.camera_fill, color: c.sage),
                  ),
                ),
                for (final p in photos.take(10))
                  Pressable(
                    onTap: () => context.push(Routes.plantGallery(plantId)),
                    scale: 0.96,
                    child: Container(
                      width: 92,
                      margin: const EdgeInsets.only(right: Space.xs),
                      clipBehavior: Clip.antiAlias,
                      decoration: const BoxDecoration(borderRadius: Radii.mediumAll),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          PlantImage(relativePath: p.thumbPath, cacheWidth: 300),
                          Positioned(
                            left: 6,
                            bottom: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: c.ink.withValues(alpha: 0.55), borderRadius: Radii.fullAll),
                              child: Text(Dates.day(context, p.takenAt), style: context.text.caption.copyWith(color: Colors.white, fontSize: 11)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Info extends ConsumerWidget {
  const _Info({required this.summary});

  final PlantSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final p = summary.plant;
    final metric = ref.watch(preferencesProvider).metricUnits;
    final rows = <(String, String)>[
      if (p.speciesName != null) (l10n.speciesHint.split(' ').first, p.speciesName!),
      (l10n.filterLocation, summary.locationName ?? l10n.noLocation),
      (l10n.health, l10n.healthName(p.health)),
      if (p.acquiredAt != null) (l10n.acquiredAt, Dates.dayYear(context, p.acquiredAt!)),
      if (p.source != null) (l10n.source, p.source!),
      if (p.price != null) (l10n.price, p.price!.toStringAsFixed(p.price! == p.price!.roundToDouble() ? 0 : 2)),
      if (p.potSize != null) (l10n.potSize, '${p.potSize!.toStringAsFixed(0)} ${metric ? 'cm' : 'in'}'),
    ];
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: l10n.info, actionLabel: l10n.edit, onAction: () => showEditPlantSheet(context, plant: p)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.page),
            child: FloraGroup(
              children: [
                for (final (label, value) in rows)
                  FloraListRow(title: label, trailing: Text(value, style: context.text.callout, textAlign: TextAlign.end, maxLines: 2, overflow: TextOverflow.ellipsis), dense: true),
                if (p.notes != null)
                  Padding(
                    padding: const EdgeInsets.all(Space.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [Text(l10n.notes, style: context.text.caption), const SizedBox(height: 4), Text(p.notes!, style: context.text.body)],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Cuttings extends ConsumerWidget {
  const _Cuttings({required this.plantId, required this.plant});

  final String plantId;
  final Plant plant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final children = ref.watch(plantChildrenProvider(plantId)).value ?? const <PlantSummary>[];
    final parent = plant.parentPlantId == null ? null : ref.watch(plantSummaryProvider(plant.parentPlantId!)).value;
    if (children.isEmpty && parent == null) return const SliverToBoxAdapter(child: SizedBox.shrink());
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: l10n.cuttings, actionLabel: l10n.createCutting, onAction: () => startCreatePlantFlow(context, ref, parentPlantId: plantId, parentName: plant.name, locationId: plant.locationId)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.page),
            child: FloraGroup(
              children: [
                if (parent != null)
                  FloraListRow(
                    leading: ClipRRect(borderRadius: BorderRadius.circular(10), child: SizedBox(width: 32, height: 32, child: PlantImage(relativePath: parent.thumbPath, cacheWidth: 96))),
                    title: parent.plant.name,
                    subtitle: l10n.parentPlant,
                    onTap: () => context.push(Routes.plant(parent.plant.id)),
                  ),
                for (final child in children)
                  FloraListRow(
                    leading: ClipRRect(borderRadius: BorderRadius.circular(10), child: SizedBox(width: 32, height: 32, child: PlantImage(relativePath: child.thumbPath, cacheWidth: 96))),
                    title: child.plant.name,
                    subtitle: child.locationName,
                    onTap: () => context.push(Routes.plant(child.plant.id)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
