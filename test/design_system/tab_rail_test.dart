import 'package:flora/design_system/design_system.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Le menu debout, celui des fenêtres larges qui ne sont pas des tablettes.
///
/// Un iPhone Duo fermé montre 466 points de large, ouvert 669 : c'est le
/// second cas que sert ce rail. Un iPad, lui, garde sa pilule en bas — d'où
/// la seconde condition, sur le côté le plus court.
///
/// Les poses du Duo sont celles relevées dans Xcode 27.1 sur un binaire
/// bord-à-bord, DPR 3. Fermé et couché, le menu se met debout lui aussi :
/// c'est voulu, une fenêtre de 466 points de haut est celle où une barre
/// posée en bas coûte le plus cher.

const _tabs = [
  FloraTab(icon: CupertinoIcons.sun_max, activeIcon: CupertinoIcons.sun_max_fill, label: "Aujourd'hui"),
  FloraTab(icon: CupertinoIcons.square_grid_2x2, activeIcon: CupertinoIcons.square_grid_2x2_fill, label: 'Plantes'),
  FloraTab(icon: CupertinoIcons.house, activeIcon: CupertinoIcons.house_fill, label: 'Jardin'),
  FloraTab(icon: CupertinoIcons.person, activeIcon: CupertinoIcons.person_fill, label: 'Profil'),
];

