import 'package:flutter/cupertino.dart';

import '../../../core/l10n/care_labels.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/utils/search_text.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/care/care_profile.dart';
import '../../../domain/problems/plant_problem.dart';
import '../../problems/presentation/problem_kind_icon.dart';

/// Le vocabulaire des fiches d'entretien et du diagnostic.
///
/// Une fiche dit « Substrat · Écorces pour orchidées » et n'explique rien :
/// c'est ici que le mot se déplie. Les termes sont ceux des énumérations du
/// domaine, dans leur ordre, pour que la liste suive toujours le code — une
/// valeur ajoutée à `SoilKind` apparaît ici sans qu'on y pense, et sa
/// définition manquante ne compile pas.
class GlossarySlivers extends StatelessWidget {
  const GlossarySlivers({super.key, required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = foldSpeciesName(query);
    // Le troisième champ est le symbole du terme, quand l'application en
    // dessine un ailleurs. Seules les familles de problèmes sont dans ce cas :
    // leur argile se voit sur une fiche de soin et dans un diagnostic, et
    // c'est ici qu'on vient chercher ce qu'elle veut dire.
    final groups = <(String, List<(String, String, Widget?)>)>[
      (
        l10n.problemKindsTitle,
        [for (final k in ProblemKind.values) (l10n.problemKindName(k), l10n.problemKindNote(k), ProblemKindIcon(kind: k))],
      ),
      (l10n.careLight, [for (final v in LightNeed.values) (l10n.lightName(v), l10n.lightNote(v), null)]),
      (l10n.careHumidity, [for (final v in HumidityNeed.values) (l10n.humidityName(v), l10n.humidityNote(v), null)]),
      (l10n.careSoil, [for (final v in SoilKind.values) (l10n.soilName(v), l10n.soilNote(v), null)]),
      (l10n.carePropagation, [for (final v in Propagation.values) (l10n.propagationName(v), l10n.propagationNote(v), null)]),
      (l10n.careToxicity, [for (final v in Toxicity.values) (l10n.toxicityName(v), l10n.toxicityNote(v), null)]),
      (l10n.careDifficulty, [for (final v in CareDifficulty.values) (l10n.difficultyName(v), l10n.difficultyNote(v), null)]),
    ];
    // La recherche porte sur le terme et sur sa définition : « orchidée »
    // sort le substrat, « perlite » aussi.
    final kept = [
      for (final (title, terms) in groups)
        (title, [for (final t in terms) if (q.isEmpty || foldSpeciesName('${t.$1} ${t.$2}').contains(q)) t]),
    ].where((g) => g.$2.isNotEmpty).toList();

    if (kept.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(Space.page),
          child: EmptyState(emoji: '🔍', title: l10n.encyclopediaNoTerm, subtitle: l10n.noResultsSubtitle, compact: true),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.lg),
      sliver: SliverList.separated(
        itemCount: kept.length,
        separatorBuilder: (_, _) => const SizedBox(height: Space.lg),
        itemBuilder: (context, i) => FloraGroup(
          header: kept[i].$1,
          children: [for (final (term, note, symbole) in kept[i].$2) _TermRow(term: term, note: note, leading: symbole)],
        ),
      ),
    );
  }
}

/// Un terme et sa définition.
///
/// Pas une [FloraListRow] : son sous-titre s'arrête à deux lignes, et une
/// définition tronquée ne définit rien.
class _TermRow extends StatelessWidget {
  const _TermRow({required this.term, required this.note, this.leading});

  final String term;
  final String note;

  /// Le symbole du terme, pour les rares mots que l'application dessine.
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (leading != null) ...[
              // Le terme est écrit juste à côté, et sa définition en dessous :
              // l'image n'a rien à ajouter à qui écoute l'écran.
              ExcludeSemantics(child: leading!),
              const SizedBox(width: Space.sm),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(term, style: context.text.body.copyWith(color: context.colors.ink)),
                  const SizedBox(height: 2),
                  Text(note, style: context.text.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
