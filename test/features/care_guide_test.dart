import 'package:flora/app/providers.dart';
import 'package:flora/data/services/preferences_service.dart';
import 'package:flora/design_system/design_system.dart';
import 'package:flora/domain/care/care_guide.dart';
import 'package:flora/domain/care/care_profile.dart';
import 'package:flora/domain/care/toxicity.dart';
import 'package:flora/domain/species/species_info.dart';
import 'package:flora/features/problems/presentation/problem_kind_icon.dart';
import 'package:flora/features/species/presentation/care_environment_hero.dart';
import 'package:flora/features/species/presentation/care_environment_scene.dart';
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
    humidityMethods: {HumidityMethod.mist},
    dormantInWinter: true,
  );

  Future<void> pump(
    WidgetTester tester, [
    CareProfile p = profile,
    double scale = 1.0,
    ToxicityFact toxicity = const ToxicityFact.unknown(),
    SpeciesCategory? category,
    bool showHero = true,
    bool paper = true,
    bool noMotion = false,
    Brightness brightness = Brightness.light,
  ]) async {
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
          theme: buildFloraTheme(brightness),
          // L'échelle du texte s'écrase seule : une `MediaQueryData` neuve
          // emporterait la taille de la vue avec elle, et la page se
          // disposerait dans le vide.
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
                disableAnimations: noMotion,
              ),
              child: Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(Space.page),
                  child: CareGuideBody(
                    care: ResolvedCare(
                      profile: p,
                      match: CareMatch.species,
                      toxicity: toxicity,
                    ),
                    category: category,
                    showEnvironmentHero: showHero,
                    paper: paper,
                  ),
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
    final card = find.ancestor(
      of: find.text(title),
      matching: find.byType(FloraCard),
    );
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
    // Le constat de chaque volet, sur sa carte. La lumière se lit deux
    // fois : la puce du héros « emplacement idéal », puis la carte.
    expect(find.text('Lumière vive indirecte'), findsNWidgets(2));
    expect(find.text("Air humide"), findsOneWidget);
    expect(find.text('Tous les 15 jours'), findsOneWidget);
    expect(find.text('Tous les 2 ans'), findsOneWidget);
    // L'arrosage dit d'abord la règle de séchage, puis l'estimation en jours.
    expect(find.text('Laisser sécher le quart supérieur'), findsOneWidget);
  });

  testWidgets('le repère d’un volet reste sur sa carte', (tester) async {
    await pump(tester);
    // La méthode d'humidité ne flotte plus au-dessus de la fiche : elle est
    // sous l'humidité, sur sa carte.
    expect(
      tintOf(tester, 'Brumiser le feuillage.'),
      FloraColors.light.roseSoft,
    );
    expect(
      tintOf(tester, 'Nécessite un repos hivernal'),
      FloraColors.light.waterSoft,
    );
    // Le substrat a sa carte, de la couleur du rempotage : même terre.
    expect(tintOf(tester, 'Substrat'), FloraColors.light.terracottaSoft);
    expect(find.text('Terreau très drainant'), findsOneWidget);
  });

  testWidgets('la toxicité porte sa provenance, à part du pied de fiche', (
    tester,
  ) async {
    // Un fait hérité de la famille ne se lit pas comme un fait de l'espèce.
    await pump(
      tester,
      profile,
      1.0,
      const ToxicityFact(
        status: Toxicity.toxic,
        level: ToxicitySource.family,
        matchedOn: 'Araceae',
      ),
    );
    expect(find.text('Toxique si ingérée'), findsOneWidget);
    expect(
      find.text('Famille des Araceae · non vérifié pour cette espèce'),
      findsOneWidget,
    );
  });

  testWidgets('une toxicité sans provenance dit son silence', (tester) async {
    await pump(tester);
    expect(find.text('Toxicité non renseignée'), findsOneWidget);
    expect(
      find.text(
        "Rien n'est renseigné pour cette espèce ; à tenir hors de portée par précaution.",
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'une fiche revue dit ce qui est vérifié, une estimation se tait',
    (tester) async {
      await pump(
        tester,
        const CareProfile(
          wateringSummerDays: 7,
          wateringWinterDays: 14,
          light: LightNeed.brightIndirect,
          humidity: HumidityNeed.average,
          difficulty: CareDifficulty.easy,
          soil: SoilKind.standard,
          sourcing: {CareField.hardiness: CareSource.rhs},
        ),
      );
      expect(find.text("Vérifié d'après RHS : Température"), findsOneWidget);

      await pump(tester);
      expect(find.textContaining("Vérifié d'après"), findsNothing);
    },
  );

  testWidgets('une lumière sourcée dit l\'idéal et le plancher', (
    tester,
  ) async {
    await pump(
      tester,
      const CareProfile(
        wateringSummerDays: 7,
        wateringWinterDays: 14,
        light: LightNeed.someSun,
        lightTolerance: LightNeed.lowLight,
        humidity: HumidityNeed.average,
        difficulty: CareDifficulty.easy,
        soil: SoilKind.standard,
        sourcing: {
          CareField.hardiness: CareSource.rhs,
          CareField.light: CareSource.rhs,
        },
      ),
    );
    expect(find.text('Quelques heures de soleil'), findsWidgets);
    expect(find.text('Tient jusqu\'à Faible lumière'), findsOneWidget);
    expect(
      find.text("Vérifié d'après RHS : Température, Lumière"),
      findsOneWidget,
    );
  });

  testWidgets('un substrat sourcé entre dans le tampon RHS', (tester) async {
    await pump(
      tester,
      const CareProfile(
        wateringSummerDays: 7,
        wateringWinterDays: 14,
        light: LightNeed.brightIndirect,
        humidity: HumidityNeed.average,
        difficulty: CareDifficulty.easy,
        soil: SoilKind.acidic,
        water: WaterTolerance.strict,
        sourcing: {
          CareField.soil: CareSource.rhs,
          CareField.water: CareSource.rhs,
        },
      ),
    );
    expect(find.text("Vérifié d'après RHS : Substrat, Eau"), findsOneWidget);
  });

  testWidgets('des problèmes sourcés entrent dans le tampon RHS', (
    tester,
  ) async {
    await pump(
      tester,
      const CareProfile(
        wateringSummerDays: 7,
        wateringWinterDays: 14,
        light: LightNeed.brightIndirect,
        humidity: HumidityNeed.average,
        difficulty: CareDifficulty.easy,
        soil: SoilKind.standard,
        issues: [CommonIssue.scale],
        sourcing: {CareField.issues: CareSource.rhs},
      ),
    );
    expect(find.text("Vérifié d'après RHS : À surveiller"), findsOneWidget);
  });

  testWidgets('le substrat dit son mélange et ce qu’elle accepte hors du pot', (
    tester,
  ) async {
    await pump(tester);
    expect(
      find.textContaining(
        '50 % de terreau, 25 % de perlite et 25 % de sable grossier',
      ),
      findsOneWidget,
    );
    // Une plante en pot se mène en pon ; celle-ci ne vit pas dans l'eau.
    expect(
      tintOf(
        tester,
        'Culture dans l’eau : déconseillée. Culture en pon : possible.',
      ),
      FloraColors.light.terracottaSoft,
    );
  });

  testWidgets('l’engrais dit lequel, et ce que le calcium lui fait', (
    tester,
  ) async {
    await pump(tester);
    expect(
      tintOf(
        tester,
        'Utilisez un engrais équilibré pour plantes vertes, dilué de moitié.',
      ),
      FloraColors.light.sageSoft,
    );
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
        damageBelowC: 12,
        bloom: Bloom(
          window: MonthWindow(4, 6),
          triggers: [BloomTrigger.coolNights],
        ),
      ),
    );
    expect(
      find.text(
        'Utilisez un engrais pour plantes de terre de bruyère, sans calcaire.',
      ),
      findsOneWidget,
    );
    // Humidité ordinaire : la serre promet de la chaleur et de la lumière,
    // pas de l'air humide.
    expect(find.text('Serre chaude et lumineuse'), findsOneWidget);
    // Le calcium se dit en nutrition : c'est la carte « Eau » qui parle calcaire.
    expect(find.textContaining('apport calcique'), findsOneWidget);
    expect(find.textContaining('eau de pluie'), findsNothing);
    // Ni eau ni pon pour une plante de terre de bruyère : la ligne disparaît.
    expect(find.textContaining('En pon'), findsNothing);
  });

  testWidgets('l’humidité dit un taux, pas seulement un mot', (tester) async {
    await pump(tester);
    expect(
      tintOf(tester, "60 à 80 % d'humidité de l'air"),
      FloraColors.light.roseSoft,
    );
    expect(find.textContaining('il faut le maintenir humide'), findsOneWidget);
    // La méthode propre à l'espèce suit : brumiser, ici.
    expect(find.text('Brumiser le feuillage.'), findsOneWidget);
  });

  testWidgets('la serre et la floraison sont deux projets, après la liste', (
    tester,
  ) async {
    await pump(tester);
    expect(tintOf(tester, 'Sous serre'), FloraColors.light.sunSoft);
    expect(find.text('Serre chaude et humide'), findsOneWidget);
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
        damageBelowC: 15,
        bloom: Bloom(
          window: MonthWindow(12, 5),
          triggers: [BloomTrigger.coolNights, BloomTrigger.keepSpike],
        ),
      ),
    );
    expect(tintOf(tester, 'Floraison'), FloraColors.light.roseSoft);
    // La saison en constat, les conditions nommées puis expliquées.
    expect(find.text('De décembre à mai'), findsOneWidget);
    expect(find.text('Des nuits fraîches · Une hampe gardée'), findsOneWidget);
    expect(
      find.textContaining('3 semaines avec des nuits autour de 15 °C'),
      findsOneWidget,
    );
  });

  testWidgets(
    'une plante qui passe l’hiver dehors n’a pas de serre à proposer',
    (tester) async {
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
          damageBelowC: -8,
        ),
      );
      expect(find.text('Sous serre'), findsNothing);
      expect(find.textContaining('En pon'), findsNothing);
    },
  );

  testWidgets('ce qui ne se pratique pas reste une liste', (tester) async {
    await pump(tester);
    expect(find.text('Difficulté'), findsOneWidget);
    expect(find.text('Toxicité'), findsOneWidget);
    // La liste ne reprend ni la lumière ni le substrat : ils ont leur carte.
    final liste = find.ancestor(
      of: find.text('Difficulté'),
      matching: find.byType(FloraGroup),
    );
    expect(liste, findsOneWidget);
    expect(
      find.descendant(of: liste, matching: find.text('Substrat')),
      findsNothing,
    );
    expect(
      find.descendant(of: liste, matching: find.text('Lumière')),
      findsNothing,
    );
  });

  testWidgets('la carte « Eau » dit ce qu\'on verse, et ouvre les sept eaux', (
    tester,
  ) async {
    await pump(tester);
    // L'eau suit l'arrosage et garde son bleu : c'est le même sujet.
    expect(tintOf(tester, 'Eau'), FloraColors.light.waterSoft);
    expect(find.text('Eau du robinet'), findsOneWidget);
    expect(find.text('Le calcaire est sans effet.'), findsOneWidget);

    await toucher(tester, 'Eau');
    expect(find.text("Types d'eau"), findsOneWidget);
    // Les sept eaux, celles qu'on n'attend pas comprises.
    expect(find.text('Eau de pluie'), findsOneWidget);
    expect(find.text('Eau osmosée'), findsOneWidget);
    expect(find.text('Eau déminéralisée'), findsOneWidget);
    expect(find.text('Eau de climatiseur'), findsOneWidget);
    expect(find.text('Eau adoucie'), findsOneWidget);
    // Le verdict est écrit : la couleur ne le porte jamais seule.
    expect(
      find.text('Recommandée'),
      findsNWidgets(2),
      reason: 'le robinet et la pluie',
    );
    expect(
      find.text('À éviter'),
      findsOneWidget,
      reason: "l'eau adoucie, pour toutes",
    );
  });

  testWidgets('une plante qui craint le calcaire écarte le robinet', (
    tester,
  ) async {
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
    expect(
      find.text("Le calcaire l'abîme, même en petite quantité."),
      findsOneWidget,
    );

    await toucher(tester, 'Eau');
    expect(
      find.text('À éviter'),
      findsNWidgets(2),
      reason: 'le robinet et l\'eau adoucie',
    );
    expect(
      find.text('Recommandée'),
      findsNWidgets(3),
      reason: 'la pluie, l\'osmosée, la déminéralisée',
    );
  });

  testWidgets('les sept eaux tiennent à 350 % sans rognage', (tester) async {
    await pump(tester, profile, 3.5);
    final eau = find.text('Eau');
    await tester.ensureVisible(eau);
    await tester.pump();
    await tester.tap(eau);
    await tester.pumpAndSettle();
    expect(find.text("Types d'eau"), findsOneWidget);
    expect(
      tester.takeException(),
      isNull,
      reason: 'un débordement signale un texte rogné',
    );
  });

  testWidgets('une plante sans engrais et sans rempotage le dit', (
    tester,
  ) async {
    await pump(
      tester,
      const CareProfile(
        wateringSummerDays: 4,
        wateringWinterDays: 4,
        light: LightNeed.fullSun,
        humidity: HumidityNeed.low,
        difficulty: CareDifficulty.easy,
        soil: SoilKind.standard,
        dormantInWinter: false,
      ),
    );
    expect(find.text('Aucun engrais nécessaire'), findsOneWidget);
    expect(find.text('Pas de rempotage (culture annuelle)'), findsOneWidget);
    expect(find.textContaining('brumisation'), findsNothing);
    expect(find.textContaining('repos hivernal'), findsNothing);
    // Sans rempotage, le rapport au pot n'a rien à dire.
    expect(find.textContaining('Rempotez'), findsNothing);
  });

  testWidgets('la lumière porte la lampe qui la remplace', (tester) async {
    await pump(tester);
    expect(
      find.text(
        'Sous lampe · LED à spectre complet, 150 à 250 µmol/m²/s, 12 h par jour',
      ),
      findsOneWidget,
    );
    expect(
      find.text('Soit 6 à 11 mol/m²/jour reçus par le feuillage.'),
      findsOneWidget,
    );
  });

  testWidgets(
    "le pourcentage est celui de l'espèce, pas celui de sa catégorie",
    (tester) async {
      await pump(tester);
      expect(
        tintOf(tester, "60 à 80 % d'humidité de l'air"),
        FloraColors.light.roseSoft,
      );
      // La serre porte la consigne : c'est là qu'on règle un taux.
      expect(
        tintOf(
          tester,
          'Tenez la plage d\'humidité le jour, laissez-la descendre la nuit, et faites circuler l\'air.',
        ),
        FloraColors.light.sunSoft,
      );

      // Même mot, autre exigence : la fiche resserre sa plage pour elle.
      await pump(
        tester,
        const CareProfile(
          wateringSummerDays: 7,
          wateringWinterDays: 14,
          light: LightNeed.brightIndirect,
          humidity: HumidityNeed.high,
          humidityIdealMin: 50,
          humidityIdealMax: 70,
          difficulty: CareDifficulty.easy,
          soil: SoilKind.standard,
          repotEveryMonths: 24,
        ),
      );
      expect(find.text("Air humide"), findsOneWidget);
      expect(find.text("50 à 70 % d'humidité de l'air"), findsOneWidget);
    },
  );

  testWidgets('le rempotage dit ce qu\'une racine qui sort veut dire', (
    tester,
  ) async {
    await pump(tester);
    // Sans avis particulier, la règle ordinaire, et pas de puce.
    expect(
      tintOf(
        tester,
        'Rempotez quand les racines sortent par le fond et tournent au fond du pot.',
      ),
      FloraColors.light.terracottaSoft,
    );
    expect(find.text("Mieux à l'étroit"), findsNothing);

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
    expect(find.text("Un pot large"), findsOneWidget);
    expect(
      find.textContaining('dès que les racines atteignent la paroi'),
      findsOneWidget,
    );

    // Une plante à réserves ne se rempote pas sur une racine : elle se
    // rempote à la reprise, la fin de son repos.
    await pump(tester, _bulb);
    expect(find.textContaining('à la reprise'), findsOneWidget);
    expect(
      find.textContaining('dès que les racines atteignent la paroi'),
      findsNothing,
    );
  });

  testWidgets('la floraison et le repos paraissent quand l\'espèce les a', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('Floraison'), findsNothing);
    expect(find.text('Repos'), findsNothing);

    await pump(tester, _bulb);
    expect(find.text('Floraison'), findsOneWidget);
    expect(find.text('De février à avril'), findsOneWidget);
    expect(
      find.textContaining('10 à 15 semaines entre 5 et 9 °C'),
      findsOneWidget,
    );
    expect(find.text('Repos'), findsOneWidget);
    expect(find.text('De juin à septembre'), findsOneWidget);
    expect(
      find.text("Au sec et à l'obscurité, entre 10 et 18 °C"),
      findsOneWidget,
    );
    expect(find.textContaining('Laissez le feuillage jaunir'), findsOneWidget);
  });

  testWidgets('le repos est la seule carte crème : elle décrit une absence', (
    tester,
  ) async {
    await pump(tester, _bulb);
    expect(tintOf(tester, 'Repos'), isNull);
    // La floraison, elle, se pratique : elle garde la teinte des volets.
    expect(tintOf(tester, 'Floraison'), FloraColors.light.roseSoft);
  });

  group('le tuteur', () {
    testWidgets('ne paraît que pour les espèces qui en demandent un', (
      tester,
    ) async {
      await pump(tester);
      expect(find.text('Tuteur'), findsNothing);
    });

    testWidgets('dit lequel, et quand s’en occuper', (tester) async {
      await pump(tester, _avec(profile, support: PlantSupport.mossPole));
      expect(find.text('Tuteur'), findsOneWidget);
      expect(find.text('Tuteur moussu'), findsOneWidget);
      expect(
        find.textContaining('Humidifiez le tuteur à chaque arrosage'),
        findsOneWidget,
      );
    });

    testWidgets(
      'garde sa carte crème : les cinq teintes sont aux volets du soin',
      (tester) async {
        await pump(tester, _avec(profile, support: PlantSupport.trellis));
        expect(tintOf(tester, 'Treillis'), isNull);
      },
    );
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

    testWidgets(
      'range les troubles avant les bêtes, et les bêtes avant les maladies',
      (tester) async {
        await pump(tester, _avec(profile, issues: beaucoup));
        double y(String texte) => tester.getTopLeft(find.text(texte)).dy;
        expect(
          y("Excès d'eau (feuilles molles et jaunes)"),
          lessThan(y('Araignées rouges (fines toiles)')),
        );
        expect(
          y('Pointes sèches et brunes'),
          lessThan(y('Araignées rouges (fines toiles)')),
        );
        expect(
          y('Araignées rouges (fines toiles)'),
          lessThan(y('Thrips (feuilles argentées)')),
        );
      },
    );

    testWidgets('ne se replie pas : la liste de l’espèce tient en entier', (
      tester,
    ) async {
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

    testWidgets('chaque ligne porte l’image de son souci', (tester) async {
      // La même argile que l'encyclopédie et le diagnostic : une cochenille
      // se reconnaît d'un écran à l'autre, ce qu'une pastille identique sur
      // toutes les lignes ne donnait pas.
      await pump(tester, _avec(profile, issues: beaucoup));
      final portees = tester
          .widgetList<CommonIssueIcon>(find.byType(CommonIssueIcon))
          .map((w) => w.issue);
      expect(portees.toSet(), beaucoup.toSet());
    });
  });

  group('« Signes sur les feuilles »', () {
    testWidgets('les signes se lisent, les causes attendent le doigt', (
      tester,
    ) async {
      await pump(tester);
      expect(find.text('Feuilles brûlées'), findsOneWidget);
      expect(find.text('Feuilles qui ne grandissent plus'), findsOneWidget);
      expect(find.text('Trop de soleil direct'), findsNothing);
    });

    testWidgets('un signe ouvert montre ses causes, et referme le précédent', (
      tester,
    ) async {
      await pump(tester);
      await toucher(tester, 'Feuilles brûlées');
      expect(find.text('Trop de soleil direct'), findsOneWidget);
      expect(find.text('Terreau resté sec trop longtemps'), findsOneWidget);

      await toucher(tester, 'Feuilles molles');
      expect(find.text('Trop de soleil direct'), findsNothing);
      expect(find.text("Racines abîmées par l'eau stagnante"), findsOneWidget);
    });

    testWidgets('une cause que l’espèce ne connaît pas n’est pas proposée', (
      tester,
    ) async {
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

  group('le héros « emplacement idéal »', () {
    testWidgets('ouvre la fiche, avant le détail des besoins', (tester) async {
      await pump(tester);
      expect(find.byType(CareEnvironmentScene), findsOneWidget);
      expect(find.text('Emplacement idéal'), findsOneWidget);
      final yHero = tester.getTopLeft(find.text('Emplacement idéal')).dy;
      final yBesoins = tester.getTopLeft(find.text('Besoins')).dy;
      expect(
        yHero,
        lessThan(yBesoins),
        reason: 'la scène se lit avant les cartes',
      );
    });

    testWidgets(
      'expose la lumière, l\'humidité, et la température quand elle existe',
      (tester) async {
        await pump(
          tester,
          const CareProfile(
            wateringSummerDays: 7,
            wateringWinterDays: 14,
            light: LightNeed.brightIndirect,
            humidity: HumidityNeed.high,
            difficulty: CareDifficulty.easy,
            soil: SoilKind.standard,
            idealTempMinC: 18,
            idealTempMaxC: 27,
          ),
        );
        final hero = find.byType(CareEnvironmentHero);
        expect(
          find.descendant(
            of: hero,
            matching: find.text('Lumière vive indirecte'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(of: hero, matching: find.text('60–80 %')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: hero, matching: find.text('18–27 °C')),
          findsOneWidget,
        );
      },
    );

    testWidgets('la température inconnue n\'affiche aucun chiffre', (
      tester,
    ) async {
      await pump(tester);
      final hero = find.byType(CareEnvironmentHero);
      expect(
        find.descendant(of: hero, matching: find.textContaining('°C')),
        findsNothing,
      );
    });

    testWidgets(
      'l\'air n\'est jamais inventé : non renseigné, rien ne se dit',
      (tester) async {
        await pump(tester);
        expect(find.textContaining('courants d\'air'), findsNothing);
        expect(find.text('Air bien ventilé'), findsNothing);
      },
    );

    testWidgets('l\'air renseigné se dit', (tester) async {
      await pump(
        tester,
        const CareProfile(
          wateringSummerDays: 7,
          wateringWinterDays: 14,
          light: LightNeed.indirect,
          humidity: HumidityNeed.high,
          difficulty: CareDifficulty.demanding,
          soil: SoilKind.standard,
          airflow: AirflowPreference.sheltered,
        ),
      );
      expect(find.text('À l\'abri des courants d\'air'), findsOneWidget);
    });

    testWidgets('la scène porte une description pour les lecteurs d\'écran', (
      tester,
    ) async {
      await pump(tester);
      expect(
        find.bySemanticsLabel(
          RegExp(
            '^Emplacement idéal : Lumière vive indirecte, Air humide',
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('tient à 200 % et à 350 % sans rognage', (tester) async {
      await pump(tester, profile, 2.0);
      expect(find.byType(CareEnvironmentScene), findsOneWidget);
      expect(
        tester.takeException(),
        isNull,
        reason: 'un débordement signale un texte rogné',
      );
      await pump(tester, profile, 3.5);
      expect(find.byType(CareEnvironmentScene), findsOneWidget);
      expect(
        tester.takeException(),
        isNull,
        reason: 'un débordement signale un texte rogné',
      );
    });

    testWidgets('reste lisible quand les animations sont désactivées', (
      tester,
    ) async {
      await pump(
        tester,
        profile,
        1.0,
        const ToxicityFact.unknown(),
        null,
        true,
        true,
        true,
      );
      expect(find.byType(CareEnvironmentScene), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('est intact sans la feuille de papier', (tester) async {
      await pump(
        tester,
        profile,
        1.0,
        const ToxicityFact.unknown(),
        null,
        true,
        false,
      );
      expect(find.byType(CareEnvironmentScene), findsOneWidget);
      expect(find.byType(PaperSheet), findsNothing);
    });

    testWidgets('peut être retiré des contextes qui n\'en veulent pas', (
      tester,
    ) async {
      await pump(
        tester,
        profile,
        1.0,
        const ToxicityFact.unknown(),
        null,
        false,
      );
      expect(find.byType(CareEnvironmentScene), findsNothing);
      expect(find.text('Emplacement idéal'), findsNothing);
      // La fiche reste entière.
      expect(find.text('Besoins'), findsOneWidget);
      expect(find.text('Arrosage'), findsOneWidget);
    });

    testWidgets('une espèce dehors a sa scène de jardin, pas un salon', (
      tester,
    ) async {
      await pump(
        tester,
        profile,
        1.0,
        const ToxicityFact.unknown(),
        SpeciesCategory.tree,
      );
      expect(find.byType(CareEnvironmentScene), findsOneWidget);
      expect(find.text('Emplacement idéal'), findsOneWidget);
      expect(find.text('Besoins'), findsOneWidget);
    });

    /// Une image de la scène dont le chemin contient [fragment].
    Finder image(String fragment) => find.byWidgetPredicate(
      (w) =>
          w is Image &&
          w.image is AssetImage &&
          (w.image as AssetImage).assetName.contains(fragment),
    );

    /// Les couches dessinées : l'ombre, plus la vapeur et le flux s'ils sont là.
    Finder couchesDessinees() => find.descendant(
      of: find.byType(CareEnvironmentScene),
      matching: find.byType(CustomPaint),
    );

    testWidgets(
      'l\'humidité élevée pose un humidificateur seulement si la fiche le prescrit',
      (tester) async {
        await pump(
          tester,
          const CareProfile(
            wateringSummerDays: 7,
            wateringWinterDays: 14,
            light: LightNeed.brightIndirect,
            humidity: HumidityNeed.high,
            difficulty: CareDifficulty.easy,
            soil: SoilKind.standard,
            humidityMethods: {HumidityMethod.humidifier},
          ),
        );
        expect(image('humidifier.webp'), findsOneWidget);
        // L'ombre et la vapeur : deux couches dessinées.
        expect(couchesDessinees(), findsNWidgets(2));

        await pump(tester, profile);
        expect(image('humidifier.webp'), findsNothing);
        expect(couchesDessinees(), findsOneWidget, reason: 'l\'ombre seule');
      },
    );

    testWidgets('un plateau de billes n\'invente pas d\'humidificateur', (
      tester,
    ) async {
      await pump(
        tester,
        const CareProfile(
          wateringSummerDays: 7,
          wateringWinterDays: 14,
          light: LightNeed.brightIndirect,
          humidity: HumidityNeed.high,
          difficulty: CareDifficulty.easy,
          soil: SoilKind.standard,
          humidityMethods: {HumidityMethod.tray},
        ),
      );
      expect(image('humidifier.webp'), findsNothing);
      expect(
        couchesDessinees(),
        findsOneWidget,
        reason: 'l\'ombre, pas de vapeur',
      );
    });

    testWidgets('l\'air à abriter entre par la fenêtre, à distance', (
      tester,
    ) async {
      await pump(
        tester,
        const CareProfile(
          wateringSummerDays: 7,
          wateringWinterDays: 14,
          light: LightNeed.indirect,
          humidity: HumidityNeed.high,
          difficulty: CareDifficulty.demanding,
          soil: SoilKind.standard,
          humidityMethods: {HumidityMethod.humidifier},
          airflow: AirflowPreference.sheltered,
        ),
      );
      expect(image('humidifier.webp'), findsOneWidget);
      // Ombre, vapeur, flux : trois couches dessinées.
      expect(couchesDessinees(), findsNWidgets(3));
      expect(find.text('À l\'abri des courants d\'air'), findsOneWidget);
    });

    testWidgets('l\'air bien ventilé a son flux autour de la plante', (
      tester,
    ) async {
      await pump(
        tester,
        const CareProfile(
          wateringSummerDays: 7,
          wateringWinterDays: 14,
          light: LightNeed.someSun,
          humidity: HumidityNeed.average,
          difficulty: CareDifficulty.easy,
          soil: SoilKind.standard,
          airflow: AirflowPreference.ventilated,
        ),
      );
      // Ombre et flux : deux couches dessinées.
      expect(couchesDessinees(), findsNWidgets(2));
      expect(find.text('Air bien ventilé'), findsOneWidget);
    });

    testWidgets('l\'air ordinaire n\'a pas d\'emphase', (tester) async {
      await pump(
        tester,
        const CareProfile(
          wateringSummerDays: 7,
          wateringWinterDays: 14,
          light: LightNeed.indirect,
          humidity: HumidityNeed.average,
          difficulty: CareDifficulty.easy,
          soil: SoilKind.standard,
          airflow: AirflowPreference.normal,
        ),
      );
      expect(couchesDessinees(), findsOneWidget, reason: 'l\'ombre seule');
      expect(find.text('Air ordinaire'), findsNothing);
    });

    testWidgets('reste un objet posé en thème sombre, pas un rectangle blanc', (
      tester,
    ) async {
      // Le diorama a ses propres murs et sols sur fond transparent : il
      // garde son identité physique sur le fond sombre, et les effets
      // dessinés suivent les tokens du thème.
      await pump(
        tester,
        profile,
        1.0,
        const ToxicityFact.unknown(),
        null,
        true,
        true,
        false,
        Brightness.dark,
      );
      expect(find.byType(CareEnvironmentScene), findsOneWidget);
      expect(find.text('Emplacement idéal'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('les effets restent lisibles et figés en reduced motion', (
      tester,
    ) async {
      await pump(
        tester,
        const CareProfile(
          wateringSummerDays: 7,
          wateringWinterDays: 14,
          light: LightNeed.indirect,
          humidity: HumidityNeed.high,
          difficulty: CareDifficulty.demanding,
          soil: SoilKind.standard,
          humidityMethods: {HumidityMethod.humidifier},
          airflow: AirflowPreference.sheltered,
        ),
        1.0,
        const ToxicityFact.unknown(),
        null,
        true,
        true,
        true,
      );
      expect(find.byType(CareEnvironmentScene), findsOneWidget);
      expect(image('humidifier.webp'), findsOneWidget);
      // La respiration bornée se termine : le settle finit toujours.
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    /// Le recul de la caméra : l'échelle du diorama à cet instant.
    double echelle(WidgetTester tester) => tester
        .widget<Transform>(
          find
              .descendant(
                of: find.byType(CareEnvironmentScene),
                matching: find.byType(Transform),
              )
              .first,
        )
        .transform
        .getMaxScaleOnAxis();

    /// La présence de la plante : son opacité à cet instant.
    double presence(WidgetTester tester) => tester
        .widget<Opacity>(
          find.descendant(
            of: find.byType(CareEnvironmentScene),
            matching: find.byType(Opacity),
          ),
        )
        .opacity;

    testWidgets('la scène se pose : gros plan sur la plante, puis recul', (
      tester,
    ) async {
      await pump(tester);
      // Première image : le cadre est serré sur la plante, qui n'est pas
      // encore posée.
      expect(echelle(tester), closeTo(CareEnvironmentScene.zoomInitial, 1e-6));
      expect(presence(tester), 0);

      // La plante est posée avant que la caméra ne recule.
      await tester.pump(CareEnvironmentScene.poseDuration * 0.36);
      expect(presence(tester), 1);
      expect(echelle(tester), closeTo(CareEnvironmentScene.zoomInitial, 1e-6));

      // Au bout de la pose, le cadre entier — et rien ne bouge plus.
      await tester.pump(CareEnvironmentScene.poseDuration);
      expect(echelle(tester), closeTo(1, 1e-6));
      expect(presence(tester), 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('en reduced motion, la scène est posée dès la première image', (
      tester,
    ) async {
      await pump(
        tester,
        profile,
        1.0,
        const ToxicityFact.unknown(),
        null,
        true,
        true,
        true,
      );
      expect(echelle(tester), closeTo(1, 1e-6));
      expect(presence(tester), 1);
      expect(tester.takeException(), isNull);
    });
  });
}

/// [base] avec un champ de plus. Les fiches du catalogue sont des constantes ;
/// un test qui en veut une variante la recopie plutôt que d'en écrire une
/// entière à chaque fois.
CareProfile _avec(
  CareProfile base, {
  PlantSupport? support,
  List<CommonIssue>? issues,
}) => CareProfile(
  wateringSummerDays: base.wateringSummerDays,
  wateringWinterDays: base.wateringWinterDays,
  light: base.light,
  humidity: base.humidity,
  difficulty: base.difficulty,
  soil: base.soil,
  humidityIdealMin: base.humidityIdealMin,
  humidityIdealMax: base.humidityIdealMax,
  water: base.water,
  fertilizingDays: base.fertilizingDays,
  fertilizingWindow: base.fertilizingWindow,
  repotEveryMonths: base.repotEveryMonths,
  pot: base.pot,
  damageBelowC: base.damageBelowC,
  idealTempMinC: base.idealTempMinC,
  idealTempMaxC: base.idealTempMaxC,
  propagation: base.propagation,
  issues: issues ?? base.issues,
  support: support ?? base.support,
  humidityMethods: base.humidityMethods,
  dormantInWinter: base.dormantInWinter,
  outdoorFriendly: base.outdoorFriendly,
  bloom: base.bloom,
  dormancy: base.dormancy,
  tipKeys: base.tipKeys,
);

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
  bloom: Bloom(
    window: MonthWindow(2, 4),
    triggers: [BloomTrigger.chillBulb, BloomTrigger.brightLight],
  ),
  dormancy: DormantRest(
    window: MonthWindow(6, 9),
    storeMinC: 10,
    storeMaxC: 18,
  ),
);
