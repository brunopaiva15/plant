import 'package:flora/app/providers.dart';
import 'package:flora/data/services/preferences_service.dart';
import 'package:flora/design_system/design_system.dart';
import 'package:flora/domain/home/home_climate.dart';
import 'package:flora/domain/home/home_climate_advisor.dart';
import 'package:flora/features/home_climate/application/home_climate_providers.dart';
import 'package:flora/features/home_climate/presentation/home_climate_widgets.dart';
import 'package:flora/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// La carte des conseils de la maison ne paraît qu'une fois par jour : les
/// plantes signalées le restent tant que la pièce ne change pas, et les
/// redire à chaque lancement serait du bruit.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const sensor = HomeSensor(id: 'T', name: 'Thermostat', roomName: 'Salon');
  final reading = HomeReading(at: DateTime(2026, 9, 14, 23), temperatureC: 25, sensor: sensor);
  const hot = HomeClimateTip(kind: HomeClimateTipKind.hot, value: 25, plantNames: ['Monstera', 'Pilea']);
  const body = 'Chaleur : Monstera et Pilea sèchent plus vite, vérifier la terre.';

  /// Une séance : l'écran du matin avec la carte, sur les réglages donnés.
  Future<void> pump(WidgetTester tester, PreferencesService prefs) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        preferencesServiceProvider.overrideWithValue(prefs),
        homeReadingProvider.overrideWith((ref) => reading),
        homeClimateTipsProvider.overrideWithValue(const [hot]),
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
        home: const Scaffold(body: Center(child: SizedBox(width: 360, child: HomeClimateAdviceCard()))),
      ),
    ));
    await tester.pumpAndSettle();
  }

  Future<PreferencesService> prefsWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return PreferencesService.load();
  }

  /// L'application quittée : l'arbre, et avec lui les providers, s'en vont.
  /// Seuls les réglages traversent, comme sur un téléphone.
  Future<void> quit(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  }

  testWidgets('la carte paraît, et ne revient pas au lancement suivant', (tester) async {
    final prefs = await prefsWith({});
    await pump(tester, prefs);
    expect(find.text(body), findsOneWidget);
    expect(prefs.homeTipsShownAt, isNotNull, reason: 'le jour est noté dès qu\'elle paraît');

    // Même journée, application relancée : la mesure n'a pas changé, la
    // carte non plus — elle se tait.
    await quit(tester);
    await pump(tester, prefs);
    expect(find.text(body), findsNothing);
  });

  testWidgets('elle tient à l\'écran une fois notée vue', (tester) async {
    final prefs = await prefsWith({});
    await pump(tester, prefs);
    // On revient sur l'onglet, on fait défiler : le jour est déjà noté,
    // et la carte reste — la noter vue ne l'efface pas sous les yeux de
    // qui la lit.
    expect(prefs.homeTipsShownAt, isNotNull);
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text(body), findsOneWidget);
  });

  testWidgets('la croix la ferme tout de suite', (tester) async {
    final prefs = await prefsWith({});
    await pump(tester, prefs);
    await tester.tap(find.bySemanticsLabel('Fermer'));
    await tester.pumpAndSettle();
    expect(find.text(body), findsNothing);
  });

  testWidgets('demain, elle revient', (tester) async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final prefs = await prefsWith({'home_tips_shown_at': yesterday.toIso8601String()});
    await pump(tester, prefs);
    expect(find.text(body), findsOneWidget);
  });
}
