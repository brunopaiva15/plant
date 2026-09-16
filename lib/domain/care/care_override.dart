import 'care_profile.dart';

/// Une retouche humaine d'une fiche d'entretien, rangée par espèce.
///
/// Care Studio n'édite pas le catalogue compilé : il pose une retouche, que la
/// résolution applique par-dessus. Chaque champ renseigné l'emporte ; les
/// autres gardent la valeur du catalogue — et l'absence de retouche sur un
/// champ n'est pas la même chose qu'une retouche qui vaudrait la valeur par
/// défaut.
///
/// Le noyau est volontairement court : ce sont les champs qu'un modérateur
/// regarde et corrige à la main. Il grandit quand le besoin se présente.
class CareOverride {
  const CareOverride({
    this.light,
    this.humidity,
    this.difficulty,
    this.wateringSummerDays,
    this.wateringWinterDays,
    this.damageBelowC,
  });

  final LightNeed? light;
  final HumidityNeed? humidity;
  final CareDifficulty? difficulty;

  /// Jours entre deux arrosages, en pleine saison et au repos.
  final int? wateringSummerDays;
  final int? wateringWinterDays;

  /// Seuil de dégâts du froid.
  final int? damageBelowC;

  bool get isEmpty =>
      light == null &&
      humidity == null &&
      difficulty == null &&
      wateringSummerDays == null &&
      wateringWinterDays == null &&
      damageBelowC == null;

  /// La fiche du catalogue, les champs retouchés à la place des siens.
  CareProfile applyTo(CareProfile base) => CareProfile(
        wateringSummerDays: wateringSummerDays ?? base.wateringSummerDays,
        wateringWinterDays: wateringWinterDays ?? base.wateringWinterDays,
        dryDown: base.dryDown,
        light: light ?? base.light,
        humidity: humidity ?? base.humidity,
        difficulty: difficulty ?? base.difficulty,
        soil: base.soil,
        growthMedium: base.growthMedium,
        humidityIdealMin: base.humidityIdealMin,
        humidityIdealMax: base.humidityIdealMax,
        humidityToleratedMin: base.humidityToleratedMin,
        water: base.water,
        fluorideSensitive: base.fluorideSensitive,
        fertilizingDays: base.fertilizingDays,
        fertilizingWindow: base.fertilizingWindow,
        fertilizer: base.fertilizer,
        calcium: base.calcium,
        waterCulture: base.waterCulture,
        ponCulture: base.ponCulture,
        repotEveryMonths: base.repotEveryMonths,
        pot: base.pot,
        damageBelowC: damageBelowC ?? base.damageBelowC,
        survivalMinC: base.survivalMinC,
        idealTempMinC: base.idealTempMinC,
        idealTempMaxC: base.idealTempMaxC,
        propagation: base.propagation,
        issues: base.issues,
        support: base.support,
        humidityMethods: base.humidityMethods,
        dormantInWinter: base.dormantInWinter,
        outdoorFriendly: base.outdoorFriendly,
        bloom: base.bloom,
        dormancy: base.dormancy,
        tipKeys: base.tipKeys,
      );

  Map<String, Object?> toJson() => {
        if (light != null) 'li': light!.name,
        if (humidity != null) 'hu': humidity!.name,
        if (difficulty != null) 'di': difficulty!.name,
        if (wateringSummerDays != null) 'ws': wateringSummerDays,
        if (wateringWinterDays != null) 'ww': wateringWinterDays,
        if (damageBelowC != null) 'tb': damageBelowC,
      };

  /// `null` quand la carte ne dit rien : une retouche vide n'est pas rangée.
  static CareOverride? fromJson(Map<String, Object?> json) {
    T? enumOf<T extends Enum>(List<T> values, Object? name) {
      for (final v in values) {
        if (v.name == name) return v;
      }
      return null;
    }

    final override = CareOverride(
      light: enumOf(LightNeed.values, json['li']),
      humidity: enumOf(HumidityNeed.values, json['hu']),
      difficulty: enumOf(CareDifficulty.values, json['di']),
      wateringSummerDays: json['ws'] as int?,
      wateringWinterDays: json['ww'] as int?,
      damageBelowC: json['tb'] as int?,
    );
    return override.isEmpty ? null : override;
  }
}
