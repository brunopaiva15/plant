import 'dart:math' as math;

import 'package:flora/design_system/design_system.dart';
import 'package:flora/features/onboarding/presentation/clay_illustration.dart';
import 'package:flora/features/onboarding/presentation/growing_plant.dart';
import 'package:flora/features/onboarding/presentation/plant_cluster.dart';
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

/// Pose [child] seul à l'écran et rend la place de sa première image.
Future<Offset> _place(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: Center(child: child))));
  await tester.pump();
  return tester.getTopLeft(find.byType(Image).first);
}

void main() {
  group('la scène', () {
    testWidgets("au repos, ne montre que l'objet de l'écran", (tester) async {
      await _pump(tester, offset: 2, page: 2);
      expect(find.byType(ClayIllustration), findsOneWidget);
    });

    testWidgets("le premier objet est la plante qui pousse, pas une image posée", (tester) async {
      await _pump(tester, offset: 0, page: 0);
      expect(find.byType(GrowingPlant), findsOneWidget);
      expect(find.byType(ClayIllustration), findsNothing);
    });

    testWidgets("le deuxième écran montre la collection, pas une image posée", (tester) async {
      await _pump(tester, offset: 1, page: 1);
      expect(find.byType(PlantCluster), findsOneWidget);
      expect(find.byType(ClayIllustration), findsNothing);
    });

    testWidgets('pendant le geste, le voisin entre en scène', (tester) async {
      await _pump(tester, offset: 2.4, page: 2);
      expect(find.byType(ClayIllustration), findsNWidgets(2));
    });

    testWidgets("l'objet du milieu est le seul animé", (tester) async {
      await _pump(tester, offset: 2, page: 2);
      final art = tester.widget<ClayIllustration>(find.byType(ClayIllustration));
      expect(art.slide, 2);
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

  group('le flou de profondeur', () {
    /// Nombre d'objets réellement adoucis. Le filtre est toujours dans
    /// l'arbre — le poser et l'ôter déferait l'objet en dessous — mais il
    /// s'éteint dès qu'il ne sert plus, et éteint il ne coûte rien.
    int softened(WidgetTester tester) => tester.widgetList<ImageFiltered>(find.byType(ImageFiltered)).where((f) => f.enabled).length;

    testWidgets('adoucit les objets qui traversent, pas celui qui se pose', (tester) async {
      await _pump(tester, offset: 2.4, page: 2);
      expect(softened(tester), 2);
      await _pump(tester, offset: 2, page: 2);
      expect(softened(tester), 0);
    });

    testWidgets("ne défait pas l'objet en s'allumant", (tester) async {
      // Le filtre s'allume à un dixième d'écran du centre, quand l'objet est
      // encore en pleine vue. S'il changeait la forme de l'arbre, l'objet
      // serait défait puis refait à cet instant : la plante de l'accueil,
      // dont la séquence se décode, disparaissait au lieu de sortir.
      await _pump(tester, offset: 0, page: 0);
      final posed = tester.element(find.byType(GrowingPlant));
      await _pump(tester, offset: 0.2, page: 0);
      expect(softened(tester), greaterThan(0));
      expect(tester.element(find.byType(GrowingPlant)), same(posed));
    });

    testWidgets('les animations réduites le laissent éteint', (tester) async {
      await _pump(tester, offset: 2.4, page: 2, reduceMotion: true);
      expect(softened(tester), 0);
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

    test('la pose de repos ne penche pas, et son ombre est entière', () {
      // Aucune phase ne la donne : à la phase zéro la hauteur est nulle mais
      // l'inclinaison est à son extrême, ce qui laissait l'objet penché d'un
      // degré quand « réduire les animations » était actif.
      expect(const BreathPose(0).tilt, closeTo(-1, 1e-9));
      const repos = BreathPose.rest();
      expect(repos.lift, 0);
      expect(repos.tilt, 0);
      expect(repos.shadowScale, 1);
      expect(repos.shadowOpacity, 1);
    });

    test("l'ombre se resserre et pâlit quand l'objet monte", () {
      final low = const BreathPose(0.75), high = const BreathPose(0.25);
      expect(high.shadowScale, lessThan(low.shadowScale));
      expect(high.shadowOpacity, lessThan(low.shadowOpacity));
      expect(low.shadowScale, closeTo(1, 1e-9));
      expect(low.shadowOpacity, closeTo(1, 1e-9));
    });

    test("l'amplitude mène du repos à la pleine respiration", () {
      // Le repos est une amplitude nulle, à n'importe quelle phase : c'est ce
      // qui permet d'y aller et d'en revenir sans saut.
      for (final phase in [0.0, 0.25, 0.5, 0.75]) {
        final posed = BreathPose(phase, amplitude: 0);
        expect(posed.lift, closeTo(0, 1e-9));
        expect(posed.tilt, closeTo(0, 1e-9));
        expect(posed.shadowScale, closeTo(1, 1e-9));
        expect(posed.shadowOpacity, closeTo(1, 1e-9));
      }
      // À mi-amplitude, l'objet est à mi-chemin du posé et du respiré.
      const full = BreathPose(0.25);
      const half = BreathPose(0.25, amplitude: 0.5);
      expect(half.lift, closeTo(full.lift / 2, 1e-9));
      expect(half.tilt, closeTo(full.tilt / 2, 1e-9));
      expect(1 - half.shadowScale, closeTo((1 - full.shadowScale) / 2, 1e-9));
      expect(1 - half.shadowOpacity, closeTo((1 - full.shadowOpacity) / 2, 1e-9));
    });
  });

  group("les objets qui s'animent", () {
    testWidgets("la collection s'écarte de sa place, elle n'y saute pas", (tester) async {
      // Posée, la composition est exactement celle qui a été choisie.
      final anchor = await _place(tester, const PlantCluster(side: 320, animate: false));
      // Elle arrive au centre : la dérive s'ouvre depuis cette place. Elle
      // partait d'un coup à sa phase — les cinq plantes sautaient ensemble.
      var previous = await _place(tester, const PlantCluster(side: 320));
      expect((previous - anchor).distance, lessThan(1));
      var drift = 0.0;
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        final now = tester.getTopLeft(find.byType(Image).first);
        expect((now - previous).distance, lessThan(1), reason: 'la dérive a sauté de $previous à $now');
        drift = math.max(drift, (now - anchor).distance);
        previous = now;
      }
      expect(drift, greaterThan(1), reason: "la dérive ne s'est jamais ouverte");

      // Et elle s'en va : la composition revient à sa place sans saut.
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Center(child: PlantCluster(side: 320, animate: false)))));
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        final now = tester.getTopLeft(find.byType(Image).first);
        expect((now - previous).distance, lessThan(1), reason: 'le retour à la place a sauté de $previous à $now');
        previous = now;
      }
      expect((previous - anchor).distance, lessThan(0.5));
    });

    testWidgets("l'objet d'argile prend et rend son souffle sans saut", (tester) async {
      // Posé, l'objet est droit ; la respiration commence à l'inclinaison
      // extrême, et sans l'amplitude il penchait d'un degré d'un coup.
      final posed = await _place(tester, const ClayIllustration(slide: 2, side: 320, animate: false));
      var previous = await _place(tester, const ClayIllustration(slide: 2, side: 320));
      expect((previous - posed).distance, lessThan(1));
      var breathed = 0.0;
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        final now = tester.getTopLeft(find.byType(Image).first);
        expect((now - previous).distance, lessThan(1), reason: 'la respiration a sauté de $previous à $now');
        breathed = math.max(breathed, (now - posed).distance);
        previous = now;
      }
      expect(breathed, greaterThan(1), reason: "l'objet n'a jamais respiré");
    });
  });

  group("l'horloge de la respiration", () {
    /// Fait tourner l'horloge à soixante images par seconde et rend, image par
    /// image, de combien la pose a bougé.
    List<double> jumps(Breath breath, {required bool breathing, required int frames, Duration from = Duration.zero}) {
      var previous = breath.pose;
      final steps = <double>[];
      for (var i = 1; i <= frames; i++) {
        breath.advance(from + Duration(microseconds: i * 1000000 ~/ 60), breathing: breathing);
        final pose = breath.pose;
        steps.add(math.max((pose.tilt - previous.tilt).abs(), (pose.shadowOpacity - previous.shadowOpacity).abs()));
        previous = pose;
      }
      return steps;
    }

    test("s'installe et se retire sans saut", () {
      final breath = Breath();
      expect(breath.resting, isTrue);
      expect(breath.level, 0);
      // C'est tout l'objet de l'amplitude : l'inclinaison est à son extrême à
      // la phase zéro, et sans elle le premier tick faisait pencher l'objet
      // d'un degré d'un coup.
      final arrivee = jumps(breath, breathing: true, frames: 60);
      expect(arrivee.every((step) => step < 0.1), isTrue, reason: "la respiration s'installe par pas : $arrivee");
      expect(breath.level, 1);

      final depart = jumps(breath, breathing: false, frames: 60, from: const Duration(seconds: 1));
      expect(depart.every((step) => step < 0.1), isTrue, reason: 'et se retire de même : $depart');
      expect(breath.resting, isTrue);
      expect(breath.pose.tilt, 0);
      expect(breath.pose.shadowOpacity, 1);
    });

    test("reprise après une pause : elle ne rattrape pas le temps passé ailleurs", () {
      final breath = Breath();
      jumps(breath, breathing: true, frames: 60);
      final quitte = breath.seconds;
      // L'horloge de l'écran recompte depuis zéro à chaque reprise : sans
      // plafond, le premier tick d'après ferait tourner l'objet d'un bloc.
      breath.advance(Duration.zero, breathing: true);
      expect(breath.seconds, closeTo(quitte, 1e-9));
      breath.advance(const Duration(seconds: 30), breathing: true);
      expect(breath.seconds - quitte, lessThan(0.1));
    });

    test("sans animations, elle pose l'objet sur-le-champ", () {
      final breath = Breath();
      jumps(breath, breathing: true, frames: 60);
      breath.rest();
      expect(breath.resting, isTrue);
      expect(breath.pose.lift, 0);
      expect(breath.pose.tilt, 0);
    });
  });
}
