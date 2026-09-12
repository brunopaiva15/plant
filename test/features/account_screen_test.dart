import 'dart:async';

import 'package:flora/app/providers.dart';
import 'package:flora/core/config/app_config.dart';
import 'package:flora/design_system/design_system.dart';
import 'package:flora/domain/auth/auth_repository.dart';
import 'package:flora/features/account/presentation/account_screen.dart';
import 'package:flora/l10n/generated/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// L'écran Compte, avant connexion, avec un backend configuré : quels boutons
/// sont dessinés. Apple est livré sur iPhone et iPad ; Google est codé mais
/// attend `AppConfig.googleSignInEnabled` — un bouton Google qui réapparaîtrait
/// par mégarde remettrait la règle 4.8 de l'App Store dans la balance.
class _RemoteAuth implements AuthRepository {
  final _user = const AppUser(id: 'u', displayName: '');

  @override
  bool get supportsRemote => true;

  @override
  AppUser? get currentUser => _user;

  @override
  Stream<AppUser?> watchUser() => Stream.value(_user);

  @override
  Future<AppUser> ensureLocalUser() async => _user;

  @override
  Future<void> updateDisplayName(String name) async {}

  @override
  Future<void> requestEmailCode(String email) async {}

  @override
  Future<void> verifyEmailCode({required String email, required String code}) async {}

  @override
  Future<void> signInWithApple() async {}

  @override
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> signOut() async {}
}

/// Dessine l'écran sur [platform], puis rend la plateforme au banc d'essai
/// avant la fin du test : il vérifie lui-même que rien n'a été laissé changé.
Future<void> _on(TargetPlatform platform, WidgetTester tester, Future<void> Function(AppLocalizations l10n) body) async {
  debugDefaultTargetPlatformOverride = platform;
  try {
    await body(await _pump(tester));
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
}

Future<AppLocalizations> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(_RemoteAuth())],
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

  testWidgets('sur iOS : Apple et l\'e-mail, pas Google', (tester) => _on(TargetPlatform.iOS, tester, (l10n) async {
        expect(find.text(l10n.continueWithApple), findsOneWidget);
        expect(find.text(l10n.continueWithEmail), findsOneWidget);
        expect(find.text(l10n.continueWithGoogle), findsNothing);
        expect(AppConfig.googleSignInEnabled, isFalse, reason: 'Google n\'est pas livré : Android n\'est pas la priorité');
      }));

  testWidgets('sur Android : l\'e-mail seulement', (tester) => _on(TargetPlatform.android, tester, (l10n) async {
        expect(find.text(l10n.continueWithApple), findsNothing);
        expect(find.text(l10n.continueWithGoogle), findsNothing);
        expect(find.text(l10n.continueWithEmail), findsOneWidget);
      }));
}
