import 'package:flora/data/services/gbif_species_service.dart';
import 'package:flora/domain/species/species_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses search results into suggestions with a common name in the requested language', () {
    const body = '''{"results":[
      {"key":2868214,"canonicalName":"Monstera acuminata","family":"Araceae","vernacularNames":[{"vernacularName":"Spitzes Fensterblatt","language":"deu"},{"vernacularName":"Piñanona","language":"spa"}]},
      {"key":2868241,"canonicalName":"Monstera deliciosa","family":"Araceae","vernacularNames":[{"vernacularName":"Faux philodendron","language":"fra"}]},
      {"key":1,"canonicalName":"Monstera deliciosa","family":"Araceae"}
    ]}''';
    final s = GbifSpeciesService.parseSuggestions(body, languageCode: 'fr');
    expect(s.map((x) => x.scientificName), ['Monstera acuminata', 'Monstera deliciosa']);
    expect(s[1].commonName, 'Faux philodendron');
    expect(s[0].commonName, isNull);
  });

  test('parses taxon, vernacular names and occurrence images with attribution', () {
    var info = GbifSpeciesService.parseTaxon('{"key":2868241,"scientificName":"Monstera deliciosa Liebm.","canonicalName":"Monstera deliciosa","authorship":"Liebm.","rank":"SPECIES","taxonomicStatus":"ACCEPTED","kingdom":"Plantae","order":"Alismatales","family":"Araceae","genus":"Monstera"}');
    info = info.copyWith(
      commonNames: GbifSpeciesService.parseVernacular('{"results":[{"vernacularName":"Faux philodendron","language":"fra"},{"vernacularName":"faux philodendron","language":"fra"},{"vernacularName":"Ceriman","language":"eng"}]}'),
      images: GbifSpeciesService.parseOccurrenceImages('{"results":[{"country":"Brazil","media":[{"identifier":"https://x/1.jpg","license":"http://creativecommons.org/licenses/by-nc/4.0/","rightsHolder":"Ana"}]},{"media":[{"identifier":"not-a-url"}]}]}'),
    );
    expect(info.family, 'Araceae');
    expect(info.commonNamesFor('fr'), ['Faux philodendron']);
    expect(info.commonNamesFor('en'), ['Ceriman']);
    expect(info.images.single.licenseLabel, 'CC BY-NC 4.0');
    expect(info.images.single.rightsHolder, 'Ana');
    expect(info.gbifUrl, 'https://www.gbif.org/species/2868241');
  });

  test('SpeciesImage license label falls back to the raw value', () {
    expect(const SpeciesImage(url: 'u', license: 'CC0').licenseLabel, 'CC0');
    expect(const SpeciesImage(url: 'u').licenseLabel, isNull);
  });
}
