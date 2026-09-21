import 'package:flora/design_system/design_system.dart';
import 'package:flora/domain/home/home_climate.dart';
import 'package:flora/domain/home/home_climate_advisor.dart';
import 'package:flora/features/home_climate/presentation/home_climate_widgets.dart';
import 'package:flora/features/today/presentation/today_notice.dart';
import 'package:flora/l10n/generated/app_localizations.dart';
import 'package:flora/l10n/generated/app_localizations_fr.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Les cartes du matin partagent une anatomie : une tuile d'emoji, un titre,
/// une phrase, des gestes, une croix. Et le conseil de la maison met la
/// mesure en titre, la consigne dessous, sans répéter la mesure.
void main() {
  Widget page(Widget child) => MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildFloraTheme(Brightness.light),
        home: Scaffold(body: Center(child: SizedBox(width: 360, child: child))),
      );

  testWidgets('une carte : tuile, titre, phrase, gestes et croix', (tester) async {
    var dismissed = false;
    await tester.pumpWidget(
      page(
        TodayNotice(
          emoji: '🌧️',
          title: "Pluie aujourd'hui",
          body: "L'arrosage de Balcon peut attendre.",
          actions: [FloraButton(label: 'Reporter', size: FloraButtonSize.small, onPressed: () {})],
          onDismiss: () => dismissed = true,
        ),
      ),
    );
    expect(find.byType(EmojiTile), findsOneWidget);
    expect(find.text("Pluie aujourd'hui"), findsOneWidget);
    expect(find.text("L'arrosage de Balcon peut attendre."), findsOneWidget);
    expect(find.text('Reporter'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Fermer'));
    expect(dismissed, isTrue);
  });

  testWidgets('la carte de repos n\'a ni geste ni croix', (tester) async {
    await tester.pumpWidget(page(const TodayNotice(emoji: '🌿', title: 'Tout est en ordre', body: "Aucun soin prévu aujourd'hui.")));
    expect(find.text('Tout est en ordre'), findsOneWidget);
    expect(find.byType(FloraButton), findsNothing);
    expect(find.byType(FloraIconButton), findsNothing);
  });

  testWidgets('un emplacement vide ne laisse pas de marge derrière lui', (tester) async {
    await tester.pumpWidget(page(const TodayNoticeSlot(visible: false, child: SizedBox(height: 80))));
    expect(tester.getSize(find.byType(TodayNoticeSlot)).height, 0);
  });

  group('le conseil de la maison', () {
    final l10n = AppLocalizationsFr();
    final at = DateTime(2026, 9, 13, 9);

    test('le titre porte la mesure et la pièce', () {
      const sensor = HomeSensor(id: 'T', name: 'Thermostat', roomName: 'Salon');
      expect(homeReadingTitle(l10n, HomeReading(at: at, temperatureC: 25.2, humidity: 41, sensor: sensor), metric: true), '25° · 41 % · Salon');
      expect(homeReadingTitle(l10n, HomeReading(at: at, temperatureC: 25.2, sensor: sensor), metric: false), '77°F · Salon');
    });

    test('sans pièce, le titre dit où l\'on est', () {
      expect(homeReadingTitle(l10n, HomeReading(at: at, temperatureC: 25), metric: true), 'Chez vous · 25°');
    });

    test('la consigne ne répète pas la mesure', () {
      const hot = HomeClimateTip(kind: HomeClimateTipKind.hot, value: 25, plantNames: ['Monstera', 'Pilea']);
      expect(homeTipText(l10n, hot), 'Chaleur : Monstera et Pilea sèchent plus vite, vérifiez la terre.');
      const dry = HomeClimateTip(kind: HomeClimateTipKind.dryAir, value: 32, plantNames: ['Calathea']);
      expect(homeTipText(l10n, dry), 'Air sec : brumisez ou regroupez Calathea.');
      const humid = HomeClimateTip(kind: HomeClimateTipKind.humidAir, value: 75, plantNames: []);
      expect(homeTipText(l10n, humid), 'Air humide : aérez la pièce.');
      const cold = HomeClimateTip(kind: HomeClimateTipKind.cold, value: 12, plantNames: ['Pilea']);
      expect(homeTipText(l10n, cold), 'Trop froid pour Pilea.');
    });
  });
}
