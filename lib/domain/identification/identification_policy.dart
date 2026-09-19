import '../../core/utils/scientific_name.dart';
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

  /// Le modèle a des candidats, mais trop faibles pour être plausibles.
  /// Ils restent visibles afin qu'une seconde photo puisse les départager.
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
    this.localMayAffirm = true,
    this.contextMargin = 0.15,
  });

  /// La même règle, pour une photo prise à un emplacement **extérieur**.
  ///
  /// Le modèle embarqué n'expose que des plantes d'intérieur (§ 13.3 de
  /// `docs/09`), et mesuré sur 40 photos de plantes hors catalogue il en
  /// **affirme 27,5 %** au-dessus du seuil et avec la marge — une plante de
  /// jardin forcée dans une liste d'appartement, sans que rien ne s'y oppose
  /// (§ 12.7). Ni le seuil, ni la marge, ni le repli ne voient cette
  /// erreur-là : elle est confiante.
  ///
  /// Dehors, Iris propose donc au lieu d'affirmer. Ce n'est pas une
  /// interdiction — `docs/14` § 8 est explicite, le contexte donne un a
  /// priori, jamais une interdiction : les candidates restent toutes
  /// affichées, le genre répond toujours, et la seconde photo est proposée
  /// puisque la réponse n'est plus tenue pour sûre.
  FallbackPolicy outdoors() => FallbackPolicy(
        acceptThreshold: acceptThreshold,
        plausibleThreshold: plausibleThreshold,
        minMargin: minMargin,
        floor: floor,
        localMayAffirm: false,
        contextMargin: contextMargin,
      );

  /// Score minimal du premier candidat pour l'accepter sans discuter.
  ///
  /// **Un seuil ne se transporte pas d'un modèle à l'autre.** Il valait 0,70
  /// pour la v5, 0,60 pour la v6, et il **est remonté à 0,70** avec Iris 7 —
  /// c'était la première fois. L'Iris 8 l'a gardé tel quel : au même seuil il
  /// est à la fois plus autonome et plus juste, si bien qu'il n'y avait rien
  /// à arbitrer (§ 6.7 bis de docs/09). Ce que le couple (seuil, marge) rend
  /// sur le modèle livré n'est pas recopié ici : `assets/model/model.json`
  /// le porte, pour chaque couple, et c'est lui qui fait foi.
  ///
  /// Le recalage d'Iris 7, mesuré sur les photos de plantes cultivées dans
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
  /// a permis l'inverse, et c'est plus intéressant. **À 0,70 elle rendait
  /// exactement l'autonomie qu'avait la v6 à 0,60 — 47 % — avec 85,9 % de
  /// justesse au lieu de 82,8 %.** L'utilisateur voit l'application trancher
  /// aussi souvent qu'avant, et elle se trompe trois points de moins.
  ///
  /// C'est la réponse acceptée qui coûte le plus cher à rater : elle
  /// s'affiche comme « probable », et c'est celle sur laquelle il ne se pose
  /// pas de question. Une liste seulement plausible, elle, est montrée avec
  /// ses cinq candidats et il tranche lui-même.
  ///
  /// Le gain était réel des deux côtés, pas un déplacement le long d'une
  /// courbe : sur les 1 439 espèces que les deux modèles connaissaient, à
  /// images identiques, Iris 7 au seuil 0,70 acceptait 46,8 % des photos
  /// contre 43 % pour la v6, et se trompait moins en le faisant (89,1 %
  /// contre 84,5 %). Iris 8 a repris le même mouvement au même seuil.
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

  /// Si le modèle embarqué a le droit d'affirmer seul, sans réserve.
  ///
  /// Vrai partout sauf à un emplacement extérieur, où [outdoors] le retire.
  /// Une réponse **distante** n'est jamais concernée : elle a déjà tranché,
  /// et elle connaît des dizaines de milliers d'espèces plutôt que les
  /// quelques centaines d'un spécialiste d'intérieur.
  final bool localMayAffirm;

  /// De combien un candidat **hors du lieu** doit dépasser le meilleur
  /// candidat du lieu, sur l'échelle globale, pour être proposé quand même.
  ///
  /// C'est la moitié applicative de la règle du § 8 de `docs/14` : le
  /// contexte donne un a priori, jamais une interdiction. Sans elle, masquer
  /// reviendrait à rendre la bonne réponse impossible — un monstera sur un
  /// balcon en été n'est pas un cas rare, et le § 3.2 décrit exactement cette
  /// panne, un modèle qui répond faux avec assurance parce qu'il ne peut pas
  /// répondre juste.
  ///
  /// La valeur n'est pas mesurée : elle attend la tête de l'Iris 9 et les
  /// mesures du § 14.4 de `docs/09`. Quinze points d'écart, c'est ce qu'il
  /// faut pour qu'un candidat écarté par le lieu reprenne la parole sans
  /// couvrir la réponse du lieu à chaque hésitation.
  final double contextMargin;

  IdentificationVerdict decide(List<IdentificationCandidate> candidates) {
    if (candidates.isEmpty) return IdentificationVerdict.noCandidate;
    final verdict = _decideAmong(inContext(candidates));
    if (verdict == IdentificationVerdict.accepted) return verdict;
    // Le lieu n'a pas tranché. Un candidat d'ailleurs, nettement plus fort
    // sur l'échelle globale, vaut d'être montré — plutôt que de laisser la
    // cascade remplacer la liste par un appel distant.
    if (verdict.index > IdentificationVerdict.plausible.index && challenger(candidates) != null) {
      return IdentificationVerdict.plausible;
    }
    return verdict;
  }

  IdentificationVerdict _decideAmong(List<IdentificationCandidate> candidates) {
    if (candidates.isEmpty) return IdentificationVerdict.noCandidate;
    final sorted = [...candidates]..sort((a, b) => b.score.compareTo(a.score));
    final top = sorted.first.score;
    if (top < floor) return IdentificationVerdict.noCandidate;
    final second = sorted.length > 1 ? sorted[1].score : 0.0;
    if (top >= acceptThreshold && top - second >= minMargin) {
      final fromDevice = sorted.first.source == IdentificationSource.local;
      if (!fromDevice || localMayAffirm) return IdentificationVerdict.accepted;
      // Dehors : la liste vaut toujours d'être montrée, mais pas d'être
      // présentée comme sûre.
      return IdentificationVerdict.plausible;
    }
    if (top >= plausibleThreshold) return IdentificationVerdict.plausible;
    return IdentificationVerdict.uncertain;
  }

  /// Le meilleur candidat hors du lieu, s'il mérite d'être proposé.
  ///
  /// La comparaison se fait sur [IdentificationCandidate.globalScore] et pas
  /// sur le score affiché : deux scores renormalisés sur deux ensembles
  /// différents ne se comparent pas, les scores globaux si (§ 14.1 de
  /// `docs/09`). Rend `null` quand le modèle n'a pas de masque — tous les
  /// candidats sont alors dans le contexte.
  IdentificationCandidate? challenger(List<IdentificationCandidate> candidates) {
    IdentificationCandidate? best;
    var inside = 0.0;
    for (final c in candidates) {
      if (c.inContext) {
        if (c.globalScore > inside) inside = c.globalScore;
      } else if (best == null || c.globalScore > best.globalScore) {
        best = c;
      }
    }
    if (best == null || best.globalScore < floor) return null;
    return best.globalScore - inside >= contextMargin ? best : null;
  }
}

