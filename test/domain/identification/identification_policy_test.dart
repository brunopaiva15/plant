import 'package:flora/domain/identification/identification_policy.dart';
import 'package:flora/domain/identification/plant_identifier.dart';
import 'package:flutter_test/flutter_test.dart';

IdentificationCandidate c(String name, double score) => IdentificationCandidate(scientificName: name, score: score);

void main() {
  const policy = FallbackPolicy();

  test('defaults: 0.70 threshold, 0.25 plausible floor', () {
    expect(policy.acceptThreshold, 0.70);
    expect(policy.plausibleThreshold, 0.25);
    expect(policy.minMargin, 0.25);
  });

  test('confident and isolated top candidate is accepted', () {
    expect(policy.decide([c('Monstera deliciosa', 0.95), c('Monstera adansonii', 0.03)]), IdentificationVerdict.accepted);
    expect(policy.decide([c('Monstera deliciosa', 0.75), c('Monstera adansonii', 0.05)]), IdentificationVerdict.accepted);
  });

  test('a list worth showing stops the cascade without a remote call', () {
    // 0,34 : le score qu'a rendu Pl@ntNet sur une photo réelle de
    // Strelitzia. Une telle liste vaut d'être montrée ; l'appel distant
    // attendra que l'utilisateur le demande.
    expect(policy.decide([c('Strelitzia reginae', 0.34), c('Philodendron martianum', 0.02)]), IdentificationVerdict.plausible);
    expect(policy.decide([c('Monstera deliciosa', 0.60), c('Monstera adansonii', 0.05)]), IdentificationVerdict.plausible);
  });

  test('two close candidates are never accepted outright', () {
    // Le modèle hésite entre deux espèces : ce n'est pas une décision.
    expect(policy.decide([c('Monstera deliciosa', 0.45), c('Monstera adansonii', 0.44)]), IdentificationVerdict.plausible);
    expect(policy.decide([c('Monstera deliciosa', 0.91), c('Monstera adansonii', 0.89)]), IdentificationVerdict.plausible);
  });

  test('a lost model asks the remote service by itself', () {
    expect(policy.decide([c('Monstera deliciosa', 0.18), c('Ficus elastica', 0.15)]), IdentificationVerdict.uncertain);
  });

  test('order of the list does not matter', () {
    expect(policy.decide([c('Monstera adansonii', 0.03), c('Monstera deliciosa', 0.95)]), IdentificationVerdict.accepted);
  });

  test('empty or floor-level lists have no candidate', () {
    expect(policy.decide(const []), IdentificationVerdict.noCandidate);
    expect(policy.decide([c('Monstera deliciosa', 0.04), c('Ficus elastica', 0.03)]), IdentificationVerdict.noCandidate);
  });

  test('custom thresholds are honoured', () {
    const loose = FallbackPolicy(acceptThreshold: 0.6, minMargin: 0.1, plausibleThreshold: 0.2);
    expect(loose.decide([c('A', 0.65), c('B', 0.5)]), IdentificationVerdict.accepted);
    expect(loose.decide([c('A', 0.65), c('B', 0.6)]), IdentificationVerdict.plausible);
    expect(loose.decide([c('A', 0.15), c('B', 0.14)]), IdentificationVerdict.uncertain);
  });
}
