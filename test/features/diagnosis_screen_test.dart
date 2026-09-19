import 'package:flora/app/providers.dart';
import 'package:flora/data/services/preferences_service.dart';
import 'package:flora/design_system/design_system.dart';
import 'package:flora/domain/home/home_climate.dart';
import 'package:flora/domain/models/models.dart';
import 'package:flora/features/diagnosis/presentation/diagnosis_screen.dart';
import 'package:flora/features/plants/application/plant_providers.dart';
import 'package:flora/features/plants/presentation/photo_capture_flow.dart';
import 'package:flora/features/weather/application/weather_providers.dart';
import 'package:flora/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes/fake_home_climate_service.dart';

/// La page de diagnostic : le viseur en tête, les trois places de photos, et
/// ce que la photo ne montre pas — ce que la personne a vérifié de sa main,
/// et ce que le capteur ne mesure pas (tout sans capteur, l'humidité seule
/// derrière un thermostat, rien quand la maison donne les deux).
const _thermostat = HomeSensor(id: 'T', name: 'Thermostat', roomName: 'Salon', hasHumidity: false);
const _station = HomeSensor(id: 'S', name: 'Eve Room', roomName: 'Salon');

final _plant = Plant(
  id: 'p1',
  gardenId: 'g1',
  name: 'Calathea',
  status: PlantStatus.active,
  health: PlantHealth.healthy,
  isFavorite: false,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
  locationId: 'salon',
);

Future<void> _open(WidgetTester tester, FakeHomeClimateService home, {Map<String, Object> stored = const {}, Set<String> outdoor = const {}}) async {
  SharedPreferences.setMockInitialValues({'locale': 'fr', ...stored});
  final prefs = await PreferencesService.load();
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        preferencesServiceProvider.overrideWithValue(prefs),
        homeClimateServiceProvider.overrideWithValue(home),
        outdoorLocationIdsProvider.overrideWithValue(outdoor),
        plantSummaryProvider(_plant.id).overrideWith((ref) => Stream.value(PlantSummary(plant: _plant))),
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
        home: DiagnosisScreen(plantId: _plant.id),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(find.text('Diagnostic'), findsOneWidget);
}

void main() {
  testWidgets('la page s’ouvre sur le viseur, et sur les trois places des photos', (tester) async {
    await _open(tester, FakeHomeClimateService());
    // Le viseur est dans la page, comme partout où l'on photographie une
    // plante, et les deux gestes sont écrits sous lui : rien à deviner.
    expect(find.byType(CaptureFrame), findsOneWidget);
    expect(find.widgetWithText(FloraButton, 'Prendre une photo'), findsOneWidget);
    expect(find.widgetWithText(FloraButton, 'Choisir une photo'), findsOneWidget);
    expect(find.text('Photographiez les feuilles, la tige et la terre, de près et en entier. Les résultats sont indicatifs.'), findsOneWidget);
    // Le geste de la page est en bas, et il attend une photo pour s'allumer.
    final analyser = tester.widget<FloraButton>(find.widgetWithText(FloraButton, 'Analyser'));
    expect(analyser.onPressed, isNull, reason: 'aucune photo, rien à analyser');
  });

  testWidgets('sans capteur, la température et l’humidité se demandent, facultatives', (tester) async {
    await _open(tester, FakeHomeClimateService());
    expect(find.text('Température'), findsOneWidget);
    expect(find.text('Humidité'), findsOneWidget);
    expect(find.text('°C'), findsOneWidget);
    expect(find.text('%'), findsOneWidget);
    expect(find.text("Facultatif : ce que la photo ne montre pas affine l'analyse."), findsOneWidget);
    expect(find.text('Autour de la plante'), findsOneWidget);
    expect(find.textContaining('Mesure de la maison'), findsNothing);
  });

  testWidgets('la terre, les racines, la lumière et les insectes se demandent, rien n’est coché', (tester) async {
    await _open(tester, FakeHomeClimateService());
    for (final sujet in ['Terre', 'Racines', 'Lumière', 'Insectes']) {
      expect(find.text(sujet), findsOneWidget, reason: '« $sujet » manque au formulaire');
    }
    // Les réponses sont offertes, aucune n'est prise d'avance : une case
    // cochée par défaut serait une observation inventée.
    expect(find.text('Détrempée'), findsOneWidget);
    expect(find.text('Brunes ou molles'), findsOneWidget);
    expect(find.text('Soleil direct'), findsOneWidget);
    expect(find.text('Aucun vu'), findsOneWidget);
    final chips = tester.widgetList<FloraChip>(find.byType(FloraChip));
    expect(chips, hasLength(12));
    expect(chips.where((c) => c.selected), isEmpty);
  });

  testWidgets('une observation se coche et se décoche', (tester) async {
    await _open(tester, FakeHomeClimateService());
    FloraChip chip(String label) => tester.widget<FloraChip>(find.widgetWithText(FloraChip, label));
    // Les questions de la main sont sous le viseur : la page y descend,
    // comme le doigt.
    Future<void> toucher(String label) async {
      await tester.ensureVisible(find.text(label));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }

    await toucher('Détrempée');
    expect(chip('Détrempée').selected, isTrue);
    expect(chip('Sèche').selected, isFalse, reason: 'un seul état de terre à la fois');

    // Le même toucher l'éteint : la question redevient sans réponse.
    await toucher('Détrempée');
    expect(chip('Détrempée').selected, isFalse);
  });

  testWidgets('en Fahrenheit, le champ le dit', (tester) async {
    await _open(tester, FakeHomeClimateService(), stored: {'metric_units': false});
    expect(find.text('°F'), findsOneWidget);
    expect(find.text('°C'), findsNothing);
  });

  testWidgets('un thermostat seul : la mesure est jointe, l’humidité seule se demande', (tester) async {
    final home = FakeHomeClimateService(reading: HomeReading(at: DateTime(2026, 9, 12), temperatureC: 21.4));
    await _open(tester, home, stored: {'home_sensor': _thermostat.encode()});
    expect(find.text('Mesure de la maison jointe : 21°.'), findsOneWidget);
    expect(find.text('Température'), findsNothing);
    expect(find.text('Humidité'), findsOneWidget);
  });

  testWidgets('la maison donne les deux : rien à demander', (tester) async {
    final home = FakeHomeClimateService(reading: HomeReading(at: DateTime(2026, 9, 12), temperatureC: 21.4, humidity: 38));
    await _open(tester, home, stored: {'home_sensor': _station.encode()});
    expect(find.text('Mesure de la maison jointe : 21° · 38 %.'), findsOneWidget);
    expect(find.text('Température'), findsNothing);
    expect(find.text('Humidité'), findsNothing);
  });

  testWidgets('une plante dehors : le thermomètre du salon ne compte pas, les deux se demandent', (tester) async {
    final home = FakeHomeClimateService(reading: HomeReading(at: DateTime(2026, 9, 12), temperatureC: 21.4, humidity: 38));
    await _open(tester, home, stored: {'home_sensor': _station.encode()}, outdoor: {'salon'});
    expect(find.textContaining('Mesure de la maison'), findsNothing);
    expect(find.text('Température'), findsOneWidget);
    expect(find.text('Humidité'), findsOneWidget);
  });
}
