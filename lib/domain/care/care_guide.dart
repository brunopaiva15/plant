import 'care_profile.dart';

/// Précision avec laquelle une fiche a été trouvée. Sert à être honnête dans
/// l'UI : « Fiche de l'espèce » n'a pas la même valeur que « Fiche du genre ».
enum CareMatch { species, genus, family, category, generic }

/// Fiche d'entretien retenue pour une plante, avec sa provenance.
class ResolvedCare {
  const ResolvedCare({required this.profile, required this.match, this.matchedOn});

  final CareProfile profile;
  final CareMatch match;

  /// Ce sur quoi la correspondance a été faite (« Ficus », « Araceae »…).
  final String? matchedOn;

  bool get isSpecific => match == CareMatch.species || match == CareMatch.genus;
}

/// Source de fiches d'entretien.
abstract class CareGuide {
  /// Fiche pour un nom scientifique. [family] affine la recherche quand le
  /// genre est inconnu du catalogue (par exemple une espèce venue de GBIF).
  ResolvedCare resolve(String? scientificName, {String? family, String? categoryKey});
}
