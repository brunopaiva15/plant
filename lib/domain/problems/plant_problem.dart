import '../../core/utils/search_text.dart';

/// Nature d'un problème, telle que la base la classe.
enum ProblemKind {
  /// Ni ravageur ni maladie : l'eau, la lumière, le froid, le substrat, une
  /// carence. La moitié de ce qu'on voit sur une plante en souffrance.
  disorder,
  pest,
  disease,

  /// Ni l'un ni l'autre : la fumagine pousse sur le miellat, sans s'attaquer
  /// à la plante. Une seule entrée, mais la ranger ailleurs serait faux.
  condition;

  static ProblemKind? parse(String raw) => switch (raw) {
        'ABIOTIQUE' => ProblemKind.disorder,
        'RAVAGEUR' => ProblemKind.pest,
        'MALADIE' => ProblemKind.disease,
        'AFFECTION' => ProblemKind.condition,
        _ => null,
      };
}

/// Étendue des hôtes, telle que la base la déclare.
enum ProblemScope {
  /// Toutes les plantes vasculaires, selon les conditions et le stade.
  general,

  /// Beaucoup d'hôtes ; les taxons cités sont des exemples.
  wide,

  /// Hôtes principaux d'un groupe cible.
  target;

  static ProblemScope? parse(String raw) => switch (raw) {
        'GENERAL' => ProblemScope.general,
        'LARGE' => ProblemScope.wide,
        'CIBLE' => ProblemScope.target,
        _ => null,
      };
}

/// Un problème de la base locale : un trouble, un ravageur ou une maladie,
/// nommé dans les quatre langues de l'application.
///
/// L'identifiant à trois chiffres est ce qui circule : l'IA le rend, l'app
/// affiche le nom de la base. C'est là tout l'intérêt d'avoir une base — deux
/// analyses de la même chose portent le même nom, dans la langue de
/// l'utilisateur, quelle que soit l'humeur du modèle ce jour-là.
class PlantProblem {
  const PlantProblem({
    required this.id,
    required this.kind,
    required this.scope,
    required this.fr,
    required this.en,
    required this.it,
    required this.de,
    required this.hosts,
    this.aliases = const [],
  });

  final String id;
  final ProblemKind kind;
  final ProblemScope scope;
  final String fr;
  final String en;
  final String it;
  final String de;

  /// Noms scientifiques des hôtes, à tous les rangs : une espèce
  /// (`Solanum lycopersicum`), un genre (`Rosa`), une famille
  /// (`Brassicaceae`), ou l'embranchement entier (`Tracheophyta`).
  final List<String> hosts;

  /// Les autres noms sous lesquels on cherche ce problème, toutes langues
  /// mêlées : les noms courants que la base n'a pas retenus comme titre
  /// (« araignée rouge » pour les tétranyques), et le nom scientifique du
  /// genre quand il est plus connu que le nom français (« Botrytis »).
  ///
  /// Ils ne s'affichent jamais : la base garde un seul nom par langue, pour
  /// que deux analyses de la même chose se lisent pareil. Ils ne servent
  /// qu'à retrouver l'entrée.
  final List<String> aliases;

  String nameIn(String languageCode) => switch (languageCode) {
        'en' => en,
        'it' => it,
        'de' => de,
        _ => fr,
      };

  /// Tout ce sous quoi l'entrée se cherche, normalisé une fois pour toutes :
  /// le numéro qui circule entre l'IA et l'application, les quatre noms, les
  /// autres noms, et les hôtes — « rosa » doit sortir ce qui touche les
  /// rosiers.
  ///
  /// Les quatre langues ensemble, et pas seulement celle qui est lue :
  /// « spider mites » tapé dans une application en français trouve la bonne
  /// entrée, et personne n'a à deviner comment la base a traduit.
  ///
  /// Reconstruit à chaque recherche : deux cents entrées de quelques mots
  /// pèsent moins que la liste qu'on redessine en même temps, et une entrée
  /// de la base reste constante.
  String get _searchIndex => foldSpeciesName([id, fr, en, it, de, ...aliases, ...hosts].join(' '));

  /// L'entrée répond-elle à cette recherche ?
  ///
  /// Mot à mot, et chaque mot en sous-chaîne : « araignée rouge » doit
  /// trouver « araignées rouges », « pourriture racinaire » les
  /// « pourritures racinaires », et l'ordre des mots ne doit pas compter.
  bool matches(String query) {
    final q = foldSpeciesName(query);
    if (q.isEmpty) return true;
    final index = _searchIndex;
    for (final word in q.split(RegExp(r'\s+'))) {
      if (word.isNotEmpty && !index.contains(word)) return false;
    }
    return true;
  }

  /// Ce problème peut-il concerner cette plante ?
  ///
  /// Question posée large, à dessein : il s'agit de dresser une liste de
  /// pistes à soumettre, pas de trancher. Un problème du genre vaut pour
  /// l'espèce, et l'inverse aussi — les hôtes cités sont des exemples, la
  /// base le dit elle-même.
  bool affects({String? species, String? family}) {
    final sp = _fold(species);
    final genus = sp.isEmpty ? '' : sp.split(' ').first;
    final fam = _fold(family);
    for (final host in hosts) {
      final h = _fold(host);
      if (h == 'tracheophyta') return true;
      if (h.isEmpty) continue;
      if (sp.isNotEmpty && (h == sp || h == genus)) return true;
      if (genus.isNotEmpty && h.startsWith('$genus ')) return true;
      if (fam.isNotEmpty && h == fam) return true;
    }
    return false;
  }

  static String _fold(String? name) => (name ?? '').trim().toLowerCase();
}
