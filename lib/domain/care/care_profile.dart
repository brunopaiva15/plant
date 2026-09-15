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

/// Ce qu'une plante accepte hors du terreau : l'eau claire d'un vase, ou le
/// pon (billes inertes — pouzzolane, zéolithe, pierre ponce — arrosées d'une
/// solution nutritive).
enum SoilFreeFit {
  /// Elle n'y tient pas.
  no,

  /// Le temps d'une bouture, pas d'une vie.
  cuttings,

  /// Elle y vit durablement.
  yes,
}

/// Type d'engrais à privilégier.
enum FertilizerKind { balanced, foliage, flowering, cactus, orchid, acidic, citrus, vegetable }

/// Le calcium : celui que l'eau du robinet apporte déjà, celui qu'il faut
/// ajouter, celui qu'il faut éviter.
enum CalciumNeed { avoid, neutral, welcome, needed }

/// Ce qui décide une plante à fleurir, quand c'est le but qu'on se donne.
///
/// Les six premiers sont des conditions à réunir avant les boutons ; les
/// suivants sont des gestes, pendant la formation ou après la fleur. Une
/// espèce en demande souvent plusieurs, d'où la liste dans [Bloom].
enum BloomTrigger {
  coolRest,
  coolNights,
  shortDays,
  drySpell,
  potbound,
  brightLight,
  chillBulb,
  fertilizer,
  maturity,
  deadhead,
  keepSpike,
  noMove,
  evenWater,
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
  const Bloom({required this.window, this.triggers = const [], this.indoors = true});

  /// Mois de floraison, hémisphère nord.
  final MonthWindow window;

  /// Ce qu'il faut réunir pour l'obtenir. Une seule condition pour la
  /// plupart ; un phalaenopsis en demande trois.
  final List<BloomTrigger> triggers;

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
    this.fertilizer,
    this.calcium,
    this.waterCulture,
    this.ponCulture,
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

  /// Engrais à privilégier, quand le substrat ne suffit pas à le dire : un
  /// agrume et un ficus poussent tous deux en terreau, pas avec le même
  /// engrais. `null` = celui que [fertilizerKind] déduit.
  final FertilizerKind? fertilizer;

  /// Rapport au calcium, quand il ne se déduit pas du substrat.
  /// `null` = celui que [calciumNeed] déduit.
  final CalciumNeed? calcium;

  /// Culture dans l'eau claire, quand elle ne se déduit pas du reste de la
  /// fiche. `null` = celle que [inWater] déduit.
  final SoilFreeFit? waterCulture;

  /// Culture en pon, même règle : `null` = celle que [inPon] déduit.
  final SoilFreeFit? ponCulture;

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

  /// Sa floraison : la saison, et ce qui la décide. `null` = plante de
  /// feuillage, ou floraison qu'on ne cherche pas à provoquer.
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

  /// Elle tient le gel, donc elle vit dehors en pleine terre : ni culture
  /// hors-sol ni serre à lui proposer.
  bool get frostHardy => (minTempC ?? 10) <= 0;

  /// Elle vit en pot toute l'année : c'est la condition du hors-sol, qu'une
  /// culture annuelle (semée, récoltée, arrachée) ne remplit pas.
  bool get potGrown => repotEveryMonths != null && !frostHardy;

  /// Vit-elle durablement dans l'eau claire ?
  ///
  /// Beaucoup de plantes d'intérieur y font des racines le temps d'une
  /// bouture sans y tenir des années : les deux cas ne se disent pas de la
  /// même façon. Les espèces qui y vivent vraiment le déclarent.
  SoilFreeFit get inWater =>
      waterCulture ??
      switch (soil) {
        SoilKind.aquatic => SoilFreeFit.yes,
        _ when frostHardy => SoilFreeFit.no,
        _ when propagation.contains(Propagation.water) => SoilFreeFit.cuttings,
        _ => SoilFreeFit.no,
      };

  /// Se mène-t-elle en pon ?
  ///
  /// Les billes inertes conviennent à presque toutes les plantes en pot ;
  /// elles ne conviennent pas à la terre de bruyère, dont elles remontent le
  /// pH, ni à ce qui vit dehors ou ne fait qu'une saison.
  SoilFreeFit get inPon =>
      ponCulture ??
      switch (soil) {
        SoilKind.acidic || SoilKind.aquatic => SoilFreeFit.no,
        _ when potGrown => SoilFreeFit.yes,
        _ => SoilFreeFit.no,
      };

  /// Engrais à privilégier. `null` quand la plante ne se fertilise pas.
  FertilizerKind? get fertilizerKind {
    if (fertilizingDays == null) return null;
    if (fertilizer case final f?) return f;
    if (issues.contains(CommonIssue.blossomEndRot)) return FertilizerKind.vegetable;
    return switch (soil) {
      SoilKind.cactus => FertilizerKind.cactus,
      SoilKind.orchid => FertilizerKind.orchid,
      SoilKind.acidic => FertilizerKind.acidic,
      _ => FertilizerKind.balanced,
    };
  }

  /// Ce que le calcium lui fait. Une plante de terre de bruyère jaunit à
  /// l'eau calcaire ; un légume-fruit sujet à la nécrose apicale en réclame.
  CalciumNeed get calciumNeed =>
      calcium ??
      switch (soil) {
        SoilKind.acidic => CalciumNeed.avoid,
        _ when issues.contains(CommonIssue.blossomEndRot) => CalciumNeed.needed,
        SoilKind.cactus => CalciumNeed.welcome,
        _ => CalciumNeed.neutral,
      };

  /// Une serre, une mini-serre ou une véranda ont-elles quelque chose à lui
  /// apporter ? Une plante qui passe l'hiver dehors n'en a pas l'usage.
  bool get benefitsFromGreenhouse => !frostHardy;
}
