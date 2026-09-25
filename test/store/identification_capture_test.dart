import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flora/app/providers.dart';
import 'package:flora/data/auth/local_auth_repository.dart';
import 'package:flora/data/db/database.dart';
import 'package:flora/data/services/photo_storage_service.dart';
import 'package:flora/data/services/preferences_service.dart';
import 'package:flora/design_system/design_system.dart';
import 'package:flora/domain/identification/identification_context.dart';
import 'package:flora/domain/identification/plant_identifier.dart';
import 'package:flora/features/plants/presentation/create_plant_flow.dart';
import 'package:flora/l10n/generated/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// La capture du visuel « Quelle est cette plante ? » : l'étape « Aperçu » de
/// la création, les noms qu'Iris pose sur la photo.
///
/// Ni le web ni le simulateur n'ont de caméra, et le modèle ne tourne pas sur
/// le web : c'est donc ici qu'on la prend, avec l'écran de l'app et une photo
/// CC0 absente du jeu d'entraînement (`store/ident/ficus-lyrata.jpg`). Les
/// trois propositions et leur score sont la réponse du modèle livré sur cette
/// photo, mesurée par `store/ident/score.py` — les mêmes que `IDENT_RESULTS`
/// dans `store/compose.py`. Seuls les noms courants suivent la langue, tirés
/// du catalogue (`tools/plant_dataset/plants.csv`).
///
/// Hors de la suite : `STORE_CAPTURE=1 flutter test
/// test/store/identification_capture_test.dart` écrit
/// `store/shots-<langue>/capture.png`, que `compose.py` reprend tel quel.
final _capture = Platform.environment['STORE_CAPTURE'] == '1';

const _ficus = 'store/ident/ficus-lyrata.jpg';

const _noms = <String, List<String?>>{
  'fr': ['Figuier lyre', 'Pothos', null],
  'en': ['Fiddle-leaf fig', 'Golden pothos', null],
  'de': ['Geigenfeige', 'Efeutute', null],
  'it': ['Ficus lyrata', 'Pothos', null],
};

const _choisir = {'fr': 'Choisir une photo', 'en': 'Choose a photo', 'de': 'Foto auswählen', 'it': 'Scegli una foto'};

class _Chemins extends PathProviderPlatform with MockPlatformInterfaceMixin {
  _Chemins(this.root);

  final String root;

  @override
  Future<String?> getApplicationDocumentsPath() async => root;

  @override
  Future<String?> getTemporaryPath() async => root;
}

/// Le sélecteur du système, remplacé : « Choisir une photo » rend le Ficus.
class _Photos extends PhotoStorageService {
  _Photos(this.root);

  final String root;

  @override
  Future<File?> pickSource(PhotoSource source) async => File(_ficus).copySync('$root/source.jpg');

  @override
  Future<StoredPhoto> importFile(File source) async {
    final dir = Directory('$root/photos')..createSync(recursive: true);
    for (final suffix in ['.jpg', '_thumb.jpg']) {
      source.copySync('${dir.path}/p$suffix');
    }
    return const StoredPhoto(filePath: 'p.jpg', thumbPath: 'p_thumb.jpg', width: 1200, height: 1600);
  }

  @override
  Future<String> absolutePath(String relative) async => '$root/photos/$relative';
}

/// Ce que le modèle livré répond sur cette photo.
class _Iris implements PlantIdentifier {
  const _Iris(this.noms);

  final List<String?> noms;

  @override
  bool get isConfigured => true;

  @override
  Future<List<IdentificationCandidate>> identify(List<File> images,
      {String? language, IdentificationContext context = IdentificationContext.unknown}) async => [
    IdentificationCandidate(scientificName: 'Ficus lyrata', commonName: noms[0], score: 0.804, source: IdentificationSource.local),
    IdentificationCandidate(scientificName: 'Epipremnum aureum', commonName: noms[1], score: 0.063, source: IdentificationSource.local),
    IdentificationCandidate(scientificName: 'Euphorbia lactea', commonName: noms[2], score: 0.039, source: IdentificationSource.local),
  ];
}

