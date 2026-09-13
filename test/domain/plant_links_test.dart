import 'package:flora/features/qr/application/plant_links.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('encode / decode round-trip', () {
    const id = '4b3c9d5e-1111-2222-3333-444455556666';
    expect(PlantLinks.decode(PlantLinks.encode(id)), id);
  });

  test('rejects foreign or malformed payloads', () {
    expect(PlantLinks.decode('https://example.com/plant/abc'), isNull);
    expect(PlantLinks.decode('auxine://location/abc'), isNull);
    expect(PlantLinks.decode('auxine://plant/'), isNull);
    expect(PlantLinks.decode('not a uri at all ::'), isNull);
  });

  test('le retour du raccourci du climat est un lien comme un autre', () {
    expect(PlantLinks.decodeLink('auxine://home-climate/updated'), const FloraLink(FloraLinkKind.homeClimate, 'updated'));
    expect(PlantLinks.decodeLink('auxine://home-climate/failed'), const FloraLink(FloraLinkKind.homeClimate, 'failed'));
    expect(PlantLinks.decodeLink('auxine://home-climate/'), isNull);
  });
}
