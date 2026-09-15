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

  /// Amène le texte sous les yeux avant d'y toucher : la fiche est plus
  /// longue que l'écran, et une cible hors cadre ne reçoit pas le doigt.
  Future<void> toucher(WidgetTester tester, String texte) async {
    final cible = find.text(texte);
    await tester.ensureVisible(cible);
    await tester.pumpAndSettle();
    await tester.tap(cible);
    await tester.pumpAndSettle();
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
    final liste = find.ancestor(of: find.text('Difficulté'), matching: find.byType(FloraGroup));
    expect(liste, findsOneWidget);
    expect(find.descendant(of: liste, matching: find.text('Substrat')), findsNothing);
    expect(find.descendant(of: liste, matching: find.text('Lumière')), findsNothing);
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

  group('le tuteur', () {
    testWidgets('ne paraît que pour les espèces qui en demandent un', (tester) async {
      await pump(tester);
      expect(find.text('Tuteur'), findsNothing);
    });

    testWidgets('dit lequel, et quand s’en occuper', (tester) async {
      await pump(tester, _avec(profile, support: PlantSupport.mossPole));
      expect(find.text('Tuteur'), findsOneWidget);
      expect(find.text('Tuteur moussu'), findsOneWidget);
      expect(find.text("Humidifier le tuteur à chaque arrosage : les racines aériennes s'y fixent."), findsOneWidget);
    });

    testWidgets('garde sa carte crème : les cinq teintes sont aux volets du soin', (tester) async {
      await pump(tester, _avec(profile, support: PlantSupport.trellis));
      expect(tintOf(tester, 'Treillis'), isNull);
    });
  });

  group('« À surveiller »', () {
    const beaucoup = [
      CommonIssue.leafSpot,
      CommonIssue.spiderMites,
      CommonIssue.overwatering,
      CommonIssue.thrips,
      CommonIssue.mealybugs,
      CommonIssue.fungusGnats,
      CommonIssue.dryTips,
      CommonIssue.rootRot,
    ];

    testWidgets('range les troubles avant les bêtes, et les bêtes avant les maladies', (tester) async {
      await pump(tester, _avec(profile, issues: beaucoup));
      double y(String texte) => tester.getTopLeft(find.text(texte)).dy;
      expect(y("Excès d'eau (feuilles molles et jaunes)"), lessThan(y('Araignées rouges (fines toiles)')));
      expect(y('Pointes sèches et brunes'), lessThan(y('Araignées rouges (fines toiles)')));
      expect(y('Araignées rouges (fines toiles)'), lessThan(y('Thrips (feuilles argentées)')));
    });

    testWidgets('ne se replie pas : la liste de l’espèce tient en entier', (tester) async {
      // La section est écrite à la main, espèce par espèce ; cacher la moitié
      // derrière un bouton reviendrait à ne nommer que les araignées rouges.
      await pump(tester, _avec(profile, issues: beaucoup));
      for (final attendu in [
        'Taches foliaires',
        'Pourriture des racines',
        'Moucherons du terreau',
        'Cochenilles farineuses',
      ]) {
        expect(find.text(attendu), findsOneWidget, reason: attendu);
      }
      expect(find.text('Tout voir'), findsNothing);
    });
  });

  group('« Signes sur les feuilles »', () {
    testWidgets('les signes se lisent, les causes attendent le doigt', (tester) async {
      await pump(tester);
      expect(find.text('Feuilles brûlées'), findsOneWidget);
      expect(find.text('Feuilles qui ne grandissent plus'), findsOneWidget);
      expect(find.text('Trop de soleil direct'), findsNothing);
    });

    testWidgets('un signe ouvert montre ses causes, et referme le précédent', (tester) async {
      await pump(tester);
      await toucher(tester, 'Feuilles brûlées');
      expect(find.text('Trop de soleil direct'), findsOneWidget);
      expect(find.text('Terreau resté sec trop longtemps'), findsOneWidget);

      await toucher(tester, 'Feuilles molles');
      expect(find.text('Trop de soleil direct'), findsNothing);
      expect(find.text("Racines abîmées par l'eau stagnante"), findsOneWidget);
    });

    testWidgets('une cause que l’espèce ne connaît pas n’est pas proposée', (tester) async {
      // Plein soleil et air sec : ni brûlure de soleil, ni pointes brunies par
      // l'air de la pièce, et pas de repos hivernal à invoquer.
      await pump(
        tester,
        const CareProfile(
          wateringSummerDays: 4,
          wateringWinterDays: 8,
          light: LightNeed.fullSun,
          humidity: HumidityNeed.low,
          difficulty: CareDifficulty.easy,
          soil: SoilKind.cactus,
          dormantInWinter: false,
        ),
      );
      // Le signe reste — il a d'autres causes —, mais pas celle-là.
      await toucher(tester, 'Feuilles brûlées');
      expect(find.text('Trop de soleil direct'), findsNothing);
      expect(find.text('Terreau resté sec trop longtemps'), findsOneWidget);

      await toucher(tester, 'Feuilles qui ne grandissent plus');
      expect(find.text('Repos hivernal'), findsNothing);
      expect(find.text('Pas assez de lumière'), findsOneWidget);
    });
  });
}

/// [base] avec un champ de plus. Les fiches du catalogue sont des constantes ;
/// un test qui en veut une variante la recopie plutôt que d'en écrire une
/// entière à chaque fois.
CareProfile _avec(CareProfile base, {PlantSupport? support, List<CommonIssue>? issues}) => CareProfile(
      wateringSummerDays: base.wateringSummerDays,
      wateringWinterDays: base.wateringWinterDays,
      light: base.light,
      humidity: base.humidity,
      difficulty: base.difficulty,
      soil: base.soil,
      fertilizingDays: base.fertilizingDays,
      fertilizingWindow: base.fertilizingWindow,
      repotEveryMonths: base.repotEveryMonths,
      minTempC: base.minTempC,
      idealTempMinC: base.idealTempMinC,
      idealTempMaxC: base.idealTempMaxC,
      toxicity: base.toxicity,
      propagation: base.propagation,
      issues: issues ?? base.issues,
      support: support ?? base.support,
      mistLeaves: base.mistLeaves,
      dormantInWinter: base.dormantInWinter,
      outdoorFriendly: base.outdoorFriendly,
      tipKeys: base.tipKeys,
    );
