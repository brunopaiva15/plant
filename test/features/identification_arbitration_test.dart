import 'dart:io';

import 'package:drift/native.dart';
import 'package:flora/app/providers.dart';
import 'package:flora/core/network/connectivity.dart';
import 'package:flora/data/auth/local_auth_repository.dart';
import 'package:flora/data/db/database.dart';
import 'package:flora/data/services/photo_storage_service.dart';
import 'package:flora/data/services/preferences_service.dart';
import 'package:flora/design_system/design_system.dart';
import 'package:flora/domain/identification/cascade_identifier.dart';
import 'package:flora/domain/identification/identification_arbiter.dart';
import 'package:flora/domain/identification/local_plant_model.dart';
import 'package:flora/domain/identification/plant_identifier.dart';
import 'package:flora/features/identification/presentation/identification_sheet.dart';
import 'package:flora/l10n/generated/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// La feuille « Espèce » quand un deuxième regard a départagé les candidates
/// d'Iris (§ 3.9 de docs/09-plant-recognition.md).
///
/// Ce qui se verrait mal autrement : une ligne d'arbitrage affichée pour rien,
/// et surtout la phrase « sans réseau » laissée en place alors que la photo
/// est sortie de l'appareil.

class _FakeStorage extends PhotoStorageService {
  @override
  Future<String> absolutePath(String relative) async => relative;

  @override
  Future<void> deleteFiles(String filePath, String thumbPath) async {}
}

/// Iris qui hésite : deux Monstera à 0,44 et 0,39.
class _Hesitant implements LocalPlantModel {
  @override
  bool get isAvailable => true;

  @override
  String? get version => 'test-1';

  @override
  int get speciesCount => 2;

  @override
  String? get loadError => null;

  @override
  void dispose() {}

  @override
  Future<bool> warmUp() async => true;

  @override
  Future<List<IdentificationCandidate>> classify(File image) async => const [
        IdentificationCandidate(scientificName: 'Monstera deliciosa', score: 0.44),
        IdentificationCandidate(scientificName: 'Monstera adansonii', score: 0.39),
      ];
}

class _Arbitre implements IdentificationArbiter {
  _Arbitre(this.answer);

  final Arbitration? answer;

  @override
  bool get isConfigured => true;

  @override
  Future<Arbitration?> arbitrate({
    required List<File> images,
    required List<IdentificationCandidate> candidates,
    required String language,
  }) async =>
      answer;
}

class _NoRemote implements PlantIdentifier {
  const _NoRemote();

  @override
  bool get isConfigured => false;

  @override
  Future<List<IdentificationCandidate>> identify(List<File> images, {String? language}) async => const [];
}

Future<void> _ouvrir(WidgetTester tester, Arbitration? avis) async {
  SharedPreferences.setMockInitialValues({'onboarding_done': true, 'locale': 'fr'});
  final prefs = await PreferencesService.load();
  final db = FloraDatabase(NativeDatabase.memory());
  final auth = LocalAuthRepository(db, prefs);
  await auth.ensureLocalUser();
  final cascade = CascadeIdentifier(
    local: _Hesitant(),
    fallback: const _NoRemote(),
    arbiter: _Arbitre(avis),
  );
  final container = ProviderContainer(overrides: [
    databaseProvider.overrideWithValue(db),
    preferencesServiceProvider.overrideWithValue(prefs),
    authRepositoryProvider.overrideWithValue(auth),
    gardenIdProvider.overrideWithValue(auth.gardenId),
    photoStorageProvider.overrideWithValue(_FakeStorage()),
    plantIdentifierProvider.overrideWithValue(cascade),
    // Sans cette valeur figée, la sonde de connectivité arme un minuteur
    // périodique et `pumpAndSettle` n'a plus de fin.
    isOnlineProvider.overrideWithValue(false),
  ]);
  addTearDown(container.dispose);
  addTearDown(db.close);

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
  // Ni `pumpAndSettle` ni des pompages seuls ne suffisent ici. La cascade lit
  // l'état du fichier avant de classer — c'est sa clé de cache —, et
  // `testWidgets` gèle le temps : il faut rendre la main au vrai boucleur
  // d'événements entre deux images pour que cette lecture aboutisse. Et la
  // feuille anime sa marque tant qu'elle attend, si bien que « settle »
  // n'arrive jamais.
  for (var i = 0; i < 8; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  testWidgets('la candidate départagée s\'affiche avec ce qui l\'a décidée', (tester) async {
    await _ouvrir(
      tester,
      const Arbitration(
        outcome: ArbitrationOutcome.picked,
        scientificName: 'Monstera adansonii',
        trait: 'fenestrations',
      ),
    );
    // Deux fois : la ligne d'arbitrage au-dessus, et la candidate dans la liste
    // d'Iris, qui garde son ordre.
    expect(find.text('Monstera adansonii'), findsNWidgets(2));
    expect(find.text('fenestrations'), findsOneWidget);
  });

  testWidgets('la photo est sortie de l\'appareil, et l\'écran le dit', (tester) async {
    await _ouvrir(
      tester,
      const Arbitration(outcome: ArbitrationOutcome.picked, scientificName: 'Monstera adansonii'),
    );
    expect(find.byIcon(CupertinoIcons.cloud), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.device_phone_portrait), findsNothing);
    expect(find.textContaining('vérifié en ligne'), findsOneWidget);
  });

  testWidgets('un avis qui confirme la tête de liste n\'ajoute pas de ligne', (tester) async {
    await _ouvrir(
      tester,
      const Arbitration(outcome: ArbitrationOutcome.picked, scientificName: 'Monstera deliciosa'),
    );
    expect(find.text('Monstera deliciosa'), findsOneWidget);
    // La photo est partie quand même : le nuage reste.
    expect(find.byIcon(CupertinoIcons.cloud), findsOneWidget);
  });

  testWidgets('sans avis, l\'écran est celui d\'avant', (tester) async {
    await _ouvrir(tester, null);
    expect(find.text('Monstera deliciosa'), findsOneWidget);
    expect(find.text('Monstera adansonii'), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.device_phone_portrait), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.cloud), findsNothing);
  });
}
