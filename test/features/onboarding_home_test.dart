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

Future<void> _pump(WidgetTester tester, FakeHomeClimateService home, {Map<String, Object> stored = const {}}) async {
  SharedPreferences.setMockInitialValues({'locale': 'fr', ...stored});
  _prefs = await PreferencesService.load();
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  // L'encoche et la barre d'accueil du téléphone : la scène et les pages se
  // partagent ce qu'elles laissent, et c'est là que la place manque.
  tester.view.padding = const FakeViewPadding(top: 141, bottom: 102);
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

/// Le texte tel qu'il est posé sur la page courante (voir
/// onboarding_account_test.dart pour le pourquoi).
Finder _onPage(WidgetTester tester, String text) {
  final width = tester.view.physicalSize.width / tester.view.devicePixelRatio;
  final onScreen = find.text(text).evaluate().where((e) {
    final box = e.renderObject as RenderBox?;
    if (box == null || !box.hasSize) return false;
    final x = box.localToGlobal(Offset.zero).dx;
    return x >= 0 && x < width;
  }).toList();
  expect(onScreen, hasLength(1), reason: '« $text » attendu une fois sur la page courante');
  return find.byElementPredicate((e) => identical(e, onScreen.single));
}

/// Touche le bouton de la page courante qui porte ce texte.
Future<void> _tap(WidgetTester tester, String text) async {
  final target = _onPage(tester, text);
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

const _salon = HomeSensor(id: 'A', name: 'Eve Room', roomName: 'Salon', homeName: 'Appartement');
const _chambre = HomeSensor(id: 'B', name: 'Eve Room 2', roomName: 'Chambre', homeName: 'Appartement', hasHumidity: false);
const _chalet = HomeSensor(id: 'C', name: 'Eve Weather', homeName: 'Chalet');

void main() {
  testWidgets("la maison vient après la ville, et un seul capteur est retenu d'un geste", (tester) async {
    final home = FakeHomeClimateService(sensorList: const [_salon], reading: HomeReading(at: DateTime(2026, 9, 12), temperatureC: 21.4, humidity: 38));
    await _pump(tester, home);
    await _pastCity(tester);
    expect(find.text('Votre intérieur'), findsOneWidget);
    expect(find.text('Votre prénom'), findsNothing, reason: 'le prénom attend derrière la maison');

    await _tap(tester, 'Connecter Apple Maison');
    expect(home.sensorCalls, 1);
    expect(_prefs.homeSensor, 'A|Eve Room|Salon|Appartement');
    expect(find.text('Salon'), findsOneWidget);
    expect(find.textContaining('21° · 38 %'), findsOneWidget);

    await _tap(tester, 'Continuer');
    expect(find.text('Votre prénom'), findsOneWidget);
  });

  testWidgets('plusieurs capteurs : la maison, puis la pièce et l’accessoire, dans une feuille', (tester) async {
    final home = FakeHomeClimateService(sensorList: const [_salon, _chambre, _chalet]);
    await _pump(tester, home);
    await _pastCity(tester);
    await _tap(tester, 'Connecter Apple Maison');
    expect(_prefs.homeSensor, isNull);
    // La feuille s'ouvre sur la première maison : ses deux pièces, et ce
    // que chaque accessoire mesure.
    expect(find.text('Choisir un capteur'), findsWidgets);
    expect(find.text('Appartement'), findsOneWidget);
    expect(find.text('Chalet'), findsOneWidget);
    // Les pièces sont des en-têtes de groupe, en capitales.
    expect(find.text('SALON'), findsOneWidget);
    expect(find.text('CHAMBRE'), findsOneWidget);
    expect(find.text('Température · Humidité'), findsOneWidget);
    expect(find.text('Température'), findsOneWidget);
    expect(find.text('Eve Weather'), findsNothing);

    // L'autre maison : un accessoire sans pièce.
    await tester.tap(find.text('Chalet'));
    await _step(tester);
    expect(find.text('Eve Weather'), findsOneWidget);
    expect(find.text('SANS PIÈCE'), findsOneWidget);
    expect(find.text('Eve Room 2'), findsNothing);

    await tester.tap(find.text('Appartement'));
    await _step(tester);
    await tester.tap(find.text('Eve Room 2'));
    await _step(tester);
    expect(_prefs.homeSensor, 'B|Eve Room 2|Chambre|Appartement');
    expect(find.text('Chambre'), findsOneWidget);
    expect(find.text('Continuer'), findsWidgets);
  });

  testWidgets("un thermostat sans hygromètre : l'humidité se demande à part", (tester) async {
    const thermostat = HomeSensor(id: 'T', name: 'Thermostat', roomName: 'Salon', homeName: 'Appartement', hasHumidity: false);
    const hygro1 = HomeSensor(id: 'H1', name: 'Hygromètre salon', roomName: 'Salon', homeName: 'Appartement', hasTemperature: false);
    const hygro2 = HomeSensor(id: 'H2', name: 'Hygromètre chambre', roomName: 'Chambre', homeName: 'Appartement', hasTemperature: false);
    final home = FakeHomeClimateService(sensorList: const [thermostat, hygro1, hygro2]);
    await _pump(tester, home);
    await _pastCity(tester);
    await _tap(tester, 'Connecter Apple Maison');
    // La feuille de la température ne propose que ce qui la mesure.
    expect(find.text('Capteur de température'), findsOneWidget);
    expect(find.text('Thermostat'), findsOneWidget);
    expect(find.text('Hygromètre salon'), findsNothing);
    await tester.tap(find.text('Thermostat'));
    await _step(tester);
    // Puis celle de l'humidité, avec les deux hygromètres.
    expect(find.text("Capteur d'humidité"), findsOneWidget);
    expect(find.text('Hygromètre salon'), findsOneWidget);
    expect(find.text('Hygromètre chambre'), findsOneWidget);
    await tester.tap(find.text('Hygromètre chambre'));
    await _step(tester);
    expect(_prefs.homeSensor, 'T|Thermostat|Salon|Appartement');
    expect(_prefs.homeHumiditySensor, 'H2|Hygromètre chambre|Chambre|Appartement');
    expect(find.text('Salon + Chambre'), findsOneWidget);
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

  testWidgets("la ville tient à l'écran, carte et boutons compris", (tester) async {
    // La scène ne rapetissait qu'à l'approche du dernier objet : là où Apple
    // Maison existe, c'est la maison, et la ville gardait au-dessus d'elle une
    // scène de pleine taille. Ses boutons tombaient sous le bord de l'écran,
    // et il fallait faire défiler pour les atteindre.
    await _pump(tester, FakeHomeClimateService(sensorList: const [_salon]), stored: {'weather_place': 'St-Imier, Suisse|47.15|6.99'});
    await _tap(tester, 'Passer');
    expect(find.text('Votre ville'), findsOneWidget);
    expect(_onPage(tester, 'St-Imier, Suisse'), findsOneWidget);

    final page = tester.state<ScrollableState>(find.ancestor(of: _onPage(tester, 'Votre ville'), matching: find.byType(Scrollable)).first);
    expect(page.position.maxScrollExtent, 0, reason: 'la page du lieu déborde de son écran');
    final view = tester.view;
    final floor = (view.physicalSize.height - view.padding.bottom) / view.devicePixelRatio;
    expect(tester.getRect(_onPage(tester, 'Continuer')).bottom, lessThan(floor));
    expect(tester.getRect(_onPage(tester, 'Plus tard')).bottom, lessThan(floor));
  });

  testWidgets("sans Apple Maison, la ville mène droit au prénom", (tester) async {
    await _pump(tester, FakeHomeClimateService(supported: false));
    await _pastCity(tester);
    expect(find.text('Votre intérieur'), findsNothing);
    expect(find.text('Votre prénom'), findsOneWidget);
  });
}