/// Les candidats que le lieu attendait.
///
/// Quand aucun ne l'est — modèle sans masque, ou lieu qui n'explique rien —
/// la liste entière est rendue : une réponse hors contexte reste une
/// réponse, et la juger sur rien reviendrait à n'en donner aucune.
List<IdentificationCandidate> inContext(List<IdentificationCandidate> candidates) {
  final kept = [for (final c in candidates) if (c.inContext) c];
  return kept.isEmpty ? candidates : kept;
}

/// Ce que l'écran d'identification propose comme photo supplémentaire.
///
/// Une seconde photo est un recours gratuit et hors ligne : elle n'est
/// proposée que lorsque la réponse locale n'est pas assez sûre.
enum SecondPhotoOffer {
  /// Rien : la réponse ne vient pas du modèle embarqué, la liste est vide,
  /// ou le maximum de photos est atteint.
  none,

  /// En évidence, avec sa phrase d'explication. Le modèle hésite, et la
  /// photo est le geste qui tranche : deux photos valent **13,7 points de
  /// top-1**, plus que dix heures de calcul et 160 000 images (§ 6.6).
  prominent,
}

/// Comment proposer la photo suivante, s'il faut la proposer.
///
/// La décision vit ici plutôt que dans les deux écrans qui s'en servent :
/// elle est la même pour la fiche d'identification et pour la création de
/// plante, et un seuil recopié dans une vue finit toujours par diverger de
/// celui de la cascade.
SecondPhotoOffer secondPhotoOffer(
  FallbackPolicy policy,
  List<IdentificationCandidate> candidates, {
  required int photos,
  required int maxPhotos,
}) {
  if (candidates.isEmpty || photos >= maxPhotos) return SecondPhotoOffer.none;
  // Une réponse du service distant est déjà la meilleure disponible : une
  // photo de plus ne la rejouerait pas sans un nouvel appel, donc sans
  // entamer le quota. Ce n'est plus le même geste gratuit.
  if (candidates.first.source != IdentificationSource.local) return SecondPhotoOffer.none;
  return policy.decide(candidates) == IdentificationVerdict.accepted
      ? SecondPhotoOffer.none
      : SecondPhotoOffer.prominent;
}

