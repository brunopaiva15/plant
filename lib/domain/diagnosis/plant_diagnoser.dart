import 'dart:io';

import '../home/home_climate.dart';
import '../problems/natural_cause.dart';
import '../problems/plant_problem.dart';
import 'diagnosis_observations.dart';

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

/// La vue qui manque à l'analyse, quand l'analyse en désigne une.
///
/// Fermée à cinq entrées : demander « une meilleure photo » ne dit pas quoi
/// cadrer, alors que « le revers d'une feuille » se photographie sans y
/// réfléchir. C'est le service qui la nomme, jamais l'application.
enum DiagnosisView {
  leafCloseup('leaf_closeup'),
  leafUnderside('leaf_underside'),
  wholePlant('whole_plant'),
  stemBase('stem_base'),
  soilRoots('soil_roots');

  const DiagnosisView(this.wire);

  /// Le mot tel qu'il circule : dans la réponse du service, dans l'état
  /// envoyé à Jev, dans le compte rendu gardé au journal.
  final String wire;

  /// La vue nommée, ou `null` pour tout le reste — « none », un mot inconnu,
  /// une clé absente. Une vue inventée ferait cadrer pour rien.
  static DiagnosisView? parse(Object? raw) {
    if (raw is! String) return null;
    final mot = raw.trim().toLowerCase();
    for (final v in DiagnosisView.values) {
      if (v.wire == mot) return v;
    }
    return null;
  }
}

/// Une question du service et ce que la personne y a répondu.
///
/// Les deux voyagent ensemble : une réponse seule ne veut rien dire, et la
/// question se relit dans le compte rendu à côté d'elle.
class DiagnosisAnswer {
  const DiagnosisAnswer({required this.question, required this.answer});

  final String question;
  final String answer;

  Map<String, Object?> toJson() => {'question': question, 'answer': answer};

  /// `null` dès que l'un des deux manque : une question sans réponse n'a pas
  /// à repartir à l'analyse, et une réponse sans question ne se relit pas.
  static DiagnosisAnswer? fromJson(Map<String, Object?> json) {
    final q = json['question'];
    final a = json['answer'];
    if (q is! String || a is! String) return null;
    if (q.trim().isEmpty || a.trim().isEmpty) return null;
    return DiagnosisAnswer(question: q.trim(), answer: a.trim());
  }
}

/// Une cause possible, avec sa vraisemblance et des gestes concrets.
class DiagnosisCause {
  const DiagnosisCause({
    required this.title,
    required this.likelihood,
    required this.explanation,
    required this.actions,
    this.problemId,
    this.naturalId,
    this.natural = false,
  });

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

  /// Numéro du phénomène naturel dans la base locale, quand la cause en est
  /// un et que le service l'a reconnu. Exclusif de [problemId] : une chose
  /// est un problème ou elle n'en est pas un.
  final String? naturalId;

  /// Vrai quand la cause n'est pas un problème : la plante fait ce qu'elle
  /// fait normalement.
  ///
  /// Des gouttes collantes sous un philodendron sont du nectar extrafloral
  /// aussi souvent que du miellat de cochenilles, et la moitié de ce qu'on
  /// photographie inquiète sans rien avoir d'anormal. Une piste pareille
  /// n'appelle pas de soin : elle se lit autrement, elle ne rend jamais le
  /// compte rendu urgent, et elle ne met pas la plante à surveiller.
  ///
  /// Toujours vrai quand [naturalId] est donné ; vrai aussi pour un
  /// phénomène que la base ne connaît pas — elle est courte, et la plante
  /// fait plus de choses normales qu'on n'en a listé.
  final bool natural;

  Map<String, Object?> toJson() => {
        'title': title,
        'likelihood': likelihood.name,
        'explanation': explanation,
        'actions': actions,
        if (problemId != null) 'problemId': problemId,
        if (naturalId != null) 'naturalId': naturalId,
        if (natural) 'natural': true,
      };

  /// Une piste qui n'a rien à montrer : ni nom propre, ni numéro pour que la
  /// base la nomme, ni explication. Une carte vide ne dit rien de plus qu'une
  /// carte absente.
  bool get isBlank => title.isEmpty && problemId == null && naturalId == null && explanation.isEmpty;

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
        naturalId: json['naturalId'] is String ? json['naturalId'] as String : null,
        natural: json['natural'] == true || json['naturalId'] is String,
      );
}

/// Résultat d'un diagnostic : toujours des suggestions, jamais des certitudes.
class Diagnosis {
  const Diagnosis({
    required this.summary,
    required this.causes,
    this.urgent = false,
    this.suggestedView,
    this.questions = const [],
  });

  /// Ce que l'on observe, en une ou deux phrases.
  final String summary;

  /// Causes classées de la plus à la moins probable.
  final List<DiagnosisCause> causes;

  /// Vrai si la plante mérite une attention rapide (parasites, pourriture…).
  final bool urgent;

  /// Vrai quand aucune piste n'est un problème : ce qui a été photographié
  /// est ce que la plante fait normalement. Le compte rendu le dit alors en
  /// tête, plutôt que de laisser lire trois cartes comme trois soucis.
  bool get onlyNatural => causes.isNotEmpty && causes.every((c) => c.natural);

  /// La vue qui manquait au service pour trancher, quand il en nomme une.
  ///
  /// Elle ne se lit nulle part dans le compte rendu : c'est une photo à
  /// proposer, pas une piste. Rien n'oblige à la donner, et l'analyse reste
  /// entière sans elle.
  final DiagnosisView? suggestedView;

