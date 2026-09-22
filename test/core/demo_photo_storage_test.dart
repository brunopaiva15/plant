import 'dart:io';

import 'package:flora/core/demo/demo_photo_storage.dart';
import 'package:flora/data/services/photo_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// La photothèque du jeu de démo. Un simulateur n'a pas de caméra et sa
/// photothèque ne montre que les images d'Apple : sans ce magasin, l'étape
/// photo de la création n'aurait jamais de plante à lire, et la capture du
/// magasin qui la montre — les noms qu'Iris pose sur la photo — ne pourrait
/// pas se prendre.
void main() {
  test('choisir une photo rend le fichier servi par le jeu de démo', () async {
    final photo = File('store/demo-photos/ficus.jpg');
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    late final String asked;
    server.listen((request) async {
      asked = request.uri.path;
      request.response
        ..headers.contentType = ContentType('image', 'jpeg')
        ..add(photo.readAsBytesSync());
      await request.response.close();
    });
    addTearDown(() => server.close(force: true));

    final storage = DemoPhotoStorage(base: 'http://127.0.0.1:${server.port}/demo-photos');
    final picked = await storage.pickSource(PhotoSource.gallery);

    expect(picked, isNotNull);
    expect(asked, '/demo-photos/ficus.jpg');
    expect(picked!.readAsBytesSync(), photo.readAsBytesSync());
    picked.deleteSync();
  });

  test("l'appareil photo rend la même chose : il n'y en a pas non plus", () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      request.response.add(File('store/demo-photos/monstera.jpg').readAsBytesSync());
      await request.response.close();
    });
    addTearDown(() => server.close(force: true));

    final storage = DemoPhotoStorage(slug: 'monstera', base: 'http://127.0.0.1:${server.port}/demo-photos');
    final picked = await storage.pickSource(PhotoSource.camera);

    expect(picked, isNotNull);
    picked!.deleteSync();
  });

  test('sans serveur en face, rien à rendre plutôt qu’une exception', () async {
    // Un port fermé : le socket est refusé tout de suite.
    final closed = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final port = closed.port;
    await closed.close();

    final storage = DemoPhotoStorage(base: 'http://127.0.0.1:$port/demo-photos');
    expect(await storage.pickSource(PhotoSource.gallery), isNull);
  });
}
