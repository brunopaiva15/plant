import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/care/care_engine.dart';
import '../../../domain/models/models.dart';
import '../../actions/application/care_actions.dart';
import '../application/completed_tasks.dart';

/// Carte « Monstera · Salon · 💧 Arroser aujourd'hui · [Arroser] ».
/// Swipe droite : fait. Swipe gauche : plus tard.
class CareTaskCard extends ConsumerStatefulWidget {
  const CareTaskCard({super.key, required this.task, required this.onOpen, this.compact = false});

  final CareTask task;
  final VoidCallback onOpen;
  final bool compact;

  @override
  ConsumerState<CareTaskCard> createState() => _CareTaskCardState();
}

class _CareTaskCardState extends ConsumerState<CareTaskCard> {
  bool _done = false;

  Future<void> _complete() async {
    if (_done) return;
    setState(() => _done = true);
    final t = widget.task;
    ref.read(completedTasksProvider.notifier).markDone(t);
    await ref.read(careActionsProvider).logQuick(context, plantId: t.plantId, plantName: t.summary.plant.name, typeKey: t.typeKey);
  }

  Future<void> _snooze() async {
    final t = widget.task;
    await ref.read(careActionsProvider).snooze(context, scheduleId: t.schedule.id, plantName: t.summary.plant.name);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final t = widget.task;
    final custom = ref.watch(actionTypeByKeyProvider)[t.typeKey];
    final emoji = custom?.emoji ?? CareKind.fromKey(t.typeKey)?.emoji ?? '✓';
    final now = DateTime.now();
    final status = t.status(now);
    final verb = l10n.kindVerb(t.typeKey, custom: custom);
    final done = l10n.kindDone(t.typeKey, custom: custom);
    final linger = ref.watch(completedTasksProvider.select((m) => m[t.schedule.id]));
    // Undo (ou tâche redevenue due) : la carte revient à l'état actif.
    if (_done && linger == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _done) setState(() => _done = false);
      });
    }
    final leaving = linger?.phase == LingerPhase.leaving;

    final card = FloraCard(
      onTap: widget.onOpen,
      padding: const EdgeInsets.all(Space.sm),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              width: widget.compact ? 52 : 64,
              height: widget.compact ? 52 : 64,
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
            doneLabel: done,
            done: _done,
            onPressed: _complete,
            color: c.strongFor(t.typeKey),
            compact: widget.compact,
          ),
        ],
      ),
    );

    return AnimatedSlide(
      offset: leaving ? const Offset(1.1, 0) : Offset.zero,
      duration: Motion.of(context, CompletedTasksController.leaveDuration),
      curve: Motion.easeInOut,
      child: AnimatedOpacity(
        opacity: leaving ? 0 : 1,
        duration: Motion.of(context, CompletedTasksController.leaveDuration),
        child: Dismissible(
      key: ValueKey('${t.schedule.id}-${t.dueAt?.millisecondsSinceEpoch}'),
      direction: _done ? DismissDirection.none : DismissDirection.horizontal,
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd) {
          await _complete();
        } else {
          await _snooze();
        }
        // La liste se met à jour via le stream ; la carte ne se retire pas d'elle-même.
        return false;
      },
      background: _SwipeBackground(alignment: Alignment.centerLeft, color: c.sageSoft, fg: c.sage, icon: CupertinoIcons.checkmark_alt, label: done),
      secondaryBackground: _SwipeBackground(alignment: Alignment.centerRight, color: c.surfaceMuted, fg: c.inkSecondary, icon: CupertinoIcons.clock, label: l10n.snooze),
      child: card,
        ),
      ),
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
          Text(label, style: context.text.callout.copyWith(color: fg, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
