import 'package:flora/core/window_regions.dart';
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
    testWidgets('se range contre le bord droit, la pilule en bas', (tester) async {
      await _pumpRail(tester);
      final pill = _pill(tester);
      // Contre le bord droit, pas au milieu.
      // Sur le même axe que la pile du système : iOS la pose à 47,7 points
      // du bord droit, mesuré dans les trois poses du Duo.
      expect(669 - pill.center.dx, closeTo(48, 0.5), reason: 'la colonne n\'est pas sur l\'axe du système');
      // En bas, comme iOS : « the tab bar moves to the bottom of the
      // vertical bar ».
      expect(951 - pill.bottom, lessThan(Space.xl), reason: 'la pilule n\'est pas au bas de la colonne');
      // Une colonne, pas une barre : plus haute que large.
      expect(pill.height, greaterThan(pill.width * 2));
    });

    testWidgets('les boutons de la page sont en haut, sous la pile du système', (tester) async {
      // « Reserve the top for primary navigation controls […] followed by
      // prominent actions. » Les glyphes du système descendent à 140 points
      // là où iOS n'en annonce que 82 : les boutons commencent sous eux.
      await _pumpRail(tester, actions: 4);
      final premier = tester.getRect(find.byKey(const ValueKey('action0')));
      expect(premier.top, greaterThanOrEqualTo(140 + 24), reason: 'les boutons collent aux glyphes du système');
      expect(premier.top, lessThan(210));
      for (var i = 0; i < 4; i++) {
        expect(tester.getRect(find.byKey(ValueKey('action$i'))).bottom, lessThan(_pill(tester).top));
      }
    });

    testWidgets('se pose dans la bande du système, pas à côté', (tester) async {
      // 84 points : la bande de l'heure et du wifi sur un Duo, mesurée dans
      // Xcode 27.1. C'est là que le pliable met les commandes d'une app ; s'en
      // écarter laissait une colonne vide large comme un pouce.
      await _pumpRail(tester, size: const Size(951, 669), rightInset: 84);
      expect(951 - _pill(tester).center.dx, closeTo(48, 0.5), reason: 'la colonne reste à côté de la bande au lieu d\'y entrer');
    });

    testWidgets('mais le contenu, lui, s\'arrête avant la bande', (tester) async {
      // La marge vaut pour le contenu ; le menu est du châssis. Le contenu
      // prend ce que la colonne lui laisse, et ce reste tombe en deçà.
      await _pumpRail(tester, size: const Size(951, 669), rightInset: 84);
      expect(tester.getRect(find.byKey(const Key('contenu'))).right, lessThanOrEqualTo(951 - 84));
    });

    testWidgets('elle reste au bord quand la bande passe de l\'autre côté', (tester) async {
      await _pumpRail(tester, size: const Size(678, 466));
      expect(678 - _pill(tester).center.dx, closeTo(48, 0.5), reason: 'la pilule s\'écarte du bord sans raison');
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

    testWidgets('la pilule reste au bas de la fenêtre dans toutes les poses', (tester) async {
      // Ni un pli ni une rotation ne doivent déplacer la navigation : elle
      // est calée sur un bord, pas sur le contenu de la colonne.
      for (final pose in [const Size(466, 678), const Size(669, 951), const Size(951, 669)]) {
        await _pumpRail(tester, size: pose, actions: 4);
        expect(pose.height - _pill(tester).bottom, lessThan(Space.xl), reason: '$pose');
      }
    });

    testWidgets('ni la pilule ni les boutons ne bougent quand la page change', (tester) async {
      // C'est de la navigation : elle doit rester sous le même doigt d'un
      // onglet à l'autre. Et les boutons, calés sous le dégagement du haut,
      // ne remontent pas d'un cran à chaque bouton de plus — c'est le vide
      // entre les deux groupes qui absorbe la différence.
      await _pumpRail(tester, actions: 0);
      final nue = _pill(tester);
      await _pumpRail(tester, actions: 2);
      expect(_pill(tester).top, moreOrLessEquals(nue.top, epsilon: 0.5));
      final deux = tester.getRect(find.byKey(const ValueKey('action0'))).top;
      await _pumpRail(tester, actions: 4);
      expect(_pill(tester).top, moreOrLessEquals(nue.top, epsilon: 0.5));
      expect(tester.getRect(find.byKey(const ValueKey('action0'))).top, moreOrLessEquals(deux, epsilon: 0.5));
    });

    testWidgets('dans une fenêtre trop courte, elle remonte plutôt que de déborder', (tester) async {
      // Un Duo fermé et couché : 466 points de haut pour quatre onglets et
      // quatre boutons. Le dégagement du haut cède avant les cibles.
      await _pumpRail(tester, size: const Size(678, 466), actions: 4);
      expect(tester.takeException(), isNull);
      final pill = _pill(tester);
      expect(
        tester.getRect(find.byKey(const ValueKey('action0'))).top,
        lessThan(140),
        reason: 'le dégagement n\'a pas cédé',
      );
      // Les onglets gardent leurs 44 points : six points de marge intérieure
      // de chaque côté, et quatre créneaux dans ce qui reste.
      expect((pill.height - 12) / 4, greaterThanOrEqualTo(44));
      expect(pill.bottom, lessThanOrEqualTo(466));
    });

    testWidgets('dans une fenêtre courte, la colonne se resserre au lieu de déborder', (tester) async {
      await _pumpRail(tester, size: const Size(669, 260));
      expect(tester.takeException(), isNull);
      expect(_pill(tester).height, lessThanOrEqualTo(260));
    });
  });

  group('ce que le système annonce', () {
    tearDown(() => WindowRegionsService.regions.value = const WindowRegions());

    testWidgets('l\'axe annoncé l\'emporte sur celui qui était mesuré', (tester) async {
      WindowRegionsService.regions.value = const WindowRegions(systemAxisFromRight: 60);
      await _pumpRail(tester);
      expect(669 - _pill(tester).center.dx, closeTo(60, 0.5));
    });

    testWidgets('le bas de la pile annoncé décide du dégagement', (tester) async {
      // Huit points sous la région annoncée, et non les 32 qui dégagent des
      // glyphes mesurés : la région est déjà ce que le système se réserve.
      WindowRegionsService.regions.value = const WindowRegions(systemStackBottom: 60);
      await _pumpRail(tester, actions: 1);
      expect(tester.getRect(find.byKey(const ValueKey('action0'))).top, moreOrLessEquals(68, epsilon: 0.5));
    });

    testWidgets('le relevé du Duo fermé ne déplace presque pas la colonne', (tester) async {
      // Ce que le simulateur a répondu le 20 septembre 2026 : bande haute de
      // 170 points, caméra à 47,8 du bord droit. La mesure disait 172 et
      // 47,7 — l'annonce la remplace sans la démentir.
      await _pumpRail(tester, size: const Size(466, 678), rightInset: 84, actions: 1);
      Rect bouton() => tester.getRect(find.byKey(const ValueKey('action0')));
      final mesure = bouton();
      WindowRegionsService.regions.value = const WindowRegions(
        systemStackBottom: 170,
        systemAxisFromRight: 47.83,
      );
      await tester.pump();
      expect(bouton().top, moreOrLessEquals(178, epsilon: 0.5));
      expect((bouton().top - mesure.top).abs(), lessThan(8), reason: 'la colonne saute');
      expect(466 - _pill(tester).center.dx, closeTo(47.83, 0.5));
    });

    testWidgets('l\'ouvert couché remonte la colonne, sans la décaler', (tester) async {
      // Relevé du 20 septembre 2026, 951 × 669 : une seule région, la bande,
      // haute de 120 au lieu de 170. Il y a moins de système au-dessus, la
      // colonne remonte d'autant. L'axe, lui, ne bouge pas : iOS n'annonce
      // pas la caméra dans cette pose, et la mesure tient.
      WindowRegionsService.regions.value = const WindowRegions(systemStackBottom: 120);
      await _pumpRail(tester, size: const Size(951, 669), rightInset: 84, actions: 1);
      expect(tester.getRect(find.byKey(const ValueKey('action0'))).top, moreOrLessEquals(128, epsilon: 0.5));
      expect(951 - _pill(tester).center.dx, closeTo(48, 0.5));
    });

    testWidgets('une annonce qui manque laisse la mesure en place', (tester) async {
      // Le pli seul : il ne dit rien de la pile ni de l'axe.
      WindowRegionsService.regions.value = const WindowRegions(fold: Rect.fromLTWH(0, 470, 669, 12));
      await _pumpRail(tester, actions: 1);
      expect(669 - _pill(tester).center.dx, closeTo(48, 0.5));
      expect(tester.getRect(find.byKey(const ValueKey('action0'))).top, moreOrLessEquals(172, epsilon: 0.5));
    });

    testWidgets('la place prise au contenu suit l\'axe annoncé', (tester) async {
      WindowRegionsService.regions.value = const WindowRegions(systemAxisFromRight: 60);
      await _pumpRail(tester);
      expect(tester.getRect(find.byKey(const Key('contenu'))).right, lessThanOrEqualTo(_pill(tester).left + 0.5));
    });
  });
}
