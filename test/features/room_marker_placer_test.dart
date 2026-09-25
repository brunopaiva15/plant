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

  Future<void> ouvrir(WidgetTester tester, Size fenetre, {RoomMarkerPlacement kind = RoomMarkerPlacement.heater, HandWindow? windowSize}) async {
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
              onPressed: () => showRoomMarkerPlacer(context, room: room, markers: const [], kind: kind, windowSize: windowSize),
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
  // les deux, et c'est la seconde qui débordait. La consigne de la fenêtre
  // tient une ligne de plus que celle du radiateur : elle débordait le
  // téléphone à son tour.
  for (final (nom, taille) in [('un téléphone', Size(393, 852)), ('une fenêtre large', Size(1024, 768))]) {
    for (final (quoi, kind) in [('du repère', RoomMarkerPlacement.heater), ('de la fenêtre', RoomMarkerPlacement.window)]) {
      testWidgets('la feuille $quoi tient dans $nom', (tester) => _surIOS(() async {
            await ouvrir(tester, taille, kind: kind, windowSize: HandWindow.wide);
            expect(find.text('Place'), findsOneWidget);
            // Un débordement de mise en page lève une exception du rendu, que
            // `flutter_test` remonte ici.
            expect(tester.takeException(), isNull);
            final feuille = tester.getRect(find.byType(FloraCard).first);
            expect(feuille.bottom, lessThanOrEqualTo(taille.height), reason: 'le plan dépasse du bas');
          }));
    }
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

  testWidgets("une fenêtre se pose d'un toucher, même à côté de la pièce", (tester) => _surIOS(() async {
        await ouvrir(tester, const Size(393, 852), kind: RoomMarkerPlacement.window, windowSize: HandWindow.wide);
        expect(find.text('Add a window'), findsOneWidget);
        // La consigne de la fenêtre tient une ligne de plus que celle du
        // radiateur : la feuille ne doit pas déborder pour autant.
        expect(tester.takeException(), isNull);
        expect(tester.widget<FloraButton>(find.widgetWithText(FloraButton, 'Place')).onPressed, isNull);

        final plan = tester.getRect(find.byType(FloraCard).first);
        await tester.tapAt(_horsDesMurs(plan));
        await tester.pumpAndSettle();

        expect(tester.widget<FloraButton>(find.widgetWithText(FloraButton, 'Place')).onPressed, isNotNull);
      }));

  testWidgets('une plante, elle, ne se pose pas hors des murs', (tester) => _surIOS(() async {
        await ouvrir(tester, const Size(393, 852), kind: RoomMarkerPlacement.plant);

        final plan = tester.getRect(find.byType(FloraCard).first);
        await tester.tapAt(_horsDesMurs(plan));
        await tester.pumpAndSettle();

        expect(tester.widget<FloraButton>(find.widgetWithText(FloraButton, 'Place')).onPressed, isNull,
            reason: 'ce coin du cadre tombe bien hors de la pièce');
      }));
}

/// Un point du cadre hors des murs de la pièce : le haut du plan, à huit
/// points du bord. Le cadre garde au moins quatorze points de marge autour de
/// la pièce, quelle qu'elle soit, et le milieu du bord est loin des arrondis —
/// un toucher sur l'arrondi ne passe pas le rognage et n'atteint pas le plan.
Offset _horsDesMurs(Rect plan) => plan.topCenter + const Offset(0, 8);

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
