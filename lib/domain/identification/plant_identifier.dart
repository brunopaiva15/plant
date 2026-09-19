import 'dart:io';

import '../species/species_info.dart';
import 'identification_context.dart';

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
    this.image,
    this.inContext = true,
    double? globalScore,
  }) : globalScore = globalScore ?? score;

  final String scientificName;
  final String? commonName;
  final double score;
  final IdentificationSource source;

  /// Faux quand le candidat est **hors du masque du lieu** : le modèle l'a
  /// calculé, le contexte ne l'attendait pas (§ 14.3 de `docs/09`).
  ///
  /// Un candidat hors contexte n'est pas écarté, il est déclassé : il ne
  /// compte pas dans le verdict du lieu, mais il reste affichable et peut
  /// être proposé quand la réponse du lieu ne convainc pas. Vrai partout
  /// ailleurs, y compris pour une réponse distante et pour un modèle sans
  /// masque.
  final bool inContext;

  /// Le score du modèle **sans masque**, c'est-à-dire sur toutes ses sorties.
  ///
  /// [score] est renormalisé sur les classes du lieu : `exp(zᵢ) / Σ_gardées`,
  /// là où celui-ci divise par la somme de *toutes* les sorties. Les deux
  /// sont égaux quand aucun masque ne s'applique, et c'est le cas par
  /// défaut — un modèle sans masque, une réponse distante.
  ///
  /// Il sert à comparer ce qui n'est pas sur la même échelle : deux scores
  /// renormalisés sur deux ensembles différents ne se comparent pas, leurs
  /// scores globaux si.
  final double globalScore;

  /// Identifiant interne de la plante si elle est au catalogue de l'app
  /// (« monstera-deliciosa »), `null` sinon.
  final String? internalId;

  /// Photo de référence de l'espèce, quand la source en fournit une. Jamais
  /// la photo de l'utilisateur : celle-ci ne quitte pas l'appareil, ici on
  /// ne reçoit qu'un cliché d'illustration. `null` tant qu'on n'en a pas,
  /// et une vignette manquante ne doit jamais empêcher de choisir.
  final SpeciesImage? image;

  IdentificationCandidate copyWith({
    String? scientificName,
    String? commonName,
    double? score,
    IdentificationSource? source,
    String? Function()? internalId,
    SpeciesImage? image,
    bool? inContext,
    double? globalScore,
  }) =>
      IdentificationCandidate(
        scientificName: scientificName ?? this.scientificName,
        commonName: commonName ?? this.commonName,
        score: score ?? this.score,
        source: source ?? this.source,
        internalId: internalId == null ? this.internalId : internalId(),
        image: image ?? this.image,
        inContext: inContext ?? this.inContext,
        globalScore: globalScore ?? this.globalScore,
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

  /// [context] est le lieu de la photo, quand l'application le connaît. Il ne
  /// concerne que le modèle embarqué, qui renormalise ses sorties sur les
  /// classes du lieu ; **une source distante l'ignore**, elle connaît des
  /// dizaines de milliers d'espèces et n'a pas besoin qu'on la borne.
  Future<List<IdentificationCandidate>> identify(List<File> images,
      {String? language, IdentificationContext context = IdentificationContext.unknown});
}

class UnconfiguredIdentifier implements PlantIdentifier {
  const UnconfiguredIdentifier();
  @override
  bool get isConfigured => false;
  @override
  Future<List<IdentificationCandidate>> identify(List<File> images,
          {String? language, IdentificationContext context = IdentificationContext.unknown}) async =>
      const [];
}
