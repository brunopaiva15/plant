import 'package:flora/design_system/design_system.dart';
import 'package:flora/features/onboarding/presentation/onboarding_screen.dart';
import 'package:flora/features/onboarding/presentation/onboarding_stage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flora/l10n/generated/app_localizations.dart';

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
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
        home: const OnboardingScreen(),
      ),
    ),
  );
  await tester.pump();
}

double _entry(WidgetTester tester) => tester.widget<OnboardingStage>(find.byType(OnboardingStage)).entry;

double _offset(WidgetTester tester) => tester.widget<OnboardingStage>(find.byType(OnboardingStage)).offset;

void main() {
  group("l'onboarding", () {
    testWidgets("l'entrée de la scène se joue à l'ouverture", (tester) async {
      await _pump(tester);
      expect(_entry(tester), lessThan(1));
      await tester.pump(const Duration(milliseconds: 1200));
      expect(_entry(tester), 1);
    });

    testWidgets("l'entrée ne se rejoue pas en cours de geste", (tester) async {
      // C'est le sursaut qu'on voyait à chaque écran : l'entrée était remise
      // à zéro à mi-parcours, et le halo comme l'objet du milieu — déjà en
      // place — repartaient d'un cran en arrière. Le passage d'un écran au
      // suivant n'appartient qu'au carrousel, qui avance sans saut.
      await _pump(tester);
      await tester.pump(const Duration(milliseconds: 1200));
      expect(_entry(tester), 1);

      await tester.tap(find.text('Continuer'));
      var switched = false;
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(_entry(tester), 1, reason: "l'entrée est repartie de zéro en plein geste");
        final stage = tester.widget<OnboardingStage>(find.byType(OnboardingStage));
        expect(stage.offset, inInclusiveRange(0, 1));
        // L'écran courant change à mi-parcours, bien avant que le carrousel
        // se pose : c'est là que tout sautait.
        if (stage.page == 1 && stage.offset < 1) switched = true;
      }
      expect(switched, isTrue, reason: "le changement d'écran n'a pas été observé en plein geste");
      expect(_offset(tester), 1);
    });
  });
}
