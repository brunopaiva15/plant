import 'identification_policy.dart';
import 'plant_identifier.dart';

/// À quel point un candidat tient debout, en trois crans.
///
/// Le score existe et il est mesuré, contrairement à celui que rendait le
/// diagnostic. Mais il n'est pas ce qu'un pourcentage laisse croire. Deux
/// raisons, et la seconde est la pire :
///
/// - un softmax n'est pas calibré. [FallbackPolicy] documente qu'un premier
///   candidat à 0,70 est juste dans 85 % des cas ; « 70 % » affiché n'est
///   donc pas « 70 % de chances d'avoir raison » ;
/// - le modèle embarqué répartit sa masse sur 894 espèces et Pl@ntNet sur
///   des dizaines de milliers. À confiance réelle égale, le premier sort des
///   scores structurellement plus hauts. Les afficher dans la même colonne
///   invitait à une comparaison qui n'a pas de sens.
///
/// Les mots restent ceux du diagnostic. Une seule échelle de vraisemblance
/// dans l'application, pas deux vocabulaires pour la même idée.
enum IdentificationConfidence {
  likely,
  possible,
  unlikely;

  /// Le cran d'un candidat, selon d'où il vient.
  ///
  /// Pour le modèle embarqué, les seuils sont ceux que la cascade utilise
  /// déjà pour décider d'appeler ou non le service distant : un candidat
  /// annoncé « probable » est exactement un candidat que la politique
  /// accepterait sans appel.
  ///
  /// Pour Pl@ntNet, les seuils sont plus bas et ne reposent sur aucune mesure
  /// faite ici — seulement sur l'allure des réponses du service. Ils sont
  /// donc séparés, plutôt que d'appliquer à ses scores une échelle calibrée
  /// sur un autre modèle.
  static IdentificationConfidence of(
    IdentificationCandidate candidate, {
    FallbackPolicy policy = const FallbackPolicy(),
  }) {
    final (haut, moyen) = switch (candidate.source) {
      IdentificationSource.local => (policy.acceptThreshold, policy.plausibleThreshold),
      _ => (remoteLikely, remotePossible),
    };
    if (candidate.score >= haut) return IdentificationConfidence.likely;
    if (candidate.score >= moyen) return IdentificationConfidence.possible;
    return IdentificationConfidence.unlikely;
  }

  /// Seuils du service distant. Non mesurés : à revoir si l'on se donne un
  /// jeu de photos annotées pour les établir.
  static const double remoteLikely = 0.50;
  static const double remotePossible = 0.15;
}
