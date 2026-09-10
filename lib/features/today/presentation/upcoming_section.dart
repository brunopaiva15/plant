import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models/models.dart';
import '../application/completed_tasks.dart';
import '../application/upcoming_view.dart';
import 'care_task_card.dart';

/// « À venir » : les soins qui ne pressent pas encore.
///
/// En grille par défaut — des photos, un nom, une échéance : la semaine se lit
/// d'un coup d'œil au lieu de dérouler. Le bouton de l'en-tête bascule en
/// liste d'un seul geste, et là chaque carte retrouve son emplacement, son
/// verbe et ses gestes de swipe.
class UpcomingSection extends ConsumerWidget {
  const UpcomingSection({super.key, required this.tasks});

  final List<CareTask> tasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final grid = ref.watch(upcomingGridProvider);
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: SectionHeader(
            title: l10n.sectionUpcoming,
            // La marge droite tombe à 8 : la boîte tactile de 44 points la
            // reprend, et le glyphe retombe pile sur la marge de page.
            padding: const EdgeInsets.fromLTRB(Space.page, Space.xl, Space.xs, Space.sm),
            trailing: FloraIconButton(
              // Sans cercle ni libellé, à hauteur du titre : l'icône montre la
              // vue d'en face, celle où le tap emmène.
              icon: grid ? CupertinoIcons.list_bullet : CupertinoIcons.square_grid_2x2,
              semanticLabel: grid ? l10n.showAsList : l10n.showAsGrid,
              filled: false,
              color: context.colors.inkSecondary,
              onPressed: ref.read(upcomingGridProvider.notifier).toggle,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: Space.page),
          sliver: grid
              ? SliverGrid.builder(
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 180,
                    mainAxisSpacing: Space.sm,
                    crossAxisSpacing: Space.sm,
                    childAspectRatio: _tileRatio(context),
                  ),
                  itemCount: tasks.length,
                  itemBuilder: (context, i) => UpcomingTile(key: ValueKey(tasks[i].schedule.id), task: tasks[i]),
                )
              : SliverList.separated(
                  itemCount: tasks.length,
                  separatorBuilder: (_, _) => const SizedBox(height: Space.sm),
                  itemBuilder: (context, i) => CareTaskCard(
                    key: ValueKey(tasks[i].schedule.id),
                    task: tasks[i],
                    compact: true,
                    onOpen: () => context.push(Routes.plant(tasks[i].plantId)),
                  ),
                ),
        ),
      ],
    );
  }
}

/// Le rapport d'une tuile : une photo à peu près carrée, puis deux lignes de
/// texte.
///
/// Ces deux lignes suivent Dynamic Type, donc la tuile aussi : à 200 % elle
/// s'allonge d'autant au lieu de rogner le nom de la plante. La largeur de
/// référence est celle d'une colonne sur téléphone ; ailleurs la photo est
/// un peu moins carrée, ce que personne ne voit.
double _tileRatio(BuildContext context) {
  const column = 160.0;
  const margins = Space.xs + Space.sm;
  const lines = 45.0;
  return column / (column + margins + MediaQuery.textScalerOf(context).scale(lines));
}

/// Une tuile de la grille : la photo en grand, le nom, l'échéance — et le rond
/// de validation, pour qu'un soin fait d'avance s'enregistre sans quitter
/// l'écran du matin.
class UpcomingTile extends ConsumerWidget {
  const UpcomingTile({super.key, required this.task});

  final CareTask task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l10n = context.l10n;
    final t = task;
    final custom = ref.watch(actionTypeByKeyProvider)[t.typeKey];
    final emoji = custom?.emoji ?? CareKind.fromKey(t.typeKey)?.emoji ?? '✓';
    final now = DateTime.now();
    final phase = watchCarePhase(ref, t);
    final done = phase != null;
    final leaving = phase == LingerPhase.leaving;

    final tile = FloraCard(
      onTap: () => context.push(Routes.plant(t.plantId)),
      padding: EdgeInsets.zero,
      clip: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                PlantImage(relativePath: t.summary.thumbPath, remoteUrl: t.summary.thumbUrl, cacheWidth: 400),
                // Posé dans l'angle, le rond garde ses 44 points d'écoute : la
                // boîte tactile touche les deux bords, le dessin reste en retrait.
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: FloraIconButton(
                    icon: CupertinoIcons.checkmark_alt,
                    semanticLabel: done ? l10n.kindDone(t.typeKey, custom: custom) : l10n.kindVerb(t.typeKey, custom: custom),
                    size: 32,
                    background: done ? c.sageSoft : null,
                    color: done ? c.sage : c.strongFor(t.typeKey),
                    onPressed: done ? null : () => completeCareTask(context, ref, t),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.sm, Space.xs, Space.sm, Space.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.summary.plant.name, style: context.text.title3, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                // Sitôt le soin enregistré, la pastille confirme au lieu
                // d'annoncer : « ✓ Arrosée », en vert, le temps de l'undo.
                DueBadge(
                  emoji: done ? '✓' : emoji,
                  label: done ? l10n.kindDone(t.typeKey, custom: custom) : l10n.dueLabel(t.dueAt, now),
                  status: t.status(now),
                  done: done,
                  compact: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // Une tuile ne glisse pas sur le côté comme une ligne de liste : elle
    // s'efface sur place, sans pousser ses voisines.
    return AnimatedScale(
      scale: leaving ? 0.92 : 1,
      duration: Motion.of(context, CompletedTasksController.leaveDuration),
      curve: Motion.easeInOut,
      child: AnimatedOpacity(
        opacity: leaving ? 0 : 1,
        duration: Motion.of(context, CompletedTasksController.leaveDuration),
        child: tile,
      ),
    );
  }
}
