import 'package:flora/data/services/plantnet_identifier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses Pl@ntNet results into candidates ordered as returned', () {
    const body = '''
    {"results": [
      {"score": 0.92, "species": {"scientificNameWithoutAuthor": "Monstera deliciosa", "commonNames": ["Faux philodendron"]}},
      {"score": 0.05, "species": {"scientificNameWithoutAuthor": "Monstera adansonii", "commonNames": []}},
      {"score": 0.01, "species": {"scientificName": "Rhaphidophora tetrasperma"}}
    ]}''';
    final r = PlantNetIdentifier.parse(body);
    expect(r.map((c) => c.scientificName), ['Monstera deliciosa', 'Monstera adansonii', 'Rhaphidophora tetrasperma']);
    expect(r.first.commonName, 'Faux philodendron');
    expect(r[1].commonName, isNull);
    expect(r.first.score, 0.92);
  });

  test('unconfigured key is reported', () {
    expect(PlantNetIdentifier('').isConfigured, isFalse);
    expect(PlantNetIdentifier(' abc ').isConfigured, isTrue);
  });
}
