import 'package:flutter/material.dart';

import '../../core/haptics.dart';
import '../theme/flora_theme.dart';
import '../tokens/motion.dart';
import '../tokens/radius.dart';
import '../tokens/spacing.dart';
import 'clay.dart';
import 'pressable.dart';

/// Chip sélectionnable en pilule (filtres, emplacements, types).
class FloraChip extends StatelessWidget {
  const FloraChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.emoji,
    this.icon,
    this.dashed = false,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final String? emoji;
  final IconData? icon;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: onTap == null
          ? null
          : () {
              Haptics.selection();
              onTap!();
            },
      haptic: false,
      scale: 0.95,
      semanticLabel: label,
      child: AnimatedContainer(
        duration: Motion.of(context, Motion.standard),
        curve: Motion.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.xs + 2),
        decoration: BoxDecoration(
          color: selected ? c.sage : c.surface,
          borderRadius: Radii.fullAll,
          border: Border.all(color: selected ? c.sage : c.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null) ...[Text(emoji!, style: const TextStyle(fontSize: 15)), const SizedBox(width: 6)],
            if (icon != null) ...[Icon(icon, size: 16, color: selected ? c.onSage : c.ink), const SizedBox(width: 6)],
            Flexible(
              child: Text(
                label,
                style: context.text.callout.copyWith(color: selected ? c.onSage : c.ink, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Action rapide : une tuile d'argile aux coins irréguliers, l'emoji dedans,
/// le libellé dessous. [variant] varie la forme d'une tuile à l'autre.
class QuickActionChip extends StatelessWidget {
  const QuickActionChip({super.key, required this.emoji, required this.label, required this.onTap, this.background, this.variant = 0});

  final String emoji;
  final String label;
  final VoidCallback onTap;
  final Color? background;
  final int variant;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: onTap,
      scale: 0.92,
      semanticLabel: label,
      child: SizedBox(
        width: 68,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClayBox(
              width: 56,
              height: 56,
              color: background ?? c.surface,
              shape: ClayShape.blob(variant),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 24, height: 1)),
            ),
            const SizedBox(height: Space.xs),
            Text(label, style: context.text.caption, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
