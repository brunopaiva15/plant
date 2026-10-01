import 'dart:async';

import 'package:flora/data/services/preferences_service.dart';
import 'package:flora/design_system/design_system.dart';
import 'package:flora/features/whats_new/application/release_notes.dart';
import 'package:flora/app/providers.dart';
import 'package:flora/app/router.dart';
import 'package:flora/features/whats_new/presentation/whats_new_gate.dart';
import 'package:flora/features/whats_new/presentation/whats_new_sheet.dart';
import 'package:flora/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/app_smoke_test.dart' as harness;

/// Les nouveautés : la règle qui décide d'ouvrir la fenêtre, et la fenêtre.
///
/// La règle est la partie qui peut vraiment nuire — une fenêtre qui s'ouvre à
/// chaque lancement, ou qui ne s'ouvre jamais. Elle se teste sans widget.

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

/// L'application d'essai : un téléphone, le français, et pas d'animation —
/// la médaille du héros respire sans fin, rien ne se stabiliserait jamais.
Widget _app(Widget home, {double scale = 1}) => MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildFloraTheme(Brightness.light),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale), disableAnimations: true),
        child: child!,
      ),
      home: home,
    );

Future<void> _pumpWindow(WidgetTester tester, {double scale = 1}) async {
  // Un téléphone, pas le carré de 800 par 600 du banc d'essai : c'est la
  // largeur qui décide du nombre de lignes des boutons du pied.
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app(const Scaffold(key: Key('host'), body: SizedBox.expand()), scale: scale));
  final context = tester.element(find.byKey(const Key('host')));
  final note = releaseNotes(AppLocalizations.of(context)).last;
  unawaited(showWhatsNew(context, note));
  await tester.pumpAndSettle();
}

