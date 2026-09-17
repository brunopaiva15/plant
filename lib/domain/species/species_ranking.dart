import '../../core/utils/search_text.dart';

/// Rangs de pertinence d'une espèce pour une requête, du plus évident au
/// plus lointain. Plus le rang est petit, plus haut remonte l'espèce.
abstract final class SpeciesRank {
  /// Le nom courant de la langue de l'application est la requête.
  static const int exact = 0;

  /// Il commence par la requête.
  static const int prefix = 1;

  /// Il contient la requête, sans être un début.
  static const int commonContains = 2;

  /// Le nom scientifique contient la requête.
  static const int scientific = 3;

  /// La famille contient la requête.
  static const int family = 4;

  /// Un autre nom — synonyme ou nom d'une autre langue — contient la requête.
  static const int other = 5;

  /// Aucune correspondance.
  static const int none = 6;
}

/// Classe une espèce par rapport à une requête.
///
/// L'ordre suit la préférence d'Auxine : le nom courant de la langue de
/// l'application d'abord, puis le nom scientifique, puis la famille, puis
/// les autres noms. C'est ce qui fait remonter « Orchidée papillon »
/// (Phalaenopsis amabilis) avant les orchidées obscures anglophones.
///
/// [commonName] est le nom vernaculaire dans la langue de l'application,
/// `null` quand l'espèce n'en a pas. [otherNames] porte les synonymes et les
/// noms des autres langues, qui restent cherchables mais passent après.
int speciesRelevance(
  String query, {
  String? commonName,
  required String scientificName,
  String? family,
  Iterable<String> otherNames = const [],
}) {
  final q = foldSpeciesName(query.trim());
  if (q.isEmpty) return SpeciesRank.none;

  if (commonName != null) {
    final common = foldSpeciesName(commonName);
    if (common == q) return SpeciesRank.exact;
    if (common.startsWith(q)) return SpeciesRank.prefix;
    if (common.contains(q)) return SpeciesRank.commonContains;
  }
  if (foldSpeciesName(scientificName).contains(q)) return SpeciesRank.scientific;
  if (family != null && foldSpeciesName(family).contains(q)) return SpeciesRank.family;
  for (final name in otherNames) {
    if (foldSpeciesName(name).contains(q)) return SpeciesRank.other;
  }
  return SpeciesRank.none;
}
