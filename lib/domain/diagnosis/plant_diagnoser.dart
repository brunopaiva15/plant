import 'dart:io';

import '../care/care_profile.dart';

/// À quel point une piste tient debout, en trois crans.
///
/// Pas un pourcentage. Un modèle de langue n'a aucun moyen de calibrer
/// « 62 % » sur une photo de feuille jaune ; le chiffre donnait à une
/// intuition l'allure d'une mesure, et une barre de progression le
/// confirmait à l'œil. Trois mots disent la même chose sans mentir sur la
/// précision.
enum Likelihood {
  likely,
  possible,
  unlikely;

  /// Le mot rendu par le service, ou `possible` faute de mieux : une piste
  /// sans étiquette reste une piste.
  static Likelihood parse(Object? raw) {
    for (final v in Likelihood.values) {
      if (v.name == raw) return v;
    }
    // Certains modèles répondent encore par un nombre malgré la consigne.
    // On le range dans un cran plutôt que de perdre la piste, en gardant des
    // seuils larges : c'est un classement, pas une conversion.
    if (raw is num) return raw >= 0.6 ? Likelihood.likely : (raw >= 0.3 ? Likelihood.possible : Likelihood.unlikely);
    return Likelihood.possible;
  }
}

/// Une cause possible, avec sa vraisemblance et des gestes concrets.
class DiagnosisCause {
  const DiagnosisCause({required this.title, required this.likelihood, required this.explanation, required this.actions});

  final String title;
  final Likelihood likelihood;
  final String explanation;
  final List<String> actions;
}

/// Résultat d'un diagnostic : toujours des suggestions, jamais des certitudes.
class Diagnosis {
  const Diagnosis({required this.summary, required this.causes, this.urgent = false});

  /// Ce que l'on observe, en une ou deux phrases.
  final String summary;

  /// Causes classées de la plus à la moins probable.
  final List<DiagnosisCause> causes;

  /// Vrai si la plante mérite une attention rapide (parasites, pourriture…).
  final bool urgent;
}

class DiagnosisException implements Exception {
  const DiagnosisException(this.message);

  final String message;

  @override
  String toString() => 'DiagnosisException: $message';
}

/// Service de diagnostic. Implémentation : AI Services d'Infomaniak, avec la
/// clé de l'éditeur fournie au build.
abstract class PlantDiagnoser {
  bool get isConfigured;
  Future<Diagnosis> diagnose({
    required List<File> images,
    required String language,
    String? plantName,
    String? species,
    String? symptoms,

    /// Ce dont l'espèce souffre habituellement, d'après sa fiche
    /// d'entretien. Une piste de départ, pas une liste de réponses : la
    /// plante peut très bien avoir autre chose.
    List<CommonIssue> knownIssues = const [],
  });
}

class UnconfiguredDiagnoser implements PlantDiagnoser {
  const UnconfiguredDiagnoser();
  @override
  bool get isConfigured => false;
  @override
  Future<Diagnosis> diagnose({
    required List<File> images,
    required String language,
    String? plantName,
    String? species,
    String? symptoms,
    List<CommonIssue> knownIssues = const [],
  }) =>
      throw const DiagnosisException('unconfigured');
}
