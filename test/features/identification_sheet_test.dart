import 'dart:io';

import 'package:drift/native.dart';
import 'package:flora/app/providers.dart';
import 'package:flora/data/auth/local_auth_repository.dart';
import 'package:flora/data/db/database.dart';
import 'package:flora/data/services/photo_storage_service.dart';
import 'package:flora/data/services/preferences_service.dart';
import 'package:flora/design_system/design_system.dart';
import 'package:flora/domain/identification/plant_identifier.dart';
import 'package:flora/features/identification/presentation/identification_sheet.dart';
import 'package:flora/l10n/generated/app_localizations.dart';
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
  Future<List<IdentificationCandidate>> identify(List<File> images, {String? language}) async =>
      const [IdentificationCandidate(scientificName: 'Ficus lyrata', score: 0.8, source: IdentificationSource.local)];
}

void main() {
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

    Navigator.of(pageContext).pop();
    await tester.pumpAndSettle();
    expect(find.text('Ficus lyrata'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
