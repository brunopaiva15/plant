import 'package:flora/app/providers.dart';
import 'package:flora/core/config/app_config.dart';
import 'package:flora/design_system/design_system.dart';
import 'package:flora/features/account/application/sign_in_availability.dart';
import 'package:flora/features/account/presentation/account_screen.dart';
import 'package:flora/l10n/generated/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_auth_repository.dart';

/// L'écran Compte, avant connexion, avec un backend configuré : quels boutons
/// sont dessinés. Chaque appareil a sa porte, et une seule : Apple sur iPhone
/// et iPad, Google sur Android. Pas de connexion par e-mail sur Auxine, et
/// Google par le navigateur sur iPhone attend `AppConfig.googleSignInEnabled`
/// — un bouton qui réapparaîtrait par mégarde remettrait la règle 4.8 de
/// l'App Store dans la balance. Sur Android sans client OAuth, le compte
/// reste local, comme sans backend.
/// Dessine l'écran sur [platform], puis rend la plateforme au banc d'essai
/// avant la fin du test : il vérifie lui-même que rien n'a été laissé changé.
Future<void> _on(
  TargetPlatform platform,
  WidgetTester tester,
  Future<void> Function(AppLocalizations l10n) body, {
  FakeAuthRepository? auth,
  String googleClientId = '',
}) async {
  debugDefaultTargetPlatformOverride = platform;
  try {
    await body(await _pump(tester, auth ?? FakeAuthRepository(remote: true), googleClientId));
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
}

Future<AppLocalizations> _pump(WidgetTester tester, FakeAuthRepository auth, String googleClientId) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        googleWebClientIdProvider.overrideWithValue(googleClientId),
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
        home: const AccountScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return AppLocalizations.of(tester.element(find.byType(AccountScreen)));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('sur iOS : Apple, et rien d\'autre', (tester) => _on(TargetPlatform.iOS, tester, (l10n) async {
        expect(find.text(l10n.continueWithApple), findsOneWidget);
        expect(find.text(l10n.continueWithGoogle), findsNothing);
        expect(find.byType(FloraButton), findsOneWidget, reason: 'aucune autre porte : pas d\'e-mail');
        expect(find.text(l10n.localAccount), findsNothing);
        expect(AppConfig.googleSignInEnabled, isFalse, reason: 'sur iPhone, Apple seul : Google y passerait par le navigateur');
      }));

  testWidgets('sur Android sans client OAuth : le compte reste local, aucun bouton', (tester) => _on(TargetPlatform.android, tester, (l10n) async {
        expect(find.byType(FloraButton), findsNothing);
        expect(find.text(l10n.localAccount), findsOneWidget);
        expect(find.text(l10n.localAccountHint), findsOneWidget);
      }));

  testWidgets('sur Android : Google, et rien d\'autre', (tester) {
    final auth = FakeAuthRepository(remote: true);
    return _on(TargetPlatform.android, tester, auth: auth, googleClientId: 'client.apps.googleusercontent.com', (l10n) async {
      expect(find.text(l10n.continueWithGoogle), findsOneWidget);
      expect(find.text(l10n.continueWithApple), findsNothing);
      expect(find.byType(FloraButton), findsOneWidget, reason: 'aucune autre porte : pas d\'e-mail');

      await tester.tap(find.text(l10n.continueWithGoogle));
      await tester.pumpAndSettle();
      expect(auth.googleSignIns, 1);
      expect(auth.appleSignIns, 0);
    });
  });
}
