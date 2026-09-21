import '../../core/utils/search_text.dart';
import 'plant_problem.dart';

/// Un phénomène naturel : ce que la plante fait normalement et qu'on prend
/// pour un problème.
///
/// Des gouttes transparentes et collantes sous les feuilles d'un
/// philodendron sont du nectar extrafloral, pas du miellat de cochenilles ;
/// une vieille feuille du bas qui jaunit est une feuille qui finit, pas une
/// carence. Ces causes-là n'appellent aucun soin, et les ranger parmi les
/// troubles serait faux : ce ne sont ni des troubles, ni des ravageurs, ni
/// des maladies.
///
/// Comme la base des problèmes, l'entrée est nommée dans les quatre langues
/// et c'est l'identifiant qui circule : le service rend `N01`, l'application
/// affiche son nom. Deux analyses de la même chose se lisent pareil.
class NaturalCause {
  const NaturalCause({
    required this.id,
    required this.scope,
    required this.fr,
    required this.en,
    required this.it,
    required this.de,
    required this.hosts,
  });

  /// `N` suivi de deux chiffres : aucune confusion possible avec les trois
  /// chiffres d'un problème, ni dans la réponse du service, ni dans un
  /// compte rendu gardé au journal.
  final String id;

  final ProblemScope scope;
  final String fr;
  final String en;
  final String it;
  final String de;

  /// Les plantes qui le montrent, aux mêmes rangs que la base des problèmes :
  /// une espèce, un genre, une famille, ou `Tracheophyta` quand cela vaut
  /// pour toutes.
  final List<String> hosts;

  String nameIn(String languageCode) => switch (languageCode) {
        'en' => en,
        'it' => it,
        'de' => de,
        _ => fr,
      };

  /// Tout ce sous quoi l'entrée se cherche dans l'encyclopédie : le numéro,
  /// les quatre noms, les hôtes — comme un problème, moins les autres noms,
  /// que la base n'a pas.
  String get _searchIndex => foldSpeciesName([id, fr, en, it, de, ...hosts].join(' '));

  /// L'entrée répond-elle à cette recherche ? Même règle que pour un
  /// problème, [searchMatches] : les deux se cherchent dans la même liste.
  bool matches(String query) => searchMatches(_searchIndex, query);

  /// Ce phénomène peut-il concerner cette plante ? Posé large, comme pour un
  /// problème : il s'agit de dresser une liste de pistes, pas de trancher.
  bool affects({String? species, String? family}) => hostsCover(hosts, species: species, family: family);
}
