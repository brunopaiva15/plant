import 'package:flora/app/providers.dart';
import 'package:flora/core/config/app_config.dart';
import 'package:flora/data/services/preferences_service.dart';
import 'package:flora/design_system/design_system.dart';
import 'package:flora/domain/home/home_climate.dart';
import 'package:flora/features/home_climate/presentation/home_climate_settings_screen.dart';
import 'package:flora/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes/fake_home_climate_service.dart';

/// Profil › Capteurs de la maison : la place qu'y tient une maison qu'on ne
/// peut pas encore brancher, et celle d'une maison branchée sur un compte —
/// ce qui s'ouvre doit pouvoir se fermer, et se fermer pour de bon.
late PreferencesService _prefs;

Future<void> _pump(WidgetTester tester, HomeClimateService home, {Map<String, Object> stored = const {}}) async {
  SharedPreferences.setMockInitialValues({'locale': 'fr', ...stored});
  _prefs = await PreferencesService.load();
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
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
        home: const HomeClimateSettingsScreen(),
      ),
    ),
  );
  await _step(tester);
}

/// Laisse passer la recherche silencieuse, une transition ou un écrit en
/// préférences. `pumpAndSettle` ne vaut rien ici : un indicateur d'attente
/// tourne sans fin et le bandeau s'anime.
Future<void> _step(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

Future<void> _tap(WidgetTester tester, String text) async {
  final target = find.text(text);
  await tester.ensureVisible(target);
  await tester.pump();
  await tester.tap(target);
  await _step(tester);
}

void main() {
  testWidgets('Google Home annoncé, pas proposé', (tester) async {
    await _pump(tester, MultiHomeClimateService([FakeHomeClimateService()]));
    expect(find.text('Google Home'), findsOneWidget);
    expect(find.text('Bientôt'), findsOneWidget);
    // Une étiquette, et rien à toucher : pas de bouton qui mènerait à un
    // « aucun capteur », pas de note sur un compte qu'on ne lit pas, et rien
    // à déconnecter.
    expect(find.text('Connecter Google Home'), findsNothing);
    expect(find.text('Google Home lit les appareils via votre compte Google.'), findsNothing);
    expect(find.text('Autorisations du compte Google'), findsNothing);
  }, skip: !AppConfig.googleHomeSoon);

  testWidgets('la maison branchée reprend son bouton', (tester) async {
    await _pump(
      tester,
      MultiHomeClimateService([
        FakeHomeClimateService(),
        FakeHomeClimateService(source: HomeSource.google, disconnectable: true),
      ]),
    );
    expect(find.text('Bientôt'), findsNothing);
    expect(find.text('Connecter Google Home'), findsOneWidget);
    expect(find.text('Google Home lit les appareils via votre compte Google.'), findsOneWidget);
    // La ligne du compte Google est là dès que la maison est lisible : c'est
    // de là que l'autorisation se retire, déconnecté ou non. Rien à
    // déconnecter en revanche, aucun capteur n'étant branché.
    expect(find.text('Autorisations du compte Google'), findsOneWidget);
    expect(find.text('Déconnecter Google Home'), findsNothing);
  });

  testWidgets('Google Home se déconnecte, et son capteur est oublié', (tester) async {
    const nest = HomeSensor(id: 'N1', name: 'Nest', roomName: 'Salon', source: HomeSource.google);
    final google = FakeHomeClimateService(
      source: HomeSource.google,
      sensorList: const [nest],
      disconnectable: true,
      reading: HomeReading(at: DateTime(2026, 9, 12, 8), temperatureC: 20),
    );
    await _pump(tester, MultiHomeClimateService([google]), stored: {'home_sensor': nest.encode()});
    expect(find.text('Déconnecter Google Home'), findsOneWidget);

    await _tap(tester, 'Déconnecter Google Home');
    // La confirmation dit ce que la déconnexion ne fait pas.
    expect(find.textContaining('reste dans votre compte Google'), findsOneWidget);
    await _tap(tester, 'Déconnecter');

    expect(google.disconnectCalls, 1);
    expect(_prefs.homeSensor, isNull);
    // Plus rien à déconnecter, et la maison redevient une maison à brancher.
    expect(find.text('Déconnecter Google Home'), findsNothing);
    expect(find.text('Connecter Google Home'), findsOneWidget);
    // La ligne du compte reste : c'est là que l'autorisation se retire.
    expect(find.text('Autorisations du compte Google'), findsOneWidget);
  });
}
