import 'dart:convert';
import 'dart:io';

import 'package:flora/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// La vignette d'une plante, et ce qu'elle fait quand on la reconstruit.
///
/// Le dossier des photos ne se connaît qu'en demandant au système, une fois.
/// Tant qu'on le redemandait à chaque construction, la vignette repartait de
/// son aplat d'attente à chaque fois : sur la grille de la collection, qui
/// se reconstruit au fil des soins, la photo n'arrivait jamais — les visuels
/// du magasin la montraient grise.

class _FakePaths extends PathProviderPlatform with MockPlatformInterfaceMixin {
  _FakePaths(this.root);

  final String root;

  @override
  Future<String?> getApplicationDocumentsPath() async => root;

  @override
  Future<String?> getTemporaryPath() async => root;
}

Widget _host(Widget child) => ProviderScope(
      child: Theme(
        data: buildFloraTheme(Brightness.light),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: SizedBox(width: 120, height: 120, child: child)),
        ),
      ),
    );

void main() {
  late Directory temp;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('flora-vignette');
    PathProviderPlatform.instance = _FakePaths(temp.path);
    final dir = Directory('${temp.path}/photos')..createSync(recursive: true);
    // Un pixel, mais un vrai fichier : Image.file le décode pour de bon.
    File('${dir.path}/a_thumb.jpg').writeAsBytesSync(
      base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=='),
    );
  });

  tearDown(() => temp.deleteSync(recursive: true));

  testWidgets('la photo est là dès la première image après une remontée', (tester) async {
    var key = UniqueKey();
    late StateSetter remount;
    await tester.pumpWidget(_host(
      StatefulBuilder(
        builder: (context, setState) {
          remount = setState;
          return PlantImage(key: key, relativePath: 'a_thumb.jpg', cacheWidth: 64);
        },
      ),
    ));
    // Le dossier des photos se résout par une vraie écriture sur le disque :
    // en temps simulé, sa promesse ne se terminerait jamais.
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump();
    expect(find.byType(Image), findsOneWidget);

    // Une clé neuve remonte la vignette, comme le fait la carte de la
    // collection quand son onglet redevient visible. Le dossier est connu :
    // la photo doit être là tout de suite. Tant qu'on le redemandait par une
    // promesse, cette image-ci montrait l'aplat d'attente.
    remount(() => key = UniqueKey());
    await tester.pump();
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('sans chemin, la vignette montre son emoji', (tester) async {
    await tester.pumpWidget(_host(const PlantImage()));
    await tester.pumpAndSettle();
    expect(find.text('🪴'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });
}
