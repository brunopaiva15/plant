import '../../domain/diagnosis/plant_diagnoser.dart';
import '../../domain/identification/identification_confidence.dart';
import '../../l10n/generated/app_localizations.dart';

/// Les trois mots de la vraisemblance, partagés par tout ce qui hésite.
///
/// Le diagnostic propose des causes, l'identification propose des espèces :
/// ce sont deux échelles distinctes, calculées différemment — l'une sortie
/// d'un modèle de langue, l'autre d'un classifieur mesuré. Mais elles disent
/// la même chose à l'utilisateur, et il n'y a aucune raison qu'elles la
/// disent avec des mots différents. Un seul jeu de trois chaînes, ici.
extension LikelihoodLabels on AppLocalizations {
  /// Vraisemblance d'une cause de diagnostic.
  String likelihoodLabel(Likelihood v) => switch (v) {
        Likelihood.likely => likelihoodLikely,
        Likelihood.possible => likelihoodPossible,
        Likelihood.unlikely => likelihoodUnlikely,
      };

  /// Confiance dans un candidat d'identification.
  String confidenceLabel(IdentificationConfidence v) => switch (v) {
        IdentificationConfidence.likely => likelihoodLikely,
        IdentificationConfidence.possible => likelihoodPossible,
        IdentificationConfidence.unlikely => likelihoodUnlikely,
      };
}
