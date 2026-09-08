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
class CareCompletion {
  const CareCompletion({
    this.wateringSummerDays,
    this.wateringWinterDays,
    this.light,
    this.humidity,
    this.soil,
    this.fertilizingDays,
    this.noFertilizer = false,
    this.repotEveryMonths,
    this.minTempC,
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
  final int? fertilizingDays;

  /// L'espèce ne se fertilise pas, ce qui n'est pas la même chose que
  /// « je ne sais pas à quelle fréquence ».
  final bool noFertilizer;
  final int? repotEveryMonths;
  final int? minTempC;
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
      fertilizingDays == null &&
      !noFertilizer &&
      repotEveryMonths == null &&
      minTempC == null &&
      idealTempMinC == null &&
      idealTempMaxC == null &&
      difficulty == null &&
      propagation.isEmpty &&
      issues.isEmpty;

  /// Repose [base] avec ce dont l'IA est sûre. Ce qu'elle n'a pas dit reste
  /// tel quel, toxicité comprise.
  CareProfile applyTo(CareProfile base) => CareProfile(
        wateringSummerDays: wateringSummerDays ?? base.wateringSummerDays,
        wateringWinterDays: wateringWinterDays ?? base.wateringWinterDays,
        light: light ?? base.light,
        humidity: humidity ?? base.humidity,
        difficulty: difficulty ?? base.difficulty,
        soil: soil ?? base.soil,
        fertilizingDays: noFertilizer ? null : (fertilizingDays ?? base.fertilizingDays),
        fertilizingWindow: base.fertilizingWindow,
        repotEveryMonths: repotEveryMonths ?? base.repotEveryMonths,
        minTempC: minTempC ?? base.minTempC,
        idealTempMinC: idealTempMinC ?? base.idealTempMinC,
        idealTempMaxC: idealTempMaxC ?? base.idealTempMaxC,
        toxicity: base.toxicity,
        propagation: propagation.isEmpty ? base.propagation : propagation,
        issues: issues.isEmpty ? base.issues : issues,
        mistLeaves: base.mistLeaves,
        dormantInWinter: base.dormantInWinter,
        outdoorFriendly: base.outdoorFriendly,
        tipKeys: base.tipKeys,
      );

  Map<String, Object?> toJson() => {
        if (wateringSummerDays != null) 'ws': wateringSummerDays,
        if (wateringWinterDays != null) 'ww': wateringWinterDays,
        if (light != null) 'li': light!.name,
        if (humidity != null) 'hu': humidity!.name,
        if (soil != null) 'so': soil!.name,
        if (fertilizingDays != null) 'fe': fertilizingDays,
        if (noFertilizer) 'nf': true,
        if (repotEveryMonths != null) 're': repotEveryMonths,
        if (minTempC != null) 'tm': minTempC,
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
      fertilizingDays: json['fe'] as int?,
      noFertilizer: json['nf'] == true,
      repotEveryMonths: json['re'] as int?,
      minTempC: json['tm'] as int?,
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