Future<void> _polices() async {
  final sdk = Platform.environment['FLUTTER_ROOT'] ?? '';
  final materiel = '$sdk/bin/cache/artifacts/material_fonts';
  Future<void> charger(String famille, List<String> fichiers) async {
    final l = FontLoader(famille);
    for (final f in fichiers) {
      l.addFont(Future.value(ByteData.sublistView(File(f).readAsBytesSync())));
    }
    await l.load();
  }

  // La police du système, faute de SF Pro : Roboto, sous les noms que le
  // thème iOS demande.
  final roboto = [for (final g in ['Regular', 'Medium', 'Bold', 'Black']) '$materiel/Roboto-$g.ttf'];
  for (final famille in ['Roboto', 'CupertinoSystemText', 'CupertinoSystemDisplay', '.SF Pro Text', '.SF Pro Display']) {
    await charger(famille, roboto);
  }
  await charger('BricolageGrotesque', ['assets/fonts/BricolageGrotesque-VF.ttf']);
  await charger('MaterialIcons', ['$materiel/MaterialIcons-Regular.otf']);
  final pubCache = Platform.environment['PUB_CACHE'] ?? '${Platform.environment['HOME']}/.pub-cache';
  final cupertino = Directory('$pubCache/hosted/pub.dev').listSync().whereType<Directory>().where((d) => d.path.contains('cupertino_icons-')).first;
  await charger('packages/cupertino_icons/CupertinoIcons', ['${cupertino.path}/assets/CupertinoIcons.ttf']);
}

void main() {
  for (final lang in _noms.keys) {
    testWidgets('capture « Aperçu » ($lang)', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final temp = Directory.systemTemp.createTempSync('auxine-capture');
      PathProviderPlatform.instance = _Chemins(temp.path);
      await tester.runAsync(_polices);

      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({'onboarding_done': true, 'locale': lang});
      final prefs = await PreferencesService.load();
      final db = FloraDatabase(NativeDatabase.memory());
      final auth = LocalAuthRepository(db, prefs);
      await auth.ensureLocalUser();
      final container = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db),
        preferencesServiceProvider.overrideWithValue(prefs),
        authRepositoryProvider.overrideWithValue(auth),
        gardenIdProvider.overrideWithValue(auth.gardenId),
        photoStorageProvider.overrideWithValue(_Photos(temp.path)),
        plantIdentifierProvider.overrideWithValue(_Iris(_noms[lang]!)),
      ]);
      final cadre = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(
        key: cadre,
        child: UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            locale: Locale(lang),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: buildFloraTheme(Brightness.light),
            home: const CreatePlantFlow(),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      // Le geste du bouton, appelé directement : un toucher simulé ne
      // l'atteint pas sur ce banc (les tests de l'étape photo butent au même
      // endroit), et c'est l'écran d'après qu'on veut photographier.
      tester.widget<FloraButton>(find.widgetWithText(FloraButton, _choisir[lang]!)).onPressed!();
      // La photo se décode pour de vrai, et le scan tient son temps.
      for (var i = 0; i < 40; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.runAsync(() async {
        for (final e in find.byType(Image).evaluate()) {
          await precacheImage((e.widget as Image).image, e);
        }
      });
      // Les noms flottent sans fin sur la photo : on avance le temps plutôt
      // que d'attendre un repos qui ne vient pas.
      await tester.pump(const Duration(seconds: 2));
      await tester.runAsync(() async {
        final boite = cadre.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boite.toImage(pixelRatio: 3);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        File('store/shots-$lang/capture.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(png!.buffer.asUint8List());
      });
      // La base se ferme hors du temps simulé : dedans, elle attendait un
      // tour d'horloge qui ne venait jamais, et le test expirait.
      await tester.runAsync(() async {
        container.dispose();
        await db.close();
      });
      debugDefaultTargetPlatformOverride = null;
    }, skip: !_capture);
  }
}
