import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/problems/natural_cause.dart';
import '../../../domain/problems/plant_problem.dart';
import '../../problems/presentation/problem_kind_icon.dart';
import 'encyclopedia_screen.dart';

/// Un groupe du rayon des problèmes : l'une des quatre familles de la base,
/// ou ce qui n'en est pas un.
///
/// Les phénomènes naturels ne sont pas une famille de plus — la base les
/// tient à part, et pour cause : il n'y a rien à soigner. Mais c'est bien
/// dans ce rayon qu'on vient les chercher, avec la même question en tête :
/// « qu'est-ce que c'est, sur ma plante ? ». Ils ferment donc la liste,
/// après les affections, sous leur propre titre.
enum ProblemGroup {
  disorder,
  pest,
  disease,
  condition,

  /// Ce que la plante fait normalement et qu'on prend pour un problème.
  natural;

  /// La famille de la base, pour les quatre qui en sont une.
  ProblemKind? get kind => switch (this) {
        ProblemGroup.disorder => ProblemKind.disorder,
        ProblemGroup.pest => ProblemKind.pest,
        ProblemGroup.disease => ProblemKind.disease,
        ProblemGroup.condition => ProblemKind.condition,
        ProblemGroup.natural => null,
      };

  static ProblemGroup of(ProblemKind kind) => switch (kind) {
        ProblemKind.disorder => ProblemGroup.disorder,
        ProblemKind.pest => ProblemGroup.pest,
        ProblemKind.disease => ProblemGroup.disease,
        ProblemKind.condition => ProblemGroup.condition,
      };
}

extension ProblemGroupLabels on AppLocalizations {
  /// Le titre du groupe, au pluriel : celui de la puce et de la section.
  String problemGroupTitle(ProblemGroup group) => switch (group.kind) {
        final ProblemKind kind => problemKindPlural(kind),
        null => naturalCauses,
      };
}

/// Les deux cents troubles, ravageurs, maladies et affections de la base, et
/// les trente-deux phénomènes naturels qu'on leur prend pour des symptômes.
///
/// La liste est paresseuse : deux cents illustrations d'argile posées d'un
/// coup, ce sont deux cents décodages sur une même image.
class ProblemsSlivers extends ConsumerWidget {
  const ProblemsSlivers({super.key, required this.query, required this.group, required this.onGroup});

  final String query;
  final ProblemGroup? group;
  final ValueChanged<ProblemGroup?> onGroup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final catalog = ref.watch(problemCatalogProvider).value;
    if (catalog == null) return const SliverCentered(child: AdaptiveProgress());

    // La recherche est dans `PlantProblem.matches` et `NaturalCause.matches`,
    // la même règle des deux côtés : les noms des quatre langues, les
    // synonymes, le numéro et les hôtes.
    //
    // Le tri range les familles dans l'ordre de l'énumération — troubles,
    // ravageurs, maladies, affections —, et les numéros à l'intérieur. La
    // base les numérote presque ainsi, à une entrée près : la fumagine porte
    // le 181, au milieu des maladies.
    final kind = group?.kind;
    final problems = <PlantProblem>[
      if (group != ProblemGroup.natural)
        for (final p in catalog.problems)
          if ((kind == null || p.kind == kind) && p.matches(query)) p,
    ]..sort((a, b) {
        final byKind = a.kind.index.compareTo(b.kind.index);
        return byKind != 0 ? byKind : a.id.compareTo(b.id);
      });
    final natural = <NaturalCause>[
      if (group == null || group == ProblemGroup.natural)
        for (final n in catalog.naturalCauses)
          if (n.matches(query)) n,
    ];

    // Sans filtre, chaque groupe prend son titre au passage ; avec, la puce
    // le dit déjà.
    final items = <Object>[];
    ProblemGroup? seen;
    void enter(ProblemGroup g) {
      if (group == null && g != seen) {
        seen = g;
        items.add(g);
      }
    }

    for (final p in problems) {
      enter(ProblemGroup.of(p.kind));
      items.add(p);
    }
    for (final n in natural) {
      enter(ProblemGroup.natural);
      items.add(n);
    }

    // Le compte dit ce que la liste contient : les deux quand les deux y
    // sont, et pas « aucun problème » devant une liste de phénomènes.
    final count = switch (group) {
      ProblemGroup.natural => l10n.encyclopediaNaturalCount(natural.length),
      ProblemGroup() => l10n.encyclopediaProblemCount(problems.length),
      null => [
          if (problems.isNotEmpty || natural.isEmpty) l10n.encyclopediaProblemCount(problems.length),
          if (natural.isNotEmpty) l10n.encyclopediaNaturalCount(natural.length),
        ].join(' · '),
    };

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: EncyclopediaFilterRow<ProblemGroup>(
            options: [
              (null, l10n.speciesCatAll),
              for (final g in ProblemGroup.values) (g, l10n.problemGroupTitle(g)),
            ],
            value: group,
            onChanged: onGroup,
          ),
        ),
        SliverToBoxAdapter(child: EncyclopediaCount(count)),
        if (items.isEmpty)
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
                final ProblemGroup g => Padding(
                    padding: EdgeInsets.only(top: i == 0 ? 0 : Space.md),
                    child: SectionHeader(title: l10n.problemGroupTitle(g), padding: const EdgeInsets.only(left: Space.md, bottom: Space.xs)),
                  ),
                final PlantProblem p => _ProblemRow(problem: p),
                final NaturalCause n => _NaturalRow(cause: n),
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

/// Une ligne de phénomène naturel : son dessin, son nom, son étendue — la
/// même ligne qu'un problème, parce qu'on le lit avec la même question.
class _NaturalRow extends StatelessWidget {
  const _NaturalRow({required this.cause});

  final NaturalCause cause;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final language = Localizations.localeOf(context).languageCode;
    return FloraCard(
      padding: EdgeInsets.zero,
      clip: true,
      child: FloraListRow(
        leading: NaturalCauseIcon(cause: cause, side: 40),
        leadingWidth: 40,
        title: cause.nameIn(language),
        titleMaxLines: 2,
        subtitle: l10n.problemScopeName(cause.scope),
        onTap: () => context.push(Routes.encyclopediaNatural(cause.id)),
      ),
    );
  }
}
