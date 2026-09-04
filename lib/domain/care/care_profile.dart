/// Besoin en lumière, du plus sombre au plus ensoleillé.
enum LightNeed { shade, lowLight, indirect, brightIndirect, someSun, fullSun }

/// Besoin en humidité de l'air.
enum HumidityNeed { low, average, high }

/// Difficulté d'entretien.
enum CareDifficulty { easy, medium, demanding }

/// Toxicité pour les animaux et les enfants.
enum Toxicity { safe, mild, toxic, unknown }

/// Type de substrat conseillé.
enum SoilKind { standard, draining, cactus, orchid, acidic, rich, aquatic }

/// Méthode de multiplication.
enum Propagation { stemCutting, leafCutting, division, offsets, layering, seed, water, tuber }

/// Problème fréquent, pour la section « À surveiller ».
enum CommonIssue {
  overwatering,
  underwatering,
  rootRot,
  spiderMites,
  mealybugs,
  scale,
  aphids,
  fungusGnats,
  whitefly,
  slugs,
  powderyMildew,
  leafSpot,
  blight,
  sunburn,
  dryTips,
  leafDrop,
  etiolation,
  chlorosis,
  blossomEndRot,
}

/// Fenêtre de mois (1–12), bornes incluses. Peut traverser l'hiver
/// (`from > to`, par exemple novembre → février).
class MonthWindow {
  const MonthWindow(this.from, this.to);

  final int from;
  final int to;

  bool contains(int month) => from <= to ? month >= from && month <= to : month >= from || month <= to;
}

/// Fiche d'entretien d'une espèce : quand arroser, quelle lumière, quel
/// substrat, à quelle fréquence rempoter, ce qu'il faut surveiller.
///
/// Les intervalles d'arrosage sont donnés pour la pleine saison et pour le
/// repos hivernal ; [wateringDaysFor] interpole selon le mois et la lumière.
class CareProfile {
  const CareProfile({
    required this.wateringSummerDays,
    required this.wateringWinterDays,
    required this.light,
    required this.humidity,
    required this.difficulty,
    required this.soil,
    this.fertilizingDays,
    this.fertilizingWindow = const MonthWindow(3, 9),
    this.repotEveryMonths,
    this.minTempC,
    this.idealTempMinC,
    this.idealTempMaxC,
    this.toxicity = Toxicity.unknown,
    this.propagation = const [],
    this.issues = const [],
    this.mistLeaves = false,
    this.dormantInWinter = true,
    this.outdoorFriendly = false,
    this.tipKeys = const [],
  });

  /// Jours entre deux arrosages en pleine croissance.
  final int wateringSummerDays;

  /// Jours entre deux arrosages au repos (hiver).
  final int wateringWinterDays;

  final LightNeed light;
  final HumidityNeed humidity;
  final CareDifficulty difficulty;
  final SoilKind soil;

  /// Jours entre deux apports d'engrais pendant [fertilizingWindow].
  /// `null` = pas d'engrais utile.
  final int? fertilizingDays;
  final MonthWindow fertilizingWindow;

  /// Mois entre deux rempotages. `null` = rempotage non pertinent (annuelles).
  final int? repotEveryMonths;

  /// Température minimale supportée, et plage idéale.
  final int? minTempC;
  final int? idealTempMinC;
  final int? idealTempMaxC;

  final Toxicity toxicity;
  final List<Propagation> propagation;
  final List<CommonIssue> issues;

  /// Brumiser le feuillage aide (plantes tropicales).
  final bool mistLeaves;

  /// Ralentit nettement en hiver (repos végétatif).
  final bool dormantInWinter;

  /// Peut passer l'été dehors, voire y rester.
  final bool outdoorFriendly;

  /// Clés de conseils libres, résolues par la couche i18n.
  final List<String> tipKeys;

  /// Intervalle d'arrosage conseillé pour un mois donné, ajusté par la
  /// lumière réelle de l'emplacement (une plante en pleine lumière boit plus).
  ///
  /// [month] : 1–12, hémisphère nord. [south] inverse les saisons.
  int wateringDaysFor(int month, {bool south = false, LightNeed? actualLight}) {
    final m = south ? (month + 6 - 1) % 12 + 1 : month;
    // Poids saisonnier : 0 en plein été, 1 au cœur de l'hiver.
    final winterness = switch (m) {
      6 || 7 || 8 => 0.0,
      5 || 9 => 0.25,
      4 || 10 => 0.5,
      3 || 11 => 0.75,
      _ => 1.0,
    };
    final base = wateringSummerDays + (wateringWinterDays - wateringSummerDays) * winterness;
    final adjusted = switch (actualLight) {
      LightNeed.fullSun || LightNeed.someSun => base * 0.85,
      LightNeed.shade || LightNeed.lowLight => base * 1.2,
      _ => base,
    };
    return adjusted.round().clamp(1, 120);
  }

  /// L'engrais est-il utile ce mois-ci ?
  bool fertilizesIn(int month, {bool south = false}) {
    if (fertilizingDays == null) return false;
    final m = south ? (month + 6 - 1) % 12 + 1 : month;
    return fertilizingWindow.contains(m);
  }
}
