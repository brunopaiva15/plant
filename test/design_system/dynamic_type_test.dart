import 'package:flora/design_system/design_system.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Dynamic Type jusqu'au bout de l'échelle d'accessibilité.
///
/// Suivre `textScaler` ne suffit pas : encore faut-il que la mise en page
/// suive le texte. Une hauteur figée ne grandit pas avec lui, elle le rogne —
/// et le rognage, dans Flutter, se signale par une exception de débordement.
/// C'est elle qu'on guette ici.

/// Les crans d'iOS, du plus petit au plus grand des réglages d'accessibilité.
const _scales = [0.82, 1.0, 1.35, 2.0, 3.0, 3.5];

Future<void> _pump(WidgetTester tester, double scale, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildFloraTheme(Brightness.light),
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: Scaffold(body: Center(child: child)),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('la barre d\'onglets', () {
    const tabs = [
      FloraTab(icon: CupertinoIcons.sun_max, activeIcon: CupertinoIcons.sun_max_fill, label: 'Aujourd\'hui'),
      FloraTab(icon: CupertinoIcons.square_grid_2x2, activeIcon: CupertinoIcons.square_grid_2x2_fill, label: 'Plantes'),
      FloraTab(icon: CupertinoIcons.house, activeIcon: CupertinoIcons.house_fill, label: 'Jardin'),
      FloraTab(icon: CupertinoIcons.person, activeIcon: CupertinoIcons.person_fill, label: 'Profil'),
    ];

    for (final scale in _scales) {
      testWidgets('ne déborde pas à ${(scale * 100).round()} %', (tester) async {
        await _pump(
          tester,
          scale,
          SizedBox(
            width: 390,
            child: FloraTabBar(tabs: tabs, index: 0, onSelect: (_) {}),
          ),
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('grandit avec le texte au lieu de le rogner', (tester) async {
      await _pump(
        tester,
        1.0,
        SizedBox(
          width: 390,
          child: FloraTabBar(tabs: tabs, index: 0, onSelect: (_) {}),
        ),
      );
      final small = tester.getSize(find.byType(ClayBox).first).height;
      await _pump(
        tester,
        3.0,
        SizedBox(
          width: 390,
          child: FloraTabBar(tabs: tabs, index: 0, onSelect: (_) {}),
        ),
      );
      final large = tester.getSize(find.byType(ClayBox).first).height;
      expect(large, greaterThan(small));
    });

    testWidgets('reste bornée en largeur sur un écran de tablette', (tester) async {
      await _pump(
        tester,
        1.0,
        SizedBox(
          width: 1180,
          child: FloraTabBar(tabs: tabs, index: 0, onSelect: (_) {}),
        ),
      );
      expect(tester.getSize(find.byType(ClayBox).first).width, lessThanOrEqualTo(520));
    });
  });

  group('les boutons', () {
    for (final scale in _scales) {
      testWidgets('un libellé long tient à ${(scale * 100).round()} %', (tester) async {
        await _pump(
          tester,
          scale,
          SizedBox(
            width: 300,
            child: FloraButton(label: 'Enregistrer le soin de cette plante', expand: true, onPressed: () {}),
          ),
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('le bouton s\'allonge plutôt que de couper son libellé', (tester) async {
      await _pump(
        tester,
        1.0,
        SizedBox(
          width: 300,
          child: FloraButton(label: 'Enregistrer le soin', expand: true, onPressed: () {}),
        ),
      );
      final small = tester.getSize(find.byType(FloraButton)).height;
      await _pump(
        tester,
        2.0,
        SizedBox(
          width: 300,
          child: FloraButton(label: 'Enregistrer le soin', expand: true, onPressed: () {}),
        ),
      );
      expect(tester.getSize(find.byType(FloraButton)).height, greaterThan(small));
    });
  });

  _boldTextTests();

  group('les lignes de liste et les chips', () {
    for (final scale in _scales) {
      testWidgets('tiennent à ${(scale * 100).round()} %', (tester) async {
        await _pump(
          tester,
          scale,
          SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloraListRow(title: 'Monstera deliciosa', subtitle: 'Arrosée il y a 3 jours', onTap: () {}),
                FloraChip(label: 'Salon', onTap: () {}),
              ],
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      });
    }
  });
}

/// « Texte en gras » : le réglage doit atteindre les grands titres aussi.
void _boldTextTests() {
  testWidgets('la fonte variable des titres suit « Texte en gras »', (tester) async {
    late TextStyle normal;
    late TextStyle bold;
    Widget probe({required bool boldText}) => MaterialApp(
      theme: buildFloraTheme(Brightness.light),
      home: MediaQuery(
        data: MediaQueryData(boldText: boldText),
        child: Builder(
          builder: (context) {
            if (boldText) {
              bold = context.text.display;
            } else {
              normal = context.text.display;
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pumpWidget(probe(boldText: false));
    await tester.pumpWidget(probe(boldText: true));
    // C'est l'axe `wght` qui compte : un `fontWeight` posé à côté serait
    // ignoré par la fonte variable.
    double wght(TextStyle s) => s.fontVariations!.firstWhere((v) => v.axis == 'wght').value;
    expect(wght(bold), greaterThan(wght(normal)));
    expect(wght(bold), lessThanOrEqualTo(800));
  });
}
