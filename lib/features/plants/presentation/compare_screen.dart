import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models/models.dart';
import 'photo_picker_sheet.dart';

/// Avant / après : deux photos superposées, un curseur pour révéler.
///
/// Les deux photos se choisissent en les voyant — une grille de vignettes
/// datées —, et chaque carte montre celle qu'elle tient. Un geste inverse
/// les deux, parce que « avant » et « après » se trompent facilement de
/// côté.
class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key, required this.photos});

  /// Photos de la plante, de la plus récente à la plus ancienne.
  final List<PlantPhoto> photos;

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  late PlantPhoto _before = widget.photos.last;
  late PlantPhoto _after = widget.photos.first;
  double _split = 0.5;

  Future<void> _pick(bool before) async {
    final l10n = context.l10n;
    final picked = await showPhotoPickerSheet(
      context,
      title: before ? l10n.before : l10n.after,
      photos: widget.photos,
      selectedId: before ? _before.id : _after.id,
    );
    if (picked == null || !mounted) return;
    setState(() => before ? _before = picked : _after = picked);
  }

  void _swap() {
    Haptics.selection();
    setState(() {
      final b = _before;
      _before = _after;
      _after = b;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    return FloraPage(
      title: l10n.compare,
      scrollable: false,
      trailing: FloraIconButton(icon: CupertinoIcons.arrow_right_arrow_left, semanticLabel: l10n.swap, onPressed: _swap),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.page, Space.md, Space.page, Space.md),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _Picker(label: l10n.before, photo: _before, onTap: () => _pick(true))),
                const SizedBox(width: Space.xs),
                Expanded(child: _Picker(label: l10n.after, photo: _after, onTap: () => _pick(false))),
              ],
            ),
            const SizedBox(height: Space.md),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => GestureDetector(
                  onHorizontalDragUpdate: (d) => setState(() => _split = (_split + d.delta.dx / constraints.maxWidth).clamp(0.05, 0.95)),
                  child: ClipRRect(
                    borderRadius: Radii.xlAll,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        PlantImage(relativePath: _after.filePath, remoteUrl: _after.remoteUrl, cacheWidth: 1200),
                        ClipRect(
                          clipper: _LeftClipper(_split),
                          child: PlantImage(relativePath: _before.filePath, remoteUrl: _before.remoteUrl, cacheWidth: 1200),
                        ),
                        // Les deux dates sur l'image même : on sait toujours
                        // de quel côté est quoi, sans lever les yeux.
                        Positioned(left: Space.sm, top: Space.sm, child: _DateTag(Dates.day(context, _before.takenAt))),
                        Positioned(right: Space.sm, top: Space.sm, child: _DateTag(Dates.day(context, _after.takenAt))),
                        Positioned(
                          left: constraints.maxWidth * _split - 1,
                          top: 0,
                          bottom: 0,
                          child: Container(width: 2, color: Colors.white),
                        ),
                        Positioned(
                          left: constraints.maxWidth * _split - 18,
                          top: constraints.maxHeight / 2 - 18,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: Shadows.soft(const Color(0x33000000))),
                            child: Icon(CupertinoIcons.arrow_left_right, size: 18, color: c.ink),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: Space.sm),
            Text(l10n.compareHint, style: context.text.caption),
          ],
        ),
      ),
    );
  }
}

/// La carte d'un côté : sa vignette, son rôle, sa date. Toucher change la
/// photo.
class _Picker extends StatelessWidget {
  const _Picker({required this.label, required this.photo, required this.onTap});

  final String label;
  final PlantPhoto photo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FloraCard(
      onTap: onTap,
      padding: const EdgeInsets.all(Space.xs),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: Radii.smallAll,
            child: SizedBox(width: 44, height: 44, child: PlantImage(relativePath: photo.thumbPath, remoteUrl: photo.remoteUrl, cacheWidth: 132)),
          ),
          const SizedBox(width: Space.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: context.text.caption),
                Text(Dates.day(context, photo.takenAt), style: context.text.title3, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Icon(CupertinoIcons.chevron_down, size: 16, color: context.colors.inkTertiary),
        ],
      ),
    );
  }
}

class _DateTag extends StatelessWidget {
  const _DateTag(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Space.xs, vertical: 3),
      decoration: BoxDecoration(color: const Color(0x8C000000), borderRadius: Radii.fullAll),
      child: Text(text, style: context.text.caption.copyWith(color: Colors.white)),
    );
  }
}

class _LeftClipper extends CustomClipper<Rect> {
  _LeftClipper(this.fraction);

  final double fraction;

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width * fraction, size.height);

  @override
  bool shouldReclip(_LeftClipper old) => old.fraction != fraction;
}
