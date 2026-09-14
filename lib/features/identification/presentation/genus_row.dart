import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../data/species/genus_catalog.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/identification/identification_policy.dart';
import '../../../domain/identification/plant_identifier.dart';

/// Le genre proposé comme une réponse qu'on peut retenir.
///
/// Quand cinq candidates sont cinq *Picea* à 0,15, le genre pèse 0,75 :
/// « Épicéa, espèce incertaine » est une réponse vraie, là où cinq noms n'en
/// sont pas une. Retenue, elle inscrit la plante sous *Picea* — sans nom
/// d'espèce faux, et avec l'entretien du genre, que `CatalogCareGuide`
/// résout déjà.
///
/// C'est ce que fait iNaturalist depuis toujours : répondre au rang dont on
/// est sûr, plutôt que promettre une espèce.
IdentificationCandidate genusCandidate(GenusAnswer answer, String languageCode) => IdentificationCandidate(
      scientificName: answer.genus,
      commonName: GenusCatalog.commonName(answer.genus, languageCode),
      // La masse d'un genre peut dépasser 1 d'un cheveu, les scores étant
      // arrondis : la confiance affichée n'a pas à s'en émouvoir.
      score: answer.mass > 1 ? 1 : answer.mass,
      source: answer.source,
    );

/// La ligne du genre, au-dessus des espèces et distincte d'elles : ce n'est
/// pas une candidate de plus, c'est une réponse d'un autre rang.
class GenusRow extends StatelessWidget {
  const GenusRow({super.key, required this.answer, required this.onUse});

  final GenusAnswer answer;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final commun = GenusCatalog.commonName(answer.genus, l10n.localeName);
    return FloraGroup(
      children: [
        FloraListRow(
          title: commun ?? answer.genus,
          // Sous le nom commun, le nom scientifique dit de quel genre il
          // s'agit ; sans nom commun, il est déjà le titre et se répéterait.
          subtitle: commun == null ? l10n.genusUncertainSpecies : '${answer.genus} · ${l10n.genusUncertainSpecies}',
          onTap: onUse,
          chevron: true,
        ),
      ],
    );
  }
}
