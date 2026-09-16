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

/// Le rapport de l'espèce à l'air qui bouge.
///
/// Renseigné seulement quand la fiche le sait : `null` dans [CareProfile.airflow]
/// signifie « non renseigné », et rien ne se dit alors sur l'air — un silence
/// n'est pas un avis, il ne devient jamais « éviter les courants d'air ».
enum AirflowPreference {
  /// Elle craint les courants d'air froids : fougères, calathéas, croton.
  sheltered,

  /// L'air ordinaire d'une pièce lui convient.
  normal,

  /// Elle aime l'air brassé : agrumes, plantes de plein vent.
  ventilated,
}

/// Comment on tient l'humidité de l'air, quand le mot ne suffit pas.
///
/// La brumisation n'est pas la réponse à tout : elle mouille la feuille
/// quelques minutes et, sur un feuillage qui reste humide, ouvre la porte aux
/// taches. Le plateau et l'humidificateur tiennent l'air dans la durée ; le
/// terrarium est pour ce qu'on cultive sous verre.
enum HumidityMethod {
  /// Brumiser le feuillage : les plantes qui boivent par leurs feuilles.
  mist,

  /// Un humidificateur d'air, pour une pièce sèche.
  humidifier,

  /// Un plateau de billes d'argile humides, ou des plantes regroupées.
  tray,

  /// Sous verre : terrarium, cloche, bocal.
  terrarium,
}

/// Jusqu'où laisser sécher le substrat avant d'arroser.
///
/// C'est la règle botanique ; l'intervalle en jours n'en est qu'une
/// estimation, qui dépend aussi du pot, de la pièce et de la saison.
enum DryDown {
  /// Il ne doit jamais sécher : tourbières, plantes d'eau, fougères.
  alwaysMoist,

  /// On attend que la surface sèche.
  surfaceDry,

  /// On attend que le quart supérieur sèche.
  topQuarterDry,

  /// On attend que la moitié du pot sèche.
  halfDry,

  /// On attend que le substrat soit presque sec.
  mostlyDry,

  /// On attend qu'il soit entièrement sec : cactus, succulentes.
  fullyDry,
}

/// Une première lecture d'un intervalle d'arrosage, en attendant une règle
/// écrite à la main : plus on arrose souvent, moins le substrat doit sécher.
DryDown dryDownFromDays(int days) => switch (days) {
      <= 2 => DryDown.alwaysMoist,
      <= 4 => DryDown.surfaceDry,
      <= 7 => DryDown.topQuarterDry,
      <= 13 => DryDown.halfDry,
      <= 24 => DryDown.mostlyDry,
      _ => DryDown.fullyDry,
    };

/// Difficulté d'entretien.
enum CareDifficulty { easy, medium, demanding }

/// Type de substrat conseillé.
enum SoilKind { standard, draining, cactus, orchid, acidic, rich, none }

/// Milieu de vie de la plante : où poussent ses racines, ou d'où elle tire son
/// eau quand elle n'en a pas en terre. Séparé du substrat, qui lui dit ce
/// qu'on met dans le pot : une tillandsie est épiphyte et sans substrat, un
/// nymphéa aquatique et sans substrat — « sans substrat » ne dit pas la même
/// chose pour l'une et pour l'autre.
enum GrowthMedium { terrestrial, epiphytic, lithophytic, aquatic, semiAquatic }

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

/// Ce que l'espèce supporte des sels de l'eau d'arrosage — calcaire, fluor,
/// sodium.
///
/// - [tolerant] : l'eau du robinet lui convient, sa dureté n'y change rien.
/// - [sensitive] : le calcaire et le fluor s'accumulent et brunissent les
///   pointes ; l'eau de pluie ou filtrée lui va mieux.
/// - [strict] : le calcaire l'abîme, même en petite quantité — plantes de
///   terre acide, carnivores, broméliacées épiphytes.
enum WaterTolerance { tolerant, sensitive, strict }

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
///
/// `water` n'en est pas une : c'est un milieu d'enracinement, écrit dans la
/// même liste depuis les premières fiches. Les fiches déjà enregistrées le
/// gardent ; [CareProfile.propagationMethods] et [CareProfile.rootingMedium]
/// séparent les deux notions sans toucher aux données.
enum Propagation { stemCutting, leafCutting, division, offsets, layering, seed, water, tuber }

