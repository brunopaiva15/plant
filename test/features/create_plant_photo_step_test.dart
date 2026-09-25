import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flora/app/providers.dart';
import 'package:flora/data/auth/local_auth_repository.dart';
import 'package:flora/data/db/database.dart';
import 'package:flora/data/services/photo_storage_service.dart';
import 'package:flora/data/services/preferences_service.dart';
import 'package:flora/design_system/design_system.dart';
import 'package:flora/domain/identification/comparison_model.dart';
import 'package:flora/domain/identification/identification_context.dart';
import 'package:flora/domain/identification/plant_identifier.dart';
import 'package:flora/features/identification/presentation/identification_sheet.dart';
import 'package:flora/features/plants/presentation/create_plant_flow.dart';
import 'package:flora/l10n/generated/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// L'étape photo de la création : une photo d'abord, analysée dans le grand
/// cadre. Les vues supplémentaires ne sont plus demandées avant le résultat ;
/// une seconde photo appartient à l'étape suivante et seulement si Iris hésite.
///
/// Le banc d'essai n'a pas de caméra : c'est le chemin sans viseur qui est
/// parcouru ici, celui où les gestes reviennent en boutons.
///
/// Et ce que l'étape suivante doit faire en s'ouvrant : rien. Le clavier ne
/// monte pas tout seul sur le nom — les propositions d'identification se
/// lisent d'abord.

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
  Completer<void>? importGate;

  @override
  Future<File?> pickSource(PhotoSource source) async {
    final raw = File('$root/raw-${++picked}.jpg');
    File('store/demo-photos/monstera.jpg').copySync(raw.path);
    return raw;
  }

  @override
  Future<StoredPhoto> importFile(File source) async {
    final gate = importGate;
    if (gate != null) await gate.future;
    final dir = Directory('$root/photos')..createSync(recursive: true);
    final name = 'p$picked';
    for (final suffix in ['.jpg', '_thumb.jpg']) {
      source.copySync('${dir.path}/$name$suffix');
    }
    return StoredPhoto(
      filePath: '$name.jpg',
      thumbPath: '${name}_thumb.jpg',
      width: 800,
      height: 1000,
    );
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
  Future<List<IdentificationCandidate>> identify(List<File> images,
          {String? language, IdentificationContext context = IdentificationContext.unknown}) async => const [];
}

class _SlowIris implements PlantIdentifier {
  final completer = Completer<List<IdentificationCandidate>>();

  @override
  bool get isConfigured => true;

  @override
  Future<List<IdentificationCandidate>> identify(List<File> images,
          {String? language, IdentificationContext context = IdentificationContext.unknown}) => completer.future;
}

class _InstantIris implements PlantIdentifier {
  const _InstantIris();

  @override
  bool get isConfigured => true;

  @override
  Future<List<IdentificationCandidate>> identify(List<File> images,
          {String? language, IdentificationContext context = IdentificationContext.unknown}) async => const [
        IdentificationCandidate(
          scientificName: 'Goeppertia zebrina',
          commonName: 'Calathéa zébré',
          score: 0.82,
          source: IdentificationSource.local,
        ),
        IdentificationCandidate(
          scientificName: 'Goeppertia warszewiczii',
          commonName: 'Calathéa',
          score: 0.11,
          source: IdentificationSource.local,
        ),
        IdentificationCandidate(
          scientificName: 'Maranta leuconeura',
          commonName: 'Maranta',
          score: 0.05,
          source: IdentificationSource.local,
        ),
      ];
}

/// Pl@ntNet-300K sous le banc d'essai : une proposition fixe, et le compte
/// des appels.
class _PlantNet300k implements PlantIdentifier {
  int calls = 0;

  @override
  bool get isConfigured => true;

  @override
  Future<List<IdentificationCandidate>> identify(List<File> images,
      {String? language, IdentificationContext context = IdentificationContext.unknown}) async {
    calls++;
    return const [
      IdentificationCandidate(scientificName: 'Kalanchoe blossfeldiana', score: 0.47, source: IdentificationSource.local),
    ];
  }
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

