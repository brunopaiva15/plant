import 'package:flora/app/providers.dart';
import 'package:flora/data/services/preferences_service.dart';
import 'package:flora/design_system/design_system.dart';
import 'package:flora/domain/home/home_climate.dart';
import 'package:flora/features/onboarding/presentation/onboarding_screen.dart';
import 'package:flora/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes/fake_auth_repository.dart';
import 'fakes/fake_home_climate_service.dart';

/// L'étape « maison » de l'onboarding : elle vient après la ville, seulement
/// là où Apple Maison existe. Un capteur trouvé est retenu sans autre geste ;
/// plusieurs, on choisit ; aucun, on passe.

late PreferencesService _prefs;

Future<void> _pump(WidgetTester tester, FakeHomeClimateService home) async {
  SharedPreferences.setMockInitialValues({'locale': 'fr'});
  _prefs = await PreferencesService.load();
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository(remote: false)),
        preferencesServiceProvider.overrideWithValue(_prefs),
        homeClimateServiceProvider.overrideWithValue(home),
      ],
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildFloraTheme(Brightness.light),
        home: const OnboardingScreen(),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _step(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

/// Touche le bouton de la page courante qui porte ce texte (voir
/// onboarding_account_test.dart pour le pourquoi).
Future<void> _tap(WidgetTester tester, String text) async {
  final width = tester.view.physicalSize.width / tester.view.devicePixelRatio;
  final onScreen = find.text(text).evaluate().where((e) {
    final box = e.renderObject as RenderBox?;
    if (box == null || !box.hasSize) return false;
    final x = box.localToGlobal(Offset.zero).dx;
    return x >= 0 && x < width;
  }).toList();
  expect(onScreen, hasLength(1), reason: '« $text » attendu une fois sur la page courante');
  final target = find.byElementPredicate((e) => identical(e, onScreen.single));
  await tester.ensureVisible(target);
  await tester.pump();
  await tester.tap(target);
  await _step(tester);
}

/// Jusqu'à la ville, puis « Plus tard ».
Future<void> _pastCity(WidgetTester tester) async {
  await _tap(tester, 'Passer');
  expect(find.text('Votre ville'), findsOneWidget);
  await _tap(tester, 'Plus tard');
}

const _salon = HomeSensor(id: 'A', name: 'Eve Room', roomName: 'Salon');
const _chambre = HomeSensor(id: 'B', name: 'Eve Room 2', roomName: 'Chambre');

void main() {
  testWidgets("la maison vient après la ville, et un seul capteur est retenu d'un geste", (tester) async {
    final home = FakeHomeClimateService(sensorList: const [_salon], reading: HomeReading(at: DateTime(2026, 9, 12), temperatureC: 21.4, humidity: 38));
    await _pump(tester, home);
    await _pastCity(tester);
    expect(find.text('Votre intérieur'), findsOneWidget);
    expect(find.text('Votre prénom'), findsNothing, reason: 'le prénom attend derrière la maison');

    await _tap(tester, 'Connecter Apple Maison');
    expect(home.sensorCalls, 1);
    expect(_prefs.homeSensor, 'A|Eve Room|Salon');
    expect(find.text('Salon'), findsOneWidget);
    expect(find.text('21° · 38 %'), findsOneWidget);

    await _tap(tester, 'Continuer');
    expect(find.text('Votre prénom'), findsOneWidget);
  });

  testWidgets('plusieurs capteurs : la liste attend un choix', (tester) async {
    final home = FakeHomeClimateService(sensorList: const [_salon, _chambre]);
    await _pump(tester, home);
    await _pastCity(tester);
    await _tap(tester, 'Connecter Apple Maison');
    expect(_prefs.homeSensor, isNull);
    expect(find.text('Salon'), findsOneWidget);
    expect(find.text('Chambre'), findsOneWidget);

    await _tap(tester, 'Chambre');
    expect(_prefs.homeSensor, 'B|Eve Room 2|Chambre');
    expect(find.text('Continuer'), findsWidgets);
  });

  testWidgets('aucun capteur : on reste là, et « Plus tard » mène au prénom', (tester) async {
    final home = FakeHomeClimateService(sensorList: const []);
    await _pump(tester, home);
    await _pastCity(tester);
    await _tap(tester, 'Connecter Apple Maison');
    expect(_prefs.homeSensor, isNull);
    expect(find.text('Votre intérieur'), findsOneWidget);
    await _tap(tester, 'Plus tard');
    expect(find.text('Votre prénom'), findsOneWidget);
  });

  testWidgets("sans Apple Maison, la ville mène droit au prénom", (tester) async {
    await _pump(tester, FakeHomeClimateService(supported: false));
    await _pastCity(tester);
    expect(find.text('Votre intérieur'), findsNothing);
    expect(find.text('Votre prénom'), findsOneWidget);
  });
}
