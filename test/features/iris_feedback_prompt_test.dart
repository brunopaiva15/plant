import 'package:flora/app/providers.dart';
import 'package:flora/data/services/preferences_service.dart';
import 'package:flora/design_system/design_system.dart';
import 'package:flora/features/identification/presentation/iris_feedback_prompt.dart';
import 'package:flora/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// La demande de consentement pour l'envoi des photos identifiées. Ce qui
/// doit tenir quoi qu'il arrive : elle n'est posée qu'une fois, et rien ne
/// s'allume sans un oui explicite.
Future<PreferencesService> _pump(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await PreferencesService.load();
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [preferencesServiceProvider.overrideWithValue(prefs)],
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
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child!,
      ),
      home: Consumer(
        builder: (context, ref, _) => Scaffold(
          body: Center(
            child: TextButton(
              key: const Key('ask'),
              onPressed: () => showIrisFeedbackPrompt(context, ref),
              child: const Text('demander'),
            ),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.byKey(const Key('ask')));
  await tester.pumpAndSettle();
  return prefs;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('la feuille dit de quoi il s’agit, avec les deux réponses', (tester) async {
    await _pump(tester);
    expect(find.text('Envoi des photos identifiées'), findsOneWidget);
    expect(find.text('Activer'), findsOneWidget);
    expect(find.text('Plus tard'), findsOneWidget);
  });

  testWidgets('« Activer » allume l’envoi, et la question ne se repose plus', (tester) async {
    final prefs = await _pump(tester);
    expect(prefs.irisFeedbackEnabled, isFalse, reason: 'rien ne part avant le oui');
    await tester.tap(find.text('Activer'));
    await tester.pumpAndSettle();
    expect(prefs.irisFeedbackEnabled, isTrue);
    expect(prefs.irisFeedbackAsked, isTrue);
  });

  testWidgets('« Plus tard » n’allume rien, et vaut réponse', (tester) async {
    final prefs = await _pump(tester);
    await tester.tap(find.text('Plus tard'));
    await tester.pumpAndSettle();
    expect(prefs.irisFeedbackEnabled, isFalse);
    expect(prefs.irisFeedbackAsked, isTrue, reason: 'redemander serait du harcèlement');
  });

  testWidgets('fermer la feuille sans répondre vaut « plus tard »', (tester) async {
    final prefs = await _pump(tester);
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    expect(prefs.irisFeedbackEnabled, isFalse);
    expect(prefs.irisFeedbackAsked, isTrue);
  });
}
