/// Le climat d'un lieu, réduit à ce qui décide du sort d'une plante laissée
/// dehors : la nuit la plus froide d'une année ordinaire, et le jour le plus
/// chaud.
///
/// Ces deux nombres viennent des années écoulées, pas de la semaine qui
/// vient : une gelée d'avril ne change pas une région, et c'est la région
/// qu'on cherche ici. Une moyenne des extrêmes annuels, donc, comme le font
/// les cartes de rusticité.
class RegionClimate {
  const RegionClimate({required this.winterLowC, required this.summerHighC, required this.years});

  /// Moyenne des minimums annuels (°C).
  final double winterLowC;

  /// Moyenne des maximums annuels (°C).
  final double summerHighC;

  /// Nombre d'années observées ; en dessous de deux, la valeur tient plus de
  /// l'anecdote que du climat.
  final int years;

  bool get isReliable => years >= 2;

  /// Zone de rusticité, graduation des cartes USDA : une zone couvre 10 °F
  /// de minimum hivernal, sa moitié basse est « a », sa moitié haute « b ».
  /// 1a commence à −60 °F, 13b s'arrête à 70 °F.
  ///
  /// Le degré Fahrenheit n'est pas un choix de goût : les zones sont nées
  /// dans cette unité, et les convertir en paliers ronds de °C décalerait
  /// toutes les bornes par rapport à ce que dit l'étiquette d'une pépinière.
  int get hardinessZone => _halfSteps ~/ 2 + 1;

  /// La moitié haute d'une zone : le « b » de « 8b ».
  bool get isUpperHalf => _halfSteps.isOdd;

  /// « 8a », tel qu'on le lit sur une étiquette.
  String get hardinessLabel => '$hardinessZone${isUpperHalf ? 'b' : 'a'}';

  int get _halfSteps {
    final fahrenheit = winterLowC * 9 / 5 + 32;
    return ((fahrenheit + 60) / 5).floor().clamp(0, 25);
  }

  /// Ce qu'une espèce risque à passer l'hiver ici, d'après le minimum que
  /// supporte sa fiche. Sans minimum connu, on ne tranche pas.
  RegionHardiness hardinessOf(int? minTempC) {
    if (minTempC == null) return RegionHardiness.unknown;
    if (minTempC <= winterLowC) return RegionHardiness.hardy;
    // Six degrés, c'est ce qu'un voile d'hivernage ou un mur exposé au sud
    // rattrapent ; au-delà, la plante passe l'hiver à l'intérieur.
    if (minTempC <= winterLowC + 6) return RegionHardiness.sheltered;
    return RegionHardiness.indoors;
  }

  /// L'été d'ici dépasse-t-il ce que l'espèce supporte ?
  bool suffersInSummer(int? idealTempMaxC) => idealTempMaxC != null && summerHighC > idealTempMaxC + 8;

  /// Le climat en anglais, pour le prompt de l'IA. Les coordonnées et le nom
  /// de la ville n'y sont pas : deux températures et une zone suffisent à
  /// dire la région, et elles ne désignent personne.
  String describe() => 'Climate: winter lows around ${winterLowC.round()} °C, summer highs around ${summerHighC.round()} °C '
      '(USDA hardiness zone $hardinessLabel).';

  /// Les extrêmes de chaque année observée, moyennés. Une année incomplète
  /// (celle qui court) fausserait le minimum : elle est écartée par
  /// l'appelant, qui seul sait où s'arrête la série.
  static RegionClimate? fromYearlyExtremes(Map<int, ({double low, double high})> byYear) {
    if (byYear.isEmpty) return null;
    final lows = byYear.values.map((e) => e.low);
    final highs = byYear.values.map((e) => e.high);
    return RegionClimate(
      winterLowC: lows.reduce((a, b) => a + b) / byYear.length,
      summerHighC: highs.reduce((a, b) => a + b) / byYear.length,
      years: byYear.length,
    );
  }
}

/// Ce qu'une espèce fait de l'hiver d'une région.
enum RegionHardiness {
  /// Elle le passe dehors sans rien.
  hardy,

  /// Elle le passe dehors protégée : voile, paillage, contre un mur.
  sheltered,

  /// Elle rentre.
  indoors,

  /// Sa fiche ne dit pas jusqu'où elle descend.
  unknown,
}
