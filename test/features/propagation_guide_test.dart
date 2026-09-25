import 'package:flora/app/providers.dart';
import 'package:flora/data/services/preferences_service.dart';
import 'package:flora/design_system/design_system.dart';
import 'package:flora/domain/cuttings/propagation_guide.dart';
import 'package:flora/features/cuttings/presentation/propagation_guide_sheet.dart';
import 'package:flora/features/cuttings/application/propagation_guides.dart';
import 'package:flora/features/cuttings/presentation/clay_sequence.dart';
import 'package:flora/features/cuttings/presentation/propagation_intro_cluster.dart';
import 'package:flora/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Le guide de multiplication : le geste choisi pour l'espèce, une
/// introduction qui réunit ses étapes, les étapes qu'on feuillette, un texte
/// local qui se précise quand l'IA connaît l'espèce, et trois sorties — au
/// bout du guide, en le passant, ou en renonçant.
///
/// Quand la plante se multiplie de plusieurs façons, un écran de choix vient
/// d'abord, et c'est lui qui décide de tout le reste.

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
class _FakeRefiner implements PropagationGuideRefiner {
  _FakeRefiner(this.reponse);

  final PropagationRefinement reponse;
  final demandes = <String>[];

  @override
  bool get isConfigured => true;

  @override
  Future<PropagationRefinement> refine({
    required String scientificName,
    required String language,
    required PropagationGuideKind kind,
    required List<String> stepIds,
  }) async {
    demandes.add('$language|${kind.name}|$scientificName');
    return reponse;
  }
}

Future<({_FakeRefiner refiner, List<bool?> resultats})> _pump(
  WidgetTester tester, {
  String? species,
  Map<String, Object> prefs = const {},
  PropagationRefinement reponse = const PropagationRefinement(steps: _precis),
}) async {
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
        propagationRefinerProvider.overrideWithValue(refiner),
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
              onPressed: () async => resultats.add(await showPropagationGuide(context, species: species)),
              child: const Text('multiplier'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('multiplier'));
  // La sheet arrive par une transition, puis la scène joue son entrée : on
  // attend que tout soit posé avant de toucher à quoi que ce soit.
  await tester.pumpAndSettle();
  return (refiner: refiner, resultats: resultats);
}

/// Feuillette le guide de l'introduction jusqu'à la dernière étape.
Future<void> _parcourt(WidgetTester tester, int etapes) async {
  await tester.tap(find.text('Suivant'));
  await tester.pumpAndSettle();
  for (var i = 0; i < etapes - 1; i++) {
    expect(find.text('Continuer'), findsOneWidget, reason: 'étape ${i + 1} sur $etapes');
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();
  }
}

