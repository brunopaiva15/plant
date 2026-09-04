import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/flora_theme.dart';
import '../tokens/spacing.dart';
import 'pressable.dart';

/// Ligne de liste : leading (emoji ou icône), titre, sous-titre, trailing.
class FloraListRow extends StatelessWidget {
  const FloraListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.chevron,
    this.destructive = false,
    this.dense = false,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool? chevron;
  final bool destructive;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final showChevron = chevron ?? (onTap != null && trailing == null);
    final row = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Space.md,
        vertical: dense ? Space.sm : Space.md,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => Row(
          children: [
            if (leading != null) ...[
              SizedBox(width: 32, child: Center(child: leading)),
              const SizedBox(width: Space.sm),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.text.body.copyWith(
                      color: destructive ? c.danger : c.ink,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: context.text.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: Space.sm),
              // Borné à la moitié de la ligne : le titre garde la priorité, sans
              // que le trailing ne partage l'espace libre (il reste calé à droite).
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth * 0.5,
                ),
                child: trailing!,
              ),
            ],
            if (showChevron) ...[
              const SizedBox(width: Space.xs),
              Icon(
                CupertinoIcons.chevron_right,
                size: 16,
                color: c.inkTertiary,
              ),
            ],
          ],
        ),
      ),
    );
    if (onTap == null) return row;
    return Pressable(
      onTap: onTap,
      scale: 1,
      child: ColoredBox(color: Colors.transparent, child: row),
    );
  }
}

/// Pastille d'emoji sur fond pastel, pour les leading de listes et cartes.
class EmojiTile extends StatelessWidget {
  const EmojiTile({
    super.key,
    required this.emoji,
    this.size = 40,
    this.background,
  });

  final String emoji;
  final double size;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background ?? context.colors.surfaceMuted,
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: TextStyle(fontSize: size * 0.48, height: 1)),
    );
  }
}
