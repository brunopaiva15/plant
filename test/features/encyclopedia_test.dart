import 'dart:io';

import 'package:flora/app/providers.dart';
import 'package:flora/core/l10n/care_labels.dart';
import 'package:flora/core/utils/search_text.dart';
import 'package:flora/data/problems/problem_catalog.dart';
import 'package:flora/data/services/preferences_service.dart';
import 'package:flora/data/species/species_catalog.dart';
import 'package:flora/data/species/species_index.dart';
import 'package:flora/design_system/design_system.dart';
import 'package:flora/domain/care/care_profile.dart';
import 'package:flora/domain/care/toxicity.dart';
import 'package:flora/domain/models/models.dart';
import 'package:flora/domain/problems/plant_problem.dart';
import 'package:flora/features/encyclopedia/presentation/encyclopedia_screen.dart';
import 'package:flora/features/encyclopedia/presentation/problem_page.dart';
import 'package:flora/features/encyclopedia/presentation/species_page.dart';
import 'package:flora/features/plants/application/plant_providers.dart';
import 'package:flora/features/problems/presentation/problem_kind_icon.dart';
import 'package:flora/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// L'encyclopédie montre les actifs embarqués sans rien y ajouter : les tests
/// lui donnent donc la vraie base des deux cents problèmes, lue sur le
/// disque, et non un jeu d'essai qui aurait toujours raison.
void main() {
  final catalog = ProblemCatalog.parse(File('assets/problems/catalog.txt').readAsStringSync());

  Plant plante(String name, {String? species}) => Plant(
        id: name,
        gardenId: 'g1',
        name: name,
        speciesName: species,
        status: PlantStatus.active,
        health: PlantHealth.healthy,
        isFavorite: false,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );

  Future<void> pump(WidgetTester tester, Widget home, {List<PlantSummary> plants = const []}) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await PreferencesService.load();
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesServiceProvider.overrideWithValue(prefs),
          problemCatalogProvider.overrideWith((ref) => catalog),
          // Le catalogue étendu pèse deux méga-octets : il n'entre pas dans
          // un test, et l'encyclopédie sait vivre sans lui.
          speciesIndexProvider.overrideWith((ref) => SpeciesIndex(const [])),
          plantSummariesProvider.overrideWith((ref, filter) => Stream.value(plants)),
        ],
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildFloraTheme(Brightness.light),
          home: home,
        ),
      ),
    );
    await tester.pump();
  }

  group('le rayon des problèmes', () {
    testWidgets('annonce les deux cents entrées de la base', (tester) async {
      await pump(tester, const EncyclopediaScreen());
      expect(find.text('200 problèmes'), findsOneWidget);
      // La liste s'ouvre sur les troubles : l'énumération les range d'abord.
      expect(find.text('Troubles'), findsWidgets);
    });

    testWidgets('une famille choisie ne laisse que la sienne', (tester) async {
      await pump(tester, const EncyclopediaScreen());
      final ravageurs = catalog.problems.where((p) => p.kind == ProblemKind.pest).length;

      // La bande de puces défile : celle des ravageurs est hors de l'écran.
      final puce = find.widgetWithText(FloraChip, 'Ravageurs');
      await tester.ensureVisible(puce);
      await tester.pump();
      await tester.tap(puce);
      await tester.pump();

      expect(find.text('$ravageurs problèmes'), findsOneWidget);
      // La puce dit déjà la famille : plus de titre de section au-dessus.
      expect(find.text('Troubles'), findsNothing);
    });

    testWidgets('la recherche trouve par le nom de l\'hôte', (tester) async {
      await pump(tester, const EncyclopediaScreen());
      await tester.enterText(find.byType(EditableText).first, 'lycopersicum');
      await tester.pump();

      final attendus = catalog.problems.where((p) => p.hosts.any((h) => h.toLowerCase().contains('lycopersicum'))).length;
      expect(attendus, greaterThan(0), reason: 'la base cite la tomate');
      expect(find.text('$attendus problèmes'), findsOneWidget);
    });

    testWidgets('un numéro de la base retrouve son entrée', (tester) async {
      await pump(tester, const EncyclopediaScreen());
      await tester.enterText(find.byType(EditableText).first, '126');
      await tester.pump();

      expect(find.text(catalog['126']!.fr), findsOneWidget);
    });

    testWidgets('un nom courant retrouve l\'entrée que la base nomme autrement', (tester) async {
      await pump(tester, const EncyclopediaScreen());
      await tester.enterText(find.byType(EditableText).first, 'araignée rouge');
      await tester.pump();

      expect(find.text(catalog['060']!.fr), findsOneWidget, reason: 'la base dit « Tétranyques »');
    });

    testWidgets('un mot sans réponse le dit, plutôt qu\'une liste vide', (tester) async {
      await pump(tester, const EncyclopediaScreen());
      await tester.enterText(find.byType(EditableText).first, 'zzzzz');
      await tester.pump();

      expect(find.text('Aucun résultat'), findsOneWidget);
    });
  });

  group('le rayon des espèces', () {
    // Sous ce test, le catalogue détaillé n'a pas fini de charger : l'écran
    // montre le repli, le catalogue trié à la main, sous le libellé
    // « fiches détaillées ».
    final toutes = '${SpeciesCatalog.entries.length} fiches détaillées';

    testWidgets('compte les espèces du catalogue intégré', (tester) async {
      await pump(tester, const EncyclopediaScreen());
      await tester.tap(find.text('Espèces'));
      await tester.pump();

      expect(find.text(toutes), findsOneWidget);
    });

    testWidgets('la recherche trouve une espèce par son nom courant', (tester) async {
      await pump(tester, const EncyclopediaScreen());
      await tester.tap(find.text('Espèces'));
      await tester.pump();
      await tester.enterText(find.byType(EditableText).first, 'monstera');
      await tester.pump();

      expect(find.text('Monstera deliciosa · Araceae'), findsOneWidget);
    });

    testWidgets('la liste reste rangée, avec ou sans recherche', (tester) async {
      // Le rayon range ses fiches une fois pour toutes, puis ne fait plus que
      // les filtrer : trier trente-trois mille espèces à chaque frappe tenait
      // l'écran trois secondes. Filtrer une liste déjà rangée garde son ordre
      // — c'est ce que ce test vérifie, sans quoi l'optimisation se paierait
      // en fiches dans le désordre.
      await pump(tester, const EncyclopediaScreen());
      await tester.tap(find.text('Espèces'));
      await tester.pump();

      List<String> titres() => tester.widgetList<FloraListRow>(find.byType(FloraListRow)).map((r) => r.title).toList();

      void estRangee(List<String> noms, String quand) {
        for (var i = 1; i < noms.length; i++) {
          expect(
            foldSpeciesName(noms[i - 1]).compareTo(foldSpeciesName(noms[i])),
            lessThanOrEqualTo(0),
            reason: '$quand : « ${noms[i - 1]} » est listé avant « ${noms[i]} »',
          );
        }
      }

      final sansRecherche = titres();
      expect(sansRecherche.length, greaterThan(1));
      estRangee(sansRecherche, 'sans recherche');

      await tester.enterText(find.byType(EditableText).first, 'a');
      await tester.pump();
      final avecRecherche = titres();
      expect(avecRecherche.length, greaterThan(1));
      estRangee(avecRecherche, 'avec une recherche');
    });

    testWidgets('changer de rayon vide la recherche', (tester) async {
      await pump(tester, const EncyclopediaScreen());
      await tester.enterText(find.byType(EditableText).first, 'oidium');
      await tester.pump();

      await tester.tap(find.text('Espèces'));
      await tester.pump();

      // Sans cela, le catalogue d'espèces s'ouvrirait vide sur un mot tapé
      // pour l'autre rayon.
      expect(find.text(toutes), findsOneWidget);
    });
  });

  group('le rayon du vocabulaire', () {
    testWidgets('déplie les termes des fiches d\'entretien', (tester) async {
      await pump(tester, const EncyclopediaScreen());
      await tester.tap(find.text('Vocabulaire'));
      await tester.pump();

      // La lumière vient après les familles de problèmes, et le premier groupe
      // remplit l'écran à lui seul : la liste étant paresseuse, « Ombre » n'est
      // pas encore construit. On l'amène sous les yeux avant de le lire.
      await tester.scrollUntilVisible(
        find.text('Ombre'),
        150,
        scrollable: find.descendant(of: find.byType(CustomScrollView), matching: find.byType(Scrollable)).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Ombre'), findsOneWidget);
      expect(find.text('Loin des fenêtres, sans rayon direct de la journée.'), findsOneWidget);
    });

    testWidgets('la recherche garde le terme et laisse le reste', (tester) async {
      await pump(tester, const EncyclopediaScreen());
      await tester.tap(find.text('Vocabulaire'));
      await tester.pump();
      await tester.enterText(find.byType(EditableText).first, 'marcottage');
      await tester.pump();

      expect(find.text('Marcottage'), findsOneWidget);
      expect(find.text('Ombre'), findsNothing);
    });

    testWidgets('les quatre familles de problèmes y portent leur symbole', (tester) async {
      // C'est ici qu'on vient chercher ce que l'argile d'une fiche de soin ou
      // d'un diagnostic veut dire ; les autres termes ne se dessinent nulle
      // part, et n'ont donc rien à montrer.
      await pump(tester, const EncyclopediaScreen());
      await tester.tap(find.text('Vocabulaire'));
      await tester.pump();

      expect(find.text('Ravageur'), findsOneWidget);
      expect(find.byType(ProblemKindIcon), findsNWidgets(ProblemKind.values.length));
    });
  });

  group('la page d\'un problème', () {
    testWidgets('dit sa famille, son étendue et ses hôtes', (tester) async {
      await pump(tester, const ProblemPage(problemId: '126'));

      final oidium = catalog['126']!;
      // Le nom entier est sur la page, pas seulement dans la barre, où les
      // plus longs finiraient en points de suspension.
      expect(find.text(oidium.fr), findsWidgets);
      expect(find.text('Maladie · Entrée 126'), findsOneWidget);
      expect(find.text('Nombreux hôtes'), findsOneWidget);
      expect(find.text('Hôtes'), findsOneWidget);
      expect(find.text(oidium.hosts.first), findsOneWidget);
    });

    testWidgets('les autres noms de l\'entrée sont donnés, le titre ne bouge pas', (tester) async {
      await pump(tester, const ProblemPage(problemId: '060'));

      final tetranyques = catalog['060']!;
      expect(find.text(tetranyques.fr), findsWidgets, reason: 'le titre reste « Tétranyques »');
      expect(find.text('Autres noms'), findsOneWidget);
      expect(find.text('Araignées rouges'), findsOneWidget);
      expect(find.text('Tetranychus urticae'), findsOneWidget, reason: 'le nom scientifique aussi');
    });

    testWidgets('sans autre nom, la section n\'apparaît pas', (tester) async {
      // 016, les dégâts de grêle : le titre porte déjà le mot qu'on taperait.
      expect(catalog['016']!.aliases, isEmpty);
      await pump(tester, const ProblemPage(problemId: '016'));
      expect(find.text('Autres noms'), findsNothing);
    });

    testWidgets('un problème universel nomme toutes les plantes vasculaires', (tester) async {
      await pump(tester, const ProblemPage(problemId: '001'));
      expect(find.text('Toutes les plantes vasculaires'), findsOneWidget);
    });

    testWidgets('les plantes du jardin qui figurent parmi les hôtes sont listées', (tester) async {
      // 126, les oïdiums : la base cite la courgette parmi ses hôtes.
      await pump(
        tester,
        const ProblemPage(problemId: '126'),
        plants: [
          // Des noms qui n'existent nulle part ailleurs sur la page : la
          // liste des hôtes affiche déjà les noms courants du catalogue.
          PlantSummary(plant: plante('Cuco', species: 'Cucurbita pepo')),
          PlantSummary(plant: plante('Nino', species: 'Dracaena trifasciata')),
        ],
      );

      expect(catalog['126']!.hosts, contains('Cucurbita pepo'));
      expect(find.text('Dans le jardin'), findsOneWidget);
      expect(find.text('Cuco'), findsOneWidget);
      expect(find.text('Nino'), findsNothing);
    });

    testWidgets('un problème universel ne liste pas tout le jardin', (tester) async {
      await pump(
        tester,
        const ProblemPage(problemId: '001'),
        plants: [PlantSummary(plant: plante('Cuco', species: 'Cucurbita pepo'))],
      );
      // « Manque d'eau » concerne tout le monde : l'écrire n'apprend rien.
      expect(find.text('Dans le jardin'), findsNothing);
    });

    testWidgets('un numéro absent de la base ne laisse pas une page muette', (tester) async {
      await pump(tester, const ProblemPage(problemId: '999'));
      expect(find.text('Aucun résultat'), findsOneWidget);
    });
  });

  group("la fiche d'une espèce", () {
    testWidgets('porte la fiche d\'entretien du catalogue, sans plante', (tester) async {
      await pump(tester, const EncyclopediaSpeciesPage(scientificName: 'Monstera deliciosa'));

      expect(find.text('Monstera deliciosa'), findsOneWidget);
      expect(find.text('Famille · Araceae'), findsOneWidget);
      expect(find.text('Intérieur'), findsOneWidget);
      // Les volets de la fiche sont là, et celui de l'espèce exacte.
      expect(find.text('Arrosage'), findsOneWidget);
      expect(find.text('Fiche de l\'espèce'), findsOneWidget);
    });

    testWidgets('une espèce inconnue retombe sur des repères généraux', (tester) async {
      await pump(tester, const EncyclopediaSpeciesPage(scientificName: 'Zzyzx inexistens'));

      expect(find.text('Zzyzx inexistens'), findsWidgets);
      expect(find.text('Arrosage'), findsOneWidget);
    });
  });

  group('le vocabulaire, dans les quatre langues', () {
    for (final locale in AppLocalizations.supportedLocales) {
      test('${locale.languageCode} : chaque terme a sa définition', () async {
        final l10n = await AppLocalizations.delegate.load(locale);
        final notes = <String>[
          for (final v in ProblemKind.values) l10n.problemKindNote(v),
          for (final v in LightNeed.values) l10n.lightNote(v),
          for (final v in HumidityNeed.values) l10n.humidityNote(v),
          for (final v in SoilKind.values) l10n.soilNote(v),
          for (final v in Propagation.values) l10n.propagationNote(v),
          for (final v in Toxicity.values) l10n.toxicityNote(v),
          for (final v in CareDifficulty.values) l10n.difficultyNote(v),
        ];
        for (final note in notes) {
          expect(note.trim(), isNotEmpty);
        }
        // Une définition recopiée d'un terme sur l'autre ne définit rien.
        expect(notes.toSet(), hasLength(notes.length), reason: 'définitions en double');
      });

      test('${locale.languageCode} : chaque étendue a son nom et sa réserve', () async {
        final l10n = await AppLocalizations.delegate.load(locale);
        for (final scope in ProblemScope.values) {
          expect(l10n.problemScopeName(scope).trim(), isNotEmpty);
          expect(l10n.problemScopeNote(scope).trim(), isNotEmpty);
        }
      });
    }
  });
}
