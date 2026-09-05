import 'plant_identifier.dart';

/// Ce que la cascade conclut d'une liste de candidats.
enum IdentificationVerdict {
  /// Le premier candidat est assez sûr pour être proposé sans autre appel.
  accepted,

  /// Il y a des candidats, mais pas assez de marge : on consulte le repli.
  uncertain,

  /// Rien d'exploitable : image hors sujet, modèle absent, liste vide.
  noCandidate,
}

/// Règle de décision entre le modèle local et le service distant.
///
/// Deux conditions, toutes deux nécessaires : le meilleur score dépasse le
/// seuil, et il distance assez le deuxième. Un modèle hésitant entre deux
/// Monstera à 0,91 et 0,89 n'a rien décidé — c'est le cas typique où le
/// service distant, plus large, tranche mieux.
class FallbackPolicy {
  const FallbackPolicy({this.acceptThreshold = 0.90, this.minMargin = 0.25, this.floor = 0.10});

  /// Score minimal du premier candidat pour l'accepter seul. Valeur de
  /// départ volontairement prudente : elle se recale sur le jeu de test
  /// une fois le modèle entraîné (voir docs/09-plant-recognition.md).
  final double acceptThreshold;

  /// Écart minimal entre le premier et le deuxième score.
  final double minMargin;

  /// Sous ce score, un candidat ne compte même pas comme « incertain » :
  /// c'est la réponse d'un modèle à qui l'on montre un chat.
  final double floor;

  IdentificationVerdict decide(List<IdentificationCandidate> candidates) {
    if (candidates.isEmpty) return IdentificationVerdict.noCandidate;
    final sorted = [...candidates]..sort((a, b) => b.score.compareTo(a.score));
    final top = sorted.first.score;
    if (top < floor) return IdentificationVerdict.noCandidate;
    final second = sorted.length > 1 ? sorted[1].score : 0.0;
    if (top >= acceptThreshold && top - second >= minMargin) return IdentificationVerdict.accepted;
    return IdentificationVerdict.uncertain;
  }
}
