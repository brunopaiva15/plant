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
    this.leadingWidth = 32,
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

  /// Largeur réservée au [leading]. Trente-deux points suffisent à une
  /// pastille ou à une vignette de plante ; une photo qu'il faut vraiment
  /// reconnaître en demande davantage.
  final double leadingWidth;

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
              SizedBox(width: leadingWidth, child: Center(child: leading)),
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
                      decoration: strikethrough ? TextDecoration.lineThrough : null,
                      decorationColor: c.inkTertiary,
                    ),
                    maxLines: titleMaxLines,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: context.text.caption.copyWith(color: subtitleColor),
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
    if (onTap == null && onLongPress == null) return MergeSemantics(child: row);
    // Un seul nœud pour VoiceOver — « Monstera, arrosée il y a trois jours »
    // plutôt qu'un bouton sans nom suivi de deux fragments de texte —, et le
    // voile gris que toute liste iOS pose sous le doigt.
    //
    // Le libellé se compose des textes de la ligne, sans en réécrire un :
    // le dire deux fois ferait bégayer la synthèse vocale, et un libellé
    // recopié à la main oublierait toujours la pastille d'échéance.
    return MergeSemantics(
      child: Pressable(
        onTap: onTap,
        onLongPress: onLongPress,
        scale: 1,
        highlightColor: c.ink.withValues(alpha: 0.06),
        child: row,
      ),
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
