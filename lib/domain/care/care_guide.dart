import 'care_profile.dart';
import 'toxicity.dart';

/// Précision avec laquelle une fiche a été trouvée. Sert à être honnête dans
/// l'UI, où « Fiche de l'espèce » n'a pas la même valeur que « Fiche du
/// genre », ni qu'une fiche complétée par l'IA faute de mieux.
enum CareMatch { species, genus, family, category, generic, assisted, edited }

/// Fiche d'entretien retenue pour une plante, avec sa provenance.
class ResolvedCare {
  const ResolvedCare({
    required this.profile,
    required this.match,
    this.matchedOn,
    this.toxicity = const ToxicityFact.unknown(),
  });

  final CareProfile profile;
  final CareMatch match;

  /// Ce sur quoi la correspondance a été faite (« Ficus », « Araceae »…).
  final String? matchedOn;

  /// Le fait de toxicité, résolu à part des profils d'entretien : il porte son
  /// propre niveau et sa propre source, indépendamment de [match].
  final ToxicityFact toxicity;

  bool get isSpecific => match == CareMatch.species || match == CareMatch.genus;
}

/// Source de fiches d'entretien.
abstract class CareGuide {
  /// Fiche pour un nom scientifique. [family] affine la recherche quand le
  /// genre est inconnu du catalogue (par exemple une espèce venue de GBIF).
  ResolvedCare resolve(String? scientificName, {String? family, String? categoryKey});
}
