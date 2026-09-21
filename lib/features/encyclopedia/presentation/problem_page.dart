import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/problems/plant_problem.dart';
import '../../onboarding/presentation/clay_illustration.dart';
import '../../problems/presentation/problem_kind_icon.dart';
import 'host_sections.dart';

/// La page d'un des deux cents problèmes de la base.
///
/// Elle ne dit que ce que la base contient — un nom, les autres noms de la
/// même chose, une famille, une étendue, des hôtes — et rien de ce qu'un
/// modèle pourrait inventer par dessus : le diagnostic, lui, a une photo sous les yeux ; ici on lit une
/// fiche, et une fiche qui broderait ne serait plus une fiche.
class ProblemPage extends ConsumerWidget {
  const ProblemPage({super.key, required this.problemId});

  final String problemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final language = Localizations.localeOf(context).languageCode;
    final catalog = ref.watch(problemCatalogProvider);
    final problem = catalog.value?[problemId];

    if (problem == null) {
      return FloraPage(
        title: l10n.encyclopediaTitle,
        child: Padding(
          padding: const EdgeInsets.only(top: Space.huge),
          child: catalog.isLoading
              ? const Center(child: AdaptiveProgress())
              : EmptyState(emoji: '🔍', title: l10n.noResultsTitle, compact: true),
        ),
      );
    }

    return FloraPage(
      title: problem.nameIn(language),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(problem: problem),
          const SizedBox(height: Space.md),
          // La famille est déjà dite en toutes lettres sous l'illustration,
          // et par la teinte de la carte : elle n'a pas de ligne ici.
          FloraGroup(
            footer: l10n.problemScopeNote(problem.scope),
            children: [_row(l10n.problemScope, l10n.problemScopeName(problem.scope))],
          ),
          _OtherNames(problem: problem),
          HostsSection(hosts: problem.hosts),
          InGardenSection(scope: problem.scope, hosts: problem.hosts),
        ],
      ),
    );
  }

  static Widget _row(String title, String value) => Builder(
        builder: (context) => FloraListRow(
          title: title,
          chevron: false,
          dense: true,
          trailing: Text(
            value,
            style: context.text.callout.copyWith(color: context.colors.ink, fontWeight: FontWeight.w600),
            textAlign: TextAlign.end,
          ),
        ),
      );
}

/// L'illustration en grand, sur la teinte de sa famille, et le nom entier.
///
/// Les dessins d'argile sont détaillés — un thermomètre, un puceron, une
/// racine coupée — et se lisent enfin ici : ailleurs ils tiennent en
/// quarante points, au bord de ce qui se distingue.
///
/// Le nom est écrit ici et pas seulement dans la barre, où « Bakterielle
/// Blattflecken und Blattnekrosen durch Xanthomonas » finirait en points de
/// suspension. Une fiche de référence donne le terme en entier.
class _Header extends StatelessWidget {
  const _Header({required this.problem});

  final PlantProblem problem;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final tint = switch (problem.kind) {
      ProblemKind.disorder => c.sunSoft,
      ProblemKind.pest => c.terracottaSoft,
      ProblemKind.disease => c.roseSoft,
      ProblemKind.condition => c.sageSoft,
    };
    const side = 112.0;
    return FloraCard(
      color: tint,
      padding: const EdgeInsets.symmetric(vertical: Space.lg, horizontal: Space.md),
      child: Column(
        children: [
          // Seul objet de la page, et posé en grand : il a droit à la
          // respiration que les vignettes de liste n'ont pas.
          Breathing(
            animate: true,
            builder: (context, pose) => ClayFloat(
              side: side,
              pose: pose,
              child: ProblemIcon(problem: problem, side: side),
            ),
          ),
          const SizedBox(height: Space.sm),
          Text(
            problem.nameIn(Localizations.localeOf(context).languageCode),
            style: context.text.title2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          // Le numéro n'est pas décoratif : c'est lui que le diagnostic
          // échange avec le modèle, et il nomme la même chose d'une analyse
          // à l'autre et d'une langue à l'autre.
          Text(
            '${l10n.problemKindName(problem.kind)} · ${l10n.problemNumber(problem.id)}',
            style: context.text.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Les autres noms sous lesquels la base connaît l'entrée.
///
/// Le titre n'en garde qu'un par langue, pour que deux analyses de la même
/// chose se lisent pareil ; les autres se lisent ici, où une fiche de
/// référence doit les donner — c'est « araignée rouge » qu'on a en tête, pas
/// « tétranyque ».
///
/// Toutes langues mêlées, comme la base les range : un nom scientifique ne
/// vaut pour aucune en particulier, et un nom courant d'ailleurs reste un
/// nom de la même chose.
///
/// Absente des vingt-neuf entrées dont le titre porte déjà le mot qu'on
/// chercherait.
class _OtherNames extends StatelessWidget {
  const _OtherNames({required this.problem});

  final PlantProblem problem;

  @override
  Widget build(BuildContext context) {
    if (problem.aliases.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: Space.lg),
        Text(l10n.problemOtherNames, style: context.text.title3),
        const SizedBox(height: Space.sm),
        FloraGroup(
          footer: l10n.problemOtherNamesNote,
          children: [
            for (final name in problem.aliases)
              FloraListRow(title: name, titleMaxLines: 2, dense: true, chevron: false),
          ],
        ),
      ],
    );
  }
}
