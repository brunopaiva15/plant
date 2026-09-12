import '../care/care_guide.dart';
import '../care/care_profile.dart';
import 'species_info.dart';

/// Où la plante va vivre. La lumière décide de presque tout, donc la question
/// est posée en termes d'endroit plutôt qu'en lux.
enum FinderSpot { brightRoom, mediumRoom, darkRoom, outdoor }

/// Le soin qu'on est prêt à donner, dit honnêtement.
enum FinderEffort { forgiving, normal, attentive }

/// Ce qui fait qu'une espèce est proposée. Rendu tel quel par le moteur, la
/// couche l10n en fait une phrase.
enum FinderReason { light, lowLight, forgiving, easy, safe, outdoor }

/// Ce que l'utilisateur a répondu. Tout est facultatif : sans réponse, le
/// critère ne pèse simplement pas.
class FinderCriteria {
  const FinderCriteria({this.spot, this.effort, this.safeOnly = false, this.categories = const {}, this.note = ''});

  final FinderSpot? spot;
  final FinderEffort? effort;

  /// Animaux ou enfants : ne proposer que des espèces non toxiques.
  final bool safeOnly;

  /// Catégories voulues. Vide = toutes.
  final Set<SpeciesCategory> categories;

  /// Texte libre, utilisé seulement si l'utilisateur demande l'avis de l'IA.
  final String note;

  bool get isEmpty => spot == null && effort == null && !safeOnly && categories.isEmpty && note.trim().isEmpty;

  FinderCriteria copyWith({
    FinderSpot? Function()? spot,
    FinderEffort? Function()? effort,
    bool? safeOnly,
    Set<SpeciesCategory>? categories,
    String? note,
  }) =>
      FinderCriteria(
        spot: spot != null ? spot() : this.spot,
        effort: effort != null ? effort() : this.effort,
        safeOnly: safeOnly ?? this.safeOnly,
        categories: categories ?? this.categories,
        note: note ?? this.note,
      );

  /// Les critères en anglais, pour le prompt de l'IA. Déterministe, donc
  /// testable, et lisible dans les journaux de requête.
  String describe() {
    final parts = <String>[
      switch (spot) {
        FinderSpot.brightRoom => 'Spot: a bright indoor room, near a window.',
        FinderSpot.mediumRoom => 'Spot: an indoor room with medium light.',
        FinderSpot.darkRoom => 'Spot: a dark indoor corner, little daylight.',
        FinderSpot.outdoor => 'Spot: outdoors, on a balcony or in a garden.',
        null => '',
      },
      switch (effort) {
        FinderEffort.forgiving => 'Care: the owner often forgets to water; the plant must forgive neglect.',
        FinderEffort.normal => 'Care: regular watering, nothing demanding.',
        FinderEffort.attentive => 'Care: the owner enjoys fussing over plants and accepts a demanding species.',
        null => '',
      },
      if (safeOnly) 'Constraint: pets or children at home, only species that are non-toxic when chewed.',
      if (categories.isNotEmpty) 'Wanted kinds: ${categories.map((c) => c.name).join(', ')}.',
      if (note.trim().isNotEmpty) 'In their own words: ${note.trim()}',
    ];
    return parts.where((p) => p.isNotEmpty).join(' ');
  }
}

/// Une espèce proposée, avec sa fiche et ce qui la fait correspondre.
class FinderMatch {
  const FinderMatch({required this.entry, required this.care, required this.score, required this.reasons});

  final SpeciesCatalogEntry entry;
  final ResolvedCare care;

  /// 0 à 1. Sert au classement, pas à être affiché : un pourcentage donnerait
  /// une illusion de précision que ces critères n'ont pas.
  final double score;
  final List<FinderReason> reasons;
}

/// Choisit dans le catalogue intégré les espèces qui collent aux critères.
///
/// Tout se joue sur les fiches d'entretien déjà présentes dans l'application :
/// lumière, difficulté, arrosage, toxicité, tenue dehors. Aucun appel réseau,
/// donc une réponse immédiate et hors ligne — et chaque proposition arrive
/// avec sa fiche, prête à être ajoutée au jardin.
class PlantFinder {
  const PlantFinder({required this.entries, required this.guide});

  final List<SpeciesCatalogEntry> entries;
  final CareGuide guide;

  /// Sous ce score, une espèce n'est pas proposée : mieux vaut ne rien dire
  /// que de placer un cactus dans une salle de bain sombre.
  static const double minScore = 0.45;

  List<FinderMatch> search(FinderCriteria criteria, {int limit = 5}) {
    // Le rang dans le catalogue départage les scores égaux — et ils le sont
    // souvent. C'est une liste triée à la main, des espèces les plus
    // courantes vers les plus rares : un meilleur départage que l'alphabet,
    // qui remonterait les « A » et rien d'autre.
    final ranked = <(FinderMatch, int)>[];
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      if (criteria.categories.isNotEmpty && !criteria.categories.contains(entry.category)) continue;
      final care = guide.resolve(entry.scientificName, family: entry.family);
      final profile = care.profile;
      if (!_admissible(criteria, profile)) continue;
      final score = _score(criteria, profile);
      if (score < minScore) continue;
      ranked.add((FinderMatch(entry: entry, care: care, score: score, reasons: _reasons(criteria, profile)), i));
    }
    int better((FinderMatch, int) a, (FinderMatch, int) b) {
      final byScore = b.$1.score.compareTo(a.$1.score);
      return byScore != 0 ? byScore : a.$2.compareTo(b.$2);
    }

