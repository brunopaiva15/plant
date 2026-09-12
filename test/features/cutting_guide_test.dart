import 'package:flora/app/providers.dart';
import 'package:flora/data/services/preferences_service.dart';
import 'package:flora/design_system/design_system.dart';
import 'package:flora/domain/cuttings/cutting_guide.dart';
import 'package:flora/features/cuttings/presentation/cutting_guide_sheet.dart';
import 'package:flora/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Le guide de bouturage : six étapes qu'on feuillette, un texte générique
/// qui se précise pour l'espèce quand l'IA la connaît, et trois sorties —
/// au bout du guide, en le passant, ou en renonçant.

const _precis = [
  'Le nœud de cette liane porte une racine aérienne : elle reprend vite.',
  'Coupe sous le nœud, lame propre.',
  'Une feuille en haut suffit.',
  "L'eau lui va mieux que la terre.",
  'Trois semaines en général.',
  'En pot dès trois centimètres de racines.',
];

/// Une IA de laboratoire : elle compte ce qu'on lui demande et répond ce
/// qu'on lui a donné.
class _FakeRefiner implements CuttingGuideRefiner {
  _FakeRefiner(this.reponse);

  final CuttingGuideRefinement reponse;
  final demandes = <String>[];

  @override
  bool get isConfigured => true;

  @override
  Future<CuttingGuideRefinement> refine({required String scientificName, required String language}) async {
    demandes.add('$language|$scientificName');
    return reponse;
  }
}

Future<({_FakeRefiner refiner, List<bool?> resultats})> _pump(WidgetTester tester,
    {String? species, Map<String, Object> prefs = const {}, CuttingGuideRefinement reponse = const CuttingGuideRefinement(steps: _precis)}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(prefs);
  final service = await PreferencesService.load();
  final refiner = _FakeRefiner(reponse);
  final resultats = <bool?>[];
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        preferencesServiceProvider.overrideWithValue(service),
        cuttingGuideRefinerProvider.overrideWithValue(refiner),
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
        // Sans animation : les objets d'argile respirent sans fin, rien ne
        // se stabiliserait jamais.
        builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: true), child: child!),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async => resultats.add(await showCuttingGuide(context, species: species)),
              child: const Text('bouturer'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('bouturer'));
  // La sheet arrive par une transition, puis la scène joue son entrée : on
  // attend que tout soit posé avant de toucher à quoi que ce soit.
  await tester.pumpAndSettle();
  return (refiner: refiner, resultats: resultats);
}

void main() {
  group('le guide de bouturage', () {
    testWidgets("montre six étapes, dans l'ordre du geste, puis crée la bouture", (tester) async {
      final t = await _pump(tester);
      // Le titre se lève ligne à ligne, et la police du banc d'essai le plie
      // vite : c'est son étiquette de synthèse vocale qui le dit d'un bloc.
      for (final titre in ['La tige', 'La coupe', 'Les feuilles', "L'eau", 'Les racines']) {
        expect(find.bySemanticsLabel(titre), findsOneWidget);
        expect(find.text('Créer la bouture'), findsNothing);
        await tester.tap(find.text('Continuer'));
        await tester.pumpAndSettle();
      }
      expect(find.bySemanticsLabel('Le pot'), findsOneWidget);
      await tester.tap(find.text('Créer la bouture'));
      await tester.pumpAndSettle();
      expect(t.resultats, [true]);
    });

    testWidgets('« Passer » crée la bouture sans lire', (tester) async {
      final t = await _pump(tester);
      await tester.tap(find.text('Passer'));
      await tester.pumpAndSettle();
      expect(t.resultats, [true]);
    });

    testWidgets('la croix renonce à la bouture', (tester) async {
      final t = await _pump(tester);
      await tester.tap(find.bySemanticsLabel('Fermer'));
      await tester.pumpAndSettle();
      expect(t.resultats, [false]);
    });

    testWidgets("le texte précisé par l'IA remplace le générique, et dit d'où il vient", (tester) async {
      final t = await _pump(tester, species: 'Epipremnum aureum');
      expect(t.refiner.demandes, ['fr|Epipremnum aureum']);
      expect(find.text(_precis[0]), findsOneWidget);
      expect(find.text("Étapes précisées par l'IA pour Epipremnum aureum."), findsOneWidget);
      expect(find.textContaining('Une tige saine'), findsNothing);
      // La réponse est gardée : la prochaine bouture de la même plante ne
      // redemande rien.
      final store = PreferencesService(await SharedPreferences.getInstance());
      expect(CuttingGuideStore.decode(store.cuttingGuides)['fr|epipremnum aureum']?.steps, _precis);
    });

    testWidgets('sans espèce, le générique reste et rien ne part', (tester) async {
      final t = await _pump(tester);
      expect(t.refiner.demandes, isEmpty);
      expect(find.textContaining('Une tige saine'), findsOneWidget);
    });

    testWidgets("l'IA coupée dans les réglages : générique, sans appel", (tester) async {
      final t = await _pump(tester, species: 'Epipremnum aureum', prefs: {'care_assist': false});
      expect(t.refiner.demandes, isEmpty);
      expect(find.textContaining('Une tige saine'), findsOneWidget);
    });

    testWidgets('une réponse déjà obtenue se lit sans réseau', (tester) async {
      final brut = CuttingGuideStore.encode({'fr|epipremnum aureum': const CuttingGuideRefinement(steps: _precis)});
      final t = await _pump(tester, species: 'Epipremnum aureum', prefs: {'cutting_guides': brut});
      expect(t.refiner.demandes, isEmpty);
      expect(find.text(_precis[0]), findsOneWidget);
    });
  });
}
