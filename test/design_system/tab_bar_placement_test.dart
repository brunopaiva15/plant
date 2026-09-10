import 'package:flora/design_system/design_system.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// La barre d'onglets là où elle vit vraiment : en `bottomNavigationBar` d'un
/// `Scaffold`, sous un contenu qui défile dessous (`extendBody`).
///
/// C'est le montage qui manquait aux premiers tests : ils posaient la barre
/// au milieu d'un `body`, où elle recevait des contraintes lâches et où un
/// `Center` mal borné ne se voyait pas. En `bottomNavigationBar`, le Scaffold
/// offre toute la hauteur de l'écran — et un widget qui s'y étire emporte la
/// pilule au milieu du contenu.

const _tabs = [
  FloraTab(icon: CupertinoIcons.sun_max, activeIcon: CupertinoIcons.sun_max_fill, label: 'Aujourd\'hui'),
  FloraTab(icon: CupertinoIcons.square_grid_2x2, activeIcon: CupertinoIcons.square_grid_2x2_fill, label: 'Plantes'),
  FloraTab(icon: CupertinoIcons.house, activeIcon: CupertinoIcons.house_fill, label: 'Jardin'),
  FloraTab(icon: CupertinoIcons.person, activeIcon: CupertinoIcons.person_fill, label: 'Profil'),
];

Future<void> _pumpShell(
  WidgetTester tester, {
  double textScale = 1.0,
  Size size = const Size(390, 844),
  double bottomInset = 0,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: buildFloraTheme(Brightness.dark),
      home: MediaQuery(
        data: MediaQueryData(
          textScaler: TextScaler.linear(textScale),
          size: size,
          padding: EdgeInsets.only(bottom: bottomInset),
          viewPadding: EdgeInsets.only(bottom: bottomInset),
        ),
        child: Scaffold(
          extendBody: true,
          body: ListView(children: [for (var i = 0; i < 20; i++) SizedBox(height: 80, child: Text('ligne $i'))]),
          bottomNavigationBar: FloraTabBar(tabs: _tabs, index: 0, onSelect: (_) {}),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('la barre d\'onglets, posée en bas d\'un Scaffold', () {
    testWidgets('n\'occupe que sa propre hauteur', (tester) async {
      await _pumpShell(tester);
      final bar = tester.getSize(find.byType(FloraTabBar));
      // Sans `heightFactor`, elle mesurait les 844 points de l'écran.
      expect(bar.height, lessThan(140), reason: 'la barre s\'étire au lieu d\'épouser son contenu');
    });

    testWidgets('la pilule se pose en bas, pas au milieu', (tester) async {
      await _pumpShell(tester);
      final pill = tester.getRect(find.byType(ClayBox).first);
      // Le centre de la pilule doit être dans le dernier cinquième de l'écran.
      expect(pill.center.dy, greaterThan(844 * 0.8), reason: 'la pilule flotte au milieu du contenu');
    });

    for (final scale in [1.0, 2.0, 3.5]) {
      testWidgets('tient sa place à ${(scale * 100).round()} % de Dynamic Type', (tester) async {
        await _pumpShell(tester, textScale: scale);
        expect(tester.takeException(), isNull);
        expect(tester.getSize(find.byType(FloraTabBar)).height, lessThan(200));
        expect(tester.getRect(find.byType(ClayBox).first).center.dy, greaterThan(844 * 0.75));
      });
    }

    // Une barre flottante flotte *dans* l'encart, elle ne se pose pas
    // au-dessus : l'indicateur d'accueil ne fait que 5 pt de haut, et les 34
    // que réserve iOS sont larges pour lui. Vingt points, c'est ce que laisse
    // l'App Store, mesuré au pixel sur une capture d'iPhone 16 Pro.
    //
    // Une barre à trois boutons, elle, est de l'interface : on la rend
    // entière, sinon la pilule passe dessous.
    //
    // (appareil, encart réservé, blanc attendu sous la pilule)
    const cases = <(String, double, double)>[
      ('iPhone à indicateur d\'accueil', 34, 20),
      ('Android, navigation par gestes', 24, 20),
      ('Android, barre à trois boutons', 48, 48),
      ('appareil sans encart', 0, 8),
    ];
    for (final (device, inset, expected) in cases) {
      testWidgets('$device : $expected pt sous la pilule', (tester) async {
        await _pumpShell(tester, bottomInset: inset);
        final pill = tester.getRect(find.byType(ClayBox).first);
        expect(844 - pill.bottom, closeTo(expected, 0.5));
      });
    }

    testWidgets('sous une barre à boutons, la pilule ne passe jamais dessous', (tester) async {
      await _pumpShell(tester, bottomInset: 48);
      final pill = tester.getRect(find.byType(ClayBox).first);
      // Le bas de la pilule reste au-dessus de la zone réservée aux boutons.
      expect(pill.bottom, lessThanOrEqualTo(844 - 48 + 0.5));
    });

    testWidgets('sur une tablette, elle reste en bas et bornée en largeur', (tester) async {
      await _pumpShell(tester, size: const Size(1180, 820));
      final pill = tester.getRect(find.byType(ClayBox).first);
      expect(pill.width, lessThanOrEqualTo(520));
      expect(pill.center.dy, greaterThan(820 * 0.8));
      // Et centrée dans la largeur, pas collée à un bord.
      expect(pill.center.dx, closeTo(1180 / 2, 1));
    });
  });
}
