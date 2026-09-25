import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/identification/comparison_model.dart';
import '../../../domain/identification/identification_context.dart';
import '../../../domain/identification/plant_identifier.dart';
import 'identification_sheet.dart';

/// Lance les modèles de comparaison allumés sur [photos] (§ 15 de docs/09),
/// et rend ce que chacun verra ; vide quand aucun ne l'est.
///
/// Chacun attend que le précédent — Iris d'abord, [after] — ait répondu ou
/// échoué. Jamais en même temps : deux inférences simultanées se
/// partageraient le processeur et pousseraient Iris au-delà du délai de la
/// cascade, qui partirait alors en ligne — la comparaison fausserait ce
/// qu'elle mesure.
///
/// Partagé par les deux endroits où l'on identifie : la feuille « Espèce »
/// et l'étape « Nom » de l'ajout d'une plante. Oublier le second, c'était
/// rendre la comparaison invisible là où l'on identifie le plus.
Map<ComparisonModel, Future<List<IdentificationCandidate>>> startModelComparisons(
  WidgetRef ref, {
  required Future<Object?> after,
  required List<File> photos,
  required String language,
  IdentificationContext place = IdentificationContext.unknown,
}) {
  final out = <ComparisonModel, Future<List<IdentificationCandidate>>>{};
  var previous = after;
  for (final model in ComparisonModel.values) {
    final comparison = ref.read(comparisonIdentifierProvider(model));
    if (comparison == null) continue;
    final next = previous
        .then<void>((_) {}, onError: (Object _) {})
        .then((_) => comparison.identify(photos, language: language, context: place));
    out[model] = next;
    previous = next;
  }
  return out;
}

/// Une section par modèle de comparaison lancé, dans l'ordre de
/// [ComparisonModel]. Rien quand aucun ne l'est.
class ModelComparisonSections extends StatelessWidget {
  const ModelComparisonSections({
    super.key,
    required this.comparisons,
    required this.maxCandidates,
    required this.onUse,
    this.selectedScientificName,
  });

  final Map<ComparisonModel, Future<List<IdentificationCandidate>>> comparisons;

  /// Autant que la liste d'Iris au-dessus : on compare des listes de même
  /// longueur.
  final int maxCandidates;
  final void Function(IdentificationCandidate candidate) onUse;

  /// L'espèce déjà retenue, marquée dans toutes les listes où elle figure.
  final String? selectedScientificName;

  @override
  Widget build(BuildContext context) {
    if (comparisons.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in comparisons.entries)
          _ComparisonSection(
            model: entry.key,
            future: entry.value,
            maxCandidates: maxCandidates,
            onUse: onUse,
            selectedScientificName: selectedScientificName,
          ),
      ],
    );
  }
}

/// Les propositions d'un modèle de comparaison, sous celles d'Iris, pour les
/// comparer sur la même photo (§ 15 de docs/09). Elles se choisissent comme les
/// autres : une comparaison qui obligerait à recopier le bon nom à la main ne
/// servirait pas longtemps.
class _ComparisonSection extends ConsumerWidget {
  const _ComparisonSection(
      {required this.model,
      required this.future,
      required this.maxCandidates,
      required this.onUse,
      this.selectedScientificName});

  final ComparisonModel model;
  final Future<List<IdentificationCandidate>> future;
  final int maxCandidates;
  final void Function(IdentificationCandidate candidate) onUse;
  final String? selectedScientificName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final name = model.displayName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: l10n.modelComparisonSuggestions(name),
          padding: const EdgeInsets.only(top: Space.lg, bottom: Space.sm),
        ),
        FutureBuilder<List<IdentificationCandidate>>(
          future: future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return Text(l10n.identifying, style: context.text.caption);
            }
            final results = (snap.data ?? const <IdentificationCandidate>[]).take(maxCandidates).toList();
            // Un modèle qui ne s'est pas chargé ne « reconnaît aucune
            // plante » : il n'a rien regardé. Le dire comme les réglages le
            // disent pour Iris, erreur native comprise — c'est elle qui
            // distingue un asset absent d'un runtime trop ancien.
            final error = ref.read(comparisonPlantModelProvider(model)).loadError;
            if (results.isEmpty && error != null) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.modelMissing(name), style: context.text.caption),
                  SelectableText(error, style: context.text.caption),
                ],
              );
            }
            if (results.isEmpty) return Text(l10n.modelComparisonNone(name), style: context.text.caption);
            return FloraGroup(
              children: [
                for (final c in results)
                  CandidateRow(
                    candidate: c,
                    onUse: () => onUse(c),
                    selected: c.scientificName == selectedScientificName,
                    showScore: true,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
