import 'dart:convert';

import 'care_profile.dart';

/// Ce que l'IA sait d'une espèce que le catalogue ne connaît pas.
///
/// Chaque champ est facultatif, et c'est le cœur de la chose. On ne lui
/// demande pas de remplir une fiche, on lui demande ce dont elle est sûre.
/// Un champ absent laisse la place au repère générique, qui a le mérite de ne
/// prétendre à rien.
///
/// La toxicité n'en fait pas partie. Tout le reste est un avis sur le confort
/// d'une plante ; « non toxique pour le chat » est une affirmation sur
/// laquelle quelqu'un agit. Elle reste au catalogue, renseignée à la main, ou
/// inconnue.
///
/// La floraison et le repos à feuillage disparu n'en font pas partie non plus,
/// pour une autre raison : une date de floraison inventée se vérifie six mois
/// trop tard, et un bulbe rangé au froid sur un mauvais conseil ne repart pas.
/// Le catalogue les renseigne ou se tait.
class CareCompletion {
  const CareCompletion({
    this.wateringSummerDays,
    this.wateringWinterDays,
    this.light,
    this.humidity,
    this.soil,
    this.water,
    this.fertilizingDays,
    this.noFertilizer = false,
    this.repotEveryMonths,
    this.pot,
    this.damageBelowC,
    this.idealTempMinC,
    this.idealTempMaxC,
    this.difficulty,
    this.propagation = const [],
    this.issues = const [],
  });

  final int? wateringSummerDays;
  final int? wateringWinterDays;
  final LightNeed? light;
  final HumidityNeed? humidity;
  final SoilKind? soil;

  /// Ce que l'espèce supporte de l'eau du robinet. Le catalogue le suppose
  /// tolérant faute de mieux ; l'IA, elle, peut le dire.
  final WaterTolerance? water;
  final int? fertilizingDays;

  /// L'espèce ne se fertilise pas, ce qui n'est pas la même chose que
  /// « je ne sais pas à quelle fréquence ».
  final bool noFertilizer;
  final int? repotEveryMonths;

  /// Ce qu'une racine sortie du pot veut dire chez cette espèce : trois mots
  /// d'un vocabulaire fermé, comme la lumière ou le substrat.
  final PotPreference? pot;
  /// Le seuil sous lequel le froid abîme l'espèce, quand l'IA le connaît.
  final int? damageBelowC;
  final int? idealTempMinC;
  final int? idealTempMaxC;
  final CareDifficulty? difficulty;
  final List<Propagation> propagation;
  final List<CommonIssue> issues;

  /// Vrai quand l'IA n'a rien affirmé : il n'y a alors rien à montrer, et
  /// rien qui vaille un second appel.
  bool get isEmpty =>
      wateringSummerDays == null &&
      wateringWinterDays == null &&
      light == null &&
      humidity == null &&
      soil == null &&
      water == null &&
      fertilizingDays == null &&
      !noFertilizer &&
      repotEveryMonths == null &&
      pot == null &&
      damageBelowC == null &&
      idealTempMinC == null &&
      idealTempMaxC == null &&
      difficulty == null &&
      propagation.isEmpty &&
      issues.isEmpty;

  /// Repose [base] avec ce dont l'IA est sûre. Ce qu'elle n'a pas dit reste
  /// tel quel. La toxicité ne passe pas par ici : elle vit sur la fiche
  /// résolue, que ce profil ne touche pas.
  CareProfile applyTo(CareProfile base) => CareProfile(
        wateringSummerDays: wateringSummerDays ?? base.wateringSummerDays,
        wateringWinterDays: wateringWinterDays ?? base.wateringWinterDays,
        dryDown: base.dryDown,
        light: light ?? base.light,
        lightTolerance: light == null ? base.lightTolerance : null,
        humidity: humidity ?? base.humidity,
        difficulty: difficulty ?? base.difficulty,
        soil: soil ?? base.soil,
        growthMedium: base.growthMedium,
        // La plage en pourcentage suit le besoin que l'IA a donné : garder
        // celle du repère générique sous un autre mot afficherait « air sec
        // accepté, 60 à 80 % ».
        humidityIdealMin: humidity == null ? base.humidityIdealMin : null,
        humidityIdealMax: humidity == null ? base.humidityIdealMax : null,
        humidityToleratedMin: humidity == null ? base.humidityToleratedMin : null,
        water: water ?? base.water,
        fluorideSensitive: base.fluorideSensitive,
        fertilizingDays: noFertilizer ? null : (fertilizingDays ?? base.fertilizingDays),
        fertilizingWindow: base.fertilizingWindow,
        // L'IA ne se prononce ni sur le type d'engrais, ni sur le calcium, ni
        // sur le hors-sol, ni sur la floraison : ce que la fiche de repli en
        // dit vient de son substrat, et le substrat, lui, peut changer.
        fertilizer: base.fertilizer,
        calcium: base.calcium,
        waterCulture: base.waterCulture,
        ponCulture: base.ponCulture,
        repotEveryMonths: repotEveryMonths ?? base.repotEveryMonths,
        pot: pot ?? base.pot,
        damageBelowC: damageBelowC ?? base.damageBelowC,
        survivalMinC: base.survivalMinC,
        idealTempMinC: idealTempMinC ?? base.idealTempMinC,
        idealTempMaxC: idealTempMaxC ?? base.idealTempMaxC,
        propagation: propagation.isEmpty ? base.propagation : propagation,
        issues: issues.isEmpty ? base.issues : issues,
        support: base.support,
        humidityMethods: base.humidityMethods,
        dormantInWinter: base.dormantInWinter,
        outdoorFriendly: base.outdoorFriendly,
        // L'IA ne se prononce pas sur l'air qui bouge : ce que la fiche sait
        // — ou ne sait pas — reste tel quel.
        airflow: base.airflow,
        bloom: base.bloom,
        dormancy: base.dormancy,
        tipKeys: base.tipKeys,
        sourcing: base.sourcing,
      );

