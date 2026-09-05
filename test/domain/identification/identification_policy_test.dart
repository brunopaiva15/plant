import 'package:flora/domain/identification/identification_policy.dart';
import 'package:flora/domain/identification/plant_identifier.dart';
import 'package:flutter_test/flutter_test.dart';

IdentificationCandidate c(String name, double score) => IdentificationCandidate(scientificName: name, score: score);

void main() {
  const policy = FallbackPolicy();

  test('defaults: 0.90 threshold, 0.25 margin', () {
    expect(policy.acceptThreshold, 0.90);
    expect(policy.minMargin, 0.25);
  });

  test('confident and isolated top candidate is accepted', () {
    expect(policy.decide([c('Monstera deliciosa', 0.95), c('Monstera adansonii', 0.03)]), IdentificationVerdict.accepted);
    expect(policy.decide([c('Monstera deliciosa', 0.91)]), IdentificationVerdict.accepted);
  });

  test('below threshold is uncertain', () {
    expect(policy.decide([c('Monstera deliciosa', 0.80), c('Monstera adansonii', 0.05)]), IdentificationVerdict.uncertain);
  });

  test('two close candidates are uncertain even above threshold', () {
    // Le modèle hésite entre deux espèces : ce n'est pas une décision.
    expect(policy.decide([c('Monstera deliciosa', 0.91), c('Monstera adansonii', 0.89)]), IdentificationVerdict.uncertain);
  });

  test('order of the list does not matter', () {
    expect(policy.decide([c('Monstera adansonii', 0.03), c('Monstera deliciosa', 0.95)]), IdentificationVerdict.accepted);
  });

  test('empty or floor-level lists have no candidate', () {
    expect(policy.decide(const []), IdentificationVerdict.noCandidate);
    expect(policy.decide([c('Monstera deliciosa', 0.04), c('Ficus elastica', 0.03)]), IdentificationVerdict.noCandidate);
  });

  test('custom thresholds are honoured', () {
    const loose = FallbackPolicy(acceptThreshold: 0.6, minMargin: 0.1);
    expect(loose.decide([c('A', 0.65), c('B', 0.5)]), IdentificationVerdict.accepted);
    expect(loose.decide([c('A', 0.65), c('B', 0.6)]), IdentificationVerdict.uncertain);
  });
}