void main() {
  group('le guide de multiplication', () {
    testWidgets('une liane ouvre sur la bouture de tige, sans écran de choix', (tester) async {
      final t = await _pump(tester, species: 'Epipremnum aureum');
      expect(find.bySemanticsLabel('Multiplier cette plante'), findsNothing);
      // Le titre d'introduction est celui du flux Boutures, pas le nom de la
      // méthode : celui-ci vit dans le choix et les étapes.
      expect(find.bySemanticsLabel('Créer une bouture de Epipremnum aureum'), findsOneWidget);
      expect(find.byType(PropagationIntroCluster), findsOneWidget);
      expect(find.textContaining('6 étapes'), findsOneWidget);
      expect(find.text('Continuer'), findsNothing);
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();
      for (final titre in ['Le nœud', 'La coupe', 'Le nœud dégagé', "L'eau", 'Les racines']) {
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

    testWidgets('un spathiphyllum montre une division, jamais une liane', (tester) async {
      await _pump(tester, species: 'Spathiphyllum wallisii');
      expect(find.bySemanticsLabel('Créer une bouture de Spathiphyllum wallisii'), findsOneWidget);
      await _parcourt(tester, 6);
      // Le flux Boutures reste générique : le titre et le bouton disent
      // « bouture », la méthode vit dans les étapes.
      expect(find.text('Créer la bouture'), findsOneWidget);
      expect(find.bySemanticsLabel('Le rempotage'), findsOneWidget);
    });

    testWidgets('sans espèce, le guide reste celui de la bouture de tige', (tester) async {
      final t = await _pump(tester);
      expect(find.bySemanticsLabel('Créer une bouture'), findsOneWidget);
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();
      expect(t.refiner.demandes, isEmpty);
      // Le mot seul, et non la phrase : le texte local se réécrit, le
      // renflement du nœud reste ce que cette étape nomme.
      expect(find.textContaining('renflement'), findsOneWidget);
    });

    testWidgets('« Passer » crée la plante sans lire', (tester) async {
      final t = await _pump(tester, species: 'Epipremnum aureum');
      await tester.tap(find.text('Passer'));
      await tester.pumpAndSettle();
      expect(t.resultats, [true]);
    });

    testWidgets('la croix renonce', (tester) async {
      final t = await _pump(tester, species: 'Epipremnum aureum');
      await tester.tap(find.bySemanticsLabel('Fermer'));
      await tester.pumpAndSettle();
      expect(t.resultats, [false]);
    });
  });

  group('le choix de la méthode', () {
    testWidgets('deux gestes possibles ouvrent un écran de choix', (tester) async {
      await _pump(tester, species: 'Dracaena trifasciata');
      expect(find.bySemanticsLabel('Multiplier cette plante'), findsOneWidget);
      expect(find.text('Division'), findsOneWidget);
      expect(find.text('Bouture de feuille'), findsOneWidget);
      expect(find.text('Conseillée'), findsOneWidget);
      // Tant que rien n'est choisi, il n'y a ni scène ni bouton de sortie.
      expect(find.byType(PropagationIntroCluster), findsNothing);
      expect(find.text('Passer'), findsNothing);
    });

    testWidgets('le geste choisi décide des étapes et des textes', (tester) async {
      final t = await _pump(tester, species: 'Dracaena trifasciata');
      await tester.tap(find.text('Bouture de feuille'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Créer une bouture de Dracaena trifasciata'), findsOneWidget);
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();
      // C'est bien le guide de la feuille que l'IA a précisé, pas un autre.
      expect(t.refiner.demandes, ['fr|leafCutting|Dracaena trifasciata']);
      expect(find.bySemanticsLabel('La feuille'), findsOneWidget);
    });

    testWidgets('la division du même sansevieria ne demande pas le même texte', (tester) async {
      final t = await _pump(tester, species: 'Dracaena trifasciata');
      await tester.tap(find.text('Division'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();
      expect(t.refiner.demandes, ['fr|division|Dracaena trifasciata']);
    });
  });

  group("ce que l'IA change, et ce qu'elle ne change pas", () {
    testWidgets('le texte précisé remplace le texte local', (tester) async {
      final t = await _pump(tester, species: 'Epipremnum aureum');
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();
      expect(t.refiner.demandes, ['fr|stemNodeVine|Epipremnum aureum']);
      expect(find.text(_precis[0]), findsOneWidget);
      expect(find.textContaining('renflement'), findsNothing);
      // La réponse est gardée sous le geste : la prochaine fois, rien ne part.
      final store = PreferencesService(await SharedPreferences.getInstance());
      expect(PropagationGuideStore.decode(store.cuttingGuides)['fr|stemNodeVine|epipremnum aureum']?.steps, _precis);
    });

    testWidgets("l'IA coupée dans les réglages : textes locaux, sans appel", (tester) async {
      final t = await _pump(tester, species: 'Epipremnum aureum', prefs: {'care_assist': false});
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();
      expect(t.refiner.demandes, isEmpty);
      // Le mot seul, et non la phrase : le texte local se réécrit, le
      // renflement du nœud reste ce que cette étape nomme.
      expect(find.textContaining('renflement'), findsOneWidget);
    });

    testWidgets('une réponse déjà obtenue se lit sans réseau', (tester) async {
      final brut = PropagationGuideStore.encode(
          {'fr|stemNodeVine|epipremnum aureum': const PropagationRefinement(steps: _precis)});
      final t = await _pump(tester, species: 'Epipremnum aureum', prefs: {'cutting_guides': brut});
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();
      expect(t.refiner.demandes, isEmpty);
      expect(find.text(_precis[0]), findsOneWidget);
    });

    testWidgets('une réponse vide laisse les textes locaux', (tester) async {
      await _pump(tester, species: 'Epipremnum aureum', reponse: const PropagationRefinement());
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();
      expect(find.textContaining('renflement'), findsOneWidget);
    });
  });

  group('la précision secondaire', () {
    testWidgets('elle dit ce qui se repère et ce qui se rate', (tester) async {
      await _pump(tester, species: 'Epipremnum aureum', reponse: const PropagationRefinement());
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();
      expect(find.text('À repérer'), findsOneWidget);
      expect(find.text('Nœud et racine aérienne'), findsOneWidget);
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();
      expect(find.text('À éviter'), findsOneWidget);
      expect(find.text('Couper au-dessus du nœud'), findsOneWidget);
    });

    testWidgets("le milieu d'enracinement vient de la fiche de l'espèce", (tester) async {
      await _pump(tester, species: 'Epipremnum aureum', reponse: const PropagationRefinement());
      await _parcourt(tester, 4);
      expect(find.text('Enracinement'), findsOneWidget);
      expect(find.text("Dans l'eau"), findsOneWidget);
    });
  });

  group('les animations', () {
    testWidgets('« réduire les animations » laisse feuilleter le guide entier', (tester) async {
      await _pump(tester, species: 'Aloe vera', reponse: const PropagationRefinement());
      expect(find.bySemanticsLabel('Créer une bouture de Aloe vera'), findsOneWidget);
      await _parcourt(tester, 6);
      expect(find.bySemanticsLabel('La reprise'), findsOneWidget);
      expect(find.text('Créer la bouture'), findsOneWidget);
    });

    testWidgets('« réduire les animations » pose la séquence sur sa dernière image', (tester) async {
      final etape = propagationGuideOf(PropagationGuideKind.offset).steps.first;
      await tester.pumpWidget(MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: ClaySequence(asset: etape.asset, side: 200)),
        ),
      ));
      // Le décodage passe par le vrai monde : sans `runAsync`, l'image
      // n'arrive jamais et le test mesurerait le banc d'essai, pas le widget.
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 800)));
      await tester.pump();
      expect(find.byType(RawImage), findsOneWidget);
    });

    testWidgets('les points de progression comptent l\'introduction et les étapes', (tester) async {
      await _pump(tester, species: 'Epipremnum aureum', reponse: const PropagationRefinement());
      expect(find.bySemanticsLabel('Étape 1 sur 7'), findsOneWidget);
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Étape 2 sur 7'), findsOneWidget);
    });
  });

  group('un guide de longueur quelconque', () {
    // Rien, dans la scène, ne suppose six étapes : la grappe d'introduction
    // se range toute seule, que le guide en compte quatre ou neuf.
    for (final n in [1, 4, 5, 7, 9]) {
      testWidgets('la grappe d\'introduction range $n séquences', (tester) async {
        final steps = [
          for (var i = 0; i < n; i++) propagationGuideOf(PropagationGuideKind.values[i % 6]).steps[i % 6],
        ];
        await tester.pumpWidget(MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Center(child: PropagationIntroCluster(steps: steps, side: 300, animate: false)),
          ),
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(ClaySequence), findsNWidgets(n));
      });
    }
  });
}
