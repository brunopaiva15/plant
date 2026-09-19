import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/problems/plant_problem.dart';
import '../../problems/presentation/problem_kind_icon.dart';
import 'encyclopedia_screen.dart';

/// Les deux cents troubles, ravageurs, maladies et affections de la base.
///
/// La liste est paresseuse : deux cents illustrations d'argile posées d'un
/// coup, ce sont deux cents décodages sur une même image.
class ProblemsSlivers extends ConsumerWidget {
  const ProblemsSlivers({super.key, required this.query, required this.kind, required this.onKind});

  final String query;
  final ProblemKind? kind;
  final ValueChanged<ProblemKind?> onKind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final catalog = ref.watch(problemCatalogProvider).value;
    if (catalog == null) return const SliverCentered(child: AdaptiveProgress());

    // La recherche est dans `PlantProblem.matches` : les noms des quatre
    // langues, les synonymes, le numéro et les hôtes.
    //
    // Le tri range les familles dans l'ordre de l'énumération — troubles,
    // ravageurs, maladies, affections —, et les numéros à l'intérieur. La
    // base les numérote presque ainsi, à une entrée près : la fumagine porte
    // le 181, au milieu des maladies.
    final found = [
      for (final p in catalog.problems)
        if ((kind == null || p.kind == kind) && p.matches(query)) p,
    ]..sort((a, b) {
        final byKind = a.kind.index.compareTo(b.kind.index);
        return byKind != 0 ? byKind : a.id.compareTo(b.id);
      });

    // Sans filtre de famille, chaque famille prend son titre au passage ;
    // avec, la puce le dit déjà.
    final items = <Object>[];
    ProblemKind? seen;
    for (final p in found) {
      if (kind == null && p.kind != seen) {
        seen = p.kind;
        items.add(p.kind);
      }
      items.add(p);
    }

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: EncyclopediaFilterRow<ProblemKind>(
            options: [
              (null, l10n.speciesCatAll),
              for (final k in ProblemKind.values) (k, l10n.problemKindPlural(k)),
            ],
            value: kind,
            onChanged: onKind,
          ),
        ),
        SliverToBoxAdapter(child: EncyclopediaCount(l10n.encyclopediaProblemCount(found.length))),
        if (found.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(Space.page),
              child: EmptyState(emoji: '🔍', title: l10n.noResultsTitle, subtitle: l10n.noResultsSubtitle, compact: true),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.lg),
            sliver: SliverList.separated(
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: Space.xs),
              itemBuilder: (context, i) => switch (items[i]) {
                final ProblemKind k => Padding(
                    padding: EdgeInsets.only(top: i == 0 ? 0 : Space.md),
                    child: SectionHeader(title: l10n.problemKindPlural(k), padding: const EdgeInsets.only(left: Space.md, bottom: Space.xs)),
                  ),
                final PlantProblem p => _ProblemRow(problem: p),
                _ => const SizedBox.shrink(),
              },
            ),
          ),
      ],
    );
  }
}

class _ProblemRow extends StatelessWidget {
  const _ProblemRow({required this.problem});

  final PlantProblem problem;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final language = Localizations.localeOf(context).languageCode;
    return FloraCard(
      padding: EdgeInsets.zero,
      clip: true,
      child: FloraListRow(
        leading: ProblemIcon(problem: problem, side: 40),
        leadingWidth: 40,
        title: problem.nameIn(language),
        titleMaxLines: 2,
        subtitle: l10n.problemScopeName(problem.scope),
        onTap: () => context.push(Routes.encyclopediaProblem(problem.id)),
      ),
    );
  }
}
