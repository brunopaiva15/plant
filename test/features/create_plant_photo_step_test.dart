import 'dart:io';

import 'package:drift/native.dart';
import 'package:flora/app/providers.dart';
import 'package:flora/data/auth/local_auth_repository.dart';
import 'package:flora/data/db/database.dart';
import 'package:flora/data/services/photo_storage_service.dart';
import 'package:flora/data/services/preferences_service.dart';
import 'package:flora/design_system/design_system.dart';
import 'package:flora/domain/identification/plant_identifier.dart';
import 'package:flora/features/plants/presentation/create_plant_flow.dart';
import 'package:flora/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// L'étape photo de la création, en trois états.
///
/// Ce qu'elle doit dire sans qu'on le devine : d'abord comment cadrer ; une
/// fois la photo prise, que c'est bien elle (elle remplit le cadre), et
/// quoi photographier de plus pour aider Iris — des emplacements nommés,
/// jamais gardés ; et que « Reprendre » efface tout pour recommencer.
///
/// Le banc d'essai n'a pas de caméra : c'est le chemin sans viseur qui est
/// parcouru ici, celui où les gestes reviennent en boutons.

class _FakePaths extends PathProviderPlatform with MockPlatformInterfaceMixin {
  _FakePaths(this.root);

  final String root;

  @override
  Future<String?> getApplicationDocumentsPath() async => root;

  @override
  Future<String?> getTemporaryPath() async => root;
}

/// Le sélecteur du système, remplacé : chaque « choix » dépose une copie de
/// la photo de démo dans le dossier des photos, sans isolate ni plugin.
class _FakeStorage extends PhotoStorageService {
  _FakeStorage(this.root);

  final String root;
  int picked = 0;

  @override
  Future<StoredPhoto?> pick(PhotoSource source) async {
    final dir = Directory('$root/photos')..createSync(recursive: true);
    final name = 'p${++picked}';
    for (final suffix in ['.jpg', '_thumb.jpg']) {
      File('store/demo-photos/monstera.jpg').copySync('${dir.path}/$name$suffix');
    }
    return StoredPhoto(filePath: '$name.jpg', thumbPath: '${name}_thumb.jpg', width: 800, height: 1000);
  }

  // Sans entrée/sortie asynchrone : le temps simulé du banc d'essai ne
  // l'achèverait jamais, et l'étape resterait à attendre.
  @override
  Future<String> absolutePath(String relative) async => '$root/photos/$relative';

  @override
  Future<void> deleteFiles(String filePath, String thumbPath) async {
    for (final rel in [filePath, thumbPath]) {
      final f = File('$root/photos/$rel');
      if (f.existsSync()) f.deleteSync();
    }
  }
}

class _Iris implements PlantIdentifier {
  const _Iris();

  @override
  bool get isConfigured => true;

  @override
  Future<List<IdentificationCandidate>> identify(List<File> images, {String? language}) async => const [];
}

void main() {
  late Directory temp;
  late _FakeStorage storage;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('flora-create-photo');
    PathProviderPlatform.instance = _FakePaths(temp.path);
    storage = _FakeStorage(temp.path);
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  Future<void> pumpFlow(WidgetTester tester, {PlantIdentifier identifier = const _Iris()}) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({'onboarding_done': true, 'locale': 'fr'});
    final prefs = await PreferencesService.load();
    final db = FloraDatabase(NativeDatabase.memory());
    final auth = LocalAuthRepository(db, prefs);
    await auth.ensureLocalUser();
    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      preferencesServiceProvider.overrideWithValue(prefs),
      authRepositoryProvider.overrideWithValue(auth),
      gardenIdProvider.overrideWithValue(auth.gardenId),
      photoStorageProvider.overrideWithValue(storage),
      plantIdentifierProvider.overrideWithValue(identifier),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildFloraTheme(Brightness.light),
        home: const CreatePlantFlow(),
      ),
    ));
    await tester.pumpAndSettle();
  }

  List<FileSystemEntity> photoFiles() => Directory('${temp.path}/photos').existsSync() ? Directory('${temp.path}/photos').listSync() : const [];

  testWidgets('viser : le cadrage est conseillé, et sans viseur les gestes sont des boutons', (tester) async {
    await pumpFlow(tester);

    expect(find.text('Une photo ?'), findsOneWidget);
    expect(find.textContaining('Cadrez la plante en entier'), findsOneWidget);
    // L'invite du cadre et le bouton disent le même geste.
    expect(find.text('Prendre une photo'), findsNWidgets(2));
    expect(find.text('Choisir une photo'), findsOneWidget);
    expect(find.text('Continuer sans photo'), findsOneWidget);
    // Pas encore de photo : rien à nommer, rien à ajouter.
    expect(find.text('La plante'), findsNothing);
    expect(find.text('Continuer'), findsNothing);
  });

  testWidgets('on la garde ? : la photo prise, les vues nommées, et « Reprendre » efface tout', (tester) async {
    await pumpFlow(tester);
    await tester.tap(find.widgetWithText(FloraButton, 'Choisir une photo'));
    await tester.pumpAndSettle();

    expect(find.text('On la garde ?'), findsOneWidget);
    expect(find.textContaining('pour aider Iris'), findsOneWidget);
    expect(find.text('Continuer'), findsOneWidget);
    expect(find.text('Reprendre'), findsOneWidget);
    // La bande dit laquelle est la photo de la plante, et quoi prendre ensuite.
    expect(find.text('La plante'), findsOneWidget);
    expect(find.text('Une feuille de près'), findsOneWidget);
    expect(find.text('Autre vue'), findsOneWidget);
    expect(find.bySemanticsLabel('Supprimer la photo'), findsNothing);
    expect(photoFiles(), hasLength(2));

    // Une vue de plus, sans viseur : l'appareil ou la galerie du système.
    await tester.tap(find.text('Une feuille de près'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choisir une photo').last);
    await tester.pumpAndSettle();
    expect(find.text('On la garde ?'), findsOneWidget, reason: 'la vue prise, le cadre montre toujours la photo de la plante');
    expect(find.bySemanticsLabel('Supprimer la photo'), findsOneWidget, reason: 'seule la vue de plus a une croix');
    expect(photoFiles(), hasLength(4));

    // Reprendre : la photo et sa vue partent ensemble, retour au viseur.
    await tester.tap(find.text('Reprendre'));
    await tester.pumpAndSettle();
    expect(find.text('Une photo ?'), findsOneWidget);
    expect(find.text('La plante'), findsNothing);
    expect(photoFiles(), isEmpty, reason: 'rien ne reste sur le disque');
  });

  testWidgets("sans moteur d'identification, aucune vue n'est proposée", (tester) async {
    await pumpFlow(tester, identifier: const UnconfiguredIdentifier());
    await tester.tap(find.widgetWithText(FloraButton, 'Choisir une photo'));
    await tester.pumpAndSettle();

    expect(find.text('On la garde ?'), findsOneWidget);
    expect(find.textContaining('depuis sa fiche'), findsOneWidget);
    expect(find.text('La plante'), findsNothing);
    expect(find.text('Une feuille de près'), findsNothing);
  });
}