/// La version que porterait le binaire. Elle n'est plus une constante du
/// code — `AppVersion` la lit sur l'application installée — donc le test
/// donne la sienne.
const _version = '1.0.3';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('la règle', () {
    test("une installation neuve voit la dernière, une fois l'accueil passé", () async {
      final prefs = await _prefs({'onboarding_done': true});
      final whatsNew = WhatsNew(prefs, _version);
      expect((await whatsNew.take(_notes))?.id, 'c');
      expect(prefs.lastRunVersion, _version);
      expect(prefs.seenReleaseNotes, {'a', 'b', 'c'});
      expect(await whatsNew.take(_notes), isNull, reason: 'une fois, pas à chaque lancement');
    });

    test('une mise à jour depuis une version publiée, qui ne notait rien, la voit aussi', () async {
      // Les versions publiées n'écrivent ni version ni nouveauté vue : la
      // règle d'avant la publication aurait tu la mise à jour qui ramène la
      // fenêtre.
      final prefs = await _prefs({'onboarding_done': true, 'plant_sort': 'name'});
      expect((await WhatsNew(prefs, _version).take(_notes))?.id, 'c');
    });

    test("rien non plus tant que l'onboarding n'est pas fait", () async {
      final prefs = await _prefs({});
      expect(await WhatsNew(prefs, _version).take(_notes), isNull);
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
      final whatsNew = WhatsNew(prefs, _version);
      expect((await whatsNew.take(_notes))?.id, 'c');
      // Relancée, l'application se tait : la fenêtre a été consommée.
      expect(await whatsNew.take(_notes), isNull);
    });

    test("la fiche 1.0.3 remplace l'ancienne fiche de nouveautés", () async {
      final prefs = await _prefs({
        'onboarding_done': true,
        'last_run_version': '1.0.2',
        'seen_release_notes': <String>['watering-pot-1'],
      });
      final note = _note(latestReleaseNoteId);
      expect((await WhatsNew(prefs, _version).take([note]))?.id, 'iris-10-1');
      expect(prefs.seenReleaseNotes, {'watering-pot-1', 'iris-10-1'});
    });

    test("deux versions sautées n'empilent pas deux fenêtres", () async {
      final prefs = await _prefs({'onboarding_done': true, 'last_run_version': '0.9.0'});
      // 'b' et 'c' sont tous deux inédits : c'est le plus récent qui s'ouvre.
      expect((await WhatsNew(prefs, _version).take(_notes))?.id, 'c');
      expect(prefs.seenReleaseNotes, {'a', 'b', 'c'});
    });

    test('une nouveauté retirée du catalogue reste vue', () async {
      final prefs = await _prefs({
        'onboarding_done': true,
        'last_run_version': '0.9.0',
        'seen_release_notes': <String>['a', 'b', 'c'],
      });
      await WhatsNew(prefs, _version).take([_note('d')]);
      expect(prefs.seenReleaseNotes, {'a', 'b', 'c', 'd'});
    });

    test('la dernière nouveauté reste ouvrable depuis les réglages', () async {
      final prefs = await _prefs({'onboarding_done': true});
      final whatsNew = WhatsNew(prefs, _version);
      await whatsNew.take(_notes);
      // `take` a tout marqué comme vu ; `latest` ne s'en soucie pas.
      expect(whatsNew.latest(_notes)?.id, 'c');
      expect(whatsNew.latest(const []), isNull);
    });
  });

  group('le catalogue', () {
    testWidgets('les identifiants livrés ne bougent plus', (tester) async {
      // Un identifiant est la mémoire des appareils : le renommer rouvre la
      // fenêtre chez qui l'avait fermée, le réemployer avale en silence celle
      // qui devait s'ouvrir. Cette liste ne s'édite donc que par la fin.
      await tester.pumpWidget(_app(const Scaffold(key: Key('host'), body: SizedBox.expand())));
      final l10n = AppLocalizations.of(tester.element(find.byKey(const Key('host'))));
      final ids = [for (final note in releaseNotes(l10n)) note.id];
      expect(ids.first, 'iris-10-1');
      expect(ids.last, latestReleaseNoteId);
      expect(ids.toSet(), hasLength(ids.length));
      // Dépensés avant la publication, sur les appareils de la bêta.
      expect(ids, isNot(contains(anyOf('iris-8', 'beta-feedback-1', 'beta-rooms-1'))));
    });
  });

  group('la fenêtre', () {
    testWidgets('montre Iris 10 et les trois points forts de la 1.0.3', (tester) async {
      await _pumpWindow(tester);
      expect(find.text('AUXINE'), findsOneWidget);
      expect(find.text('Iris 10'), findsOneWidget);
      expect(find.text("L'arrosage selon le pot"), findsOneWidget);
      expect(find.text('Photos plus fluides'), findsOneWidget);
      expect(find.text('Interface et stabilité'), findsOneWidget);
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

    testWidgets('la page emprunte le contrôleur que la sheet lui prête', (tester) async {
      // Sans lui, la sheet d'iOS arme son propre reconnaisseur de glissement
      // par-dessus le contenu, remporte chaque geste vertical, et la page reste
      // figée pendant que la sheet descend — c'est ce qu'on a vu sur l'appareil.
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_app(WhatsNewView(note: _note('x'), controller: controller)));
      await tester.pump();
      expect(tester.widget<SingleChildScrollView>(find.byType(SingleChildScrollView)).controller, same(controller));
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

  group('à l\'ouverture', () {
    testWidgets("elle s'ouvre après l'animation d'ouverture, et n'est plus proposée ensuite", (tester) async {
      final container = await harness.boot(tester, whatsNewSeen: false);
      await harness.pumpApp(tester, container, settleAfter: false);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(WhatsNewView), findsNothing, reason: "pas pendant l'ouverture");

      await tester.pump(WhatsNewGate.delay);
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(WhatsNewView), findsOneWidget);
      expect(container.read(preferencesServiceProvider).seenReleaseNotes, contains(latestReleaseNoteId));
      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets('une nouveauté déjà vue ne se rouvre pas', (tester) async {
      final container = await harness.boot(tester);
      await harness.pumpApp(tester, container);
      await tester.pump(WhatsNewGate.delay * 2);
      expect(find.byType(WhatsNewView), findsNothing);
      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets("une page déjà ouverte par-dessus : elle attend la prochaine ouverture", (tester) async {
      final container = await harness.boot(tester, whatsNewSeen: false);
      await harness.pumpApp(tester, container, settleAfter: false);
      container.read(routerProvider).push(Routes.finder);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(WhatsNewGate.delay);
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(WhatsNewView), findsNothing);
      expect(container.read(preferencesServiceProvider).seenReleaseNotes, isEmpty, reason: 'pas vue, donc pas consommée');
      await tester.pump(const Duration(seconds: 6));
    });
  });
}
