import 'package:flora/app/providers.dart';
import 'package:flora/design_system/design_system.dart';
import 'package:flora/domain/species/species_info.dart';
import 'package:flora/features/finder/presentation/finder_cards.dart';
import 'package:flora/features/finder/presentation/plant_finder_screen.dart';
import 'package:flora/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// GBIF n'est pas joignable depuis un test : aucune vignette, et la tuile
/// d'emoji tient la place.
class _OfflineSpecies implements SpeciesService {
  @override
  Future<List<SpeciesSuggestion>> suggest(String query, {String? languageCode}) async => const [];

  @override
  Future<SpeciesSearchPage> search(String query, {int offset = 0, int limit = 30, String? languageCode}) async =>
      const SpeciesSearchPage(results: [], endOfRecords: true);

  @override
  Future<SpeciesInfo?> lookup(String scientificName) async => null;

  @override
  Future<SpeciesInfo?> byKey(int key) async => null;

  @override
  Future<SpeciesImage?> thumbnail(String scientificName) async => null;
}

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [speciesServiceProvider.overrideWithValue(_OfflineSpecies())],
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
        home: const PlantFinderScreen(),
      ),
    ),
  );
  await tester.pump();
}

/// Touche une réponse et laisse la page tourner : la tuile se colore le
/// temps d'un battement avant que la page ne bouge, et ce battement est un
/// minuteur, que seul le temps fait passer.
Future<void> _answer(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
}

/// Touche une puce de genre, quitte à faire défiler la rangée jusqu'à elle.
/// La rangée ne construit que ce qu'elle montre : une puce sortie du cadre
/// n'est plus dans l'arbre, et il faut d'abord la ramener.
Future<void> _filter(WidgetTester tester, String label) async {
  final row = find.byWidgetPredicate((w) => w is ListView && w.scrollDirection == Axis.horizontal);
  if (find.text(label).evaluate().isEmpty) {
    await tester.drag(row, const Offset(600, 0));
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(find.text(label));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

Future<void> _reachResults(WidgetTester tester, {String spot = 'Coin sombre', String effort = 'Arrosage occasionnel', String safety = 'Oui, sans risque de préférence'}) async {
  await _pump(tester);
  await _answer(tester, spot);
  await _answer(tester, effort);
  await _answer(tester, safety);
}

void main() {
  group('« Trouver une plante »', () {
    testWidgets('trois questions, puis un premier choix et ses raisons', (tester) async {
      await _pump(tester);
      expect(find.text('Emplacement'), findsOneWidget);
      expect(find.text('Question 1 sur 3'), findsOneWidget);

      await _answer(tester, 'Coin sombre');
      expect(find.text('Quel entretien ?'), findsOneWidget);
      expect(find.text('Question 2 sur 3'), findsOneWidget);

      await _answer(tester, 'Arrosage occasionnel');
      expect(find.text('Des animaux ou des enfants ?'), findsOneWidget);

      await _answer(tester, 'Oui, sans risque de préférence');
      expect(find.text('Propositions'), findsOneWidget);
      expect(find.text('Notre premier choix'), findsOneWidget);
      expect(find.byType(FinderTopPickCard), findsOneWidget);
      expect(find.byType(FinderMatchCard), findsWidgets);
      // Un coin sombre : le premier choix supporte l'ombre, et « sans
      // risque » se lit sur chaque carte.
      expect(find.text("Supporte l'ombre"), findsWidgets);
      expect(find.text('Non toxique'), findsWidgets);
    });

    testWidgets('« Peu importe » passe la question sans répondre', (tester) async {
      await _pump(tester);
      await _answer(tester, 'Peu importe');
      expect(find.text('Quel entretien ?'), findsOneWidget);
      await _answer(tester, 'Peu importe');
      await _answer(tester, 'Pas de contrainte');
      expect(find.text('Notre premier choix'), findsOneWidget);
      expect(find.text('Endroit : peu importe'), findsOneWidget);
      expect(find.text('Entretien : peu importe'), findsOneWidget);
    });

    testWidgets('le genre de plante filtre les propositions sur place', (tester) async {
      await _reachResults(tester);
      expect(find.byType(FinderTopPickCard), findsOneWidget);

      // Un cactus dans un coin sombre : le catalogue n'a rien d'honnête à
      // dire, et il le dit.
      await _filter(tester, 'Succulentes');
      expect(find.text('Aucun résultat'), findsOneWidget);
      expect(find.byType(FinderTopPickCard), findsNothing);

      await _filter(tester, 'Toutes');
      expect(find.byType(FinderTopPickCard), findsOneWidget);
    });

    testWidgets('une puce ramène à sa question, et la réponse revient aux propositions', (tester) async {
      await _reachResults(tester);
      await tester.tap(find.text('Coin sombre'));
      await tester.pumpAndSettle();
      expect(find.text('Emplacement'), findsOneWidget);

      await _answer(tester, 'Pièce lumineuse');
      expect(find.text('Propositions'), findsOneWidget);
      expect(find.text('Pièce lumineuse'), findsOneWidget);
      expect(find.text('Coin sombre'), findsNothing);
    });

    testWidgets('recommencer efface les réponses', (tester) async {
      await _reachResults(tester);
      await tester.dragUntilVisible(find.text('Recommencer'), find.byType(ListView).first, const Offset(0, -300));
      await tester.tap(find.text('Recommencer'));
      await tester.pumpAndSettle();
      expect(find.text('Emplacement'), findsOneWidget);
      await _answer(tester, 'Peu importe');
      await _answer(tester, 'Peu importe');
      await _answer(tester, 'Pas de contrainte');
      expect(find.text('Endroit : peu importe'), findsOneWidget);
      expect(find.text('Pas de contrainte'), findsOneWidget);
    });
  });
}
