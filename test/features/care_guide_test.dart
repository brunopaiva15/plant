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

  Future<void> pump(WidgetTester tester, [CareProfile p = profile]) async {
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
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(Space.page),
              child: CareGuideBody(care: ResolvedCare(profile: p, match: CareMatch.species)),
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
        bloom: Bloom(window: MonthWindow(4, 6), triggers: [BloomTrigger.coolNights]),
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
    expect(tintOf(tester, "60 à 80 % d'humidité de l'air"), FloraColors.light.roseSoft);
    expect(find.text("Plateau de billes d'argile humides, plantes groupées, pièce d'eau."), findsOneWidget);
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
        bloom: Bloom(window: MonthWindow(12, 5), triggers: [BloomTrigger.coolNights, BloomTrigger.keepSpike]),
      ),
    );
    expect(tintOf(tester, 'Floraison'), FloraColors.light.roseSoft);
    // La saison en constat, les conditions nommées puis expliquées.
    expect(find.text('De décembre à mai'), findsOneWidget);
    expect(find.text('Des nuits fraîches · Une hampe gardée'), findsOneWidget);
    expect(find.textContaining('Trois semaines à 15 °C la nuit'), findsOneWidget);
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
    // Sans rempotage, le rapport au pot n'a rien à dire.
    expect(find.textContaining('Rempotez'), findsNothing);
  });

  testWidgets('la lumière porte la lampe qui la remplace', (tester) async {
    await pump(tester);
    expect(find.text('Sous lampe · LED à spectre complet, 150 à 250 µmol/m²/s, 12 h par jour'), findsOneWidget);
    expect(find.text('Soit 6 à 11 mol/m²/jour reçus par le feuillage.'), findsOneWidget);
  });

  testWidgets("le pourcentage est celui de l'espèce, pas celui de sa catégorie", (tester) async {
    await pump(tester);
    expect(tintOf(tester, "60 à 80 % d'humidité de l'air"), FloraColors.light.roseSoft);
    // La serre porte la consigne : c'est là qu'on règle un taux.
    expect(tintOf(tester, 'Tenez la plage d\'humidité le jour, laissez-la descendre la nuit, et faites circuler l\'air.'), FloraColors.light.sunSoft);

    // Même mot, autre exigence : la fiche resserre sa plage pour elle.
    await pump(
      tester,
      const CareProfile(
        wateringSummerDays: 7,
        wateringWinterDays: 14,
        light: LightNeed.brightIndirect,
        humidity: HumidityNeed.high,
        humidityMinPercent: 50,
        humidityMaxPercent: 70,
        difficulty: CareDifficulty.easy,
        soil: SoilKind.standard,
        repotEveryMonths: 24,
      ),
    );
    expect(find.text("Aime l'air humide"), findsOneWidget);
    expect(find.text("50 à 70 % d'humidité de l'air"), findsOneWidget);
  });

  testWidgets('le rempotage dit ce qu\'une racine qui sort veut dire', (tester) async {
    await pump(tester);
    // Sans avis particulier, la règle ordinaire, et pas de puce.
    expect(tintOf(tester, 'Rempotez quand les racines sortent par le fond et tournent au fond du pot.'), FloraColors.light.terracottaSoft);
    expect(find.text("Aime être à l'étroit"), findsNothing);

    await pump(
      tester,
      const CareProfile(
        wateringSummerDays: 7,
        wateringWinterDays: 14,
        light: LightNeed.brightIndirect,
        humidity: HumidityNeed.average,
        difficulty: CareDifficulty.easy,
        soil: SoilKind.rich,
        repotEveryMonths: 24,
        pot: PotPreference.roomy,
      ),
    );
    expect(find.text("Aime l'espace"), findsOneWidget);
    expect(find.textContaining('dès que les racines atteignent la paroi'), findsOneWidget);

    // Une plante à réserves ne se rempote pas sur une racine : elle se
    // rempote à la reprise, la fin de son repos.
    await pump(tester, _bulb);
    expect(find.textContaining('à la reprise'), findsOneWidget);
    expect(find.textContaining('dès que les racines atteignent la paroi'), findsNothing);
  });

  testWidgets('la floraison et le repos paraissent quand l\'espèce les a', (tester) async {
    await pump(tester);
    expect(find.text('Floraison'), findsNothing);
    expect(find.text('Repos'), findsNothing);

    await pump(tester, _bulb);
    expect(find.text('Floraison'), findsOneWidget);
    expect(find.text('De février à avril'), findsOneWidget);
    expect(find.textContaining('Dix à quinze semaines entre 5 et 9 °C'), findsOneWidget);
    expect(find.text('Repos'), findsOneWidget);
    expect(find.text('De juin à septembre'), findsOneWidget);
    expect(find.text("Au sec et à l'obscurité, entre 10 et 18 °C"), findsOneWidget);
    expect(find.textContaining('Laissez le feuillage jaunir'), findsOneWidget);
  });

  testWidgets('le repos est la seule carte crème : elle décrit une absence', (tester) async {
    await pump(tester, _bulb);
    expect(tintOf(tester, 'Repos'), isNull);
    // La floraison, elle, se pratique : elle garde la teinte des volets.
    expect(tintOf(tester, 'Floraison'), FloraColors.light.roseSoft);
  });
}

/// Une plante à bulbe : elle veut de la place, fleurit à la sortie de l'hiver
/// et disparaît tout l'été.
const _bulb = CareProfile(
  wateringSummerDays: 30,
  wateringWinterDays: 10,
  light: LightNeed.fullSun,
  humidity: HumidityNeed.low,
  difficulty: CareDifficulty.easy,
  soil: SoilKind.draining,
  repotEveryMonths: 12,
  pot: PotPreference.roomy,
  dormantInWinter: false,
  bloom: Bloom(window: MonthWindow(2, 4), triggers: [BloomTrigger.chillBulb, BloomTrigger.brightLight]),
  dormancy: DormantRest(window: MonthWindow(6, 9), storeMinC: 10, storeMaxC: 18),
);
