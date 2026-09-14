import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/care/care_engine.dart';
import '../../../domain/models/models.dart';
import '../application/completed_tasks.dart';

/// Carte « Monstera · Salon · 💧 Arroser aujourd'hui · [Arroser] ».
/// Swipe droite : fait. Swipe gauche : plus tard.
class CareTaskCard extends ConsumerWidget {
  const CareTaskCard({super.key, required this.task, required this.onOpen, this.compact = false});

  final CareTask task;
  final VoidCallback onOpen;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l10n = context.l10n;
    final t = task;
    final custom = ref.watch(actionTypeByKeyProvider)[t.typeKey];
    final emoji = custom?.emoji ?? CareKind.fromKey(t.typeKey)?.emoji ?? '✓';
    final now = DateTime.now();
    final status = t.status(now);
    final verb = l10n.kindVerb(t.typeKey, custom: custom);
    final doneLabel = l10n.kindDone(t.typeKey, custom: custom);
    final phase = watchCarePhase(ref, t);
    final done = phase != null;
    final leaving = phase == LingerPhase.leaving;

    final card = FloraCard(
      onTap: onOpen,
      padding: const EdgeInsets.all(Space.sm),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              width: compact ? 52 : 64,
              height: compact ? 52 : 64,
              child: PlantImage(relativePath: t.summary.thumbPath, remoteUrl: t.summary.thumbUrl, cacheWidth: 192),
            ),
          ),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.summary.plant.name, style: context.text.title3, maxLines: 1, overflow: TextOverflow.ellipsis),
                if (t.summary.locationName != null) ...[
                  const SizedBox(height: 2),
                  Text(t.summary.locationName!, style: context.text.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 6),
                DueBadge(
                  emoji: emoji,
                  // Le bouton porte déjà le verbe : le badge reste court.
                  label: switch (status) {
                    DueStatus.today => l10n.verbToday(verb),
                    DueStatus.overdue => l10n.dueLabel(t.dueAt, now),
                    _ => l10n.careDueLabel(l10n.kindName(t.typeKey, custom: custom), l10n.dueLabel(t.dueAt, now)),
                  },
                  status: status,
                  compact: true,
                ),
              ],
            ),
          ),
          const SizedBox(width: Space.xs),
          CompletableButton(
            label: verb,
            doneLabel: doneLabel,
            done: done,
            onPressed: () => completeCareTask(context, ref, t),
            color: c.strongFor(t.typeKey),
            compact: compact,
          ),
        ],
      ),
    );

    // La carte s'en va : elle part vers la droite en s'effaçant, et la place
    // qu'elle occupait se referme en même temps. Sans ce dernier point, la
    // carte disparaissait bien en douceur mais les suivantes sautaient d'un
    // cran à l'instant où la liste se reconstruisait sans elle.
    return _Collapsing(
      collapsed: leaving,
      duration: Motion.of(context, CompletedTasksController.leaveDuration),
      child: AnimatedSlide(
        offset: leaving ? const Offset(1.1, 0) : Offset.zero,
        duration: Motion.of(context, CompletedTasksController.leaveDuration),
        curve: Motion.easeInOut,
        child: AnimatedOpacity(
          opacity: leaving ? 0 : 1,
          duration: Motion.of(context, CompletedTasksController.leaveDuration),
          child: Dismissible(
            key: ValueKey('${t.schedule.id}-${t.dueAt?.millisecondsSinceEpoch}'),
            direction: done ? DismissDirection.none : DismissDirection.horizontal,
            confirmDismiss: (dir) async {
              if (dir == DismissDirection.startToEnd) {
                await completeCareTask(context, ref, t);
              } else {
                await snoozeCareTask(context, ref, t);
              }
              // La liste se met à jour via le stream ; la carte ne se retire pas d'elle-même.
              return false;
            },
            background: _SwipeBackground(alignment: Alignment.centerLeft, color: c.sageSoft, fg: c.sage, icon: CupertinoIcons.checkmark_alt, label: doneLabel),
            secondaryBackground: _SwipeBackground(alignment: Alignment.centerRight, color: c.surfaceMuted, fg: c.inkSecondary, icon: CupertinoIcons.clock, label: l10n.snooze),
            child: card,
          ),
        ),
      ),
    );
  }
}

/// Referme la place d'une pièce qui s'en va, de toute sa hauteur à rien.
///
/// `AnimatedSize` ne conviendrait pas : il faudrait remplacer l'enfant par du
/// vide, et on perdrait le glissement et le fondu qui se jouent dessus. Ici
/// l'enfant reste entier, c'est la boîte qui se referme autour de lui.
///
/// Le rognage n'arrive qu'une fois la fermeture commencée, sans quoi il
/// mangerait l'ombre portée de l'argile, qui déborde de la carte — toutes les
/// cartes de l'écran y perdraient leur relief, en permanence, pour une
/// animation qui dure moins d'une demi-seconde.
class _Collapsing extends StatelessWidget {
  const _Collapsing({required this.collapsed, required this.duration, required this.child});

  final bool collapsed;
  final Duration duration;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1, end: collapsed ? 0 : 1),
      duration: duration,
      curve: Motion.easeInOut,
      builder: (context, factor, child) {
        final box = Align(alignment: Alignment.topCenter, heightFactor: factor, child: child);
        return factor == 1 ? box : ClipRect(child: box);
      },
      child: child,
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({required this.alignment, required this.color, required this.fg, required this.icon, required this.label});

  final Alignment alignment;
  final Color color;
  final Color fg;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: Space.lg),
      decoration: BoxDecoration(color: color, borderRadius: Radii.largeAll),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fg, size: 20),
          const SizedBox(width: Space.xs),
          Text(
            label,
            style: context.text.callout.copyWith(color: fg, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