  Future<void> pumpFlow(WidgetTester tester, {PlantIdentifier identifier = const _Iris(), PlantIdentifier? plantNet}) async {
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
      comparisonIdentifierProvider(ComparisonModel.plantNet300k).overrideWithValue(plantNet),
      comparisonIdentifierProvider(ComparisonModel.plantClef2024).overrideWithValue(null),
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

    expect(find.text('Photo'), findsOneWidget);
    expect(find.textContaining('Cadrez la plante en entier'), findsOneWidget);
    // L'invite du cadre et le bouton disent le même geste.
    expect(find.text('Prendre une photo'), findsNWidgets(2));
    expect(find.text('Choisir une photo'), findsOneWidget);
    expect(find.text('Continuer sans photo'), findsOneWidget);
    // Pas encore de photo : rien à nommer, rien à ajouter.
    expect(find.text('La plante'), findsNothing);
    expect(find.text('Continuer'), findsNothing);
  });

  testWidgets('la photo source et la grille apparaissent avant la fin de l’import', (tester) async {
    final gate = Completer<void>();
    storage.importGate = gate;
    await pumpFlow(tester, identifier: const _InstantIris());

    await tester.tap(find.widgetWithText(FloraButton, 'Choisir une photo'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Aperçu'), findsOneWidget);
    expect(find.byType(ProcessingField), findsOneWidget);
    final rawPreview = tester.widgetList<Image>(find.byType(Image)).where(
      (image) => image.image is FileImage &&
          (image.image as FileImage).file.path.endsWith('raw-1.jpg'),
    );
    expect(rawPreview, hasLength(1));
    expect(photoFiles(), isEmpty,
        reason: 'la copie redimensionnée n’existe pas encore');
    final continueButton =
        tester.widget<FloraButton>(find.widgetWithText(FloraButton, 'Continuer'));
    expect(continueButton.onPressed, isNull);

    gate.complete();
    await tester.pumpAndSettle();
    expect(photoFiles(), hasLength(2));
  });

  testWidgets('la première photo suffit et « Reprendre » la supprime', (tester) async {
    await pumpFlow(tester);
    await tester.tap(find.widgetWithText(FloraButton, 'Choisir une photo'));
    await tester.pumpAndSettle();

    expect(find.text('Aperçu'), findsOneWidget);
    expect(find.text('Continuer'), findsOneWidget);
    expect(find.text('Reprendre'), findsOneWidget);
    final rawPreview = tester.widgetList<Image>(find.byType(Image)).where(
      (image) => image.image is FileImage &&
          (image.image as FileImage).file.path.endsWith('raw-1.jpg'),
    );
    expect(rawPreview, hasLength(1),
        reason: 'le cadre garde le fichier source original, pas la miniature');
    // Aucune seconde vue n'est demandée avant de connaître la confiance.
    expect(find.text('La plante'), findsNothing);
    expect(find.text('Une feuille de près'), findsNothing);
    expect(find.text('Autre vue'), findsNothing);
    expect(photoFiles(), hasLength(2));

    await tester.tap(find.text('Reprendre'));
    await tester.pumpAndSettle();
    expect(find.text('Photo'), findsOneWidget);
    expect(photoFiles(), isEmpty, reason: 'la photo principale a bien été supprimée');
  });

  testWidgets('Iris analyse la première photo dans le grand cadre', (tester) async {
    final iris = _SlowIris();
    await pumpFlow(tester, identifier: iris);
    await tester.tap(find.widgetWithText(FloraButton, 'Choisir une photo'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Aperçu'), findsOneWidget);
    expect(find.byType(ProcessingField), findsOneWidget);
    expect(find.byType(IrisMark), findsOneWidget);

    iris.completer.complete(const []);
    await tester.pumpAndSettle();
    expect(find.byType(ProcessingField), findsNothing);
  });

  testWidgets('un résultat instantané garde une demi-seconde de scan et révèle les noms', (tester) async {
    await pumpFlow(tester, identifier: const _InstantIris());
    await tester.tap(find.widgetWithText(FloraButton, 'Choisir une photo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(ProcessingField), findsOneWidget);
    expect(find.text('Calathéa zébré'), findsOneWidget);
    expect(find.text('Goeppertia zebrina'), findsOneWidget);
    var continueButton = tester.widget<FloraButton>(find.widgetWithText(FloraButton, 'Continuer'));
    expect(continueButton.onPressed, isNull, reason: 'le scan doit rester visible au moins deux secondes');

    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byType(ProcessingField), findsOneWidget);

    // À 0,5 s, le scan ne disparaît pas d'un coup : l'ancien champ reste dans
    // l'AnimatedSwitcher pendant son fondu de sortie.
    await tester.pump(const Duration(milliseconds: 220));
    expect(find.byType(ProcessingField), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(ProcessingField), findsNothing);
    continueButton = tester.widget<FloraButton>(find.widgetWithText(FloraButton, 'Continuer'));
    expect(continueButton.onPressed, isNotNull);
    expect(find.text('Maranta'), findsOneWidget);
  });

  testWidgets('toucher un nom détecté le sélectionne et continue', (tester) async {
    await pumpFlow(tester, identifier: const _InstantIris());
    await tester.tap(find.widgetWithText(FloraButton, 'Choisir une photo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.text('Calathéa zébré'), findsOneWidget);
    await tester.tap(find.text('Calathéa zébré'));
    await tester.pumpAndSettle();

    expect(find.text('Nom'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is EditableText &&
            widget.controller.text == 'Goeppertia zebrina',
      ),
      findsOneWidget,
      reason: 'l’espèce tapée doit être préremplie à l’étape suivante',
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is EditableText &&
            widget.controller.text == 'Calathéa zébré',
      ),
      findsOneWidget,
      reason: 'le nom commun est également repris comme nom de la plante',
    );
    expect(
      find.byIcon(CupertinoIcons.checkmark_alt_circle_fill),
      findsOneWidget,
      reason: 'la candidate choisie doit être réellement marquée utilisée',
    );
    expect(
      find.widgetWithText(FloraButton, 'Utiliser'),
      findsNWidgets(2),
      reason: 'les deux autres candidates restent sélectionnables',
    );
  });

  testWidgets("l'étape du nom s'ouvre sans clavier, et le champ à un toucher", (tester) async {
    await pumpFlow(tester);
    await tester.tap(find.widgetWithText(FloraButton, 'Continuer sans photo'));
    await tester.pumpAndSettle();

    final name = find.byWidgetPredicate((w) => w is FloraTextField && w.hint == 'Nom de la plante');
    expect(name, findsOneWidget);
    for (final field in tester.widgetList<EditableText>(find.byType(EditableText))) {
      expect(field.focusNode.hasFocus, isFalse, reason: 'aucun champ ne prend le clavier en arrivant');
    }

    await tester.tap(name);
    await tester.pumpAndSettle();
    final edit = tester.widget<EditableText>(find.descendant(of: name, matching: find.byType(EditableText)));
    expect(edit.focusNode.hasFocus, isTrue, reason: 'le champ reste à un toucher');
  });

  testWidgets("sans moteur d'identification, aucune seconde photo n'est proposée", (tester) async {
    await pumpFlow(tester, identifier: const UnconfiguredIdentifier());
    await tester.tap(find.widgetWithText(FloraButton, 'Choisir une photo'));
    await tester.pumpAndSettle();

    expect(find.text('Aperçu'), findsOneWidget);
    expect(find.textContaining('depuis sa fiche'), findsOneWidget);
    expect(find.text('La plante'), findsNothing);
    expect(find.text('Une feuille de près'), findsNothing);
  });

  // L'ajout d'une plante est l'endroit où l'on identifie le plus : la
  // comparaison y avait d'abord été oubliée, visible seulement dans la
  // feuille « Espèce » d'une fiche.
  testWidgets('allumée, la comparaison s\'affiche aussi à l\'étape « Nom »', (tester) async {
    final plantNet = _PlantNet300k();
    await pumpFlow(tester, identifier: const _InstantIris(), plantNet: plantNet);
    await tester.tap(find.widgetWithText(FloraButton, 'Choisir une photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FloraButton, 'Continuer'));
    await tester.pumpAndSettle();

    expect(find.text('Nom'), findsOneWidget);
    expect(plantNet.calls, 1);
    await tester.scrollUntilVisible(find.text('Propositions de Pl@ntNet-300K'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Propositions de Pl@ntNet-300K'), findsOneWidget);
    expect(find.textContaining(RegExp(r'47\s%')), findsOneWidget);

    await tester.ensureVisible(find.text('Kalanchoe blossfeldiana'));
    await tester.tap(find.descendant(
      of: find.ancestor(of: find.text('Kalanchoe blossfeldiana'), matching: find.byType(CandidateRow)),
      matching: find.byType(FloraButton),
    ));
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate((w) => w is EditableText && w.controller.text == 'Kalanchoe blossfeldiana'),
      findsOneWidget,
      reason: 'une proposition de la comparaison se retient comme celles d\'Iris',
    );
  });
}
