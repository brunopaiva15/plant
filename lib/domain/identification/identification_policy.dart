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
  /// Mesuré sur le jeu de test du modèle v4 (10 582 images, 846 espèces),
  /// et surtout sur ses 1 384 photos de plantes cultivées, celles que les
  /// utilisateurs prennent : à 0,90 le modèle ne répond seul que dans 41 %
  /// des cas ; à 0,70 il le fait dans 57 %, avec 83 % de justesse sur ces
  /// réponses au lieu de 92 %. Comme l'écran propose cinq candidats et que
  /// l'utilisateur tranche, une première ligne parfois fausse coûte bien
  /// moins qu'un appel réseau systématique.
  final double acceptThreshold;

  /// Au-dessus de ce score, la liste locale est montrée sans appel distant,
  /// avec la possibilité d'en demander un.
  final double plausibleThreshold;

  /// Écart minimal entre le premier et le deuxième score.
  ///
  /// Sans effet tant que [acceptThreshold] dépasse 0,625 : les scores d'un
  /// softmax somment à 1, donc un premier à 0,90 laisse au plus 0,10 au
  /// deuxième. À 0,70 la règle redevient active et écarte les cas où le
  /// modèle hésite entre deux espèces proches.
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
