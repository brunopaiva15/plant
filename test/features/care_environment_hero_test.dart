import 'package:flora/design_system/design_system.dart';
import 'package:flora/domain/care/care_profile.dart';
import 'package:flora/features/species/presentation/care_environment_hero.dart';
import 'package:flora/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const profile = CareProfile(
    wateringSummerDays: 7,
    wateringWinterDays: 14,
    light: LightNeed.brightIndirect,
    humidity: HumidityNeed.high,
    humidityIdealMin: 55,
    humidityIdealMax: 75,
    difficulty: CareDifficulty.easy,
    soil: SoilKind.rich,
    idealTempMinC: 18,
    idealTempMaxC: 27,
  );

  Future<void> pump(WidgetTester tester, {double scale = 1}) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildFloraTheme(Brightness.light),
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
            child: const Scaffold(
              body: SingleChildScrollView(
                padding: EdgeInsets.all(Space.page),
                child: CareEnvironmentHero(profile: profile, speciesName: 'Monstera deliciosa'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('la scène résume lumière, humidité et température', (tester) async {
    await pump(tester);
    expect(find.byType(CareEnvironmentHero), findsOneWidget);
    expect(find.text('Lumière vive indirecte'), findsOneWidget);
    expect(find.text("55 à 75 % d'humidité de l'air"), findsOneWidget);
    expect(find.text('18 à 27 °C'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('les callouts quittent la scène à 350 % sans overflow', (tester) async {
    await pump(tester, scale: 3.5);
    expect(find.byType(CareEnvironmentHero), findsOneWidget);
    expect(find.text('Lumière vive indirecte'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
