import 'dart:io';

/// Une espèce candidate, avec un score de 0 à 1. Jamais une certitude.
class IdentificationCandidate {
  const IdentificationCandidate({required this.scientificName, required this.score, this.commonName});

  final String scientificName;
  final String? commonName;
  final double score;
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
