import 'package:flora/data/services/photo_storage_service.dart';
import 'package:flora/design_system/design_system.dart';
import 'package:flora/features/plants/presentation/inline_camera.dart';
import 'package:flora/features/plants/presentation/quick_capture_screen.dart';
import 'package:flora/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// La prise de vue plein écran, celle des photos qu'un écran demande après
/// coup (la vue que réclame un diagnostic). Ici, pas de caméra : c'est le
/// repli qui se voit, et il doit laisser les deux gestes à portée.
void main() {
  Future<List<StoredPhoto?>> ouvrir(WidgetTester tester) async {
    final results = <StoredPhoto?>[];
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
          home: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () async => results.add(await showQuickCapture(context, title: 'Nouvelle photo', subtitle: 'À photographier : une feuille de près.')),
                child: const Text('ouvrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
    return results;
  }

  testWidgets('sans viseur, le cadre garde son invite et les deux gestes restent', (tester) async {
    await ouvrir(tester);
    expect(InlineCameraController.isSupported, isFalse);
    expect(find.text('Nouvelle photo'), findsOneWidget);
    expect(find.text('À photographier : une feuille de près.'), findsOneWidget);
    // L'invite du cadre, puis le bouton qui la double.
    expect(find.text('Prendre une photo'), findsNWidgets(2));
    expect(find.text('Choisir une photo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('la croix referme sans photo', (tester) async {
    final results = await ouvrir(tester);
    await tester.tap(find.bySemanticsLabel('Fermer'));
    await tester.pumpAndSettle();
    expect(find.text('Nouvelle photo'), findsNothing);
    expect(results, [null]);
  });
}
