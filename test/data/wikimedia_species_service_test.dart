import 'package:flora/data/services/wikimedia_species_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const valide = '''
  {"query":{"pages":[
    {"title":"File:Pilea peperomioides.jpg","imageinfo":[{"mime":"image/jpeg","thumburl":"https://upload.wikimedia.org/pilea-640.jpg","url":"https://upload.wikimedia.org/pilea.jpg","extmetadata":{"LicenseUrl":{"value":"https://creativecommons.org/licenses/by/3.0"},"Artist":{"value":"<a href=\\"//commons.wikimedia.org/wiki/User:Jane\\">Jane Doe</a>"}}}]},
    {"title":"File:Pilea peperomioides (herbarium).jpg","imageinfo":[{"mime":"image/jpeg","thumburl":"https://x/herbier.jpg","extmetadata":{"LicenseUrl":{"value":"https://creativecommons.org/licenses/by/4.0"}}}]},
    {"title":"File:Pilea peperomioides distribution map.png","imageinfo":[{"mime":"image/png","thumburl":"https://x/carte.png","extmetadata":{"LicenseUrl":{"value":"https://creativecommons.org/publicdomain/zero/1.0/"}}}]},
    {"title":"File:Pilea peperomioides NC.jpg","imageinfo":[{"mime":"image/jpeg","thumburl":"https://x/nc.jpg","extmetadata":{"LicenseUrl":{"value":"https://creativecommons.org/licenses/by-nc/4.0/"}}}]},
    {"title":"File:Pilea peperomioides scan.tif","imageinfo":[{"mime":"image/tiff","thumburl":"https://x/scan.tif","extmetadata":{"LicenseUrl":{"value":"https://creativecommons.org/publicdomain/zero/1.0/"}}}]},
    {"title":"File:Pilea peperomioides sans licence.jpg","imageinfo":[{"mime":"image/jpeg","thumburl":"https://x/sans-licence.jpg","extmetadata":{}}]},
    {"title":"File:Pilea peperomioides CC0.jpg","imageinfo":[{"mime":"image/jpeg","thumburl":"https://x/cc0.jpg","extmetadata":{"LicenseShortName":{"value":"CC0"}}}]},
    {"title":"File:Pilea peperomioides doublon.jpg","imageinfo":[{"mime":"image/jpeg","thumburl":"https://upload.wikimedia.org/pilea-640.jpg","extmetadata":{"LicenseUrl":{"value":"https://creativecommons.org/licenses/by/4.0"}}}]}
  ]}}
  ''';

  test('ne garde que les photos libres, écarte les herbiers et nettoie l\'auteur', () {
    final images = WikimediaSpeciesService.parsePhotos(valide);
    expect(images.map((i) => i.url), ['https://upload.wikimedia.org/pilea-640.jpg', 'https://x/cc0.jpg']);
    expect(images.first.license, 'https://creativecommons.org/licenses/by/3.0');
    expect(images.first.rightsHolder, 'Jane Doe');
    expect(images.last.licenseLabel, 'CC0');
  });

  group('la source Commons', () {
    test('interroge la recherche de fichiers et garde l\'en-tête identifiable', () async {
      late Uri uri;
      late String? userAgent;
      final service = WikimediaSpeciesService(client: MockClient((req) async {
        uri = req.url;
        userAgent = req.headers['User-Agent'];
        return http.Response('{"query":{"pages":[]}}', 200);
      }));
      await service.photos('Pilea peperomioides');
      expect(uri.host, 'commons.wikimedia.org');
      expect(uri.path, '/w/api.php');
      expect(uri.queryParameters['gsrsearch'], 'intitle:"Pilea peperomioides"');
      expect(uri.queryParameters['gsrnamespace'], '6');
      expect(uri.queryParameters['prop'], 'imageinfo');
      expect(userAgent, isNotEmpty);
    });

    test('met en cache le résultat et ne redemande pas', () async {
      var calls = 0;
      final service = WikimediaSpeciesService(client: MockClient((_) async {
        calls++;
        return http.Response(valide, 200);
      }));
      await service.photos('Pilea peperomioides');
      await service.photos('Pilea peperomioides');
      expect(calls, 1);
    });

    test('un nom vide ne part pas sur le réseau', () async {
      final service = WikimediaSpeciesService(client: MockClient((_) async => fail('aucune requête attendue')));
      expect(await service.photos('   '), isEmpty);
    });

    test('réseau coupé : pas de photo, pas d\'exception, et on retentera', () async {
      var calls = 0;
      final service = WikimediaSpeciesService(client: MockClient((_) async {
        calls++;
        throw const SocketExceptionStub();
      }));
      expect(await service.photos('Pilea peperomioides'), isEmpty);
      expect(await service.photos('Pilea peperomioides'), isEmpty);
      expect(calls, 2, reason: 'une panne réseau ne se mémorise pas');
    });
  });
}

/// Une panne réseau, sans dépendre de `dart:io` dans un test.
class SocketExceptionStub implements Exception {
  const SocketExceptionStub();
}
