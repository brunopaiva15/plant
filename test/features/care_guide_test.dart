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
          // L'échelle du texte s'écrase seule : une `MediaQueryData` neuve
          // emporterait la taille de la vue avec elle, et la page se
          // disposerait dans le vide.
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
              child: Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(Space.page),
                  child: CareGuideBody(care: ResolvedCare(profile: p, match: CareMatch.species)),
                ),
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
    // Le substrat a sa carte, de la couleur du rempotage : même terre.
    expect(tintOf(tester, 'Substrat'), FloraColors.light.terracottaSoft);
    expect(find.text('Terreau très drainant'), findsOneWidget);
  });

  testWidgets('le substrat dit son mélange et ce qu’elle accepte hors du pot', (tester) async {
    await pump(tester);
    expect(find.text('50 % de terreau, 25 % de perlite, 25 % de sable grossier ou de pouzzolane.'), findsOneWidget);
    // Une plante en pot se mène en pon ; celle-ci ne vit pas dans l'eau.
    expect(tintOf(tester, "Dans l'eau : non · En pon : oui"), FloraColors.light.terracottaSoft);
  });

  testWidgets('l’engrais dit lequel, et ce que le calcium lui fait', (tester) async {
    await pump(tester);
    expect(tintOf(tester, 'Engrais plantes vertes équilibré, dilué de moitié.'), FloraColors.light.sageSoft);
    expect(find.text('de mars à septembre'), findsOneWidget);
    // Terreau drainant : le calcium ne pose pas de question, rien n'en est dit.
    expect(find.textContaining('Calcium'), findsNothing);

    await pump(
      tester,
      const CareProfile(
        wateringSummerDays: 5,
        wateringWinterDays: 12,
        light: LightNeed.brightIndirect,
        humidity: HumidityNeed.average,
        difficulty: CareDifficulty.medium,
        soil: SoilKind.acidic,
        fertilizingDays: 30,
        repotEveryMonths: 24,
        minTempC: 12,
        bloom: BloomTrigger.coolNights,
      ),
    );
    expect(find.text('Engrais pour terre de bruyère, sans calcaire.'), findsOneWidget);
    // Humidité ordinaire : la serre promet de la chaleur et de la lumière,
    // pas de l'air humide.
    expect(find.text('Chaleur et lumière'), findsOneWidget);
    expect(find.textContaining('le calcaire fait jaunir son feuillage'), findsOneWidget);
    // Ni eau ni pon pour une plante de terre de bruyère : la ligne disparaît.
    expect(find.textContaining('En pon'), findsNothing);
  });

  testWidgets('l’humidité dit un taux, pas seulement un mot', (tester) async {
    await pump(tester);
    expect(tintOf(tester, '60 % et plus : plateau de billes d\'argile humides, plantes groupées, pièce d\'eau. Sous 45 %, l\'air lui manque.'), FloraColors.light.roseSoft);
  });

  testWidgets('la serre et la floraison sont deux projets, après la liste', (tester) async {
    await pump(tester);
    expect(tintOf(tester, 'Sous serre'), FloraColors.light.sunSoft);
    expect(find.text('Chaleur et air humide'), findsOneWidget);
    // Rien à tenter pour la faire fleurir : la carte ne paraît pas.
    expect(find.text('Floraison'), findsNothing);

    await pump(
      tester,
      const CareProfile(
        wateringSummerDays: 7,
        wateringWinterDays: 14,
        light: LightNeed.indirect,
        humidity: HumidityNeed.high,
        difficulty: CareDifficulty.medium,
        soil: SoilKind.orchid,
        fertilizingDays: 21,
        repotEveryMonths: 24,
        minTempC: 15,
        bloom: BloomTrigger.coolNights,
      ),
    );
    expect(tintOf(tester, 'Floraison'), FloraColors.light.roseSoft);
    expect(find.text('Des nuits fraîches'), findsOneWidget);
  });

  testWidgets('une plante qui passe l’hiver dehors n’a pas de serre à proposer', (tester) async {
    await pump(
      tester,
      const CareProfile(
        wateringSummerDays: 6,
        wateringWinterDays: 20,
        light: LightNeed.fullSun,
        humidity: HumidityNeed.low,
        difficulty: CareDifficulty.easy,
        soil: SoilKind.draining,
        fertilizingDays: 45,
        repotEveryMonths: 36,
        minTempC: -8,
      ),
    );
    expect(find.text('Sous serre'), findsNothing);
    expect(find.textContaining('En pon'), findsNothing);
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
