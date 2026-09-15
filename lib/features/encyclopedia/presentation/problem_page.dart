import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/l10n/l10n.dart';
import '../../../data/species/species_catalog.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models/models.dart';
import '../../../domain/problems/plant_problem.dart';
import '../../../domain/repositories/repositories.dart';
import '../../onboarding/presentation/clay_illustration.dart';
import '../../plants/application/plant_providers.dart';
import '../../problems/presentation/problem_kind_icon.dart';

/// La page d'un des deux cents problèmes de la base.
///
/// Elle ne dit que ce que la base contient — un nom, une famille, une
/// étendue, des hôtes — et rien de ce qu'un modèle pourrait inventer par
/// dessus : le diagnostic, lui, a une photo sous les yeux ; ici on lit une
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
          _Hosts(problem: problem),
          _InGarden(problem: problem),
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

/// Les hôtes cités par la base, dans son ordre à elle.
class _Hosts extends StatelessWidget {
  const _Hosts({required this.problem});

  final PlantProblem problem;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: Space.lg),
        Text(l10n.problemHosts, style: context.text.title3),
        const SizedBox(height: Space.sm),
        FloraGroup(
          footer: l10n.problemHostsNote,
          children: [for (final host in problem.hosts) _HostRow(host: host)],
        ),
      ],
    );
  }
}

/// Un hôte : une espèce (deux mots), une famille (en -aceae), un genre, ou
/// l'embranchement entier.
///
/// Seule une espèce que l'un des deux catalogues connaît mène quelque part :
/// d'un genre ou d'une famille, il n'y a pas de fiche à ouvrir.
class _HostRow extends ConsumerWidget {
  const _HostRow({required this.host});

  final String host;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    if (host == 'Tracheophyta') {
      return FloraListRow(
        leading: const Text('🌍', style: TextStyle(fontSize: 18)),
        title: l10n.problemHostsAll,
        dense: true,
        chevron: false,
      );
    }
    final lang = Localizations.localeOf(context).languageCode;
    final species = host.contains(' ');
    final common = !species
        ? null
        : (SpeciesCatalog.find(host)?.commonName(lang) ?? ref.watch(speciesIndexProvider).value?.find(host)?.commonName(lang));
    return FloraListRow(
      leading: Text(species ? '🌿' : '🗂️', style: const TextStyle(fontSize: 18)),
      title: host,
      titleMaxLines: 2,
      subtitle: species ? common : (host.endsWith('aceae') ? l10n.speciesFamily : l10n.speciesGenus),
      dense: true,
      chevron: common != null,
      onTap: common == null ? null : () => context.push(Routes.encyclopediaSpecies(host)),
    );
  }
}

/// Les plantes du jardin que la base range parmi les hôtes.
///
/// Absente des problèmes universels : y aligner toute la collection ne dirait
/// rien — un manque d'eau concerne tout le monde, la base le déclare ainsi.
class _InGarden extends ConsumerWidget {
  const _InGarden({required this.problem});

  final PlantProblem problem;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (problem.scope == ProblemScope.general) return const SizedBox.shrink();
    final l10n = context.l10n;
    final familyOf = speciesFamilyLookup(ref);
    final plants = ref.watch(plantSummariesProvider(const PlantFilter())).value ?? const <PlantSummary>[];
    final concerned = [
      for (final s in plants)
        if (s.plant.speciesName != null && problem.affects(species: s.plant.speciesName, family: familyOf(s.plant.speciesName))) s,
    ];
    if (concerned.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: Space.lg),
        Text(l10n.problemInGarden, style: context.text.title3),
        const SizedBox(height: Space.sm),
        FloraGroup(
          children: [
            for (final s in concerned)
              FloraListRow(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(width: 36, height: 36, child: PlantImage(relativePath: s.thumbPath, remoteUrl: s.thumbUrl, cacheWidth: 108)),
                ),
                leadingWidth: 36,
                title: s.plant.name,
                subtitle: s.plant.speciesName,
                dense: true,
                onTap: () => context.push(Routes.plant(s.plant.id)),
              ),
          ],
        ),
      ],
    );
  }
}
