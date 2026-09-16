import '../../domain/care/care_guide.dart';
import 'care_profiles.dart';
import 'species_catalog.dart';
import 'toxicity_catalog.dart';

/// Fiches d'entretien issues du catalogue intégré.
///
/// Résolution du plus précis au plus général : espèce exacte, genre, famille,
/// catégorie d'usage, puis profil générique. Une plante inconnue du catalogue
/// hérite donc quand même d'une fiche crédible via son genre ou sa famille.
///
/// La toxicité suit sa propre cascade ([ToxicityCatalog]), à part du profil :
/// une espèce peut avoir une fiche d'entretien de famille et un fait de
/// toxicité de genre, sans que l'un mente sur l'autre.
class CatalogCareGuide implements CareGuide {
  const CatalogCareGuide();

  @override
  ResolvedCare resolve(String? scientificName, {String? family, String? categoryKey}) {
    final name = _normalize(scientificName);

    // Famille : celle fournie (GBIF), sinon celle du catalogue intégré.
    final entry = name == null ? null : SpeciesCatalog.find(name);
    final fam = _capitalize(family) ?? entry?.family;
    final toxicity = ToxicityCatalog.resolve(name, family: fam);

    if (name != null) {
      final exact = CareProfiles.bySpecies[name];
      if (exact != null) {
        return ResolvedCare(profile: exact, match: CareMatch.species, matchedOn: name, toxicity: toxicity);
      }

      final genus = genusOf(name);
      if (genus != null) {
        final byGenus = CareProfiles.byGenus[genus];
        if (byGenus != null) {
          return ResolvedCare(profile: byGenus, match: CareMatch.genus, matchedOn: genus, toxicity: toxicity);
        }
      }
    }

    if (fam != null) {
      final byFamily = CareProfiles.byFamily[fam];
      if (byFamily != null) {
        return ResolvedCare(profile: byFamily, match: CareMatch.family, matchedOn: fam, toxicity: toxicity);
      }
    }

    final cat = categoryKey ?? entry?.category.name;
    if (cat != null) {
      final byCategory = CareProfiles.byCategory[cat];
      if (byCategory != null) {
        return ResolvedCare(profile: byCategory, match: CareMatch.category, matchedOn: cat, toxicity: toxicity);
      }
    }

    return ResolvedCare(profile: CareProfiles.fallback, match: CareMatch.generic, toxicity: toxicity);
  }

  /// Genre d'un nom scientifique : « Ficus lyrata » → « Ficus ».
  /// Gère les hybrides (« Citrus × limon ») et les noms mal capitalisés.
  static String? genusOf(String scientificName) {
    final first = scientificName.trim().split(RegExp(r'\s+')).firstOrNull;
    if (first == null || first.isEmpty || first == '×') return null;
    return _capitalize(first);
  }

  /// Forme canonique d'un nom scientifique : genre capitalisé, épithète en
  /// minuscules (« FICUS LYRATA » comme « ficus lyrata » → « Ficus lyrata »).
  static String? _normalize(String? name) {
    final t = name?.trim();
    if (t == null || t.isEmpty) return null;
    final parts = t.split(RegExp(r'\s+'));
    if (parts.length == 1) return _capitalize(t);
    final epithet = parts.sublist(1).map((w) => w.toLowerCase()).join(' ');
    return '${_capitalize(parts.first)} $epithet';
  }

  static String? _capitalize(String? s) {
    final t = s?.trim();
    if (t == null || t.isEmpty) return null;
    return t[0].toUpperCase() + t.substring(1).toLowerCase();
  }
}