  /// Ce que le service demanderait pour trancher : une à trois questions
  /// courtes, dans la langue de la personne, ou rien.
  ///
  /// Une photo ne dit ni depuis quand, ni ce qui a changé dans la pièce, ni
  /// ce qui a déjà été tenté — et le service n'avait aucun moyen de le
  /// demander : il répondait donc avec ce qu'il avait. Comme la vue de plus,
  /// c'est une proposition : les pistes sont rendues en entier, et personne
  /// n'est obligé de répondre.
  final List<String> questions;

  /// Les questions telles qu'on les garde : rognées, vides écartées, doublons
  /// écartés, trois au plus. La consigne le demande déjà ; on ne dépend pas
  /// de son respect.
  static List<String> readQuestions(Object? raw) {
    final vues = <String>{};
    final gardees = <String>[];
    for (final q in raw is List ? raw : const []) {
      if (q is! String) continue;
      final texte = q.trim();
      if (texte.isEmpty || !vues.add(texte.toLowerCase())) continue;
      gardees.add(texte);
      if (gardees.length == 3) break;
    }
    return gardees;
  }

  Map<String, Object?> toJson() => {
        'summary': summary,
        'urgent': urgent,
        if (suggestedView != null) 'view': suggestedView!.wire,
        if (questions.isNotEmpty) 'questions': questions,
        'causes': [for (final c in causes) c.toJson()],
      };

  factory Diagnosis.fromJson(Map<String, Object?> json) => Diagnosis(
        summary: json['summary'] is String ? json['summary'] as String : '',
        urgent: json['urgent'] == true,
        suggestedView: DiagnosisView.parse(json['view']),
        questions: readQuestions(json['questions']),
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

    /// Ce que cette plante fait normalement et qu'on prend pour un problème :
    /// nectar extrafloral, guttation, vieille feuille du bas qui jaunit.
    /// Soumis à côté des problèmes — la moitié des photos d'inquiétude ne
    /// montrent rien d'anormal, et le service n'y pensait pas tout seul.
    List<NaturalCause> naturalCauses = const [],

    /// Parmi eux, ceux que la fiche d'entretien signale pour l'espèce.
    Set<String> frequentIds = const {},

    /// Le climat mesuré chez l'utilisateur (Apple Maison), pour une plante
    /// d'intérieur. Un air à 30 % explique des pointes sèches mieux qu'une
    /// photo ; sans capteur, ou pour une plante dehors, rien n'est transmis.
    HomeReading? indoorClimate,

    /// Ce que la personne a donné elle-même, pour ce que le capteur ne
    /// mesure pas — ou tout, sans capteur.
    ReportedClimate? reportedClimate,

    /// Ce qu'elle est allée vérifier de sa main : la terre, les racines, la
    /// lumière, les insectes. Aucune photo ne les montre, et ce sont eux qui
    /// tranchent le plus souvent.
    DiagnosisObservations? observations,

    /// Ce que le service avait demandé au tour précédent, et ce qu'on lui a
    /// répondu. Une analyse ne se recolle pas à la précédente : elle se
    /// refait en entier, avec ces réponses en plus.
    List<DiagnosisAnswer> answers = const [],

    /// Vrai pour une plante qui vit dans la maison, faux pour une plante
    /// dehors, `null` quand on l'ignore — une plante sans emplacement.
    bool? indoors,

    /// Le jour de l'analyse. Une cochenille en février et une brûlure en
    /// juillet ne se confondent pas, et aucune photo ne dit la saison.
    DateTime? date,

    /// La latitude du lieu déjà connu de l'application, quand il y en a un.
    /// Seul son signe part : il dit l'hémisphère, donc la saison du mois.
    double? latitude,
  });
}

/// La température et l'humidité autour de la plante, données de la main de
/// la personne quand aucun capteur ne les mesure. Facultatives, l'une comme
/// l'autre.
class ReportedClimate {
  const ReportedClimate({this.temperatureC, this.humidity});

  final double? temperatureC;
  final int? humidity;

  bool get isEmpty => temperatureC == null && humidity == null;

  /// Lit ce qui a été tapé : virgule ou point, dans l'unité affichée. Une
  /// valeur hors de toute plage vraisemblable (−30 à 60 °C, 0 à 100 %) est
  /// ignorée plutôt que transmise.
  static ReportedClimate parse({String? temperature, String? humidity, bool fahrenheit = false}) {
    double? number(String? s) {
      final v = s == null ? null : double.tryParse(s.trim().replaceAll(',', '.'));
      return v == null || !v.isFinite ? null : v;
    }

    var t = number(temperature);
    if (t != null && fahrenheit) t = (t - 32) * 5 / 9;
    if (t != null && (t < -30 || t > 60)) t = null;
    var h = number(humidity)?.round();
    if (h != null && (h < 0 || h > 100)) h = null;
    return ReportedClimate(temperatureC: t, humidity: h);
  }
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
    List<NaturalCause> naturalCauses = const [],
    Set<String> frequentIds = const {},
    HomeReading? indoorClimate,
    ReportedClimate? reportedClimate,
    DiagnosisObservations? observations,
    List<DiagnosisAnswer> answers = const [],
    bool? indoors,
    DateTime? date,
    double? latitude,
  }) =>
      throw const DiagnosisException('unconfigured');
}
