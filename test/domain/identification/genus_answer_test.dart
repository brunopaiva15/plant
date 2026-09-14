import 'package:flora/core/utils/scientific_name.dart';
import 'package:flora/domain/identification/identification_policy.dart';
import 'package:flora/domain/identification/plant_identifier.dart';
import 'package:flutter_test/flutter_test.dart';

IdentificationCandidate c(String name, double score, {IdentificationSource source = IdentificationSource.local}) =>
    IdentificationCandidate(scientificName: name, score: score, source: source);

/// Répondre au genre quand l'espèce renonce. Ce qui se tromperait en
/// silence : une masse mal sommée, ou un genre qui prendrait la place d'une
/// espèce que le modèle savait nommer — une perte déguisée en gain.
void main() {
  const policy = FallbackPolicy();

  group('le genre d’un nom', () {
    test('le premier mot, normalisé', () {
      expect(genusOf('Picea abies'), 'Picea');
      expect(genusOf('picea  ABIES'), 'Picea');
      expect(genusOf('Citrus × limon'), 'Citrus');
    });

    test('un hybride intergénérique porte son nom après le signe', () {
      expect(genusOf('× Fatshedera lizei'), 'Fatshedera');
    });

    test('rien à tirer d’un nom vide', () => expect(genusOf('   '), ''));
  });

  group('la réponse au genre', () {
    test('cinq Picea à 0,15 pèsent 0,75 et répondent', () {
      final g = genusAnswer(policy, [
        c('Picea abies', 0.16), c('Picea glauca', 0.15), c('Picea pungens', 0.15),
        c('Picea mariana', 0.15), c('Picea sitchensis', 0.15),
      ]);
      expect(g, isNotNull);
      expect(g!.genus, 'Picea');
      expect(g.mass, closeTo(0.76, 1e-9));
      expect(g.species, 5);
    });

    test('une espèce qui passe le seuil répond seule', () {
      // Même quand son genre est plus sûr encore : un nom d'espèce vaut
      // mieux qu'un nom de genre, et le genre n'est là que pour le vide.
      expect(genusAnswer(policy, [c('Picea abies', 0.75), c('Picea glauca', 0.2)]), isNull);
    });

    test('un genre trop léger ne répond pas : le repli garde sa raison d’être', () {
      expect(genusAnswer(policy, [c('Picea abies', 0.3), c('Monstera deliciosa', 0.3), c('Picea glauca', 0.2)]), isNull);
    });

    test('une espèce seule dans son genre n’ajoute rien', () {
      // Sa masse est son score : elle ne peut pas passer au genre ce qu'elle
      // ne passait pas à l'espèce.
      expect(genusAnswer(policy, [c('Monstera deliciosa', 0.65), c('Picea abies', 0.2)]), isNull);
    });

    test('le genre le plus lourd gagne, pas celui de la première candidate', () {
      final g = genusAnswer(policy, [
        c('Monstera deliciosa', 0.28), c('Picea abies', 0.26), c('Picea glauca', 0.25), c('Picea mariana', 0.2),
      ]);
      expect(g!.genus, 'Picea');
      expect(g.species, 3);
    });

    test('une réponse distante a déjà tranché', () {
      expect(genusAnswer(policy, [
        c('Picea abies', 0.4, source: IdentificationSource.remote),
        c('Picea glauca', 0.4, source: IdentificationSource.remote),
      ]), isNull);
    });

    test('sans candidate, rien', () => expect(genusAnswer(policy, const []), isNull));
  });
}
