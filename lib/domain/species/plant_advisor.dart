import 'plant_finder.dart';

/// Une espèce proposée par l'IA, hors catalogue intégré.
class AdvisorSuggestion {
  const AdvisorSuggestion({required this.scientificName, this.commonName, this.reason = ''});

  final String scientificName;
  final String? commonName;

  /// Pourquoi elle conviendrait, en une phrase, dans la langue de l'app.
  final String reason;
}

class AdvisorException implements Exception {
  const AdvisorException(this.message);

  final String message;

  @override
  String toString() => 'AdvisorException: $message';
}

/// Élargit la recherche au-delà du catalogue intégré, quand celui-ci n'a rien
/// de convaincant à proposer. Appelé seulement sur demande explicite : le
/// catalogue répond hors ligne et gratuitement, l'IA est le second tour.
abstract class PlantAdvisor {
  bool get isConfigured;

  Future<List<AdvisorSuggestion>> suggest({
    required FinderCriteria criteria,
    required String language,
    List<String> exclude,
  });
}

class UnconfiguredAdvisor implements PlantAdvisor {
  const UnconfiguredAdvisor();

  @override
  bool get isConfigured => false;

  @override
  Future<List<AdvisorSuggestion>> suggest({required FinderCriteria criteria, required String language, List<String> exclude = const []}) =>
      throw const AdvisorException('unconfigured');
}
