import 'dart:convert';
import 'dart:io';

import 'package:flora/design_system/design_system.dart';
import 'package:flora/domain/room/room_plan_parser.dart';
import 'package:flora/domain/room/scanned_room.dart';
import 'package:flora/features/room_scan/presentation/room_marker_placer_sheet.dart';
import 'package:flora/l10n/generated/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// La feuille qui pose un repère sur le plan d'une pièce.
///
/// Son plan prenait la largeur qu'on lui donnait et se réservait la hauteur
/// qui va avec. Sur une fenêtre large — un iPad, un iPhone Duo ouvert —, cela
/// faisait sept cents points de plan dans une feuille qui n'en a que la
/// hauteur de l'écran : la colonne débordait, et « Poser » tombait hors de
/// l'écran sans rien pour défiler jusqu'à lui.
void main() {
  late ScannedRoom room;

  setUpAll(() {
    final json = jsonDecode(File('test/domain/fixtures/roomplan_diorama.json').readAsStringSync()) as Map;
    room = RoomPlanParser.parse(Map<String, Object?>.from(json), northOffsetDeg: 90);
  });

  Future<void> ouvrir(WidgetTester tester, Size fenetre) async {
    await tester.binding.setSurfaceSize(fenetre);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildFloraTheme(Brightness.light),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FloraButton(
              label: 'Ouvrir',
              onPressed: () => showRoomMarkerPlacer(context, room: room, markers: const [], kind: RoomMarkerPlacement.heater),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
  }

  // Un téléphone debout, une fenêtre large et basse : la feuille tient dans
  // les deux, et c'est la seconde qui débordait.
  for (final (nom, taille) in [('un téléphone', Size(393, 852)), ('une fenêtre large', Size(1024, 768))]) {
    testWidgets('la feuille du repère tient dans $nom', (tester) => _surIOS(() async {
          await ouvrir(tester, taille);
          expect(find.text('Place'), findsOneWidget);
          // Un débordement de mise en page lève une exception du rendu, que
          // `flutter_test` remonte ici.
          expect(tester.takeException(), isNull);
          final feuille = tester.getRect(find.byType(FloraCard).first);
          expect(feuille.bottom, lessThanOrEqualTo(taille.height), reason: 'le plan dépasse du bas');
        }));
  }

  testWidgets('un toucher sur le plan pose le repère', (tester) => _surIOS(() async {
        await ouvrir(tester, const Size(393, 852));
        expect(tester.widget<FloraButton>(find.widgetWithText(FloraButton, 'Place')).onPressed, isNull);

        await tester.tap(find.byType(FloraCard).first);
        await tester.pumpAndSettle();

        expect(tester.widget<FloraButton>(find.widgetWithText(FloraButton, 'Place')).onPressed, isNotNull);
      }));

  testWidgets('le doigt qui glisse sur le plan déplace le repère, sans refermer la feuille', (tester) => _surIOS(() async {
        await ouvrir(tester, const Size(393, 852));
        // Rien de posé : « Poser » est éteint.
        expect(tester.widget<FloraButton>(find.widgetWithText(FloraButton, 'Place')).onPressed, isNull);

        await tester.dragFrom(tester.getCenter(find.byType(FloraCard).first), const Offset(0, 40));
        await tester.pumpAndSettle();

        expect(find.text('Place'), findsOneWidget, reason: 'le glissement ne doit pas refermer la feuille');
        expect(tester.widget<FloraButton>(find.widgetWithText(FloraButton, 'Place')).onPressed, isNotNull, reason: 'le repère a suivi le doigt');
      }));
}

/// La plateforme se pose dans le corps du test : la reposer ailleurs fait
/// échouer la vérification d'invariants de `flutter_test`.
Future<void> _surIOS(Future<void> Function() corps) async {
  debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
  try {
    await corps();
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
}
