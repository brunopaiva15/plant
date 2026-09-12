import 'dart:convert';
import 'dart:io';

import 'package:flora/app/providers.dart';
import 'package:flora/data/services/photo_storage_service.dart';
import 'package:flora/design_system/design_system.dart';
import 'package:flora/domain/models/models.dart';
import 'package:flora/features/plants/application/plant_providers.dart';
import 'package:flora/features/plants/presentation/photo_viewer.dart';
import 'package:flora/l10n/generated/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// La visionneuse : ce qu'elle dit autour de la photo, et les gestes qui
/// la font vivre — toucher pour faire place nette, glisser pour passer à la
/// suivante, tirer vers le bas pour la refermer.

class _FakePaths extends PathProviderPlatform with MockPlatformInterfaceMixin {
  _FakePaths(this.root);

  final String root;

  @override
  Future<String?> getApplicationDocumentsPath() async => root;

  @override
  Future<String?> getTemporaryPath() async => root;
}

void _photoFiles(Directory root, List<String> names) {
  final dir = Directory('${root.path}/photos')..createSync(recursive: true);
  final png = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==');
  for (final n in names) {
    File('${dir.path}/$n').writeAsBytesSync(png);
  }
}

PlantPhoto _photo(String id, {String? label, DateTime? takenAt}) => PlantPhoto(
      id: id,
      plantId: 'p1',
      filePath: '$id.jpg',
      thumbPath: '${id}_thumb.jpg',
      width: 1,
      height: 1,
      takenAt: takenAt ?? DateTime(2026, 6, 1),
      createdAt: DateTime(2026, 6, 1),
      label: label,
    );

void main() {
  late Directory temp;
  final photos = [_photo('a', label: 'Nouvelle feuille', takenAt: DateTime(2026, 6, 15)), _photo('b', takenAt: DateTime(2026, 5, 1))];

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('flora-viewer');
    PathProviderPlatform.instance = _FakePaths(temp.path);
    _photoFiles(temp, ['a.jpg', 'a_thumb.jpg', 'b.jpg', 'b_thumb.jpg']);
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  /// Un écran d'accueil dont le bouton ouvre la visionneuse, comme le ferait
  /// une vignette : la visionneuse est une route au-dessus, qu'on peut
  /// refermer.
  Future<void> open(WidgetTester tester, {String photoId = 'a'}) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        plantPhotosProvider.overrideWith((ref, id) => Stream.value(photos)),
        plantSummaryProvider.overrideWith((ref, id) => Stream.value(null)),
        photoStorageProvider.overrideWithValue(PhotoStorageService()),
      ],
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildFloraTheme(Brightness.light),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () => showPhotoViewer(context, plantId: 'p1', photoId: photoId, photos: photos, primaryId: 'a'),
                child: const Text('ouvrir'),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('autour de la photo : le compte, la date, le titre, les quatre gestes', (tester) async {
    await open(tester);

    expect(find.byType(PhotoViewer), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.text('Nouvelle feuille'), findsOneWidget);
    expect(find.text('Titre'), findsOneWidget);
    expect(find.text('Principale'), findsOneWidget);
    expect(find.text('Partager'), findsOneWidget);
    expect(find.text('Supprimer'), findsOneWidget);
    // C'est la principale : l'étoile est pleine.
    expect(find.byIcon(CupertinoIcons.star_fill), findsOneWidget);
  });

  testWidgets('la suivante, et son invite à titrer', (tester) async {
    await open(tester);
    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();

    expect(find.text('2 / 2'), findsOneWidget);
    // Pas de titre : l'invite prend sa place, et l'étoile est vide.
    expect(find.text('Ajouter un titre'), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.star), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.star_fill), findsNothing);
  });

  testWidgets('toucher fait place nette, toucher encore ramène tout', (tester) async {
    await open(tester);
    AnimatedOpacity chrome() => tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity).first);
    // Un toucher n'est tenu pour simple qu'une fois le délai du double
    // toucher passé : le banc d'essai doit laisser ce temps s'écouler.
    Future<void> tapPhoto() async {
      await tester.tap(find.byType(PageView));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
    }

    expect(chrome().opacity, 1);

    await tapPhoto();
    expect(chrome().opacity, 0);
    expect(find.byType(PhotoViewer), findsOneWidget, reason: 'toucher ne referme plus la visionneuse');

    await tapPhoto();
    expect(chrome().opacity, 1);
  });

  testWidgets('tirer vers le bas referme', (tester) async {
    await open(tester);
    await tester.drag(find.byType(PageView), const Offset(0, 260));
    await tester.pumpAndSettle();
    expect(find.byType(PhotoViewer), findsNothing);
  });

  testWidgets('un petit geste ne referme pas : la photo revient en place', (tester) async {
    await open(tester);
    await tester.drag(find.byType(PageView), const Offset(0, 40));
    await tester.pumpAndSettle();
    expect(find.byType(PhotoViewer), findsOneWidget);
    expect(tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity).first).opacity, 1);
  });

  testWidgets('toucher deux fois agrandit, et bloque le passage de page', (tester) async {
    await open(tester);
    final page = find.byType(PageView);
    await tester.tap(page);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(page);
    await tester.pumpAndSettle();

    final viewer = tester.widget<InteractiveViewer>(find.byType(InteractiveViewer).first);
    expect(viewer.transformationController!.value.getMaxScaleOnAxis(), closeTo(2.5, 0.01));
    expect(tester.widget<PageView>(page).physics, isA<NeverScrollableScrollPhysics>());
  });
}
