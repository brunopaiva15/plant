import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models/models.dart';

/// Choisir une photo parmi celles de la plante : une grille de vignettes
/// datées, la photo retenue entourée de vert. Retourne la photo touchée, ou
/// `null` si la sheet se referme sans choix.
///
/// Avant, l'avant / après proposait une feuille d'action système avec une
/// date par ligne — trente lignes pour trente photos, et rien à voir. On
/// choisit une photo en la regardant.
Future<PlantPhoto?> showPhotoPickerSheet(BuildContext context, {required String title, required List<PlantPhoto> photos, String? selectedId}) =>
    showFloraSheet<PlantPhoto>(
      context,
      scrollable: true,
      builder: (_) => _PickerBody(title: title, photos: photos, selectedId: selectedId),
    );

class _PickerBody extends StatelessWidget {
  const _PickerBody({required this.title, required this.photos, this.selectedId});

  final String title;
  final List<PlantPhoto> photos;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(title: title),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: Space.xs, crossAxisSpacing: Space.xs, childAspectRatio: 0.8),
            itemCount: photos.length,
            itemBuilder: (context, i) {
              final p = photos[i];
              final selected = p.id == selectedId;
              return Pressable(
                onTap: () => Navigator.of(context).pop(p),
                scale: 0.96,
                semanticLabel: Dates.dayYear(context, p.takenAt),
                child: AnimatedContainer(
                  duration: Motion.of(context, Motion.standard),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: Radii.mediumAll,
                    border: Border.all(color: selected ? c.sage : Colors.transparent, width: 3),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      PlantImage(relativePath: p.thumbPath, remoteUrl: p.remoteUrl, cacheWidth: 400),
                      Positioned(
                        left: 6,
                        right: 6,
                        bottom: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: c.ink.withValues(alpha: 0.55), borderRadius: Radii.fullAll),
                          child: Text(
                            Dates.day(context, p.takenAt),
                            style: context.text.caption.copyWith(color: Colors.white, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      if (selected)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(color: c.sage, shape: BoxShape.circle),
                            child: Icon(CupertinoIcons.checkmark, size: 12, color: c.onSage),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
