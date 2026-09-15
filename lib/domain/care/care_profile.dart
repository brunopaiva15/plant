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
///
/// Le mot suffit pour poser un pot dans un salon ; sous serre ou en vitrine,
/// c'est un pourcentage qui se règle, d'où [humidityPercentRange].
enum HumidityNeed { low, average, high }

/// Plage d'hygrométrie tenue par un besoin, en pourcentage. Une fiche peut la
/// resserrer pour son espèce : entre deux plantes « qui aiment l'air humide »,
/// l'anthurium tient à 60 % et l'adiante en demande 80.
(int, int) humidityPercentRange(HumidityNeed need) => switch (need) {
      HumidityNeed.low => (30, 50),
      HumidityNeed.average => (40, 60),
      HumidityNeed.high => (60, 80),
    };

/// Difficulté d'entretien.
enum CareDifficulty { easy, medium, demanding }

/// Toxicité pour les animaux et les enfants.
enum Toxicity { safe, mild, toxic, unknown }

/// Type de substrat conseillé.
enum SoilKind { standard, draining, cactus, orchid, acidic, rich, aquatic }

/// Rapport d'une plante à son pot.
///
/// Il décide de ce que veut dire une racine qui sort par le trou de drainage :
/// signal de rempotage pour l'une, état normal pour l'autre. Le phalaenopsis
/// et le spathiphyllum fleurissent d'être à l'étroit ; le monstera s'arrête
/// dès que ses racines tournent au fond.
enum PotPreference {
  /// À l'étroit, et mieux ainsi : un pot trop grand la fait bouder.
  snug,

  /// Rempotage quand la motte est prise.
  steady,

  /// De la place, sans quoi la croissance s'arrête.
  roomy,
}

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

  /// La même fenêtre vue de l'autre hémisphère, décalée de six mois : la
  /// saison de croissance d'un jardin de Sydney tombe quand celle d'un jardin
  /// de Lyon s'arrête.
  MonthWindow forHemisphere({bool south = false}) => south ? MonthWindow(_mirror(from), _mirror(to)) : this;

  static int _mirror(int month) => (month + 5) % 12 + 1;
}

/// Ce que l'espèce donne comme fleurs, et à quelles conditions.
///
/// Une fiche sans floraison ne dit rien : la plante se tient pour son
/// feuillage, et la question ne se pose pas.
class Bloom {
  const Bloom({required this.window, this.triggerKeys = const [], this.indoors = true});

  /// Mois de floraison, hémisphère nord.
  final MonthWindow window;

  /// Ce qu'il faut réunir pour l'obtenir : une clé par condition, résolue par
  /// la couche i18n comme les conseils.
  final List<String> triggerKeys;

  /// Elle fleurit en pot, dans une pièce. Faux pour celles qui ne fleurissent
  /// qu'en pleine terre, ou après des années dehors.
  final bool indoors;
}

/// Repos à feuillage disparu.
///
/// Le crocus, le caladium ou le cyclamen ne meurent pas quand leurs feuilles
/// jaunissent : ils rentrent entièrement dans leur bulbe, leur tubercule ou
/// leur rhizome, qui attend au sec l'année suivante. Sans ce passage, rien ne
/// repart — d'où la plage de température et l'obscurité, qui sont des gestes,
/// pas des symptômes.
class DormantRest {
  const DormantRest({required this.window, this.storeMinC, this.storeMaxC, this.dark = true});

  /// Mois de sommeil, hémisphère nord. La reprise vient juste après.
  final MonthWindow window;

  /// Où garder l'organe de réserve, en degrés.
  final int? storeMinC;
  final int? storeMaxC;

  /// À l'obscurité. Faux pour celles qui passent leur repos en pleine lumière,
  /// comme le cyclamen au frais sous un arbre.
  final bool dark;
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
    this.humidityMinPercent,
    this.humidityMaxPercent,
    this.fertilizingDays,
    this.fertilizingWindow = const MonthWindow(3, 9),
    this.repotEveryMonths,
    this.pot = PotPreference.steady,
    this.minTempC,
    this.idealTempMinC,
    this.idealTempMaxC,
    this.toxicity = Toxicity.unknown,
    this.propagation = const [],
    this.issues = const [],
    this.mistLeaves = false,
    this.dormantInWinter = true,
    this.outdoorFriendly = false,
    this.bloom,
    this.dormancy,
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

  /// Hygrométrie en pourcentage, quand l'espèce demande plus précis que sa
  /// catégorie. `null` des deux côtés = la plage du besoin suffit.
  final int? humidityMinPercent;
  final int? humidityMaxPercent;

  /// Jours entre deux apports d'engrais pendant [fertilizingWindow].
  /// `null` = pas d'engrais utile.
  final int? fertilizingDays;
  final MonthWindow fertilizingWindow;

  /// Mois entre deux rempotages. `null` = rempotage non pertinent (annuelles).
  final int? repotEveryMonths;

  /// Ce qu'une racine qui sort du pot veut dire pour cette espèce.
  final PotPreference pot;

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

  /// Sa floraison, quand elle en a une qui se provoque. `null` = plante de
  /// feuillage, la question ne se pose pas.
  final Bloom? bloom;

  /// Son repos à feuillage disparu, pour les plantes à réserves. `null` = elle
  /// garde ses feuilles toute l'année.
  final DormantRest? dormancy;

  /// Clés de conseils libres, résolues par la couche i18n.
  final List<String> tipKeys;

  /// Plage d'hygrométrie à viser, en pourcentage : celle de l'espèce quand
  /// elle est renseignée, sinon celle de son besoin.
  (int, int) get humidityRange {
    final base = humidityPercentRange(humidity);
    return (humidityMinPercent ?? base.$1, humidityMaxPercent ?? base.$2);
  }

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
