import 'package:flora/app/providers.dart';
import 'package:flora/data/services/preferences_service.dart';
import 'package:flora/design_system/design_system.dart';
import 'package:flora/features/home_climate/presentation/home_shortcut_guide_sheet.dart';
import 'package:flora/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// La feuille « Capteurs d'un HomePod » : le pourquoi, quatre étapes numérotées,
/// et la dernière valeur reçue par le raccourci.
void main() {
  testWidgets('la feuille explique, en quatre étapes, et montre ce qui est arrivé', (tester) async {
    final written = DateTime.now().subtract(const Duration(minutes: 3)).millisecondsSinceEpoch;
    SharedPreferences.setMockInitialValues({'locale': 'fr', 'home_shortcut_reading': '|45|$written|Salle de jeux'});
    final prefs = await PreferencesService.load();
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
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
          home: Builder(builder: (context) => TextButton(onPressed: () => showHomeShortcutGuide(context), child: const Text('ouvrir'))),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
    expect(find.text("Capteurs d'un HomePod"), findsOneWidget);
    for (final n in ['1', '2', '3', '4']) {
      expect(find.text(n), findsOneWidget);
    }
    expect(find.text("Une automatisation à l'ouverture"), findsOneWidget);
    expect(find.text('Choisir « Raccourci » comme capteur'), findsOneWidget);
    expect(find.text('45 %'), findsOneWidget);
    expect(find.textContaining('Salle de jeux'), findsOneWidget);
    expect(find.text('Ouvrir Raccourcis'), findsOneWidget);
  });
}
