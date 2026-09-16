import '../../domain/care/care_guide.dart';
import '../../domain/care/care_override.dart';
import 'care_override_store.dart';

/// Un guide qui applique les retouches de Care Studio par-dessus le catalogue.
///
/// La retouche se pose sur le nom demandé : c'est celui que le modérateur a
/// choisi, et c'est par lui que la fiche se retrouve. Les champs non retouchés
/// gardent la valeur du catalogue, et la provenance passe à [CareMatch.edited]
/// pour que la fiche ne fasse pas passer une retouche pour un fait d'espèce.
class OverriddenCareGuide implements CareGuide {
  const OverriddenCareGuide({required this.base, required this.overrides});

  final CareGuide base;
  final Map<String, CareOverride> overrides;

  @override
  ResolvedCare resolve(String? scientificName, {String? family, String? categoryKey}) {
    final care = base.resolve(scientificName, family: family, categoryKey: categoryKey);
    final name = scientificName?.trim();
    if (name == null || name.isEmpty) return care;
    final override = overrides[CareOverrideStore.keyOf(name)];
    if (override == null) return care;
    return ResolvedCare(
      profile: override.applyTo(care.profile),
      match: CareMatch.edited,
      matchedOn: care.matchedOn,
      toxicity: care.toxicity,
    );
  }
}
