import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../data/services/photo_storage_service.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models/models.dart';
import '../../actions/application/care_actions.dart';
import '../application/plant_providers.dart';
import 'compare_screen.dart';
import 'timelapse_screen.dart';

/// Croissance : toutes les photos, groupées par mois, plein écran au tap.
class PlantGalleryScreen extends ConsumerWidget {
  const PlantGalleryScreen({super.key, required this.plantId});

  final String plantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final photos = ref.watch(plantPhotosProvider(plantId)).value ?? const <PlantPhoto>[];
    final plant = ref.watch(plantSummaryProvider(plantId)).value?.plant;
    final groups = <(String, List<PlantPhoto>)>[];
    for (final p in photos) {
      final label = Dates.monthYear(context, p.takenAt);
      if (groups.isNotEmpty && groups.last.$1 == label) {
        groups.last.$2.add(p);
      } else {
        groups.add((label, [p]));
      }
    }
    return FloraPage(
      title: l10n.growth,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (photos.length >= 2) ...[
            FloraIconButton(
              icon: CupertinoIcons.play_fill,
              semanticLabel: l10n.play,
              onPressed: () => Navigator.of(context, rootNavigator: true).push(
                PageRouteBuilder(
                  opaque: false,
                  barrierColor: Colors.black,
                  transitionDuration: Motion.of(context, Motion.emphasis),
                  pageBuilder: (_, anim, _) => FadeTransition(opacity: anim, child: TimelapseScreen(photos: photos)),
                ),
              ),
            ),
            const SizedBox(width: Space.xs),
            FloraIconButton(
              icon: CupertinoIcons.rectangle_split_3x1,
              semanticLabel: l10n.compare,
              onPressed: () => Navigator.of(context).push(
                isCupertino(context)
                    ? CupertinoPageRoute<void>(builder: (_) => CompareScreen(photos: photos))
                    : MaterialPageRoute<void>(builder: (_) => CompareScreen(photos: photos)),
              ),
            ),
            const SizedBox(width: Space.xs),
          ],
          FloraIconButton(
        icon: CupertinoIcons.camera,
        semanticLabel: l10n.addPhoto,
        onPressed: () => showAdaptiveActionSheet(
          context,
          cancelLabel: l10n.cancel,
          actions: [
            SheetAction(label: l10n.camera, icon: CupertinoIcons.camera, onPressed: () => ref.read(careActionsProvider).addPhoto(context, plantId: plantId, source: PhotoSource.camera)),
            SheetAction(label: l10n.gallery, icon: CupertinoIcons.photo, onPressed: () => ref.read(careActionsProvider).addPhoto(context, plantId: plantId, source: PhotoSource.gallery)),
          ],
        ),
          ),
        ],
      ),
      child: photos.isEmpty
          ? EmptyState(emoji: '📷', title: l10n.noPhotosTitle, subtitle: l10n.noPhotosSubtitle, compact: true)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (label, items) in groups) ...[
                  TimelineDayLabelLike(label),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 6, crossAxisSpacing: 6, childAspectRatio: 0.8),
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final p = items[i];
                      final isPrimary = plant?.primaryPhotoId == p.id;
                      return Pressable(
                        onTap: () => _openViewer(context, ref, photos, photos.indexOf(p), plant),
                        scale: 0.96,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(borderRadius: Radii.mediumAll, child: PlantImage(relativePath: p.thumbPath, cacheWidth: 400, heroTag: 'photo-${p.id}')),
                            if (isPrimary)
                              Positioned(
                                top: 6,
                                left: 6,
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(color: context.colors.surface.withValues(alpha: 0.9), shape: BoxShape.circle),
                                  child: Icon(CupertinoIcons.star_fill, size: 12, color: context.colors.sun),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: Space.lg),
                ],
              ],
            ),
    );
  }

  void _openViewer(BuildContext context, WidgetRef ref, List<PlantPhoto> photos, int index, Plant? plant) {
    Haptics.light();
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        transitionDuration: Motion.of(context, Motion.emphasis),
        reverseTransitionDuration: Motion.of(context, Motion.standard),
        pageBuilder: (_, anim, _) => FadeTransition(opacity: anim, child: _PhotoViewer(photos: photos, index: index, plantId: plantId, primaryId: plant?.primaryPhotoId)),
      ),
    );
  }
}

class TimelineDayLabelLike extends StatelessWidget {
  const TimelineDayLabelLike(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final s = label[0].toUpperCase() + label.substring(1);
    return Padding(padding: const EdgeInsets.only(bottom: Space.sm, top: Space.xs), child: Text(s, style: context.text.title3));
  }
}

class _PhotoViewer extends ConsumerStatefulWidget {
  const _PhotoViewer({required this.photos, required this.index, required this.plantId, required this.primaryId});

  final List<PlantPhoto> photos;
  final int index;
  final String plantId;
  final String? primaryId;

  @override
  ConsumerState<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends ConsumerState<_PhotoViewer> {
  late final _controller = PageController(initialPage: widget.index);
  late int _index = widget.index;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _menu() async {
    final l10n = context.l10n;
    final photo = widget.photos[_index];
    await showAdaptiveActionSheet(
      context,
      cancelLabel: l10n.cancel,
      actions: [
        if (widget.primaryId != photo.id)
          SheetAction(
            label: l10n.setAsPrimary,
            icon: CupertinoIcons.star,
            onPressed: () async {
              await ref.read(photoRepositoryProvider).setPrimary(widget.plantId, photo.id);
              Haptics.success();
              if (mounted) Navigator.of(context).pop();
            },
          ),
        SheetAction(
          label: l10n.deletePhoto,
          icon: CupertinoIcons.trash,
          destructive: true,
          onPressed: () async {
            final ok = await showAdaptiveConfirm(context, title: l10n.deletePhoto, confirmLabel: l10n.delete, cancelLabel: l10n.cancel, destructive: true);
            if (!ok) return;
            await ref.read(photoRepositoryProvider).delete(photo.id);
            await ref.read(photoStorageProvider).deleteFiles(photo.filePath, photo.thumbPath);
            Haptics.warning();
            if (mounted) Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final storage = ref.watch(photoStorageProvider);
    final photo = widget.photos[_index];
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.photos.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              final p = widget.photos[i];
              return GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Center(
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: Hero(
                      tag: 'photo-${p.id}',
                      child: FutureBuilder<String>(
                        future: storage.absolutePath(p.filePath),
                        builder: (context, snap) => snap.hasData ? Image.file(File(snap.data!), fit: BoxFit.contain) : const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(Space.sm),
              child: Row(
                children: [
                  FloraIconButton(icon: CupertinoIcons.xmark, semanticLabel: context.l10n.close, onPressed: () => Navigator.of(context).pop(), background: Colors.white24, color: Colors.white),
                  const Spacer(),
                  Text(Dates.dayYear(context, photo.takenAt), style: context.text.callout.copyWith(color: Colors.white)),
                  const Spacer(),
                  FloraIconButton(icon: CupertinoIcons.ellipsis, semanticLabel: context.l10n.more, onPressed: _menu, background: Colors.white24, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
