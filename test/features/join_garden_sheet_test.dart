import 'package:flora/app/providers.dart';
import 'package:flora/data/services/preferences_service.dart';
import 'package:flora/design_system/design_system.dart';
import 'package:flora/domain/sharing/garden_collaboration.dart';
import 'package:flora/features/account/presentation/join_garden_sheet.dart';
import 'package:flora/l10n/generated/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes/fake_auth_repository.dart';

/// La feuille « Rejoindre un jardin » quand on n'a pas de compte — le cas de
/// presque tous ceux qui ouvrent un lien d'invitation. Là où la connexion
/// existe, le bouton devient « Continuer avec Apple » et l'invitation est
/// acceptée dans la foulée ; là où elle n'existe pas, la feuille le dit
/// d'emblée.

class _FakeCollaboration extends UnavailableCollaborationService {
  final accepted = <String>[];

  @override
  bool get isAvailable => true;

  @override
  Future<InvitePreview?> previewInvite(String code) async =>
      InvitePreview(gardenId: 'g2', gardenName: 'Balcon', role: GardenRole.member, ownerName: 'Laura', alreadyMember: false);

  @override
  Future<String> acceptInvite(String code) async {
    accepted.add(code);
    return 'g2';
  }
}

Future<bool?> _open(WidgetTester tester, {required FakeAuthRepository auth, required _FakeCollaboration collab}) async {
  SharedPreferences.setMockInitialValues({'locale': 'fr', 'user_id': 'u', 'garden_id': 'g1'});
  final prefs = await PreferencesService.load();
  bool? result;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        preferencesServiceProvider.overrideWithValue(prefs),
        collaborationServiceProvider.overrideWithValue(collab),
        gardenIdProvider.overrideWithValue('g1'),
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
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () async => result = await showJoinGardenSheet(context, code: 'ABCDEFGH'),
                child: const Text('ouvrir'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('ouvrir'));
  await tester.pumpAndSettle();
  return result;
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
  testWidgets('sans compte, sur iOS : Apple, puis le jardin est rejoint dans la foulée', (tester) => _on(TargetPlatform.iOS, () async {
        final auth = FakeAuthRepository(remote: true);
        final collab = _FakeCollaboration();
        await _open(tester, auth: auth, collab: collab);
        // L'invitation est déjà lue : on sait qui invite, et dans quel jardin.
        expect(find.textContaining('Laura'), findsOneWidget);
        expect(find.text('Continuer avec Apple'), findsOneWidget);
        expect(find.text('Rejoindre'), findsNothing);

        await tester.tap(find.text('Continuer avec Apple'));
        await tester.pumpAndSettle();
        expect(auth.appleSignIns, 1);
        expect(collab.accepted, ['ABCDEFGH']);
        expect(find.text('Continuer avec Apple'), findsNothing, reason: 'la feuille se referme une fois le jardin rejoint');
      }));

  testWidgets('sans compte, sur Android : la feuille le dit, sans promettre une connexion', (tester) => _on(TargetPlatform.android, () async {
        final auth = FakeAuthRepository(remote: true);
        await _open(tester, auth: auth, collab: _FakeCollaboration());
        expect(find.text('Continuer avec Apple'), findsNothing);
        expect(find.text('Il faut un compte pour rejoindre un jardin.'), findsOneWidget);
      }));
}