    ranked.sort(better);
    final picked = _diversify(ranked, limit)..sort(better);
    return [for (final entry in picked) entry.$1];
  }

  /// Ce qui disqualifie sans discussion : une promesse qu'on ne peut pas
  /// tenir (toxicité inconnue quand on demande du sans risque), une plante
  /// qui ne survivrait pas à l'endroit, ou qui demande trop pour qui oublie.
  ///
  /// La lumière tolère un cran d'écart, pas deux : une plante de lumière
  /// vive dans un coin sombre végète, et les autres réponses — un arrosage
  /// qu'on oublie, des animaux — ne la sauvent pas. Avec deux crans admis,
  /// « j'oublie d'arroser » suffisait à faire remonter un Gasteria dans un
  /// coin sombre, et sa fiche disait le contraire juste en dessous.
  bool _admissible(FinderCriteria c, CareProfile p) {
    if (c.safeOnly && p.toxicity != Toxicity.safe) return false;
    if (c.spot == FinderSpot.outdoor && !p.outdoorFriendly) return false;
    if (c.spot != null && (p.light.index - _targetLight(c.spot!).index).abs() > 1) return false;
    if (c.effort == FinderEffort.forgiving && (p.difficulty == CareDifficulty.demanding || p.humidity == HumidityNeed.high)) return false;
    return true;
  }

  double _score(FinderCriteria c, CareProfile p) {
    // Chaque critère répondu apporte son poids et sa note (0 à 1).
    final parts = <(double, double)>[
      if (c.spot != null) (0.55, _lightScore(p.light, _targetLight(c.spot!))),
      if (c.effort != null) (0.45, _effortScore(c.effort!, p)),
      // Prior d'aisance : à critères égaux, la plante la plus facile passe
      // devant. Poids volontairement faible, il ne décide jamais seul.
      (0.05, _easeScore(p)),
    ];
    final total = parts.fold(0.0, (sum, part) => sum + part.$1);
    return parts.fold(0.0, (sum, part) => sum + part.$1 * part.$2) / total;
  }

  static LightNeed _targetLight(FinderSpot spot) => switch (spot) {
        FinderSpot.brightRoom => LightNeed.brightIndirect,
        FinderSpot.mediumRoom => LightNeed.indirect,
        FinderSpot.darkRoom => LightNeed.lowLight,
        FinderSpot.outdoor => LightNeed.someSun,
      };

  static double _lightScore(LightNeed actual, LightNeed target) {
    final gap = (actual.index - target.index).abs();
    return gap >= 3 ? 0.0 : 1 - gap / 3;
  }

  static double _effortScore(FinderEffort effort, CareProfile p) {
    final byDifficulty = switch ((effort, p.difficulty)) {
      (FinderEffort.forgiving, CareDifficulty.easy) => 1.0,
      (FinderEffort.forgiving, _) => 0.5,
      (FinderEffort.normal, CareDifficulty.easy) => 1.0,
      (FinderEffort.normal, CareDifficulty.medium) => 0.85,
      (FinderEffort.normal, CareDifficulty.demanding) => 0.4,
      // Qui aime s'en occuper n'a rien contre une plante exigeante, et
      // s'ennuierait un peu avec la plus robuste des trois.
      (FinderEffort.attentive, CareDifficulty.easy) => 0.75,
      (FinderEffort.attentive, _) => 1.0,
    };
    if (effort != FinderEffort.forgiving) return byDifficulty;
    // Oublier d'arroser pardonne à qui boit peu.
    final tolerance = ((p.wateringSummerDays - 5) / 10).clamp(0.0, 1.0).toDouble();
    return byDifficulty * 0.6 + tolerance * 0.4;
  }

  static double _easeScore(CareProfile p) => switch (p.difficulty) {
        CareDifficulty.easy => 1.0,
        CareDifficulty.medium => 0.6,
        CareDifficulty.demanding => 0.2,
      };

  static List<FinderReason> _reasons(FinderCriteria c, CareProfile p) {
    final reasons = <FinderReason>[
      if (c.spot == FinderSpot.darkRoom && p.light.index <= LightNeed.indirect.index)
        FinderReason.lowLight
      else if (c.spot != null && (p.light.index - _targetLight(c.spot!).index).abs() <= 1)
        FinderReason.light,
      if (c.spot == FinderSpot.outdoor && p.outdoorFriendly) FinderReason.outdoor,
      if (c.effort == FinderEffort.forgiving && p.wateringSummerDays >= 10) FinderReason.forgiving,
      if (p.difficulty == CareDifficulty.easy) FinderReason.easy,
      if (c.safeOnly && p.toxicity == Toxicity.safe) FinderReason.safe,
    ];
    return reasons.take(3).toList();
  }

  /// Cinq Ficus ne sont pas cinq propositions. Un seul par genre d'abord,
  /// puis on complète si la liste est trop courte.
  static List<(FinderMatch, int)> _diversify(List<(FinderMatch, int)> ranked, int limit) {
    final picked = <(FinderMatch, int)>[];
    final genera = <String>{};
    for (final entry in ranked) {
      if (picked.length >= limit) break;
      if (genera.add(_genusOf(entry.$1.entry.scientificName))) picked.add(entry);
    }
    for (final entry in ranked) {
      if (picked.length >= limit) break;
      if (!picked.contains(entry)) picked.add(entry);
    }
    return picked;
  }

  static String _genusOf(String scientificName) => scientificName.trim().split(' ').first.toLowerCase();
}
