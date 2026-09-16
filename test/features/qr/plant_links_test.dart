import 'package:flora/features/qr/application/plant_links.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlantLinks species', () {
    test('encode et décode un nom scientifique avec espace', () {
      final encoded = PlantLinks.encodeSpecies('Monstera deliciosa');

      expect(encoded, contains('species/Monstera%20deliciosa'));
      expect(
        PlantLinks.decodeLink(encoded),
        const FloraLink(FloraLinkKind.species, 'Monstera deliciosa'),
      );
    });

    test('préserve les noms hybrides', () {
      final encoded = PlantLinks.encodeSpecies('Begonia × semperflorens-cultorum');

      expect(
        PlantLinks.decodeLink(encoded),
        const FloraLink(FloraLinkKind.species, 'Begonia × semperflorens-cultorum'),
      );
    });
  });
}
