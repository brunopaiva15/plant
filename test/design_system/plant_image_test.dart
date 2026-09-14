import 'dart:convert';
import 'dart:io';

import 'package:flora/app/providers.dart';
import 'package:flora/data/services/photo_storage_service.dart';
import 'package:flora/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// La vignette d'une plante, et ce qu'elle fait quand on la remonte.
///
/// Le dossier des photos ne se connaît qu'en demandant au système, une fois.
/// Tant qu'on le redemandait par une promesse née dans `build`, la vignette
/// repartait de son aplat d'attente à chaque remontée — et la carte de la
/// collection en connaît une chaque fois que son onglet redevient visible.
/// Les visuels du magasin montraient la grille toute grise.

class _FakePaths extends PathProviderPlatform with MockPlatformInterfaceMixin {
  _FakePaths(this.root);

  final String root;

  @override
  Future<String?> getApplicationDocumentsPath() async => root;

  @override
  Future<String?> getTemporaryPath() async => root;
}

void main() {
  late Directory temp;
  late PhotoStorageService storage;

  Widget host(Widget child) => ProviderScope(
        overrides: [photoStorageProvider.overrideWithValue(storage)],
        child: Theme(
          data: buildFloraTheme(Brightness.light),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(child: SizedBox(width: 120, height: 120, child: child)),
          ),
        ),
      );

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('flora-vignette');
    PathProviderPlatform.instance = _FakePaths(temp.path);
    Directory('${temp.path}/photos').createSync(recursive: true);
    // Un pixel, mais un vrai fichier : Image.file le décode pour de bon.
    File('${temp.path}/photos/a_thumb.jpg').writeAsBytesSync(
      base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=='),
    );
    // Le dossier se résout en touchant vraiment le disque. On le fait ici,
    // hors du temps simulé du test, où cette promesse ne finirait jamais ;
    // l'application, elle, le fait une fois au démarrage.
    storage = PhotoStorageService();
    await storage.photosDirectory();
  });

  tearDown(() => temp.deleteSync(recursive: true));

  testWidgets('la photo est là dès la première image après une remontée', (tester) async {
    var key = UniqueKey();
    late StateSetter remount;
    await tester.pumpWidget(host(
      StatefulBuilder(
        builder: (context, setState) {
          remount = setState;
          return PlantImage(key: key, relativePath: 'a_thumb.jpg', cacheWidth: 64);
        },
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsOneWidget);

    // Une clé neuve remonte la vignette. Le dossier est connu : la photo
    // doit être là tout de suite, sans une image d'attente au passage.
    remount(() => key = UniqueKey());
    await tester.pump();
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('sans chemin, la vignette montre son emoji', (tester) async {
    await tester.pumpWidget(host(const PlantImage()));
    await tester.pumpAndSettle();
    expect(find.text('🪴'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });
}
