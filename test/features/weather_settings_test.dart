import 'package:flora/app/providers.dart';
import 'package:flora/data/services/preferences_service.dart';
import 'package:flora/design_system/design_system.dart';
import 'package:flora/domain/location/location_service.dart';
import 'package:flora/domain/weather/region_climate.dart';
import 'package:flora/domain/weather/weather.dart';
import 'package:flora/features/weather/presentation/weather_settings_screen.dart';
import 'package:flora/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// L'écran Météo : le lieu se prend sur l'appareil autant qu'il se cherche,
/// et le titre de l'interrupteur de pluie se lit en entier.

/// Le service météo est muet : l'écran se monte sans réseau.
class _SilentWeather implements WeatherService {
  @override
  Future<List<WeatherPlace>> searchPlaces(String query, {String? language}) async => const [];

  @override
  Future<List<DailyWeather>> forecast(WeatherPlace place, {int days = 5, int pastDays = 0}) async => const [];

  @override
  Future<RegionClimate?> climate(WeatherPlace place) async => null;
}

/// L'appareil donne ce lieu-là, ou rien du tout.
class _FakeLocation implements LocationService {
  _FakeLocation(this.place);

  final WeatherPlace? place;
  int calls = 0;

  @override
  Future<WeatherPlace?> currentPlace({String? language}) async {
    calls++;
    return place;
  }
}

class _Harness {
  const _Harness(this.prefs, this.location, this.l10n);

  final PreferencesService prefs;
  final _FakeLocation location;
  final AppLocalizations l10n;
}

Future<_Harness> _pump(
  WidgetTester tester, {
  WeatherPlace? found,
  WeatherPlace? place,
  String locale = 'fr',
  double width = 390,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await PreferencesService.load();
  if (place != null) {
    await prefs.setWeatherPlace(name: place.name, lat: place.latitude, lon: place.longitude);
  }
  final location = _FakeLocation(found);
  tester.view.physicalSize = Size(width * 3, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      preferencesServiceProvider.overrideWithValue(prefs),
      weatherServiceProvider.overrideWithValue(_SilentWeather()),
      locationServiceProvider.overrideWithValue(location),
    ],
    child: MaterialApp(
      locale: Locale(locale),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildFloraTheme(Brightness.light),
      home: const WeatherSettingsScreen(),
    ),
  ));
  await tester.pumpAndSettle();
  return _Harness(prefs, location, AppLocalizations.of(tester.element(find.byType(WeatherSettingsScreen))));
}

const _bern = WeatherPlace(name: 'Berne, Suisse', latitude: 46.95, longitude: 7.45);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("la position de l'appareil pose le lieu sans rien taper", (tester) async {
    final h = await _pump(tester, found: _bern);
    expect(h.prefs.weatherPlace, isNull);

    await tester.tap(find.text(h.l10n.useMyLocation));
    await tester.pumpAndSettle();

    expect(h.location.calls, 1);
    expect(h.prefs.weatherPlace?.name, 'Berne, Suisse');
    expect(find.text('Berne, Suisse'), findsOneWidget);
  });

  testWidgets('position refusée : le lieu reste vide, et le champ de recherche avec', (tester) async {
    final h = await _pump(tester, found: null);

    await tester.tap(find.text(h.l10n.useMyLocation));
    await tester.pumpAndSettle();

    expect(h.prefs.weatherPlace, isNull);
    expect(find.text(h.l10n.weatherNone), findsOneWidget);
    expect(find.byType(FloraTextField), findsOneWidget);
  });

  testWidgets('un lieu déjà choisi se remplace par la position', (tester) async {
    final h = await _pump(tester, place: const WeatherPlace(name: 'Courtelary, Suisse', latitude: 47.17, longitude: 7.07), found: _bern);

    final row = find.text(h.l10n.useMyLocation);
    await tester.ensureVisible(row);
    await tester.tap(row);
    await tester.pumpAndSettle();

    expect(h.prefs.weatherPlace?.name, 'Berne, Suisse');
  });

  // « La pluie compte comme un arrosage » ne tient pas sur une ligne à côté
  // d'un interrupteur : le titre plie plutôt que de finir en points de
  // suspension. La police du banc d'essai donne la même chasse à tous les
  // glyphes et ne mesure pas le texte réel : ce qui se vérifie ici, c'est le
  // nombre de lignes accordées, et que l'écran se monte sans déborder sur un
  // iPhone SE, dans les quatre langues.
  for (final locale in ['fr', 'en', 'de', 'it']) {
    testWidgets("le titre de l'interrupteur de pluie plie au lieu d'être coupé, en $locale", (tester) async {
      final h = await _pump(tester, place: _bern, locale: locale, width: 320);
      final title = find.text(h.l10n.weatherRainCounts);
      await tester.ensureVisible(title);
      expect(tester.widget<Text>(title).maxLines, greaterThanOrEqualTo(2));
      expect(tester.takeException(), isNull);
    });
  }
}
