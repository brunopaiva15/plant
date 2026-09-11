import 'dart:async';

import 'package:flora/core/config/app_config.dart';
import 'package:flora/data/services/preferences_service.dart';
import 'package:flora/design_system/design_system.dart';
import 'package:flora/features/whats_new/application/release_notes.dart';
import 'package:flora/features/whats_new/presentation/whats_new_sheet.dart';
import 'package:flora/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Les nouveautés : la règle qui décide d'ouvrir la fenêtre, et la fenêtre.
///
/// La règle est la partie qui peut vraiment nuire — une fenêtre qui s'ouvre à
/// chaque lancement, ou qui accueille quelqu'un qui vient d'installer l'app
/// en lui racontant ce qu'il n'a jamais connu. Elle se teste sans widget.

Future<PreferencesService> _prefs(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  return PreferencesService.load();
}

/// Trois nouveautés de laboratoire : la règle ne lit que leurs identifiants.
ReleaseNote _note(String id) => ReleaseNote(
      id: id,
      eyebrow: 'Nouveauté',
      title: id,
      body: 'Corps',
      highlights: const [],
    );

final _notes = [_note('a'), _note('b'), _note('c')];

Future<void> _pumpWindow(WidgetTester tester, {double scale = 1}) async {
  // Un téléphone, pas le carré de 800 par 600 du banc d'essai : c'est la
  // largeur qui décide du nombre de lignes des boutons du pied.
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
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
      // La médaille respire sans fin : sans « réduire les animations », rien
      // ne se stabiliserait jamais et `pumpAndSettle` tournerait en rond.
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale), disableAnimations: true),
        child: child!,
      ),
      home: const Scaffold(key: Key('host'), body: SizedBox.expand()),
    ),
  );
  final context = tester.element(find.byKey(const Key('host')));
  final note = releaseNotes(AppLocalizations.of(context)).last;
  unawaited(showWhatsNew(context, note));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('la règle', () {
    test('une installation neuve ne raconte rien, et note son point de départ', () async {
      final prefs = await _prefs({'onboarding_done': true});
      expect(await WhatsNew(prefs).take(_notes), isNull);
      // Le point de départ est posé : c'est la mise à jour suivante qui parlera.
      expect(prefs.lastRunVersion, AppConfig.version);
      expect(prefs.seenReleaseNotes, {'a', 'b', 'c'});
    });

    test("rien non plus tant que l'onboarding n'est pas fait", () async {
      final prefs = await _prefs({});
      expect(await WhatsNew(prefs).take(_notes), isNull);
      // Et surtout : rien d'écrit. Le premier vrai lancement fera le point.
      expect(prefs.lastRunVersion, isNull);
      expect(prefs.seenReleaseNotes, isEmpty);
    });

    test('une mise à jour annonce la nouveauté, une seule fois', () async {
      final prefs = await _prefs({
        'onboarding_done': true,
        'last_run_version': '0.9.0',
        'seen_release_notes': <String>['a'],
      });
      final whatsNew = WhatsNew(prefs);
      expect((await whatsNew.take(_notes))?.id, 'c');
      // Relancée, l'application se tait : la fenêtre a été consommée.
      expect(await whatsNew.take(_notes), isNull);
    });

    test("deux versions sautées n'empilent pas deux fenêtres", () async {
      final prefs = await _prefs({'onboarding_done': true, 'last_run_version': '0.9.0'});
      // 'b' et 'c' sont tous deux inédits : c'est le plus récent qui s'ouvre.
      expect((await WhatsNew(prefs).take(_notes))?.id, 'c');
      expect(prefs.seenReleaseNotes, {'a', 'b', 'c'});
    });

    test('une nouveauté retirée du catalogue reste vue', () async {
      final prefs = await _prefs({
        'onboarding_done': true,
        'last_run_version': '0.9.0',
        'seen_release_notes': <String>['a', 'b', 'c'],
      });
      await WhatsNew(prefs).take([_note('d')]);
      expect(prefs.seenReleaseNotes, {'a', 'b', 'c', 'd'});
    });

    test('la dernière nouveauté reste ouvrable depuis les réglages', () async {
      final prefs = await _prefs({'onboarding_done': true});
      final whatsNew = WhatsNew(prefs);
      await whatsNew.take(_notes);
      // `take` a tout marqué comme vu ; `latest` ne s'en soucie pas.
      expect(whatsNew.latest(_notes)?.id, 'c');
      expect(whatsNew.latest(const []), isNull);
    });
  });

  group('la fenêtre', () {
    testWidgets('montre le titre, son accroche et ses points forts', (tester) async {
      await _pumpWindow(tester);
      expect(find.text(AppConfig.modelDisplayName('8')), findsOneWidget);
      expect(find.text('MISE À JOUR DU MODÈLE'), findsOneWidget);
      expect(find.text('5000 espèces reconnues'), findsOneWidget);
      expect(find.text("Toujours sur l'appareil"), findsOneWidget);
      expect(find.byType(IrisMark), findsOneWidget);
    });

    testWidgets('le bouton la referme', (tester) async {
      await _pumpWindow(tester);
      expect(find.byType(WhatsNewView), findsOneWidget);
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();
      expect(find.byType(WhatsNewView), findsNothing);
    });

    testWidgets('la croix aussi', (tester) async {
      await _pumpWindow(tester);
      await tester.tap(find.bySemanticsLabel('Fermer'));
      await tester.pumpAndSettle();
      expect(find.byType(WhatsNewView), findsNothing);
    });

    for (final scale in [0.82, 1.0, 2.0, 3.5]) {
      testWidgets('ne déborde pas à ${(scale * 100).round()} %', (tester) async {
        await _pumpWindow(tester, scale: scale);
        expect(tester.takeException(), isNull);
        // Le bouton principal reste sous les yeux : c'est la page qui défile,
        // pas le pied.
        expect(find.text('Continuer'), findsOneWidget);
      });
    }
  });
}
