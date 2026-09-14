import 'package:flora/domain/identification/identification_policy.dart';
import 'package:flora/domain/identification/plant_identifier.dart';
import 'package:flora/features/identification/presentation/genus_row.dart';
import 'package:flutter_test/flutter_test.dart';

/// La candidate de synthèse que retenir le genre produit. Elle traverse tout
/// le reste de l'application comme une candidate ordinaire : ce qu'elle
/// porte doit donc être juste.
void main() {
  test('elle porte le nom du genre, et son nom commun quand il existe', () {
    final c = genusCandidate(const GenusAnswer(genus: 'Acer', mass: 0.8, species: 4), 'fr');
    expect(c.scientificName, 'Acer');
    expect(c.commonName, 'Érable');
    expect(c.score, closeTo(0.8, 1e-9));
    expect(c.source, IdentificationSource.local);
  });

  test('un genre sans nom commun s’affiche sous son nom scientifique', () {
    final c = genusCandidate(const GenusAnswer(genus: 'Gymnadenia', mass: 0.75, species: 3), 'fr');
    expect(c.commonName, isNull);
    expect(c.scientificName, 'Gymnadenia');
  });

  test('une masse au-dessus de 1 ne déborde pas la confiance affichée', () {
    // Les scores sont arrondis : cinq à 0,21 font 1,05.
    final c = genusCandidate(const GenusAnswer(genus: 'Picea', mass: 1.05, species: 5), 'fr');
    expect(c.score, 1.0);
  });
}
