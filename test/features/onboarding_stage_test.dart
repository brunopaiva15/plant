import 'package:flora/design_system/design_system.dart';
import 'package:flora/features/onboarding/presentation/clay_illustration.dart';
import 'package:flora/features/onboarding/presentation/onboarding_stage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flora/l10n/generated/app_localizations.dart';

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

    testWidgets("la scène rapetisse à l'approche du dernier écran, qui a ses boutons", (tester) async {
      await _pump(tester, offset: 3, page: 3);
      expect(tester.getSize(find.byType(OnboardingStage)).height, closeTo(360, 1));
      await _pump(tester, offset: 3.5, page: 3);
      expect(tester.getSize(find.byType(OnboardingStage)).height, closeTo(360 * (1 - 0.19), 1));
      await _pump(tester, offset: 4, page: 4);
      expect(tester.getSize(find.byType(OnboardingStage)).height, closeTo(360 * OnboardingStage.compact, 1));
    });

    testWidgets("la scène se referme à mesure qu'on la quitte", (tester) async {
      await _pump(tester, offset: 4.5, page: 4);
      expect(tester.getSize(find.byType(OnboardingStage)).height, closeTo(360 * OnboardingStage.compact * 0.5, 1));
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
    Widget title(double width) => MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            child: const RisingTitle(text: 'Votre jardin, simplement.', style: TextStyle(fontSize: 30, height: 1.1), t: 1),
          ),
        ),
      ),
    );

    testWidgets("tient sur une ligne quand il y a la place", (tester) async {
      await tester.pumpWidget(title(800));
      await tester.pump();
      expect(find.text('Votre jardin, simplement.'), findsOneWidget);
      expect(find.bySemanticsLabel('Votre jardin, simplement.'), findsOneWidget);
    });

    testWidgets('se découpe aux mêmes lignes que le texte posé', (tester) async {
      await tester.pumpWidget(title(360));
      await tester.pump();
      // Découpé pour l'œil, entier pour l'oreille.
      expect(find.bySemanticsLabel('Votre jardin, simplement.'), findsOneWidget);
      expect(find.text('Votre jardin, simplement.'), findsNothing);
      final lines = RisingTitle.layoutLines('Votre jardin, simplement.', const TextStyle(fontSize: 30, height: 1.1), 360, TextScaler.noScaling, TextDirection.ltr);
      expect(lines.length, greaterThan(1));
      expect(lines.map((l) => l.text).join(' '), 'Votre jardin, simplement.');
      for (final line in lines) {
        expect(find.text(line.text), findsOneWidget);
      }
      // La hauteur du titre levé est celle du titre posé : rien ne se coupe.
      final painter = TextPainter(
        text: const TextSpan(text: 'Votre jardin, simplement.', style: TextStyle(fontSize: 30, height: 1.1)),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 360);
      expect(tester.getSize(find.byType(RisingTitle)).height, closeTo(painter.height, 0.5));
      painter.dispose();
    });
  });

  group('la respiration', () {
    test('part du repos et y revient à chaque tour', () {
      expect(const BreathPose(0).lift, closeTo(0, 1e-9));
      expect(const BreathPose(1).lift, closeTo(0, 1e-9));
      expect(const BreathPose(0.25).lift, closeTo(1, 1e-9));
      expect(const BreathPose(0.75).lift, closeTo(-1, 1e-9));
    });

    test("l'inclinaison est en retard d'un quart de tour sur la hauteur", () {
      expect(const BreathPose(0.25).tilt, closeTo(0, 1e-9));
      expect(const BreathPose(0.5).tilt, closeTo(1, 1e-9));
    });

    test("l'ombre se resserre et pâlit quand l'objet monte", () {
      final low = const BreathPose(0.75), high = const BreathPose(0.25);
      expect(high.shadowScale, lessThan(low.shadowScale));
      expect(high.shadowOpacity, lessThan(low.shadowOpacity));
      expect(low.shadowScale, closeTo(1, 1e-9));
      expect(low.shadowOpacity, closeTo(1, 1e-9));
    });
  });
}
