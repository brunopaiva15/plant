import 'package:flutter/cupertino.dart';

import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';

/// Une carte de l'écran du matin qui dit une chose : la pluie, l'air de la
/// maison, les rappels, ou que tout est en ordre.
///
/// Toutes ont la même anatomie — une tuile d'emoji, un titre, une phrase,
/// parfois un ou deux boutons, une croix quand elle se ferme — et la même
/// teinte douce pour ce qui demande un regard ; la carte de repos reste
/// crème. Le titre est un nom, la phrase un constat.
class TodayNotice extends StatelessWidget {
  const TodayNotice({super.key, required this.emoji, required this.title, this.body, this.color, this.actions = const [], this.onDismiss});

  final String emoji;
  final String title;

  /// Le constat, sous le titre. Plusieurs lignes se séparent d'un `\n`.
  final String? body;

  /// La teinte de la carte ; crème sans.
  final Color? color;

  /// Les gestes proposés, sur une rangée sous le texte.
  final List<Widget> actions;

  /// Ferme la carte pour la journée. Rien sans : la carte ne se ferme pas.
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    return FloraCard(
      color: color,
      padding: const EdgeInsets.all(Space.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // La tuile reste crème sur une carte teintée : c'est elle qui fait
          // ressortir l'emoji, pas la teinte.
          EmojiTile(emoji: emoji, background: color == null ? null : c.surface),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Le titre s'aligne sur le centre de la tuile quand il tient
                // sur une ligne ; la phrase suit dessous.
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(title, style: context.text.title3),
                ),
                if (body != null) ...[const SizedBox(height: 2), Text(body!, style: context.text.callout)],
                if (actions.isNotEmpty) ...[const SizedBox(height: Space.sm), Wrap(spacing: Space.xs, runSpacing: Space.xs, children: actions)],
              ],
            ),
          ),
          if (onDismiss != null) ...[
            const SizedBox(width: Space.xs),
            FloraIconButton(icon: CupertinoIcons.xmark, semanticLabel: l10n.close, filled: false, size: 32, onPressed: onDismiss),
          ],
        ],
      ),
    );
  }
}

/// La pose commune des cartes du matin : la marge de page, et l'écart qui
/// les sépare de ce qui précède. Une carte absente ne laisse pas de vide.
class TodayNoticeSlot extends StatelessWidget {
  const TodayNoticeSlot({super.key, required this.child, this.visible = true});

  final Widget child;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: Motion.of(context, Motion.emphasis),
      curve: Motion.emphasized,
      alignment: Alignment.topCenter,
      child: !visible ? const SizedBox.shrink() : Padding(padding: const EdgeInsets.fromLTRB(Space.page, Space.sm, Space.page, 0), child: child),
    );
  }
}
