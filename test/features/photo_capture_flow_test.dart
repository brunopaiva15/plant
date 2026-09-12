import 'dart:convert';
import 'dart:io';

import 'package:flora/app/providers.dart';
import 'package:flora/data/services/photo_storage_service.dart';
import 'package:flora/design_system/design_system.dart';
import 'package:flora/domain/models/models.dart';
import 'package:flora/features/plants/application/plant_providers.dart';
import 'package:flora/features/plants/presentation/photo_capture_flow.dart';
import 'package:flora/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Le flow guidé d'ajout de photo.
///
/// Ce qu'il doit dire : où l'on en est (première photo ou nouvelle), les
/// trois portes pour en apporter une, et — une fois la photo prise — un
/// titre qui se remplit d'un geste, la photo principale seulement quand la
/// question se pose.

class _FakePaths extends PathProviderPlatform with MockPlatformInterfaceMixin {
  _FakePaths(this.root);

  final String root;

  @override
  Future<String?> getApplicationDocumentsPath() async => root;

  @override
  Future<String?> getTemporaryPath() async => root;
}

/// Un PNG d'un pixel dans le dossier des photos : `PlantImage` a alors un
/// vrai fichier à lire.
String _photoFile(Directory root) {
  final dir = Directory('${root.path}/photos')..createSync(recursive: true);
  File('${dir.path}/p_thumb.jpg').writeAsBytesSync(base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=='));
  return 'p_thumb.jpg';
}

PlantPhoto _photo(String id, {DateTime? takenAt}) => PlantPhoto(
      id: id,
      plantId: 'p1',
      filePath: 'p.jpg',
      thumbPath: 'p_thumb.jpg',
      width: 1,
      height: 1,
      takenAt: takenAt ?? DateTime(2026, 6, 1),
      createdAt: DateTime(2026, 6, 1),
    );

Widget _app(Widget child, {List<PlantPhoto> photos = const []}) => ProviderScope(
      overrides: [
        plantPhotosProvider.overrideWith((ref, id) => Stream.value(photos)),
        photoStorageProvider.overrideWithValue(PhotoStorageService()),
      ],
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildFloraTheme(Brightness.light),
        home: child,
      ),
    );

void main() {
  late Directory temp;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('flora-photo-flow');
    PathProviderPlatform.instance = _FakePaths(temp.path);
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  testWidgets('sans viseur, la première étape garde son invite et ses trois portes', (tester) async {
    await tester.pumpWidget(_app(const PhotoCaptureFlow(plantId: 'p1')));
    await tester.pumpAndSettle();

    // Pas encore de photo : le titre le dit, et explique ce qu'elle deviendra.
    expect(find.text('Première photo'), findsOneWidget);
    expect(find.textContaining('photo principale'), findsOneWidget);
    // L'invite du cadre et le bouton disent le même geste.
    expect(find.text('Prendre une photo'), findsNWidgets(2));
    expect(find.text('Choisir une photo'), findsOneWidget);
    expect(find.text('Depuis une adresse web'), findsOneWidget);
    // Le calque ne se propose pas sans viseur : il n'y aurait rien dessous.
    expect(find.text('Superposer la dernière photo'), findsNothing);
    expect(find.byType(StepDots), findsOneWidget);
  });

  testWidgets('avec des photos, le titre change et le cadrage est conseillé', (tester) async {
    _photoFile(temp);
    await tester.pumpWidget(_app(const PhotoCaptureFlow(plantId: 'p1'), photos: [_photo('a')]));
    await tester.pumpAndSettle();

    expect(find.text('Nouvelle photo'), findsOneWidget);
    expect(find.textContaining('même cadrage'), findsOneWidget);
    expect(find.text('Première photo'), findsNothing);
  });

  group('l\'étape du titre', () {
    late TextEditingController label;

    setUp(() => label = TextEditingController());
    tearDown(() => label.dispose());

    Future<void> pump(WidgetTester tester, {bool? makePrimary, VoidCallback? onSave}) async {
      // Un écran de téléphone, en hauteur : sur les 800 × 600 du banc
      // d'essai, les puces passent sous le pli et le doigt ne les trouve pas.
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final file = _photoFile(temp);
      await tester.pumpWidget(_app(Scaffold(
        body: PhotoReviewStep(
          thumbPath: file,
          label: label,
          makePrimary: makePrimary,
          onPrimaryChanged: (_) {},
          onSave: onSave ?? () {},
          onRetake: () {},
        ),
      )));
      await tester.pumpAndSettle();
    }

    testWidgets('une suggestion remplit le titre, la même le vide', (tester) async {
      await pump(tester);
      expect(find.text('Titre'), findsOneWidget);

      // La puce, pas le champ : une fois remplie, le champ porte le même mot.
      Finder chip(String s) => find.widgetWithText(FloraChip, s);

      await tester.tap(chip('Nouvelle feuille'));
      await tester.pumpAndSettle();
      expect(label.text, 'Nouvelle feuille');

      // Une autre suggestion remplace : un seul titre à la fois.
      await tester.tap(chip('Floraison'));
      await tester.pumpAndSettle();
      expect(label.text, 'Floraison');

      // La même une seconde fois efface : la puce se comporte comme une case.
      await tester.tap(chip('Floraison'));
      await tester.pumpAndSettle();
      expect(label.text, isEmpty);
    });

    testWidgets('la photo principale ne se demande que si la question se pose', (tester) async {
      // Première photo : elle sera principale de toute façon.
      await pump(tester, makePrimary: null);
      expect(find.text('Photo principale'), findsNothing);

      // Il y en a déjà : l'interrupteur apparaît, éteint.
      await pump(tester, makePrimary: false);
      expect(find.text('Photo principale'), findsOneWidget);
      expect(find.byType(AdaptiveSwitch), findsOneWidget);
    });

    testWidgets('« Enregistrer » enregistre, « Reprendre » est là', (tester) async {
      var saved = 0;
      await pump(tester, onSave: () => saved++);
      expect(find.text('Reprendre'), findsOneWidget);
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      expect(saved, 1);
    });
  });
}
