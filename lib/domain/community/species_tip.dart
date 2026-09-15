/// Les conseils écrits par d'autres personnes sur une espèce.
///
/// Le catalogue intégré dit ce qu'une espèce demande ; il ne dit pas ce qu'on
/// apprend en la gardant trois ans dans une pièce donnée. Un conseil est
/// rattaché à l'espèce, pas à une plante : il se lit sur la fiche d'entretien
/// de n'importe quel exemplaire, et depuis l'encyclopédie, sans posséder la
/// plante.
library;

/// Longueur d'un conseil. Les mêmes bornes tiennent côté serveur
/// (`supabase/schema.sql`, contrainte `check` de `species_tips`) : un client
/// modifié ne fait pas passer un roman.
const int speciesTipMinLength = 10;
const int speciesTipMaxLength = 300;

/// Nombre de signalements après lequel un conseil n'est plus montré aux
/// autres. Le serveur en est seul juge ; la valeur est ici pour le texte qui
/// l'annonce.
const int speciesTipReportsToHide = 3;

/// Le texte d'un conseil ramené à ce qui peut partir : espaces repliés,
/// lignes vides multiples réduites à une. `null` quand il ne reste pas assez,
/// ou qu'il en reste trop.
String? cleanTipBody(String raw) {
  final body = raw
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .split('\n')
      .map((line) => line.trim())
      .join('\n')
      .trim();
  if (body.length < speciesTipMinLength || body.length > speciesTipMaxLength) return null;
  return body;
}

/// Un conseil publié sur une espèce.
class SpeciesTip {
  const SpeciesTip({
    required this.id,
    required this.speciesId,
    required this.authorName,
    required this.body,
    required this.votes,
    required this.createdAt,
    this.speciesName = '',
    this.mine = false,
    this.voted = false,
    this.hidden = false,
    this.reports = 0,
  });

  final String id;

  /// Clé interne de l'espèce (`hoya-kerrii`), celle qui relie une classe du
  /// modèle, un résultat Pl@ntNet et une entrée du catalogue.
  final String speciesId;

  /// Nom scientifique tel qu'il a été saisi. La lecture courante n'en a pas
  /// besoin — la fiche le porte déjà —, l'écran de modération si : il montre
  /// des conseils de toutes les espèces à la fois.
  final String speciesName;

  /// Nom d'affichage de l'auteur, tel que le serveur l'a joint. Vide quand le
  /// compte n'en porte pas : l'écran met alors son propre mot.
  final String authorName;
  final String body;

  /// Combien de personnes l'ont trouvé utile.
  final int votes;
  final DateTime createdAt;

  /// Écrit depuis ce compte : il s'ouvre en modification plutôt qu'en
  /// signalement.
  final bool mine;

  /// Déjà voté depuis ce compte.
  final bool voted;

  /// Signalé assez de fois pour ne plus paraître aux autres. Seul son auteur
  /// le reçoit encore, pour qu'il sache pourquoi il a disparu.
  final bool hidden;

  /// Combien de signalements pèsent sur lui. Zéro partout sauf sur l'écran de
  /// modération : ailleurs, le compte des signalements ne regarde personne.
  final int reports;

  /// L'ordre de lecture : le conseil qu'on a écrit d'abord — c'est le seul
  /// qu'on vient modifier —, puis les plus utiles, puis les plus récents.
  ///
  /// Le serveur trie déjà, mais un vote donné à l'instant déplace une carte
  /// sans que la liste reparte : le tri est refait ici sur ce qui est à
  /// l'écran.
  static int compare(SpeciesTip a, SpeciesTip b) {
    if (a.mine != b.mine) return a.mine ? -1 : 1;
    if (a.votes != b.votes) return b.votes.compareTo(a.votes);
    return b.createdAt.compareTo(a.createdAt);
  }

  static List<SpeciesTip> sorted(Iterable<SpeciesTip> tips) => [...tips]..sort(compare);
}

/// Les conseils de la communauté, côté domaine.
///
/// Rien de tout cela n'existe sans backend : [isAvailable] est faux, et la
/// section ne se dessine pas. Lire ne demande pas de compte — la clé anonyme
/// suffit —, écrire en demande un ([canPublish]).
abstract class CommunityTipsService {
  /// `false` quand aucun backend n'est configuré : l'UI masque la fonction.
  bool get isAvailable;

  /// `false` sans compte distant : la lecture reste ouverte, le bouton
  /// d'écriture laisse la place à la ligne qui dit pourquoi.
  bool get canPublish;

  /// Les conseils d'une espèce, les plus utiles d'abord.
  Future<List<SpeciesTip>> tips(String speciesId);

  /// Publie le conseil de ce compte sur cette espèce, ou remplace celui qui
  /// s'y trouve : une personne, un conseil par espèce.
  Future<SpeciesTip> publish({required String speciesId, required String speciesName, required String body});

  /// Retire son propre conseil.
  Future<void> withdraw(String tipId);

  /// Donne ou reprend sa voix ; renvoie le conseil avec son compte à jour.
  Future<SpeciesTip> vote(String tipId, {required bool helpful});

  /// Signale le conseil de quelqu'un d'autre.
  Future<void> report(String tipId);

  /// Ce compte modère-t-il ? La réponse vient du serveur : la liste des
  /// modérateurs est une table que rien ne laisse écrire depuis l'application
  /// — un drapeau posé sur son propre profil se donnerait à soi-même.
  Future<bool> isModerator();

  /// Les conseils signalés, les plus signalés d'abord. Vide pour qui ne
  /// modère pas.
  Future<List<SpeciesTip>> reported();

  /// Masque un conseil, ou le rétablit — ce qui efface ses signalements.
  Future<void> moderate(String tipId, {required bool hidden});

  /// Retire un conseil pour de bon.
  Future<void> remove(String tipId);
}
