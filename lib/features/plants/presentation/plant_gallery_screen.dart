import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models/models.dart';
import '../application/plant_providers.dart';
import 'compare_screen.dart';
import 'growth_section.dart';
import 'photo_capture_flow.dart';
import 'photo_viewer.dart';
import 'timelapse_screen.dart';

/// Croissance : toutes les photos de la plante, et ce qu'on peut en faire.
///
/// En haut, les deux outils, nommés — le timelapse et l'avant / après —
/// plutôt que deux icônes muettes dans la barre. Puis combien, depuis quand.
/// Puis les photos, mois par mois, chacune avec son titre quand elle en a
/// un. Et le geste principal, prendre une photo, posé en bas où le pouce
/// l'attend.
class PlantGalleryScreen extends ConsumerWidget {
  const PlantGalleryScreen({super.key, required this.plantId});

  final String plantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
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
    void add() => showPhotoCaptureFlow(context, ref, plantId: plantId);
    return FloraPage(
      title: l10n.growth,
      bottom: photos.isEmpty
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(Space.page, Space.xs, Space.page, Space.sm),
                child: FloraButton(label: l10n.takePhoto, icon: CupertinoIcons.camera_fill, expand: true, onPressed: add),
              ),
            ),
      child: photos.isEmpty
          ? EmptyState(emoji: '📷', title: l10n.photoFirstTitle, subtitle: l10n.growthEmptySubtitle, actionLabel: l10n.takePhoto, onAction: add)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (photos.length >= 2) ...[
                  Row(
                    children: [
                      Expanded(
                        child: FloraActionTile(
                          icon: CupertinoIcons.play_fill,
                          label: l10n.timelapse,
                          tint: c.water,
                          onTap: () => showTimelapse(context, photos),
                        ),
                      ),
                      const SizedBox(width: Space.sm),
                      Expanded(
                        child: FloraActionTile(
                          icon: CupertinoIcons.rectangle_split_3x1,
                          label: l10n.beforeAfter,
                          tint: c.terracotta,
                          onTap: () => Navigator.of(context).push(
                            isCupertino(context) ? CupertinoPageRoute<void>(builder: (_) => CompareScreen(photos: photos)) : MaterialPageRoute<void>(builder: (_) => CompareScreen(photos: photos)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Space.md),
                ],
                Text(l10n.growthSummary(photos.length, Dates.monthYear(context, photos.last.takenAt)), style: context.text.caption),
                const SizedBox(height: Space.sm),
                for (final (label, items) in groups) ...[
                  _MonthLabel(label),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    // Une grille imbriquée sans marge explicite reprend
                    // celles de l'écran : un vide au-dessus de chaque mois.
                    padding: EdgeInsets.zero,
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 140, mainAxisSpacing: 6, crossAxisSpacing: 6, childAspectRatio: 0.8),
                    itemCount: items.length,
                    itemBuilder: (context, i) => _Tile(
                      photo: items[i],
                      isPrimary: plant?.primaryPhotoId == items[i].id,
                      onTap: () => showPhotoViewer(context, plantId: plantId, photoId: items[i].id, photos: photos, primaryId: plant?.primaryPhotoId),
                    ),
                  ),
                  const SizedBox(height: Space.lg),
                ],
              ],
            ),
    );
  }
}

class _MonthLabel extends StatelessWidget {
  const _MonthLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final s = label[0].toUpperCase() + label.substring(1);
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm, top: Space.xs),
      child: Semantics(header: true, child: Text(s, style: context.text.title3)),
    );
  }
}

/// Une vignette de la grille : l'étoile si c'est la principale, le titre
/// s'il y en a un.
class _Tile extends StatelessWidget {
  const _Tile({required this.photo, required this.isPrimary, required this.onTap});

  final PlantPhoto photo;
  final bool isPrimary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: onTap,
      scale: 0.96,
      semanticLabel: photo.label ?? Dates.dayYear(context, photo.takenAt),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: Radii.mediumAll,
            child: PlantImage(relativePath: photo.thumbPath, remoteUrl: photo.remoteUrl, cacheWidth: 400, heroTag: defaultPhotoHeroTag(photo), heroRadius: Radii.mediumAll),
          ),
          if (isPrimary) const Positioned(top: 6, left: 6, child: PrimaryPhotoBadge()),
          if (photo.label != null)
            Positioned(
              left: 6,
              right: 6,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: c.ink.withValues(alpha: 0.55), borderRadius: Radii.fullAll),
                child: Text(
                  photo.label!,
                  style: context.text.caption.copyWith(color: Colors.white, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
