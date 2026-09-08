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

  String nameIn(String languageCode) => switch (languageCode) {
        'en' => en,
        'it' => it,
        'de' => de,
        _ => fr,
      };

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
