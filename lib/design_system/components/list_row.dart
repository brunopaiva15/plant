import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/flora_theme.dart';
import '../tokens/spacing.dart';
import 'clay.dart';
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
    this.onLongPress,
    this.chevron,
    this.destructive = false,
    this.dense = false,
    this.subtitleColor,
    this.strikethrough = false,
    this.titleMaxLines = 1,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool? chevron;
  final bool destructive;
  final bool dense;

  /// Couleur du sous-titre (échéance en retard, par exemple).
  final Color? subtitleColor;

  /// Titre barré (tâche terminée).
  final bool strikethrough;

  /// Lignes autorisées pour le titre : 2 pour une phrase courte.
  final int titleMaxLines;

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
              // Le trailing prend ce qu'il lui faut, à deux réserves près : au
              // moins la moitié de la ligne revient au titre sur un large
              // écran, et une centaine de points lui restent sur un écran étroit —
              // de quoi lire « Arrosage » sans que le « + » ne sorte du cadre.
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: math.max(constraints.maxWidth * 0.5, constraints.maxWidth - 96),
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

/// Tuile d'emoji en argile pastel, aux coins irréguliers, pour les leading
/// de listes et cartes. [variant] varie la forme d'une tuile à l'autre.
class EmojiTile extends StatelessWidget {
  const EmojiTile({
    super.key,
    required this.emoji,
    this.size = 40,
    this.background,
    this.variant = 0,
  });

  final String emoji;
  final double size;
  final Color? background;
  final int variant;

  @override
  Widget build(BuildContext context) {
    return ClayBox(
      width: size,
      height: size,
      color: background ?? context.colors.surfaceMuted,
      shape: ClayShape.blob(variant),
      alignment: Alignment.center,
      child: Text(emoji, style: TextStyle(fontSize: size * 0.48, height: 1)),
    );
  }
}