/// Le genre que le modèle désigne quand il n'ose aucune espèce.
class GenusAnswer {
  const GenusAnswer({required this.genus, required this.mass, required this.species,
      this.source = IdentificationSource.local});

  /// Le nom du genre, « Picea ».
  final String genus;

  /// La somme des scores de ses espèces. C'est elle qui passe le seuil.
  final double mass;

  /// Combien d'espèces de ce genre la réponse recouvre. Jamais une seule :
  /// sa masse serait son score, et elle n'aurait pas passé le seuil.
  final int species;

  /// D'où viennent les candidates sommées — toujours l'appareil, la cascade
  /// ne proposant le genre que sur une réponse locale.
  final IdentificationSource source;
}

/// Le genre à proposer, ou `null` s'il n'y a rien à en dire.
///
/// Cinq *Picea* à 0,15 pèsent 0,75 : « un Picea, espèce incertaine » est une
/// réponse **vraie**, là où cinq noms n'en sont pas une et où l'utilisateur
/// n'a d'autre recours que de chercher en ligne ou de choisir au hasard — ce
/// qui inscrirait une espèce fausse, et son profil de soin avec.
///
/// **L'espèce garde la priorité** : le genre ne parle que là où elle
/// renonçait, c'est un gain net et jamais un remplacement. Et seulement sur
/// une réponse locale : une réponse distante a déjà tranché.
///
/// Mesuré sur l'Iris 8 (§ 12.15) : le genre répond sur 6,6 % des photos en
/// pot que l'espèce n'accepte pas, et il a raison 88,7 % du temps — presque
/// aussi souvent qu'une réponse à l'espèce.
GenusAnswer? genusAnswer(FallbackPolicy policy, List<IdentificationCandidate> candidates) {
  if (candidates.isEmpty) return null;
  // Sommer les scores d'un genre suppose qu'ils sont sur la même échelle :
  // les candidats du lieu sont renormalisés entre eux, ceux d'ailleurs ne le
  // sont pas. On ne mélange donc pas les deux dans une même masse.
  final sorted = [...inContext(candidates)]..sort((a, b) => b.score.compareTo(a.score));
  if (sorted.first.source != IdentificationSource.local) return null;
  // « L'espèce garde la priorité » veut dire : là où elle a répondu. Dehors
  // elle n'a pas le droit d'affirmer, donc elle n'a pas répondu, et le genre
  // reprend son rôle — c'est même là qu'il sert le plus, « un érable, espèce
  // incertaine » étant exactement ce qu'on peut dire d'une plante de jardin.
  if (policy.decide(sorted) == IdentificationVerdict.accepted) return null;

  final masses = <String, double>{};
  final counts = <String, int>{};
  for (final c in sorted) {
    final g = genusOf(c.scientificName);
    if (g.isEmpty) continue;
    masses[g] = (masses[g] ?? 0) + c.score;
    counts[g] = (counts[g] ?? 0) + 1;
  }
  if (masses.isEmpty) return null;
  final best = masses.entries.reduce((a, b) => b.value > a.value ? b : a);
  if (best.value < policy.acceptThreshold) return null;
  // Un genre d'une seule espèce n'est pas une réponse de genre : sa masse
  // *est* le score de l'espèce, et la nommer « genre » ne ferait que
  // rhabiller une réponse d'espèce. La garde était implicite tant que
  // l'espèce répondait toujours au-dessus du seuil ; dehors elle n'a plus le
  // droit, et il faut l'écrire.
  if (counts[best.key]! < 2) return null;
  return GenusAnswer(genus: best.key, mass: best.value, species: counts[best.key]!);
}
