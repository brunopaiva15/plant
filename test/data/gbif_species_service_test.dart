import 'package:flora/data/services/gbif_species_service.dart';
import 'package:flora/domain/species/species_info.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

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

  test('SpeciesImage reads the plain licence codes Pl@ntNet returns', () {
    expect(const SpeciesImage(url: 'u', license: 'cc-by-sa').licenseLabel, 'CC BY-SA');
    expect(const SpeciesImage(url: 'u', license: 'cc-by-nc-sa').licenseLabel, 'CC BY-NC-SA');
    expect(const SpeciesImage(url: 'u', license: 'cc0').licenseLabel, 'CC0');
    expect(const SpeciesImage(url: 'u', license: 'http://creativecommons.org/publicdomain/zero/1.0/').licenseLabel, 'CC0');
    expect(const SpeciesImage(url: 'u', license: 'tous droits réservés').licenseLabel, 'tous droits réservés');
  });

  test('SpeciesImage tells apart what may be shown from what may not', () {
    const shown = [
      'http://creativecommons.org/licenses/by/4.0/',
      'http://creativecommons.org/licenses/by-sa/3.0/',
      'http://creativecommons.org/publicdomain/zero/1.0/',
      'cc-by',
      'cc0',
    ];
    const hidden = [
      'http://creativecommons.org/licenses/by-nc/4.0/',
      'http://creativecommons.org/licenses/by-nc-sa/4.0/',
      'http://creativecommons.org/licenses/by-nd/4.0/',
      'cc-by-nc-sa',
      'tous droits réservés',
      '',
    ];
    for (final l in shown) {
      expect(SpeciesImage(url: 'u', license: l).isFreelyDisplayable, isTrue, reason: l);
    }
    for (final l in hidden) {
      expect(SpeciesImage(url: 'u', license: l).isFreelyDisplayable, isFalse, reason: l);
    }
    // Sans mention de licence, on s'abstient.
    expect(const SpeciesImage(url: 'u').isFreelyDisplayable, isFalse);
  });

  group('la vignette d\'un candidat', () {
    const match = '{"usageKey":2868241,"matchType":"EXACT"}';
    const occurrence =
        '{"results":[{"country":"Brazil","media":[{"identifier":"https://x/1.jpg","license":"http://creativecommons.org/licenses/by/4.0/","rightsHolder":"Ana"}]}]}';

    test('accorde le nom puis prend une photo, et ne la redemande pas', () async {
      final calls = <String>[];
      final service = GbifSpeciesService(client: MockClient((req) async {
        calls.add(req.url.path);
        return http.Response(req.url.path.contains('match') ? match : occurrence, 200);
      }));
      final image = await service.thumbnail('Monstera deliciosa');
      expect(image?.url, 'https://x/1.jpg');
      expect(image?.rightsHolder, 'Ana');
      expect(calls, ['/v1/species/match', '/v1/occurrence/search']);

      // Deuxième passage : la feuille se rouvre, le réseau ne bouge plus.
      expect((await service.thumbnail('Monstera deliciosa'))?.url, 'https://x/1.jpg');
      expect(calls.length, 2);
    });

    test('un nom inconnu de GBIF ne coûte qu\'une requête, une seule fois', () async {
      var calls = 0;
      final service = GbifSpeciesService(client: MockClient((_) async {
        calls++;
        return http.Response('{"matchType":"NONE"}', 200);
      }));
      expect(await service.thumbnail('Plantus inventus'), isNull);
      expect(await service.thumbnail('Plantus inventus'), isNull);
      expect(calls, 1);
    });

    test('réseau coupé : pas de vignette, pas d\'exception, et on retentera', () async {
      var calls = 0;
      final service = GbifSpeciesService(client: MockClient((_) async {
        calls++;
        throw const SocketExceptionStub();
      }));
      expect(await service.thumbnail('Monstera deliciosa'), isNull);
      expect(await service.thumbnail('Monstera deliciosa'), isNull);
      expect(calls, 2, reason: 'une panne réseau ne se mémorise pas');
    });

    test('écarte une photo qu\'on n\'a pas le droit de montrer', () async {
      const mixed = '''{"results":[
        {"media":[{"identifier":"https://x/nc.jpg","license":"http://creativecommons.org/licenses/by-nc/4.0/"}]},
        {"media":[{"identifier":"https://x/libre.jpg","license":"http://creativecommons.org/licenses/by/4.0/","rightsHolder":"Bo"}]}
      ]}''';
      final service = GbifSpeciesService(client: MockClient((req) async =>
          http.Response(req.url.path.contains('match') ? match : mixed, 200)));
      expect((await service.thumbnail('Monstera deliciosa'))?.url, 'https://x/libre.jpg');
    });

    test('demande à GBIF les seules licences affichables', () async {
      late Uri occurrence;
      final service = GbifSpeciesService(client: MockClient((req) async {
        if (!req.url.path.contains('match')) occurrence = req.url;
        return http.Response(req.url.path.contains('match') ? match : '{"results":[]}', 200);
      }));
      await service.thumbnail('Monstera deliciosa');
      expect(occurrence.queryParametersAll['license'], ['CC0_1_0', 'CC_BY_4_0']);
      expect(occurrence.queryParameters['mediaType'], 'StillImage');
    });

    test('un nom vide ne part pas sur le réseau', () async {
      final service = GbifSpeciesService(client: MockClient((_) async => fail('aucune requête attendue')));
      expect(await service.thumbnail('   '), isNull);
    });
  });
}

/// Une panne réseau, sans dépendre de `dart:io` dans un test.
class SocketExceptionStub implements Exception {
  const SocketExceptionStub();
}
