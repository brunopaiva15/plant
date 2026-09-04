import 'package:flora/features/qr/application/plant_links.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('encode / decode round-trip', () {
    const id = '4b3c9d5e-1111-2222-3333-444455556666';
    expect(PlantLinks.decode(PlantLinks.encode(id)), id);
  });

  test('rejects foreign or malformed payloads', () {
    expect(PlantLinks.decode('https://example.com/plant/abc'), isNull);
    expect(PlantLinks.decode('flora://location/abc'), isNull);
    expect(PlantLinks.decode('flora://plant/'), isNull);
    expect(PlantLinks.decode('not a uri at all ::'), isNull);
  });
}
