import 'dart:io';

import 'package:drift/native.dart';
import 'package:flora/app/providers.dart';
import 'package:flora/data/auth/local_auth_repository.dart';
import 'package:flora/data/db/database.dart';
import 'package:flora/data/services/photo_storage_service.dart';
import 'package:flora/data/services/preferences_service.dart';
import 'package:flora/design_system/design_system.dart';
import 'package:flora/domain/identification/identification_context.dart';
import 'package:flora/domain/identification/local_plant_model.dart';
import 'package:flora/domain/identification/plant_identifier.dart';
import 'package:flora/features/identification/presentation/identification_sheet.dart';
import 'package:flora/l10n/generated/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// La feuille « Espèce », à sa fermeture.
///
/// Elle efface en partant les photos qu'elle a prises elle-même. Ce ménage
/// a lieu dans `dispose`, quand le widget est déjà démonté : y relire un
/// provider jetait « Using "ref" when a widget is about to or has been
/// unmounted is unsafe » et cassait l'arbre au moment où l'on refermait la
/// feuille. Le magasin de photos est donc retenu à l'ouverture.

/// Le magasin qui note ce qu'on lui demande d'effacer, sans toucher au disque.
class _FakeStorage extends PhotoStorageService {
  final List<String> deleted = [];

  @override
  Future<String> absolutePath(String relative) async => relative;

  @override
  Future<void> deleteFiles(String filePath, String thumbPath) async => deleted.addAll([filePath, thumbPath]);
}

class _Iris implements PlantIdentifier {
  const _Iris();

  @override
  bool get isConfigured => true;

  @override
  Future<List<IdentificationCandidate>> identify(List<File> images,
          {String? language, IdentificationContext context = IdentificationContext.unknown}) async =>
      const [IdentificationCandidate(scientificName: 'Ficus lyrata', score: 0.8, source: IdentificationSource.local)];
}

/// Pl@ntNet-300K, sous le banc d'essai : une réponse fixe, et le compte de ce
/// qu'on lui a demandé.
class _PlantNet300k implements PlantIdentifier {
  int calls = 0;

  @override
  bool get isConfigured => true;

  @override
  Future<List<IdentificationCandidate>> identify(List<File> images,
      {String? language, IdentificationContext context = IdentificationContext.unknown}) async {
    calls++;
    return const [
      IdentificationCandidate(scientificName: 'Ficus elastica', score: 0.62, source: IdentificationSource.local),
      IdentificationCandidate(scientificName: 'Ficus lyrata', score: 0.3, source: IdentificationSource.local),
    ];
  }
}

/// Une comparaison qui ne rend rien, et le modèle qui explique pourquoi.
class _Empty implements PlantIdentifier {
  const _Empty();

  @override
  bool get isConfigured => true;

  @override
  Future<List<IdentificationCandidate>> identify(List<File> images,
          {String? language, IdentificationContext context = IdentificationContext.unknown}) async =>
      const [];
}

class _Broken extends NoLocalModel {
  const _Broken();

  @override
  String? get loadError => 'asset absent';
}

void main() {
  Future<BuildContext> pump(WidgetTester tester, {PlantIdentifier? comparison, LocalPlantModel? comparisonModel}) async {
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
      photoStorageProvider.overrideWithValue(_FakeStorage()),
      plantIdentifierProvider.overrideWithValue(const _Iris()),
      comparisonIdentifierProvider.overrideWithValue(comparison),
      comparisonPlantModelProvider.overrideWithValue(comparisonModel ?? const NoLocalModel()),
    ]);
    addTearDown(container.dispose);
    late BuildContext pageContext;
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildFloraTheme(Brightness.light),
        home: Builder(builder: (context) {
          pageContext = context;
          return const SizedBox.shrink();
        }),
      ),
    ));
    return pageContext;
  }

  group('comparaison avec Pl@ntNet-300K', () {
    testWidgets('éteinte, la feuille ne montre qu\'Iris, sans score', (tester) async {
      final context = await pump(tester);
      showIdentificationSheet(context, absoluteImagePath: 'photo.jpg');
      await tester.pumpAndSettle();
      expect(find.text('Ficus lyrata'), findsOneWidget);
      expect(find.textContaining('Pl@ntNet-300K'), findsNothing);
      expect(find.textContaining('%'), findsNothing);
    });

    testWidgets('un modèle qui ne se charge pas le dit, au lieu de ne rien reconnaître', (tester) async {
      final context = await pump(tester, comparison: const _Empty(), comparisonModel: const _Broken());
      showIdentificationSheet(context, absoluteImagePath: 'photo.jpg');
      await tester.pumpAndSettle();
      expect(find.text('Pl@ntNet-300K indisponible sur cet appareil'), findsOneWidget);
      expect(find.text('asset absent'), findsOneWidget);
      expect(find.text('Pl@ntNet-300K ne reconnaît aucune plante sur ces photos.'), findsNothing);
    });

    testWidgets('allumée, ses propositions suivent celles d\'Iris, scores compris', (tester) async {
      final plantNet = _PlantNet300k();
      final context = await pump(tester, comparison: plantNet);
      showIdentificationSheet(context, absoluteImagePath: 'photo.jpg');
      await tester.pumpAndSettle();
      expect(plantNet.calls, 1);
      expect(find.text('Propositions de Pl@ntNet-300K'), findsOneWidget);
      expect(find.text('Ficus elastica'), findsOneWidget);
      // Ficus lyrata deux fois : une par modèle.
      expect(find.text('Ficus lyrata'), findsNWidgets(2));
      // Le score brut, d'Iris comme de Pl@ntNet-300K : c'est ce qui se compare.
      expect(find.textContaining(RegExp(r'80\s%')), findsOneWidget);
      expect(find.textContaining(RegExp(r'62\s%')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('la feuille « Espèce » se referme sans casser l’arbre', (tester) async {
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
      photoStorageProvider.overrideWithValue(_FakeStorage()),
      plantIdentifierProvider.overrideWithValue(const _Iris()),
    ]);
    addTearDown(container.dispose);

    late BuildContext pageContext;
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildFloraTheme(Brightness.light),
        home: Builder(builder: (context) {
          pageContext = context;
          return const SizedBox.shrink();
        }),
      ),
    ));

    showIdentificationSheet(pageContext, absoluteImagePath: 'photo.jpg');
    await tester.pumpAndSettle();
    expect(find.text('Ficus lyrata'), findsOneWidget);
    // La liste vient de l'appareil : le signe le dit avant la phrase.
    expect(find.byIcon(CupertinoIcons.device_phone_portrait), findsOneWidget);

    Navigator.of(pageContext).pop();
    await tester.pumpAndSettle();
    expect(find.text('Ficus lyrata'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
