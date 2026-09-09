import 'dart:io';

import '../problems/plant_problem.dart';

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
  const DiagnosisCause({required this.title, required this.likelihood, required this.explanation, required this.actions, this.problemId});

  /// Le titre rendu par le service. Sert de repli quand la cause ne
  /// correspond à rien de la base ; sinon c'est le nom de la base qui
  /// s'affiche.
  final String title;
  final Likelihood likelihood;
  final String explanation;
  final List<String> actions;

  /// Numéro du problème dans la base locale, quand le service en a reconnu
  /// un parmi ceux qu'on lui a soumis. `null` pour tout le reste : la base
  /// couvre beaucoup, pas tout, et forcer une correspondance vaudrait moins
  /// que de l'admettre.
  final String? problemId;

  Map<String, Object?> toJson() => {
        'title': title,
        'likelihood': likelihood.name,
        'explanation': explanation,
        'actions': actions,
        if (problemId != null) 'problemId': problemId,
      };

  /// Une piste qui n'a rien à montrer : ni nom propre, ni numéro pour que la
  /// base la nomme, ni explication. Une carte vide ne dit rien de plus qu'une
  /// carte absente.
  bool get isBlank => title.isEmpty && problemId == null && explanation.isEmpty;

  /// Relit une cause gardée au journal. Tolérante : une analyse conservée il
  /// y a six mois a pu être écrite par une version antérieure, et un champ
  /// manquant vaut mieux qu'une entrée perdue.
  factory DiagnosisCause.fromJson(Map<String, Object?> json) => DiagnosisCause(
        title: json['title'] is String ? json['title'] as String : '',
        likelihood: Likelihood.parse(json['likelihood']),
        explanation: json['explanation'] is String ? json['explanation'] as String : '',
        actions: [
          for (final a in json['actions'] is List ? json['actions'] as List : const [])
            if (a is String && a.trim().isNotEmpty) a,
        ],
        problemId: json['problemId'] is String ? json['problemId'] as String : null,
      );
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

  Map<String, Object?> toJson() => {
        'summary': summary,
        'urgent': urgent,
        'causes': [for (final c in causes) c.toJson()],
      };

  factory Diagnosis.fromJson(Map<String, Object?> json) => Diagnosis(
        summary: json['summary'] is String ? json['summary'] as String : '',
        urgent: json['urgent'] == true,
        causes: [
          for (final c in json['causes'] is List ? json['causes'] as List : const [])
            if (c is Map)
              if (DiagnosisCause.fromJson(c.cast<String, Object?>()) case final cause when !cause.isBlank) cause,
        ],
      );
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

    /// Les problèmes de la base locale qui peuvent concerner cette plante.
    /// Une liste de pistes soumise au service, pas une liste de réponses :
    /// la plante peut très bien avoir autre chose.
    List<PlantProblem> candidates = const [],

    /// Parmi eux, ceux que la fiche d'entretien signale pour l'espèce.
    Set<String> frequentIds = const {},
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
    List<PlantProblem> candidates = const [],
    Set<String> frequentIds = const {},
  }) =>
      throw const DiagnosisException('unconfigured');
}
