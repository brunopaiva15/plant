import 'package:flora/app/providers.dart';
import 'package:flora/data/services/preferences_service.dart';
import 'package:flora/design_system/design_system.dart';
import 'package:flora/domain/care/care_guide.dart';
import 'package:flora/domain/care/care_profile.dart';
import 'package:flora/features/species/presentation/care_guide_screen.dart';
import 'package:flora/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// La fiche d'entretien sépare ce qui se pratique : l'arrosage, la lumière,
/// l'humidité, l'engrais et le rempotage ont chacun leur carte et leur teinte,
/// et ce qui ne vaut que pour un volet reste avec lui. Ce qui se lit sans rien
/// faire — température, difficulté, toxicité — tient dans la liste qui suit.
void main() {
  const profile = CareProfile(
    wateringSummerDays: 7,
    wateringWinterDays: 14,
    light: LightNeed.brightIndirect,
    humidity: HumidityNeed.high,
    difficulty: CareDifficulty.easy,
    soil: SoilKind.draining,
    fertilizingDays: 15,
    fertilizingWindow: MonthWindow(3, 9),
    repotEveryMonths: 24,
    mistLeaves: true,
    dormantInWinter: true,
    toxicity: Toxicity.safe,
  );

  Future<void> pump(WidgetTester tester, [CareProfile p = profile, double scale = 1.0]) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await PreferencesService.load();
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [preferencesServiceProvider.overrideWithValue(prefs)],
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
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(Space.page),
                child: CareGuideBody(care: ResolvedCare(profile: p, match: CareMatch.species)),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// La teinte de la carte qui porte ce titre.
  Color? tintOf(WidgetTester tester, String title) {
    final card = find.ancestor(of: find.text(title), matching: find.byType(FloraCard));
    return tester.widget<FloraCard>(card.first).color;
  }

  testWidgets('chaque volet du soin a sa carte et sa teinte', (tester) async {
    await pump(tester);
    const c = FloraColors.light;
    expect(tintOf(tester, 'Arrosage'), c.waterSoft);
    expect(tintOf(tester, 'Lumière'), c.sunSoft);
    expect(tintOf(tester, 'Humidité'), c.roseSoft);
    expect(tintOf(tester, 'Engrais'), c.sageSoft);
    expect(tintOf(tester, 'Rempotage'), c.terracottaSoft);
    // Le constat de chaque volet, sur sa carte.
    expect(find.text('Lumière vive indirecte'), findsOneWidget);
    expect(find.text("Aime l'air humide"), findsOneWidget);
    expect(find.text('Tous les 15 jours'), findsOneWidget);
    expect(find.text('Tous les 2 ans'), findsOneWidget);
  });

  testWidgets('le repère d’un volet reste sur sa carte', (tester) async {
    await pump(tester);
    // « Brumiser » ne flotte plus au-dessus de la fiche : il est sous l'humidité.
    expect(tintOf(tester, 'Brumiser'), FloraColors.light.roseSoft);
    expect(tintOf(tester, 'Repos hivernal'), FloraColors.light.waterSoft);
    // Le substrat se lit avec le rempotage : c'est le jour où il sert.
    expect(tintOf(tester, 'Substrat · Terreau très drainant'), FloraColors.light.terracottaSoft);
  });

  testWidgets('ce qui ne se pratique pas reste une liste', (tester) async {
    await pump(tester);
    expect(find.text('Difficulté'), findsOneWidget);
    expect(find.text('Toxicité'), findsOneWidget);
    // La liste ne reprend ni la lumière ni le substrat : ils ont leur carte.
    expect(find.byType(FloraGroup), findsOneWidget);
    expect(find.descendant(of: find.byType(FloraGroup), matching: find.text('Substrat')), findsNothing);
  });

  testWidgets('la carte « Eau » dit ce qu\'on verse, et ouvre les sept eaux', (tester) async {
    await pump(tester);
    // L'eau suit l'arrosage et garde son bleu : c'est le même sujet.
    expect(tintOf(tester, 'Eau'), FloraColors.light.waterSoft);
    expect(find.text('Eau du robinet'), findsOneWidget);
    expect(find.text('Le calcaire ne la gêne pas.'), findsOneWidget);

    await tester.tap(find.text('Eau'));
    await tester.pumpAndSettle();
    expect(find.text("Types d'eau"), findsOneWidget);
    // Les sept eaux, celles qu'on n'attend pas comprises.
    expect(find.text('Eau de pluie'), findsOneWidget);
    expect(find.text('Eau osmosée'), findsOneWidget);
    expect(find.text('Eau déminéralisée'), findsOneWidget);
    expect(find.text('Eau de climatiseur'), findsOneWidget);
    expect(find.text('Eau adoucie'), findsOneWidget);
    // Le verdict est écrit : la couleur ne le porte jamais seule.
    expect(find.text('Recommandée'), findsNWidgets(2), reason: 'le robinet et la pluie');
    expect(find.text('À éviter'), findsOneWidget, reason: "l'eau adoucie, pour toutes");
  });

  testWidgets('une plante qui craint le calcaire écarte le robinet', (tester) async {
    await pump(
      tester,
      const CareProfile(
        wateringSummerDays: 4,
        wateringWinterDays: 10,
        light: LightNeed.indirect,
        humidity: HumidityNeed.high,
        difficulty: CareDifficulty.demanding,
        soil: SoilKind.acidic,
        water: WaterTolerance.strict,
      ),
    );
    expect(find.text('Eau sans calcaire'), findsOneWidget);
    expect(find.text("Le calcaire l'abîme, même en petite quantité."), findsOneWidget);

    await tester.tap(find.text('Eau'));
    await tester.pumpAndSettle();
    expect(find.text('À éviter'), findsNWidgets(2), reason: 'le robinet et l\'eau adoucie');
    expect(find.text('Recommandée'), findsNWidgets(3), reason: 'la pluie, l\'osmosée, la déminéralisée');
  });

  testWidgets('les sept eaux tiennent à 350 % sans rognage', (tester) async {
    await pump(tester, profile, 3.5);
    final eau = find.text('Eau');
    await tester.ensureVisible(eau);
    await tester.pump();
    await tester.tap(eau);
    await tester.pumpAndSettle();
    expect(find.text("Types d'eau"), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'un débordement signale un texte rogné');
  });

  testWidgets('une plante sans engrais et sans rempotage le dit', (tester) async {
    await pump(
      tester,
      const CareProfile(
        wateringSummerDays: 4,
        wateringWinterDays: 4,
        light: LightNeed.fullSun,
        humidity: HumidityNeed.low,
        difficulty: CareDifficulty.easy,
        soil: SoilKind.standard,
        mistLeaves: false,
        dormantInWinter: false,
      ),
    );
    expect(find.text('Aucun engrais nécessaire'), findsOneWidget);
    expect(find.text('Pas de rempotage (culture annuelle)'), findsOneWidget);
    expect(find.text('Brumiser'), findsNothing);
    expect(find.text('Repos hivernal'), findsNothing);
  });
}
