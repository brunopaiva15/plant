import '../problems/plant_problem.dart';

/// Besoin en lumière, du plus sombre au plus ensoleillé.
enum LightNeed { shade, lowLight, indirect, brightIndirect, someSun, fullSun }

/// Lumière réelle d'un emplacement, depuis le code stocké sur celui-ci
/// (`high`, `medium`, `low`) : une plante au soleil boit plus vite que ce que
/// dit la fiche de son espèce.
LightNeed? lightNeedFromCode(String? code) => switch (code) {
      'high' => LightNeed.someSun,
      'medium' => LightNeed.brightIndirect,
      'low' => LightNeed.lowLight,
      _ => null,
    };

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
///
/// Chaque entrée dit de quelle famille elle relève — un trouble, un ravageur,
/// une maladie —, la même que celle de la base des deux cents problèmes. La
/// liste d'une espèce se range alors d'elle-même : ce qui vient de l'eau et
/// de la lumière d'abord, les bêtes ensuite, les champignons en dernier.
enum CommonIssue {
  overwatering(ProblemKind.disorder),
  underwatering(ProblemKind.disorder),
  rootRot(ProblemKind.disease),
  spiderMites(ProblemKind.pest),
  thrips(ProblemKind.pest),
  mealybugs(ProblemKind.pest),
  scale(ProblemKind.pest),
  aphids(ProblemKind.pest),
  fungusGnats(ProblemKind.pest),
  whitefly(ProblemKind.pest),
  trueBugs(ProblemKind.pest),
  slugs(ProblemKind.pest),
  powderyMildew(ProblemKind.disease),
  greyMould(ProblemKind.disease),
  leafSpot(ProblemKind.disease),
  blight(ProblemKind.disease),
  sunburn(ProblemKind.disorder),
  dryTips(ProblemKind.disorder),
  leafDrop(ProblemKind.disorder),
  etiolation(ProblemKind.disorder),
  chlorosis(ProblemKind.disorder),
  blossomEndRot(ProblemKind.disorder);

  const CommonIssue(this.kind);

  final ProblemKind kind;
}

/// Ce qui tient une plante debout, quand elle ne le fait pas seule.
///
/// Renseigné pour les espèces où le support change quelque chose : une
/// grimpante à racines aériennes ne fait ses grandes feuilles qu'en montant,
/// une tomate casse sans tuteur. Ailleurs, `null` — et la fiche n'en parle
/// pas plutôt que de dire « aucun ».
enum PlantSupport {
  /// Tuteur moussu, en sphaigne ou en fibre de coco : les racines aériennes
  /// s'y accrochent, à condition qu'il reste humide.
  mossPole,

  /// Tuteur droit, auquel la tige s'attache à mesure qu'elle monte.
  stake,

  /// Treillis, fil ou grillage, le long duquel les tiges se guident.
  trellis,
}

/// Fenêtre de mois (1–12), bornes incluses. Peut traverser l'hiver
/// (`from > to`, par exemple novembre → février).
class MonthWindow {
  const MonthWindow(this.from, this.to);

  final int from;
  final int to;

  bool contains(int month) => from <= to ? month >= from && month <= to : month >= from || month <= to;

  /// La même fenêtre vue de l'autre hémisphère, décalée de six mois : la
  /// saison de croissance d'un jardin de Sydney tombe quand celle d'un jardin
  /// de Lyon s'arrête.
  MonthWindow forHemisphere({bool south = false}) => south ? MonthWindow(_mirror(from), _mirror(to)) : this;

  static int _mirror(int month) => (month + 5) % 12 + 1;
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
    this.support,
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

  /// Le support que l'espèce demande, quand elle en demande un.
  final PlantSupport? support;

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
