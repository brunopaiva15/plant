import 'package:flora/app/providers.dart';
import 'package:flora/data/services/preferences_service.dart';
import 'package:flora/design_system/design_system.dart';
import 'package:flora/features/onboarding/presentation/onboarding_screen.dart';
import 'package:flora/l10n/generated/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes/fake_auth_repository.dart';

/// L'étape « compte » de l'onboarding : elle vient après le prénom, seulement
/// là où l'on peut ouvrir un compte — un backend, et Sign in with Apple. Sans
/// backend, ou sur Android, le prénom mène droit au soutien : on ne propose
/// pas une connexion qui n'existe pas.

Future<void> _pump(WidgetTester tester, FakeAuthRepository auth) async {
  SharedPreferences.setMockInitialValues({'locale': 'fr'});
  final prefs = await PreferencesService.load();
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        preferencesServiceProvider.overrideWithValue(prefs),
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
        home: const OnboardingScreen(),
      ),
    ),
  );
  await tester.pump();
}

/// L'onboarding avance par pas de temps : ses animations d'entrée durent
/// plus d'une seconde, et un `pumpAndSettle` les attendrait toutes.
Future<void> _step(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

/// Touche le bouton de la page courante qui porte ce texte. Le carrousel
/// construit aussi les pages voisines, hors champ, qui portent souvent le
/// même « Plus tard » : on garde celui dont l'abscisse tombe dans l'écran.
/// Et avec la police des tests, plus large que la vraie, le bas d'une page
/// passe sous le pli : on l'amène à l'écran avant de toucher.
Future<void> _tap(WidgetTester tester, String text) async {
  final width = tester.view.physicalSize.width / tester.view.devicePixelRatio;
  final onScreen = find.text(text).evaluate().where((e) {
    final box = e.renderObject as RenderBox?;
    if (box == null || !box.hasSize) return false;
    final x = box.localToGlobal(Offset.zero).dx;
    return x >= 0 && x < width;
  }).toList();
  expect(onScreen, hasLength(1), reason: '« $text » attendu une fois sur la page courante');
  final target = find.byElementPredicate((e) => identical(e, onScreen.single));
  await tester.ensureVisible(target);
  await tester.pump();
  await tester.tap(target);
  await _step(tester);
}

/// Jusqu'au prénom, puis « Plus tard ».
Future<void> _pastName(WidgetTester tester) async {
  await _tap(tester, 'Passer');
  expect(find.text('Votre ville'), findsOneWidget);
  await _tap(tester, 'Plus tard');
  expect(find.text('Comment vous appelez-vous\u00a0?'), findsOneWidget);
  await _tap(tester, 'Plus tard');
}

Future<void> _on(TargetPlatform platform, Future<void> Function() body) async {
  debugDefaultTargetPlatformOverride = platform;
  try {
    await body();
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
}

void main() {
  testWidgets("sur iOS avec un backend : le compte vient après le prénom, et Apple mène à la suite", (tester) => _on(TargetPlatform.iOS, () async {
        final auth = FakeAuthRepository(remote: true);
        await _pump(tester, auth);
        await _pastName(tester);
        expect(find.text('Et si vous changez de téléphone\u00a0?'), findsOneWidget);
        expect(find.text('Continuer avec Apple'), findsOneWidget);
        expect(find.text('Auxine est gratuite'), findsNothing, reason: 'le soutien attend derrière le compte');

        await _tap(tester, 'Continuer avec Apple');
        expect(auth.appleSignIns, 1);
        expect(find.text('Auxine est gratuite'), findsOneWidget);
      }));

  testWidgets("« Plus tard » passe outre, sans se connecter", (tester) => _on(TargetPlatform.iOS, () async {
        final auth = FakeAuthRepository(remote: true);
        await _pump(tester, auth);
        await _pastName(tester);
        expect(find.text('Et si vous changez de téléphone\u00a0?'), findsOneWidget);
        await _tap(tester, 'Plus tard');
        expect(auth.appleSignIns, 0);
        expect(find.text('Auxine est gratuite'), findsOneWidget);
      }));

  testWidgets('sans backend : le prénom mène droit au soutien', (tester) => _on(TargetPlatform.iOS, () async {
        await _pump(tester, FakeAuthRepository(remote: false));
        await _pastName(tester);
        expect(find.text('Et si vous changez de téléphone\u00a0?'), findsNothing);
        expect(find.text('Auxine est gratuite'), findsOneWidget);
      }));

  testWidgets('sur Android, même avec un backend : pas de compte à proposer', (tester) => _on(TargetPlatform.android, () async {
        await _pump(tester, FakeAuthRepository(remote: true));
        await _pastName(tester);
        expect(find.text('Et si vous changez de téléphone\u00a0?'), findsNothing);
        expect(find.text('Auxine est gratuite'), findsOneWidget);
      }));
}