/// Le rail monté comme la coquille le monte : à droite d'un contenu qui prend
/// le reste.
Future<void> _pumpRail(
  WidgetTester tester, {
  Size size = const Size(669, 951),
  double rightInset = 0,
  int index = 0,
  int actions = 0,
  ValueChanged<int>? onSelect,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: buildFloraTheme(Brightness.light),
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          padding: EdgeInsets.only(right: rightInset),
          viewPadding: EdgeInsets.only(right: rightInset),
        ),
        child: Scaffold(
          extendBody: true,
          body: Row(
            children: [
              const Expanded(child: SizedBox.expand(key: Key('contenu'))),
              FloraTabRail(
                tabs: _tabs,
                index: index,
                onSelect: onSelect ?? (_) {},
                actions: [
                  for (var i = 0; i < actions; i++)
                    // La vraie pièce : 40 points de rond, 44 de cible.
                    FloraIconButton(
                      key: ValueKey('action$i'),
                      icon: CupertinoIcons.plus,
                      semanticLabel: 'action $i',
                      onPressed: () {},
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

/// La pilule du rail : la seule boîte d'argile de ce montage.
Rect _pill(WidgetTester tester) => tester.getRect(find.byType(ClayBox).first);

/// La bulle : la seule pièce sauge du rail.
Rect _bulle(WidgetTester tester) => tester.getRect(
      find.byWidgetPredicate(
        (w) => w is DecoratedBox && w.decoration is BoxDecoration && (w.decoration as BoxDecoration).color == FloraColors.light.sage,
      ),
    );

void main() {
  group('où le menu se met debout', () {
    // (ce qu'on tient, la fenêtre, le menu debout)
    const cas = <(String, Size, bool)>[
      ('iPhone', Size(402, 874), false),
      ('iPhone 16 Pro Max', Size(440, 956), false),
      ('iPhone Duo fermé', Size(466, 678), true),
      ('iPhone Duo fermé, couché', Size(678, 466), true),
      ('iPhone Duo ouvert', Size(669, 951), true),
      ('iPhone Duo ouvert, couché', Size(951, 669), true),
      ('iPad mini, portrait', Size(744, 1133), false),
      ('iPad 11 pouces, paysage', Size(1180, 820), false),
      ('iPad en Split View aux deux tiers', Size(678, 1133), false),
      ('en multitâche, la moitié', Size(445, 626), false),
      ('en multitâche, le tiers', Size(320, 626), false),
    ];
    for (final (appareil, size, debout) in cas) {
      testWidgets('$appareil : ${debout ? 'à droite' : 'en bas'}', (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        late bool result;
        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(size: size),
            child: Builder(builder: (context) {
              result = FloraTabRail.fitsIn(context);
              return const SizedBox();
            }),
          ),
        );
        expect(result, debout);
      });
    }
  });

  group('le menu debout', () {
    testWidgets('se range contre le bord droit, à hauteur du regard', (tester) async {
      await _pumpRail(tester);
      final pill = _pill(tester);
      // Contre le bord droit, pas au milieu.
      expect(669 - pill.right, lessThan(20), reason: 'la pilule flotte loin du bord');
      // Et centrée dans la hauteur.
      expect(pill.center.dy, closeTo(951 / 2, 1));
      // Une colonne, pas une barre : plus haute que large.
      expect(pill.height, greaterThan(pill.width * 2));
    });

    testWidgets('se pose dans la bande du système, pas à côté', (tester) async {
      // 84 points : la bande de l'heure et du wifi sur un Duo, mesurée dans
      // Xcode 27.1. C'est là que le pliable met les commandes d'une app ; s'en
      // écarter laissait une colonne vide large comme un pouce.
      await _pumpRail(tester, size: const Size(951, 669), rightInset: 84);
      expect(951 - _pill(tester).right, lessThan(16), reason: 'la colonne reste à côté de la bande au lieu d\'y entrer');
    });

    testWidgets('mais le contenu, lui, s\'arrête avant la bande', (tester) async {
      // La marge vaut pour le contenu ; le menu est du châssis. Le contenu
      // prend ce que la colonne lui laisse, et ce reste tombe en deçà.
      await _pumpRail(tester, size: const Size(951, 669), rightInset: 84);
      expect(tester.getRect(find.byKey(const Key('contenu'))).right, lessThanOrEqualTo(951 - 84));
    });

    testWidgets('elle reste au bord quand la bande passe de l\'autre côté', (tester) async {
      await _pumpRail(tester, size: const Size(678, 466));
      expect(678 - _pill(tester).right, lessThan(16), reason: 'la pilule s\'écarte du bord sans raison');
    });

    testWidgets('ne laisse pas le contenu passer dessous', (tester) async {
      await _pumpRail(tester);
      final contenu = tester.getRect(find.byKey(const Key('contenu')));
      expect(contenu.right, lessThanOrEqualTo(_pill(tester).left + 0.5));
    });

    testWidgets('chaque onglet reste sous le doigt : 44 points au moins', (tester) async {
      await _pumpRail(tester);
      for (final tab in _tabs) {
        final cible = tester.getSize(find.bySemanticsLabel(tab.label));
        expect(cible.width, greaterThanOrEqualTo(44));
        expect(cible.height, greaterThanOrEqualTo(44));
      }
    });

    testWidgets('toucher un onglet le choisit', (tester) async {
      final choisis = <int>[];
      await _pumpRail(tester, onSelect: choisis.add);
      await tester.tap(find.bySemanticsLabel('Jardin'));
      await tester.pump();
      expect(choisis, [2]);
    });

    testWidgets('la bulle glisse dans la colonne au lieu d\'y sauter', (tester) async {
      await _pumpRail(tester);
      final depart = _bulle(tester);

      await _pumpRail(tester, index: 3);
      await tester.pump(const Duration(milliseconds: 60));
      final route = _bulle(tester);
      expect(route.top, greaterThan(depart.top), reason: 'elle est partie');
      expect(route.top, lessThan(depart.top + depart.height * 3), reason: 'et elle est encore en route');

      await tester.pumpAndSettle();
      final arrivee = _bulle(tester);
      expect(arrivee.top, moreOrLessEquals(depart.top + depart.height * 3, epsilon: 1));
      // Elle descend : elle ne s'étire pas, et elle ne part pas de côté.
      expect(arrivee.height, moreOrLessEquals(depart.height, epsilon: 0.5));
      expect(arrivee.center.dx, moreOrLessEquals(depart.center.dx, epsilon: 0.5));
    });

    testWidgets('la pilule ne bouge pas quand la page change de boutons', (tester) async {
      // C'est de la navigation : elle doit rester sous le même doigt d'un
      // onglet à l'autre. Centrer le groupe entier la faisait remonter à
      // chaque bouton de plus — assez haut, à quatre, pour passer sous
      // l'heure du système.
      await _pumpRail(tester, actions: 0);
      final nue = _pill(tester);
      await _pumpRail(tester, actions: 2);
      expect(_pill(tester).top, moreOrLessEquals(nue.top, epsilon: 0.5));
      await _pumpRail(tester, actions: 4);
      expect(_pill(tester).top, moreOrLessEquals(nue.top, epsilon: 0.5));
    });

    testWidgets('et dans une fenêtre trop courte pour tout centrer, le groupe remonte sans déborder', (tester) async {
      // L'écran extérieur du Duo, onglet Plantes : la pilule et quatre
      // boutons ne tiennent plus en gardant la pilule au milieu. Le groupe
      // remonte de ce qu'il faut, et pas d'un point de plus.
      await _pumpRail(tester, size: const Size(466, 678), actions: 4);
      expect(tester.takeException(), isNull);
      final bas = tester.getRect(find.byKey(const ValueKey('action3'))).bottom;
      expect(bas, lessThanOrEqualTo(678));
    });

    testWidgets('les boutons pendent sous la pilule', (tester) async {
      await _pumpRail(tester, actions: 4);
      final pilule = _pill(tester);
      for (var i = 0; i < 4; i++) {
        expect(tester.getRect(find.byKey(ValueKey('action$i'))).top, greaterThan(pilule.bottom));
      }
    });

    testWidgets('dans une fenêtre courte, la colonne se resserre au lieu de déborder', (tester) async {
      await _pumpRail(tester, size: const Size(669, 260));
      expect(tester.takeException(), isNull);
      expect(_pill(tester).height, lessThanOrEqualTo(260));
    });
  });
}
