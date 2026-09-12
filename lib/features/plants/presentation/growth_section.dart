import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models/models.dart';
import 'photo_viewer.dart';

/// La section Croissance de la fiche : ce que la plante est devenue, en
/// photos, et le geste pour en ajouter une.
///
/// Sans photo, une carte qui explique à quoi ça sert, pas une bande vide
/// avec une icône. Avec, la bande des dernières photos — chacune s'ouvre en
/// grand d'un toucher, là où elle menait avant à une grille — suivie d'une
/// ligne qui compte : combien, depuis quand. Et quand la dernière date, une
/// relance : c'est en prenant des photos régulièrement qu'on voit pousser.
class GrowthSection extends StatelessWidget {
  const GrowthSection({super.key, required this.plantId, required this.photos, required this.primaryId, required this.onAdd});

  final String plantId;

  /// De la plus récente à la plus ancienne.
  final List<PlantPhoto> photos;
  final String? primaryId;
  final VoidCallback onAdd;

  /// Au-delà, la section rappelle qu'une nouvelle photo aiderait.
  static const Duration staleAfter = Duration(days: 30);

  /// Le nom du héros dans cette bande. Le journal de la même fiche montre
  /// parfois la même photo sous son nom ordinaire ; les deux ne doivent pas
  /// se confondre.
  static String heroTag(PlantPhoto photo) => 'growth-${photo.id}';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: l10n.growth, actionLabel: photos.isEmpty ? null : l10n.seeAll, onAction: () => context.push(Routes.plantGallery(plantId))),
          if (photos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.page),
              child: FloraCard(
                onTap: onAdd,
                child: Row(
                  children: [
                    EmojiTile(emoji: '📷', size: 44, background: c.sageSoft),
                    const SizedBox(width: Space.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.photoFirstTitle, style: context.text.title3),
                          const SizedBox(height: 2),
                          Text(l10n.growthEmptySubtitle, style: context.text.caption),
                        ],
                      ),
                    ),
                    const SizedBox(width: Space.xs),
                    Icon(CupertinoIcons.chevron_right, size: 16, color: c.inkTertiary),
                  ],
                ),
              ),
            )
          else ...[
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: Space.page),
                children: [
                  _AddTile(onTap: onAdd),
                  for (final p in photos.take(10))
                    _Thumb(
                      photo: p,
                      isPrimary: p.id == primaryId,
                      onTap: () => showPhotoViewer(context, plantId: plantId, photoId: p.id, photos: photos, primaryId: primaryId, heroTag: heroTag),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.page, Space.sm, Space.page, 0),
              child: _Summary(photos: photos, onAdd: onAdd),
            ),
          ],
        ],
      ),
    );
  }
}

/// « 12 photos · depuis mars 2024 », et la relance quand la dernière date.
class _Summary extends StatelessWidget {
  const _Summary({required this.photos, required this.onAdd});

  final List<PlantPhoto> photos;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final latest = photos.first.takenAt;
    final oldest = photos.last.takenAt;
    final stale = DateTime.now().difference(latest) > GrowthSection.staleAfter;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.growthSummary(photos.length, Dates.monthYear(context, oldest)), style: context.text.caption),
        if (stale) ...[
          const SizedBox(height: Space.xxs),
          Pressable(
            onTap: onAdd,
            scale: 0.98,
            child: Row(
              children: [
                Icon(CupertinoIcons.camera_fill, size: 14, color: c.sage),
                const SizedBox(width: 6),
                Flexible(child: Text(l10n.growthNudge(Dates.dayYear(context, latest)), style: context.text.caption.copyWith(color: c.sage, fontWeight: FontWeight.w600))),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// La première case de la bande : le déclencheur, qui dit son nom.
class _AddTile extends StatelessWidget {
  const _AddTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: onTap,
      scale: 0.95,
      semanticLabel: context.l10n.addPhoto,
      child: Container(
        width: 92,
        margin: const EdgeInsets.only(right: Space.xs),
        decoration: BoxDecoration(color: c.sageSoft, borderRadius: Radii.mediumAll),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.camera_fill, color: c.sage),
            const SizedBox(height: Space.xs),
            Text(context.l10n.add, style: context.text.caption.copyWith(color: c.sage, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.photo, required this.isPrimary, required this.onTap});

  final PlantPhoto photo;
  final bool isPrimary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: onTap,
      scale: 0.96,
      child: Container(
        width: 92,
        margin: const EdgeInsets.only(right: Space.xs),
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(borderRadius: Radii.mediumAll),
        child: Stack(
          fit: StackFit.expand,
          children: [
            PlantImage(relativePath: photo.thumbPath, remoteUrl: photo.remoteUrl, cacheWidth: 300, heroTag: GrowthSection.heroTag(photo), heroRadius: Radii.mediumAll),
            if (isPrimary) const Positioned(top: 6, left: 6, child: PrimaryPhotoBadge()),
            Positioned(
              left: 6,
              right: 6,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: c.ink.withValues(alpha: 0.55), borderRadius: Radii.fullAll),
                child: Text(
                  photo.label ?? Dates.day(context, photo.takenAt),
                  style: context.text.caption.copyWith(color: Colors.white, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// L'étoile de la photo principale, sur une pastille claire.
class PrimaryPhotoBadge extends StatelessWidget {
  const PrimaryPhotoBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      label: context.l10n.setAsMainPhoto,
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(color: c.surface.withValues(alpha: 0.9), shape: BoxShape.circle),
        child: Icon(CupertinoIcons.star_fill, size: 12, color: c.sun),
      ),
    );
  }
}
