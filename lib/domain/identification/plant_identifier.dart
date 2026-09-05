import 'dart:io';

/// D'où vient un candidat.
enum IdentificationSource {
  /// Modèle embarqué, sans réseau.
  local,

  /// Service distant (Pl@ntNet).
  remote,

  /// Origine inconnue ou test.
  unknown,
}

/// Une espèce candidate, avec un score de 0 à 1. Jamais une certitude.
class IdentificationCandidate {
  const IdentificationCandidate({
    required this.scientificName,
    required this.score,
    this.commonName,
    this.source = IdentificationSource.unknown,
    this.internalId,
  });

  final String scientificName;
  final String? commonName;
  final double score;
  final IdentificationSource source;

  /// Identifiant interne de la plante si elle est au catalogue de l'app
  /// (« monstera-deliciosa »), `null` sinon.
  final String? internalId;

  IdentificationCandidate copyWith({String? scientificName, String? commonName, double? score, IdentificationSource? source, String? Function()? internalId}) =>
      IdentificationCandidate(
        scientificName: scientificName ?? this.scientificName,
        commonName: commonName ?? this.commonName,
        score: score ?? this.score,
        source: source ?? this.source,
        internalId: internalId == null ? this.internalId : internalId(),
      );
}

class IdentificationException implements Exception {
  const IdentificationException(this.message);

  final String message;

  @override
  String toString() => 'IdentificationException: $message';
}

/// Service d'identification. Implémentations : Pl@ntNet (Phase 2), autres plus tard.
abstract class PlantIdentifier {
  bool get isConfigured;
  Future<List<IdentificationCandidate>> identify(List<File> images, {String? language});
}

class UnconfiguredIdentifier implements PlantIdentifier {
  const UnconfiguredIdentifier();
  @override
  bool get isConfigured => false;
  @override
  Future<List<IdentificationCandidate>> identify(List<File> images, {String? language}) async => const [];
}
