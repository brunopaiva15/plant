import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models/models.dart';

/// Avant / après : deux photos superposées, un curseur pour révéler.
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
    await showAdaptiveActionSheet(
      context,
      title: before ? l10n.before : l10n.after,
      cancelLabel: l10n.cancel,
      actions: [
        for (final p in widget.photos)
          SheetAction(label: Dates.dayYear(context, p.takenAt), onPressed: () => setState(() => before ? _before = p : _after = p)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    return FloraPage(
      title: l10n.compare,
      scrollable: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.page, Space.md, Space.page, Space.md),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _Picker(label: l10n.before, date: Dates.day(context, _before.takenAt), onTap: () => _pick(true))),
                const SizedBox(width: Space.xs),
                Expanded(child: _Picker(label: l10n.after, date: Dates.day(context, _after.takenAt), onTap: () => _pick(false))),
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
                        PlantImage(relativePath: _after.filePath, cacheWidth: 1200),
                        ClipRect(
                          clipper: _LeftClipper(_split),
                          child: PlantImage(relativePath: _before.filePath, cacheWidth: 1200),
                        ),
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

class _Picker extends StatelessWidget {
  const _Picker({required this.label, required this.date, required this.onTap});

  final String label;
  final String date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FloraCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Text(label, style: context.text.caption), Text(date, style: context.text.title3)],
            ),
          ),
          Icon(CupertinoIcons.chevron_down, size: 16, color: context.colors.inkTertiary),
        ],
      ),
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
