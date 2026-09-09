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
    this.acceptThreshold = 0.70,
    this.plausibleThreshold = 0.25,
    this.minMargin = 0.25,
    this.floor = 0.10,
  });

  /// Score minimal du premier candidat pour l'accepter sans discuter.
  ///
  /// **Un seuil ne se transporte pas d'un modèle à l'autre.** Il valait 0,70
  /// pour la v5, 0,60 pour la v6, et il **remonte à 0,70** avec Iris 7 —
  /// c'est la première fois. Mesuré sur les photos de plantes cultivées, dans
  /// le calcul exact que fait la cascade (`tools/plant_model/multi_photo.py`,
  /// listes de cinq candidats) :
  ///
  /// | seuil | une photo | deux photos |
  /// |---|---|---|
  /// | 0,80 | 40 % de réponses seules, 92,6 % justes | 30 %, 98,0 % |
  /// | **0,70** | **47 %, 85,9 %** | **35 %, 94,1 %** |
  /// | 0,60 | 53 %, 81,5 % | 41 %, 94,2 % |
  /// | 0,50 | 59 %, 76,3 % | 49 %, 93,9 % |
  ///
  /// Les deux versions précédentes avaient dépensé leur surplus de justesse
  /// en autonomie : plus sûres, elles pouvaient répondre plus souvent. Iris 7
  /// permet l'inverse, et c'est plus intéressant. **À 0,70 elle rend
  /// exactement l'autonomie qu'avait la v6 à 0,60 — 47 % — avec 85,9 % de
  /// justesse au lieu de 82,8 %.** L'utilisateur voit l'application trancher
  /// aussi souvent qu'avant, et elle se trompe trois points de moins.
  ///
  /// C'est la réponse acceptée qui coûte le plus cher à rater : elle
  /// s'affiche comme « probable », et c'est celle sur laquelle il ne se pose
  /// pas de question. Une liste seulement plausible, elle, est montrée avec
  /// ses cinq candidats et il tranche lui-même.
  ///
  /// Le gain est réel des deux côtés, pas un déplacement le long d'une
  /// courbe : sur les 1 439 espèces que les deux modèles connaissent, à
  /// images identiques, Iris 7 au seuil 0,70 accepte 46,8 % des photos contre
  /// 43 % pour la v6, et se trompe moins en le faisant (89,1 % contre
  /// 84,5 %).
  final double acceptThreshold;

  /// Au-dessus de ce score, la liste locale est montrée sans appel distant,
  /// avec la possibilité d'en demander un.
  final double plausibleThreshold;

  /// Écart minimal entre le premier et le deuxième score.
  ///
  /// Sans effet tant que [acceptThreshold] dépasse 0,625 : les scores d'un
  /// softmax somment à 1, donc un premier à 0,70 laisse au plus 0,30 au
  /// deuxième, soit une marge d'au moins 0,40. Elle avait failli mordre avec
  /// le 0,60 de la v6 ; le retour à 0,70 la remet au repos. Mesurée sur le
  /// jeu de test, elle ne changeait de toute façon quasiment rien à 0,60. On
  /// la garde parce qu'elle coûte zéro et qu'elle protège d'un modèle futur
  /// moins bien calibré.
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