/// Où une bouture prend racine.
///
/// `none` vaut pour les plantes qu'on divise ou dont on sépare un rejet :
/// le fragment a déjà ses racines, il n'y a rien à enraciner.
enum RootingMedium { water, substrate, either, none }

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
    this.dryDown,
    required this.light,
    required this.humidity,
    required this.difficulty,
    required this.soil,
    this.growthMedium = GrowthMedium.terrestrial,
    this.humidityIdealMin,
    this.humidityIdealMax,
    this.humidityToleratedMin,
    this.water = WaterTolerance.tolerant,
    this.fluorideSensitive = false,
    this.fertilizingDays,
    this.fertilizingWindow = const MonthWindow(3, 9),
    this.fertilizer,
    this.calcium,
    this.waterCulture,
    this.ponCulture,
    this.repotEveryMonths,
    this.pot = PotPreference.steady,
    this.damageBelowC,
    this.survivalMinC,
    this.idealTempMinC,
    this.idealTempMaxC,
    this.propagation = const [],
    this.issues = const [],
    this.support,
    this.humidityMethods = const {},
    this.dormantInWinter = true,
    this.outdoorFriendly = false,
    this.airflow,
    this.bloom,
    this.dormancy,
    this.tipKeys = const [],
    this.source,
  });

  /// Jours entre deux arrosages en pleine croissance.
  final int wateringSummerDays;

  /// Jours entre deux arrosages au repos (hiver).
  final int wateringWinterDays;

  /// La règle de séchage, quand elle est écrite à la main. `null` = on la lit
  /// dans l'intervalle d'arrosage (voir [dryDownRule]).
  final DryDown? dryDown;

  final LightNeed light;
  final HumidityNeed humidity;
  final CareDifficulty difficulty;
  final SoilKind soil;

  /// Où vit la plante : en terre pour la plupart, sur un support ou dans l'eau
  /// pour les autres. Le substrat dit quoi mettre dans le pot ; ceci dit si
  /// elle y pousse.
  final GrowthMedium growthMedium;

  /// La plage d'hygrométrie que l'espèce préfère, quand elle demande plus
  /// précis que sa catégorie. `null` des deux côtés = la plage du besoin suffit.
  final int? humidityIdealMin;
  final int? humidityIdealMax;

  /// Le plancher sous lequel elle souffre du sec : son minimum toléré, quand
  /// on le connaît. `null` = on lit une marge sous le bas de sa plage idéale,
  /// car préférer 60 % n'est pas souffrir sous 60 %.
  final int? humidityToleratedMin;

  /// La marge, en points, entre le bas de la plage idéale et le plancher
  /// toléré quand celui-ci n'est pas renseigné.
  static const int humidityTolerance = 15;

  /// Tolérance au calcaire. La valeur par défaut est celle du plus
  /// grand nombre : une plante ordinaire boit l'eau du robinet.
  final WaterTolerance water;

  /// Le fluor du réseau lui brunit les pointes. C'est un axe à part du
  /// calcaire : un dracæna boit volontiers l'eau du robinet et brunit pourtant
  /// au fluor, qu'une carafe ne retire pas.
  final bool fluorideSensitive;

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

  /// Seuil sous lequel le froid abîme la plante (« éviter sous »), minimum de
  /// survie absolue quand il est connu, et plage idéale.
  ///
  /// Deux seuils et non un : une plante abîmée à 5 °C ne meurt pas pour
  /// autant, et l'ancien champ unique `minTempC` mélangeait les deux.
  final int? damageBelowC;
  final int? survivalMinC;
  final int? idealTempMinC;
  final int? idealTempMaxC;

  final List<Propagation> propagation;
  final List<CommonIssue> issues;

  /// Le support que l'espèce demande, quand elle en demande un.
  final PlantSupport? support;

  /// Les moyens de tenir l'humidité de l'air, quand un mot ne suffit pas :
  /// brumiser le feuillage, poser un humidificateur ou un plateau, cultiver
  /// sous verre. Vide pour la plupart des plantes — l'air ordinaire convient.
  final Set<HumidityMethod> humidityMethods;

  /// Ralentit nettement en hiver (repos végétatif).
  final bool dormantInWinter;

  /// Peut passer l'été dehors, voire y rester.
  final bool outdoorFriendly;

  /// Son rapport à l'air qui bouge, quand la fiche le sait. `null` = non
  /// renseigné : la scène d'environnement ne montre alors rien qui touche à
  /// l'air, plutôt qu'un conseil inventé.
  final AirflowPreference? airflow;

  /// Sa floraison : la saison, et ce qui la décide. `null` = plante de
  /// feuillage, ou floraison qu'on ne cherche pas à provoquer.
  final Bloom? bloom;

  /// Son repos à feuillage disparu, pour les plantes à réserves. `null` = elle
  /// garde ses feuilles toute l'année.
  final DormantRest? dormancy;

  /// Clés de conseils libres, résolues par la couche i18n.
  final List<String> tipKeys;

  /// La référence consultée quand la fiche a été revue (« RHS », « ASPCA »…).
  /// `null` = fiche estimée, pas encore confrontée à une source : c'est le cas
  /// de la plupart des profils de genre, déduits de leur famille.
  final String? source;

  /// Plage d'hygrométrie idéale à viser, en pourcentage : celle de l'espèce
  /// quand elle est renseignée, sinon celle de son besoin.
  (int, int) get humidityRange {
    final base = humidityPercentRange(humidity);
    return (humidityIdealMin ?? base.$1, humidityIdealMax ?? base.$2);
  }

  /// Le plancher sous lequel elle souffre du sec, en pourcentage : son minimum
  /// toléré, à défaut [humidityTolerance] points sous le bas de l'idéal.
  int get humidityFloor => humidityToleratedMin ?? (humidityRange.$1 - humidityTolerance);

  /// Le plafond au-dessus duquel une pièce est trop humide pour elle : le haut
  /// de sa plage idéale, plus la même marge que le plancher.
  int get humidityCeiling => humidityRange.$2 + humidityTolerance;

  /// La règle de séchage du substrat. La règle écrite l'emporte ; à défaut,
  /// on lit une estimation dans l'intervalle d'arrosage.
  DryDown get dryDownRule {
    if (dryDown case final rule?) return rule;
    final active = wateringSummerDays <= wateringWinterDays ? wateringSummerDays : wateringWinterDays;
    return dryDownFromDays(active);
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

  /// Les méthodes de multiplication, le milieu d'enracinement mis à part.
  List<Propagation> get propagationMethods => [
        for (final p in propagation)
          if (p != Propagation.water) p,
      ];

  /// Où la bouture prend racine. Une succulente pourrit dans l'eau ; une
  /// liane y va aussi bien qu'en terre ; une division n'a rien à enraciner.
  RootingMedium get rootingMedium {
    final bouture = propagationMethods.any((m) => m == Propagation.stemCutting || m == Propagation.leafCutting);
    if (!bouture) return RootingMedium.none;
    if (soil == SoilKind.cactus) return RootingMedium.substrate;
    return propagation.contains(Propagation.water) ? RootingMedium.water : RootingMedium.either;
  }

  /// L'engrais est-il utile ce mois-ci ?
  bool fertilizesIn(int month, {bool south = false}) {
    if (fertilizingDays == null) return false;
    final m = south ? (month + 6 - 1) % 12 + 1 : month;
    return fertilizingWindow.contains(m);
  }

  /// Le seuil sous lequel le froid abîme la plante : son seuil de dégâts, à
  /// défaut le bas de sa plage idéale. C'est lui qu'une alerte météo regarde.
  int? get coldLimitC => damageBelowC ?? idealTempMinC;

  /// Le froid qui décide de l'hiver : la survie quand elle est connue, sinon
  /// le seuil de dégâts. Une plante abîmée à 5 °C peut survivre plus bas ;
  /// sans donnée de survie, on ne le suppose pas.
  int? get winterMinC => survivalMinC ?? damageBelowC;

  /// Elle tient le gel, donc elle vit dehors en pleine terre : ni culture
  /// hors-sol ni serre à lui proposer. La rusticité se lit sur [winterMinC],
  /// pas sur le seuil de dégâts — une plante abîmée par le gel n'en meurt pas
  /// forcément.
  bool get frostHardy => (winterMinC ?? 10) <= 0;

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
      switch (growthMedium) {
        GrowthMedium.aquatic => SoilFreeFit.yes,
        _ when frostHardy => SoilFreeFit.no,
        _ when propagation.contains(Propagation.water) => SoilFreeFit.cuttings,
        _ => SoilFreeFit.no,
      };

  /// Se mène-t-elle en pon ?
  ///
  /// Les billes inertes conviennent à presque toutes les plantes en pot ;
  /// elles ne conviennent pas à la terre de bruyère, dont elles remontent le
  /// pH, ni à ce qui vit dehors ou ne fait qu'une saison.
  SoilFreeFit get inPon {
    if (ponCulture case final fit?) return fit;
    if (soil == SoilKind.acidic || growthMedium == GrowthMedium.aquatic) return SoilFreeFit.no;
    return potGrown ? SoilFreeFit.yes : SoilFreeFit.no;
  }

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
