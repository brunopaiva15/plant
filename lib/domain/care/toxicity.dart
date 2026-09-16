/// Toxicité d'une plante, et d'où l'application la tient.
///
/// C'est la donnée la plus sensible de la fiche : un « sans danger » se lit
/// comme une autorisation, et une espèce dangereuse n'a pas toujours de fiche
/// d'entretien complète. La toxicité vit donc à part des profils, pour qu'on
/// puisse l'écrire sans inventer un arrosage, une lumière et un substrat.
library;

/// Toxicité pour les animaux domestiques et les enfants.
enum Toxicity { safe, mild, toxic, unknown }

/// Niveau auquel un fait de toxicité a été trouvé, du plus précis au plus
/// général.
///
/// La famille et la catégorie ne peuvent dire que `toxic`, `mild` ou rien :
/// affirmer « sans danger » pour tout un groupe est le sens de l'erreur que
/// cette séparation corrige.
enum ToxicitySource { species, genus, family, none }

/// Ce que l'application sait de la toxicité d'une plante, et à quel niveau.
class ToxicityFact {
  const ToxicityFact({
    required this.status,
    required this.level,
    this.matchedOn,
    this.source,
  });

  /// Rien de renseigné : ni fait, ni provenance.
  const ToxicityFact.unknown()
      : status = Toxicity.unknown,
        level = ToxicitySource.none,
        matchedOn = null,
        source = null;

  final Toxicity status;

  final ToxicitySource level;

  /// Le nom sur lequel le fait a été trouvé (« Ficus », « Araceae »…).
  final String? matchedOn;

  /// La référence du fait, quand il en a une (« ASPCA », « CAPAE-Ouest »…).
  /// Renseigné pour les corrections vérifiées, à généraliser avec Care Studio.
  final String? source;

  /// Le fait vaut pour l'espèce ou son genre, pas pour un groupe plus large :
  /// c'est la condition d'une promesse « sans risque ».
  bool get isSpecific => level == ToxicitySource.species || level == ToxicitySource.genus;
}
