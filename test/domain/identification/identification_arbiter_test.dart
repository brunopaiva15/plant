import 'package:flora/domain/identification/identification_arbiter.dart';
import 'package:flora/domain/identification/identification_policy.dart';
import 'package:flora/domain/identification/plant_identifier.dart';
import 'package:flutter_test/flutter_test.dart';

IdentificationCandidate c(String name, double score, {IdentificationSource source = IdentificationSource.local}) =>
    IdentificationCandidate(scientificName: name, score: score, source: source);

const policy = FallbackPolicy();

void main() {
  group('ce qui vaut la peine d\'être départagé', () {
    test('une réponse acceptée ne se fait pas réviser', () {
      // 0,80 contre 0,10 : Iris a tranché, et il a raison neuf fois sur dix
      // quand il tranche. Un deuxième avis n'a rien à gagner et peut perdre.
      expect(worthArbitrating(policy, [c('Monstera deliciosa', 0.80), c('Monstera adansonii', 0.10)]), isFalse);
    });

    test('une liste plausible, oui', () {
      expect(worthArbitrating(policy, [c('Monstera adansonii', 0.44), c('Monstera deliciosa', 0.39)]), isTrue);
    });

    test('une liste incertaine, oui — c\'est même le cas le plus utile', () {
      expect(worthArbitrating(policy, [c('Picea abies', 0.18), c('Picea omorika', 0.15)]), isTrue);
    });

    test('rien d\'exploitable, non : il n\'y a pas d\'ensemble à fermer', () {
      expect(worthArbitrating(policy, [c('Picea abies', 0.05), c('Picea omorika', 0.03)]), isFalse);
    });

    test('une seule candidate, non : ce serait demander une confirmation', () {
      expect(worthArbitrating(policy, [c('Monstera adansonii', 0.40)]), isFalse);
    });

    test('une liste distante, non : elle a déjà tranché', () {
      expect(
        worthArbitrating(policy, [
          c('Monstera adansonii', 0.44, source: IdentificationSource.remote),
          c('Monstera deliciosa', 0.39, source: IdentificationSource.remote),
        ]),
        isFalse,
      );
    });
  });

  group('la candidate désignée', () {
    final liste = [
      c('Monstera deliciosa', 0.44),
      c('Monstera adansonii', 0.39),
      c('Rhaphidophora tetrasperma', 0.12),
    ];

    test('se retrouve dans la liste soumise', () {
      final pick = arbitratedCandidate(
        liste,
        const Arbitration(outcome: ArbitrationOutcome.picked, scientificName: 'Monstera adansonii'),
      );
      expect(pick?.scientificName, 'Monstera adansonii');
      // C'est bien la candidate d'Iris, avec son score : rien n'est fabriqué.
      expect(pick?.score, 0.39);
    });

    test('se retrouve même avec un auteur collé au nom', () {
      final pick = arbitratedCandidate(
        liste,
        const Arbitration(outcome: ArbitrationOutcome.picked, scientificName: 'Monstera adansonii Schott'),
      );
      expect(pick?.scientificName, 'Monstera adansonii');
    });

    test('un nom qu\'on n\'a pas soumis ne vaut rien', () {
      final pick = arbitratedCandidate(
        liste,
        const Arbitration(outcome: ArbitrationOutcome.picked, scientificName: 'Epipremnum pinnatum'),
      );
      expect(pick, isNull);
    });

    test('« aucune de ces candidates » ne désigne personne', () {
      expect(arbitratedCandidate(liste, const Arbitration.none()), isNull);
    });

    test('« pas une plante » non plus', () {
      expect(arbitratedCandidate(liste, const Arbitration(outcome: ArbitrationOutcome.notPlant)), isNull);
    });

    test('sans avis, rien', () {
      expect(arbitratedCandidate(liste, null), isNull);
    });
  });

  group('l\'avis ne s\'affiche que s\'il déplace la tête de liste', () {
    final liste = [c('Monstera deliciosa', 0.44), c('Monstera adansonii', 0.39)];

    test('une autre candidate que la première : il y a quelque chose à dire', () {
      expect(
        arbitrationLeads(liste, const Arbitration(outcome: ArbitrationOutcome.picked, scientificName: 'Monstera adansonii')),
        isTrue,
      );
    });

    test('la première : l\'écran la montre déjà en tête', () {
      expect(
        arbitrationLeads(liste, const Arbitration(outcome: ArbitrationOutcome.picked, scientificName: 'Monstera deliciosa')),
        isFalse,
      );
    });

    test('aucune : rien à mettre en tête', () {
      expect(arbitrationLeads(liste, const Arbitration.none()), isFalse);
    });
  });

  test('sans arbitre, la cascade est celle d\'avant', () async {
    const arbiter = NoArbiter();
    expect(arbiter.isConfigured, isFalse);
    expect(
      await arbiter.arbitrate(images: const [], candidates: const [], language: 'fr'),
      isNull,
    );
  });
}
