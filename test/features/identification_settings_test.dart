import 'package:flora/app/providers.dart';
import 'package:flora/data/services/preferences_service.dart';
import 'package:flora/design_system/design_system.dart';
import 'package:flora/features/identification/presentation/identification_settings_screen.dart';
import 'package:flora/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Les réglages d'identification, côté envoi des photos identifiées.
///
/// L'envoi demande un compte distant : sans lui, l'enregistreur est muet
/// (`irisFeedbackAvailableProvider`). Un interrupteur qu'on peut allumer sans
/// que rien ne parte est un mensonge — il est donc éteint, et l'écran dit
/// pourquoi.
class _Harness {
  const _Harness(this.prefs, this.l10n);

  final PreferencesService prefs;
  final AppLocalizations l10n;
}

Future<_Harness> _pump(WidgetTester tester, {required bool available, String locale = 'fr', double width = 390}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await PreferencesService.load();
  tester.view.physicalSize = Size(width * 3, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      preferencesServiceProvider.overrideWithValue(prefs),
      irisFeedbackAvailableProvider.overrideWithValue(available),
      // Le modèle embarqué ne se charge pas sous le banc d'essai, et
      // l'interrupteur ne l'attend pas.
      localModelStatusProvider.overrideWith((ref) async => const LocalModelStatus(ready: false, version: null, speciesCount: 0)),
    ],
    child: MaterialApp(
      locale: Locale(locale),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildFloraTheme(Brightness.light),
      home: const IdentificationSettingsScreen(),
    ),
  ));
  await tester.pumpAndSettle();
  return _Harness(prefs, AppLocalizations.of(tester.element(find.byType(IdentificationSettingsScreen))));
}

Finder _feedbackSwitch(AppLocalizations l10n) => find.descendant(
      of: find.ancestor(of: find.text(l10n.irisFeedback), matching: find.byType(FloraListRow)),
      matching: find.byType(AdaptiveSwitch),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('sans compte, l\'interrupteur ne s\'allume pas et l\'écran le dit', (tester) async {
    final h = await _pump(tester, available: false);
    expect(find.text(h.l10n.irisFeedbackNeedsAccount), findsOneWidget);
    expect(tester.widget<AdaptiveSwitch>(_feedbackSwitch(h.l10n)).onChanged, isNull,
        reason: 'allumer n\'enverrait rien : l\'interrupteur ne le promet pas');
  });

  testWidgets('avec un compte, l\'interrupteur se manœuvre', (tester) async {
    final h = await _pump(tester, available: true);
    expect(find.text(h.l10n.irisFeedbackNeedsAccount), findsNothing);
    expect(h.prefs.irisFeedbackEnabled, isFalse, reason: 'rien ne part par défaut');
    final sw = _feedbackSwitch(h.l10n);
    await tester.ensureVisible(sw);
    await tester.tap(sw);
    await tester.pumpAndSettle();
    expect(h.prefs.irisFeedbackEnabled, isTrue);
  });

  testWidgets('la comparaison avec Pl@ntNet-300K est éteinte, et s\'allume', (tester) async {
    final h = await _pump(tester, available: false);
    expect(h.prefs.plantNet300kComparison, isFalse, reason: 'un banc d\'essai ne tourne pas par défaut');
    final sw = find.descendant(
      of: find.ancestor(of: find.text(h.l10n.plantNet300kComparison('Pl@ntNet-300K')), matching: find.byType(FloraListRow)),
      matching: find.byType(AdaptiveSwitch),
    );
    await tester.ensureVisible(sw);
    await tester.tap(sw);
    await tester.pumpAndSettle();
    expect(h.prefs.plantNet300kComparison, isTrue);
  });

  // Le titre est plus long qu'avant, et la ligne le porte avec un
  // interrupteur : sur un iPhone SE, dans les quatre langues, elle ne
  // déborde pas.
  for (final locale in ['fr', 'en', 'de', 'it']) {
    testWidgets('la ligne ne déborde pas sur un écran étroit, en $locale', (tester) async {
      await _pump(tester, available: true, locale: locale, width: 320);
      expect(tester.takeException(), isNull);
    });
  }
}
