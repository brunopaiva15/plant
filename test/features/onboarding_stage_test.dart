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

    testWidgets("la scène se referme à mesure qu'on la quitte", (tester) async {
      await _pump(tester, offset: 4.5, page: 4);
      expect(tester.getSize(find.byType(OnboardingStage)).height, closeTo(180, 1));
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

  group("l'horloge de la boucle", () {
    const clock = LoopClock(playFor: Duration(seconds: 1));

    test('joue à pleine vitesse le temps demandé', () {
      expect(clock.phase(Duration.zero), 0);
      expect(clock.phase(const Duration(milliseconds: 500)), 0.5);
      expect(clock.phase(const Duration(seconds: 1)), 1);
    });

    test('freine ensuite sans à-coup, deux fois plus longtemps que la distance restante', () {
      // Un tour à parcourir, deux secondes pour le faire.
      expect(clock.brakingDuration, const Duration(seconds: 2));
      expect(clock.total, const Duration(seconds: 3));
      // Juste après le début du freinage, la vitesse est encore celle de la
      // pleine vitesse : un tour par seconde.
      final before = clock.phase(const Duration(milliseconds: 1000));
      final after = clock.phase(const Duration(milliseconds: 1010));
      expect((after - before) / 0.010, closeTo(1, 0.02));
      // Juste avant la fin, l'objet ne bouge presque plus.
      final near = clock.phase(const Duration(milliseconds: 2990));
      final end = clock.phase(const Duration(milliseconds: 3000));
      expect((end - near) / 0.010, lessThan(0.02));
    });

    test('se pose sur un tour entier, la pose de repos', () {
      expect(clock.phase(clock.total), 2);
      expect(clock.frame(clock.total), 0);
      expect(clock.done(clock.total), isTrue);
      expect(clock.done(clock.total - const Duration(milliseconds: 1)), isFalse);
    });

    test("ne recule jamais", () {
      var last = -1.0;
      for (var ms = 0; ms <= 3000; ms += 10) {
        final p = clock.phase(Duration(milliseconds: ms));
        expect(p, greaterThanOrEqualTo(last));
        last = p;
      }
    });

    test("montre l'image fixe au départ, la cache au milieu, la ramène à la fin", () {
      expect(clock.still(Duration.zero), 1);
      expect(clock.still(const Duration(milliseconds: 500)), 0);
      expect(clock.still(const Duration(milliseconds: 2000)), 0);
      expect(clock.still(const Duration(milliseconds: 2700)), greaterThan(0));
      expect(clock.still(const Duration(milliseconds: 2700)), lessThan(1));
      expect(clock.still(clock.total), 1);
    });
  });
}
