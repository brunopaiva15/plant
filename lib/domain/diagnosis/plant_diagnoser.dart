import 'dart:io';

/// Une cause possible, avec sa vraisemblance (0–1) et des gestes concrets.
class DiagnosisCause {
  const DiagnosisCause({required this.title, required this.likelihood, required this.explanation, required this.actions});

  final String title;
  final double likelihood;
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
  });
}

class UnconfiguredDiagnoser implements PlantDiagnoser {
  const UnconfiguredDiagnoser();
  @override
  bool get isConfigured => false;
  @override
  Future<Diagnosis> diagnose({required List<File> images, required String language, String? plantName, String? species, String? symptoms}) =>
      throw const DiagnosisException('unconfigured');
}
