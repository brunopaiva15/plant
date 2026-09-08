import 'plant_identifier.dart';

/// Ce que la cascade conclut d'une liste de candidats.
enum IdentificationVerdict {
  /// Le premier candidat est assez sûr pour être proposé sans autre appel.
  accepted,

  /// La liste vaut la peine d'être montrée, sans être sûre. On l'affiche et
  /// on laisse l'utilisateur demander une recherche en ligne si aucune
  /// proposition ne lui convient — plutôt que de payer un appel d'avance
  /// pour une réponse dont il n'a peut-être pas besoin.
  plausible,

  /// Le modèle n'a rien reconnu : c'est là que le service distant sert
  /// vraiment, et l'appel se fait tout seul.
  uncertain,

  /// Rien d'exploitable : image hors sujet, modèle absent, liste vide.
  noCandidate,
}

/// Règle de décision entre le modèle local et le service distant.
///
/// Trois zones plutôt que deux. Le tout ou rien d'origine envoyait chez
/// Pl@ntNet 84 % des photos, y compris celles où le modèle proposait
/// justement la bonne espèce en tête sans en être certain. L'écran montre
/// cinq candidats et l'utilisateur choisit : une liste plausible lui est
/// utile telle quelle, et l'appel distant peut attendre qu'il le demande.
class FallbackPolicy {
  const FallbackPolicy({
    this.acceptThreshold = 0.60,
    this.plausibleThreshold = 0.25,
    this.minMargin = 0.25,
    this.floor = 0.10,
  });

  /// Score minimal du premier candidat pour l'accepter sans discuter.
  ///
  /// **Un seuil ne se transporte pas d'un modèle à l'autre.** Il valait 0,70
  /// pour la v5 et ses 894 espèces ; la v6 en compte 1 445, donc sa
  /// confiance se répartit sur plus de candidats et le même seuil la rendait
  /// trop prudente. Mesuré sur les photos de plantes cultivées du jeu de
  /// test de la v6, dans le calcul exact que fait la cascade
  /// (`tools/plant_model/multi_photo.py`) :
  ///
  /// | seuil | une photo | deux photos |
  /// |---|---|---|
  /// | 0,70 | 42 % de réponses seules, 86,0 % justes | 37 %, 93,1 % |
  /// | 0,60 | 47 %, 82,8 % | 43 %, 90,8 % |
  /// | 0,50 | 55 %, 74,3 % | 49 %, 85,9 % |
  ///
  /// À 0,60 la v6 cède trois points de justesse à une photo et en gagne cinq
  /// d'autonomie ; avec deux photos elle remonte à 90,8 %. C'est le même
  /// arbitrage qu'à la v5 : l'écran propose cinq candidats et l'utilisateur
  /// tranche, donc une première ligne parfois fausse coûte bien moins qu'un
  /// appel réseau systématique.
  ///
  /// Sur les seules espèces que les deux modèles connaissent, à images
  /// identiques, la v6 à 0,70 était déjà bien plus sûre que la v5 au même
  /// seuil (89,9 % contre 83,4 %) : abaisser le seuil dépense ce surplus en
  /// autonomie plutôt que de le laisser dormir.
  final double acceptThreshold;

  /// Au-dessus de ce score, la liste locale est montrée sans appel distant,
  /// avec la possibilité d'en demander un.
  final double plausibleThreshold;

  /// Écart minimal entre le premier et le deuxième score.
  ///
  /// Sans effet tant que [acceptThreshold] dépasse 0,625 : les scores d'un
  /// softmax somment à 1, donc un premier à 0,90 laisse au plus 0,10 au
  /// deuxième. Elle redevient active en dessous — mais, mesurée sur le jeu
  /// de test de la v6, elle n'y change quasiment rien : à 0,60 les chiffres
  /// sont identiques avec ou sans marge. On la garde parce qu'elle coûte
  /// zéro et qu'elle protège d'un modèle futur moins bien calibré.
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
    if (top >= plausibleThreshold) return IdentificationVerdict.plausible;
    return IdentificationVerdict.uncertain;
  }
}