  Map<String, Object?> toJson() => {
        if (wateringSummerDays != null) 'ws': wateringSummerDays,
        if (wateringWinterDays != null) 'ww': wateringWinterDays,
        if (light != null) 'li': light!.name,
        if (humidity != null) 'hu': humidity!.name,
        if (soil != null) 'so': soil!.name,
        if (water != null) 'wa': water!.name,
        if (fertilizingDays != null) 'fe': fertilizingDays,
        if (noFertilizer) 'nf': true,
        if (repotEveryMonths != null) 're': repotEveryMonths,
        if (pot != null) 'po': pot!.name,
        if (damageBelowC != null) 'tm': damageBelowC,
        if (idealTempMinC != null) 'ti': idealTempMinC,
        if (idealTempMaxC != null) 'ta': idealTempMaxC,
        if (difficulty != null) 'di': difficulty!.name,
        if (propagation.isNotEmpty) 'pr': [for (final p in propagation) p.name],
        if (issues.isNotEmpty) 'is': [for (final i in issues) i.name],
      };

  static CareCompletion fromJson(Map<String, Object?> json) {
    T? enumOf<T extends Enum>(List<T> values, Object? name) {
      for (final v in values) {
        if (v.name == name) return v;
      }
      return null;
    }

    List<T> enumsOf<T extends Enum>(List<T> values, Object? raw) => [
          for (final name in (raw as List?) ?? const []) ?enumOf(values, name),
        ];

    return CareCompletion(
      wateringSummerDays: json['ws'] as int?,
      wateringWinterDays: json['ww'] as int?,
      light: enumOf(LightNeed.values, json['li']),
      humidity: enumOf(HumidityNeed.values, json['hu']),
      soil: enumOf(SoilKind.values, json['so']),
      water: enumOf(WaterTolerance.values, json['wa']),
      fertilizingDays: json['fe'] as int?,
      noFertilizer: json['nf'] == true,
      repotEveryMonths: json['re'] as int?,
      pot: enumOf(PotPreference.values, json['po']),
      damageBelowC: json['tm'] as int?,
      idealTempMinC: json['ti'] as int?,
      idealTempMaxC: json['ta'] as int?,
      difficulty: enumOf(CareDifficulty.values, json['di']),
      propagation: enumsOf(Propagation.values, json['pr']),
      issues: enumsOf(CommonIssue.values, json['is']),
    );
  }
}

class CareCompletionException implements Exception {
  const CareCompletionException(this.message);

  final String message;

  @override
  String toString() => 'CareCompletionException: $message';
}

/// Complète une fiche d'entretien pour une espèce inconnue du catalogue.
abstract class CareCompleter {
  bool get isConfigured;

  Future<CareCompletion> complete({required String scientificName, required String language});
}

class UnconfiguredCareCompleter implements CareCompleter {
  const UnconfiguredCareCompleter();

  @override
  bool get isConfigured => false;

  @override
  Future<CareCompletion> complete({required String scientificName, required String language}) =>
      throw const CareCompletionException('unconfigured');
}

/// Les réponses déjà obtenues, gardées sur l'appareil.
///
/// Une fiche s'ouvre souvent ; sans mémoire, le même appel repartirait à
/// chaque visite pour le même texte. Les réponses vides comptent autant que
/// les autres : une espèce que l'IA ne connaît pas ne vaut pas d'être
/// redemandée.
abstract class CareCompletionStore {
  CareCompletion? read(String scientificName, String language);

  Future<void> write(String scientificName, String language, CareCompletion completion);

  /// Clé de rangement, le nom d'espèce normalisé et la langue.
  static String keyOf(String scientificName, String language) =>
      '$language|${scientificName.trim().toLowerCase()}';

  /// Encodage du cache entier, tel qu'il est rangé dans les réglages.
  static String encode(Map<String, CareCompletion> entries) =>
      jsonEncode({for (final e in entries.entries) e.key: e.value.toJson()});

  static Map<String, CareCompletion> decode(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      final json = jsonDecode(raw);
      if (json is! Map) return {};
      return {
        for (final e in json.entries)
          if (e.value is Map) e.key as String: CareCompletion.fromJson(Map<String, Object?>.from(e.value as Map)),
      };
    } on FormatException {
      return {};
    }
  }
}
