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

  test('keeps the reference photo, its author and its licence', () {
    const body = '''
    {"results": [
      {"score": 0.92, "species": {"scientificNameWithoutAuthor": "Monstera deliciosa"},
       "images": [{"url": {"o": "https://x/o.jpg", "m": "https://x/m.jpg", "s": "https://x/s.jpg"}, "license": "cc-by-sa", "author": "Ana"}]},
      {"score": 0.05, "species": {"scientificNameWithoutAuthor": "Monstera adansonii"},
       "images": [{"url": {"m": "https://x/m2.jpg"}, "license": "cc-by"}]},
      {"score": 0.03, "species": {"scientificNameWithoutAuthor": "Philodendron hederaceum"},
       "images": [
         {"url": {"s": "https://x/nc.jpg"}, "license": "cc-by-nc-sa"},
         {"url": {"s": "https://x/libre.jpg"}, "license": "cc0"}
       ]},
      {"score": 0.02, "species": {"scientificNameWithoutAuthor": "Epipremnum aureum"},
       "images": [{"url": {"s": "pas-une-url"}, "license": "cc-by"}, {"url": {"s": "https://x/muet.jpg"}}]},
      {"score": 0.01, "species": {"scientificNameWithoutAuthor": "Rhaphidophora tetrasperma"}}
    ]}''';
    final r = PlantNetIdentifier.parse(body);
    // La plus petite des trois tailles : c'est une vignette de liste.
    expect(r[0].image?.url, 'https://x/s.jpg');
    expect(r[0].image?.rightsHolder, 'Ana');
    expect(r[0].image?.licenseLabel, 'CC BY-SA');
    // Sans « s », la taille suivante fait l'affaire.
    expect(r[1].image?.url, 'https://x/m2.jpg');
    // Une photo qu'on n'a pas le droit de montrer est passée, pas gardée.
    expect(r[2].image?.url, 'https://x/libre.jpg');
    // Ce qui n'est pas une URL, ou n'a pas de licence, n'est pas affichable —
    // et l'espèce reste proposée malgré tout, sans vignette.
    expect(r[3].image, isNull);
    expect(r[4].image, isNull);
    expect(r.map((c) => c.scientificName).length, 5);
  });

  test('unconfigured key is reported', () {
    expect(PlantNetIdentifier('').isConfigured, isFalse);
    expect(PlantNetIdentifier(' abc ').isConfigured, isTrue);
  });
}
