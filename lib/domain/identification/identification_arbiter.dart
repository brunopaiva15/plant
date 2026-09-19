import 'dart:io';

import '../../core/utils/scientific_name.dart';
import 'identification_policy.dart';
import 'plant_identifier.dart';

/// Ce qu'un arbitre distant peut conclure d'une photo qu'Iris n'a pas su
/// trancher.
enum ArbitrationOutcome {
  /// Une des candidates soumises correspond à la photo.
  picked,

  /// Aucune des candidates soumises ne correspond, ou la photo ne permet pas
  /// d'en désigner une. C'est une réponse, pas un échec : elle dit que la
  /// liste d'Iris est à côté, et que la recherche en ligne est le recours.
  none,

  /// La photo ne montre pas de plante. Un classifieur à N classes répond
  /// toujours quelque chose, même devant un chat (§ 3.2 de
  /// docs/09-plant-recognition.md) ; c'est le garde-fou qui manquait.
  notPlant,
}

/// L'avis de l'arbitre sur une liste de candidates.
///
/// Jamais une espèce libre : [scientificName] est forcément l'un des noms
/// soumis. Un nom hors catalogue n'aurait pas d'identifiant interne, donc pas
/// de fiche d'entretien ni de vignette — et la recherche en ensemble ouvert
/// est le travail de Pl@ntNet, pas le sien.
class Arbitration {
  const Arbitration({required this.outcome, this.scientificName, this.trait});

  const Arbitration.none()
      : outcome = ArbitrationOutcome.none,
        scientificName = null,
        trait = null;

  final ArbitrationOutcome outcome;

  /// Le nom retenu, tel qu'il a été soumis, quand [outcome] vaut
  /// [ArbitrationOutcome.picked].
  final String? scientificName;

  /// Le caractère visible qui a décidé — « fenestrations », « feuille
  /// charnue », « tige rouge ». C'est la seule chose de l'arbitrage qui
  /// s'affiche : un nom de plus sans raison ne vaut pas mieux qu'un score.
  final String? trait;
}

/// Un avis extérieur sur les candidates d'Iris, à partir de la même photo.
///
/// Ce n'est **pas** un identifiant de plus : l'ensemble est fermé, l'arbitre
/// choisit parmi ce qu'Iris a proposé ou ne choisit rien. Iris garde donc la
/// main sur ce que l'application sait nommer, et l'arbitre ne peut pas
/// inventer une espèce.
abstract class IdentificationArbiter {
  bool get isConfigured;

  /// Rend un avis, ou `null` si l'appel n'a rien donné — réseau, délai,
  /// réponse illisible. `null` n'est pas une opinion : l'appelant garde la
  /// liste d'Iris telle quelle.
  Future<Arbitration?> arbitrate({
    required List<File> images,
    required List<IdentificationCandidate> candidates,
    required String language,
  });
}

/// Pas d'arbitre : sans clé au build, l'identification reste entière.
class NoArbiter implements IdentificationArbiter {
  const NoArbiter();

  @override
  bool get isConfigured => false;

  @override
  Future<Arbitration?> arbitrate({
    required List<File> images,
    required List<IdentificationCandidate> candidates,
    required String language,
  }) async =>
      null;
}

/// Y a-t-il quelque chose à départager ?
///
/// Trois conditions, et elles disent toutes la même chose : ne payer que là
/// où le gain est possible.
///
/// - **Iris a répondu.** Une liste distante a déjà tranché, et une liste vide
///   n'offre rien à choisir.
/// - **Iris n'est pas sûr.** Une réponse acceptée est juste neuf fois sur dix
///   (`metrics.captive` de `assets/model/model.json`) : il n'y a rien à
///   gagner et tout à perdre à la faire réviser.
/// - **Il y a au moins deux candidates.** Arbitrer un ensemble d'un seul nom,
///   c'est demander une confirmation, pas un arbitrage.
bool worthArbitrating(FallbackPolicy policy, List<IdentificationCandidate> candidates) {
  if (candidates.length < 2) return false;
  final sorted = [...candidates]..sort((a, b) => b.score.compareTo(a.score));
  if (sorted.first.source != IdentificationSource.local) return false;
  return switch (policy.decide(candidates)) {
    IdentificationVerdict.plausible || IdentificationVerdict.uncertain => true,
    IdentificationVerdict.accepted || IdentificationVerdict.noCandidate => false,
  };
}

/// La candidate désignée par l'arbitre, retrouvée dans la liste soumise.
///
/// Le rapprochement passe par `normalizeScientificName`, comme partout
/// ailleurs : c'est ce qui garantit que la ligne affichée est bien une
/// candidate d'Iris, avec son score, son identifiant interne et sa vignette,
/// et non un nom revenu du réseau.
IdentificationCandidate? arbitratedCandidate(
  List<IdentificationCandidate> candidates,
  Arbitration? arbitration,
) {
  if (arbitration == null || arbitration.outcome != ArbitrationOutcome.picked) return null;
  final wanted = normalizeScientificName(arbitration.scientificName ?? '');
  if (wanted.isEmpty) return null;
  for (final c in candidates) {
    if (normalizeScientificName(c.scientificName) == wanted) return c;
  }
  // Un nom qu'on n'a pas soumis ne vaut rien, même s'il est plausible.
  return null;
}

/// Faut-il montrer l'arbitrage comme une réponse à part ?
///
/// Seulement quand il **déplace** la tête de liste. Un arbitre qui confirme
/// la première candidate d'Iris n'a rien à ajouter à l'écran : la ligne est
/// déjà là, en premier, et la répéter au-dessus inviterait à choisir deux
/// fois la même plante.
bool arbitrationLeads(List<IdentificationCandidate> candidates, Arbitration? arbitration) {
  final pick = arbitratedCandidate(candidates, arbitration);
  if (pick == null || candidates.isEmpty) return false;
  return normalizeScientificName(pick.scientificName) !=
      normalizeScientificName(candidates.first.scientificName);
}
