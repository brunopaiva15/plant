import 'package:flora/domain/identification/identification_confidence.dart';
import 'package:flora/domain/identification/identification_policy.dart';
import 'package:flora/domain/identification/plant_identifier.dart';
import 'package:flutter_test/flutter_test.dart';

IdentificationCandidate _c(double score, IdentificationSource source) =>
    IdentificationCandidate(scientificName: 'Monstera deliciosa', score: score, source: source);

void main() {
  IdentificationConfidence local(double score) => IdentificationConfidence.of(_c(score, IdentificationSource.local));
  IdentificationConfidence remote(double score) => IdentificationConfidence.of(_c(score, IdentificationSource.remote));

  group('le modèle embarqué', () {
    test('suit les seuils de la cascade, pas les siens', () {
      const policy = FallbackPolicy();
      // « Probable » veut dire exactement « la politique accepterait ce
      // candidat sans appeler le service distant ».
      expect(local(policy.acceptThreshold), IdentificationConfidence.likely);
      expect(local(policy.acceptThreshold - 0.01), IdentificationConfidence.possible);
      expect(local(policy.plausibleThreshold), IdentificationConfidence.possible);
      expect(local(policy.plausibleThreshold - 0.01), IdentificationConfidence.unlikely);
    });

    test('les trois crans couvrent toute l\'échelle', () {
      expect(local(1.0), IdentificationConfidence.likely);
      expect(local(0.0), IdentificationConfidence.unlikely);
    });
  });

  group('le service distant', () {
    test('a ses propres seuils', () {
      // Un softmax sur 1 457 espèces et un service qui en connaît des dizaines
      // de milliers ne produisent pas des scores comparables : 0,55 est un
      // bon score chez Pl@ntNet et une hésitation pour le modèle local.
      expect(remote(0.55), IdentificationConfidence.likely);
      expect(local(0.55), IdentificationConfidence.possible);
      expect(remote(0.20), IdentificationConfidence.possible);
      expect(remote(0.10), IdentificationConfidence.unlikely);
    });

    test('une origine inconnue est traitée comme distante', () {
      expect(IdentificationConfidence.of(_c(0.55, IdentificationSource.unknown)), IdentificationConfidence.likely);
    });
  });

  test('une politique plus exigeante déplace le cran', () {
    const stricte = FallbackPolicy(acceptThreshold: 0.90);
    expect(IdentificationConfidence.of(_c(0.75, IdentificationSource.local), policy: stricte), IdentificationConfidence.possible);
    expect(IdentificationConfidence.of(_c(0.75, IdentificationSource.local)), IdentificationConfidence.likely);
  });
}
