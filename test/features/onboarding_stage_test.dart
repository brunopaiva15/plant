import 'package:flora/design_system/design_system.dart';
import 'package:flora/features/onboarding/presentation/clay_illustration.dart';
import 'package:flora/features/onboarding/presentation/onboarding_stage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flora/l10n/generated/app_localizations.dart';

const _chips = [
  SceneChip(icon: CupertinoIcons.drop_fill, label: 'Arrosage', tint: _water, at: Alignment(-1, -0.6)),
  SceneChip(icon: CupertinoIcons.camera_fill, label: 'Photos', tint: _sage, at: Alignment(1, 0.7)),
];

Color _water(FloraColors c) => c.water;
Color _sage(FloraColors c) => c.sage;

Future<void> _pump(
  WidgetTester tester, {
  required double offset,
  required int page,
  double entry = 1,
  bool reduceMotion = false,
}) async {
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
      home: Scaffold(
        body: OnboardingStage(
          count: 5,
          offset: offset,
          page: page,
          entry: entry,
          drift: 0.25,
          chips: _chips,
          height: 360,
          reduceMotion: reduceMotion,
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('la scène', () {
    testWidgets("au repos, ne montre que l'objet de l'écran", (tester) async {
      await _pump(tester, offset: 2, page: 2);
      expect(find.byType(ClayIllustration), findsOneWidget);
    });

    testWidgets('pendant le geste, le voisin entre en scène', (tester) async {
      await _pump(tester, offset: 2.4, page: 2);
      expect(find.byType(ClayIllustration), findsNWidgets(2));
    });

    testWidgets("l'objet du milieu est le seul animé", (tester) async {
      await _pump(tester, offset: 2, page: 2);
      final art = tester.widget<ClayIllustration>(find.byType(ClayIllustration));
      expect(art.slide, 3);
      expect(art.animate, isTrue);
    });

    testWidgets('pendant le geste, la boucle se met en pause', (tester) async {
      // Rien ne sert d'animer un objet qui traverse l'écran : la boucle
      // reprend quand la page se pose.
      await _pump(tester, offset: 2.4, page: 2);
      final arts = tester.widgetList<ClayIllustration>(find.byType(ClayIllustration));
      expect(arts.where((a) => a.animate), isEmpty);
    });

    testWidgets('les objets se rangent en quittant la présentation', (tester) async {
      await _pump(tester, offset: 5, page: 4);
      expect(find.byType(ClayIllustration), findsNothing);
      expect(tester.getSize(find.byType(OnboardingStage)).height, 0);
    });

    testWidgets("la scène se referme à mesure qu'on la quitte", (tester) async {
      await _pump(tester, offset: 4.5, page: 4);
      expect(tester.getSize(find.byType(OnboardingStage)).height, closeTo(180, 1));
    });
  });

  group('les éclats', () {
    testWidgets("se posent une fois l'écran arrivé", (tester) async {
      await _pump(tester, offset: 1, page: 1);
      expect(find.text('Arrosage'), findsOneWidget);
      expect(find.text('Photos'), findsOneWidget);
    });

    testWidgets('disparaissent dès que le doigt emporte la page', (tester) async {
      await _pump(tester, offset: 1.4, page: 1);
      expect(find.text('Arrosage'), findsNothing);
    });

    testWidgets("n'apparaissent pas avant la fin de l'entrée", (tester) async {
      await _pump(tester, offset: 1, page: 1, entry: 0.2);
      expect(find.text('Arrosage'), findsNothing);
    });
  });

  group('les animations réduites', () {
    testWidgets('retirent le flou de profondeur', (tester) async {
      await _pump(tester, offset: 2.4, page: 2, reduceMotion: true);
      expect(find.byType(ImageFiltered), findsNothing);
    });

    testWidgets('laissent le flou quand elles sont permises', (tester) async {
      // Les deux objets en mouvement sont adoucis ; celui qui se pose ne
      // l'est plus.
      await _pump(tester, offset: 2.4, page: 2);
      expect(find.byType(ImageFiltered), findsNWidgets(2));
      await _pump(tester, offset: 2, page: 2);
      expect(find.byType(ImageFiltered), findsNothing);
    });
  });

  group('les barres de progression', () {
    testWidgets('annoncent le pas courant à la synthèse vocale', (tester) async {
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
          home: const Scaffold(body: OnboardingProgress(count: 7, index: 2)),
        ),
      );
      await tester.pump();
      expect(find.bySemanticsLabel('Étape 3 sur 7'), findsOneWidget);
    });
  });

  group('le titre qui se lève', () {
    testWidgets('découpe le titre mot à mot', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RisingTitle(text: 'Votre jardin, simplement.', style: TextStyle(fontSize: 30, height: 1.1), t: 1),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Votre'), findsOneWidget);
      expect(find.text('jardin,'), findsOneWidget);
      expect(find.text('simplement.'), findsOneWidget);
      // Découpé pour l'œil, entier pour l'oreille.
      expect(find.bySemanticsLabel('Votre jardin, simplement.'), findsOneWidget);
    });
  });
}
