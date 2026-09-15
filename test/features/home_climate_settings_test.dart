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

/// Profil › Capteurs de la maison, et la place qu'y tient une maison qu'on
/// ne peut pas encore brancher : Google Home garde sa ligne et son
/// étiquette tant que les Home APIs ne sont pas ouvertes, et la reperd le
/// jour où elle se branche pour de bon.
Future<void> _pump(WidgetTester tester, HomeClimateService home) async {
  SharedPreferences.setMockInitialValues({'locale': 'fr'});
  final prefs = await PreferencesService.load();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        preferencesServiceProvider.overrideWithValue(prefs),
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
  await tester.pump();
}

void main() {
  testWidgets('Google Home annoncé, pas proposé', (tester) async {
    await _pump(tester, MultiHomeClimateService([FakeHomeClimateService()]));
    expect(find.text('Google Home'), findsOneWidget);
    expect(find.text('Bientôt'), findsOneWidget);
    // Une étiquette, et rien à toucher : pas de bouton qui mènerait à un
    // « aucun capteur », pas de note sur un compte qu'on ne lit pas.
    expect(find.text('Connecter Google Home'), findsNothing);
    expect(find.text('Google Home lit les appareils via votre compte Google.'), findsNothing);
  }, skip: !AppConfig.googleHomeSoon);

  testWidgets('la maison branchée reprend son bouton', (tester) async {
    await _pump(
      tester,
      MultiHomeClimateService([FakeHomeClimateService(), FakeHomeClimateService(source: HomeSource.google)]),
    );
    expect(find.text('Bientôt'), findsNothing);
    expect(find.text('Connecter Google Home'), findsOneWidget);
    expect(find.text('Google Home lit les appareils via votre compte Google.'), findsOneWidget);
  });
}
