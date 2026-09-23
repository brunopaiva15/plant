import 'package:flora/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Le recentrage du contenu sur les écrans larges, vérifié dans une vraie
/// page — pas dans un montage de laboratoire.
///
/// Ce chemin ne s'active qu'au-delà de 700 points : sur téléphone il ne doit
/// rien changer du tout, et sur tablette il doit rendre le surplus en marges
/// sans rien casser ni rien faire disparaître.

Future<void> _pumpPage(WidgetTester tester, Size size, {EdgeInsets marges = EdgeInsets.zero}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: buildFloraTheme(Brightness.light),
      home: MediaQuery(
        data: MediaQueryData(size: size, padding: marges, viewPadding: marges),
        child: LargeTitlePage(
          title: 'Mes plantes',
          slivers: [
            SliverList.list(
              children: [for (var i = 0; i < 8; i++) FloraCard(child: Text('carte $i'))],
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('le recentrage sur écran large', () {
    testWidgets('ne touche à rien sur un téléphone', (tester) async {
      await _pumpPage(tester, const Size(390, 844));
      expect(tester.takeException(), isNull);
      expect(readableInset(tester.element(find.text('carte 0'))), 0);
      // La carte occupe la largeur, marges de page comprises.
      expect(tester.getRect(find.byType(FloraCard).first).width, greaterThan(300));
    });

    testWidgets('rend le surplus en marges sur une tablette', (tester) async {
      await _pumpPage(tester, const Size(1180, 820));
      expect(tester.takeException(), isNull);
      final card = tester.getRect(find.byType(FloraCard).first);
      // Le contenu ne traverse plus l'écran…
      expect(card.width, lessThanOrEqualTo(700));
      // … et il est centré, pas collé au bord gauche.
      expect(card.center.dx, closeTo(1180 / 2, 1));
    });

    // Sur un pliable, la bande de la caméra passe sur un bord — 84 points
    // mesurés dans Xcode 27.1 —, et rien ne dit qu'elle soit symétrique. Le
    // contenu doit s'en écarter : sans ça, une liste ou un sélecteur de
    // section court dessous, et on lit « Calen… » sous l'heure du système.
    testWidgets('il s\'écarte de la bande que le système réserve à droite', (tester) async {
      await _pumpPage(tester, const Size(466, 678), marges: const EdgeInsets.only(right: 84, top: 82, bottom: 34));
      expect(tester.takeException(), isNull);
      expect(tester.getRect(find.byType(FloraCard).first).right, lessThanOrEqualTo(466 - 84 + 0.5));
    });

    testWidgets('et de la même bande passée à gauche', (tester) async {
      await _pumpPage(tester, const Size(466, 678), marges: const EdgeInsets.only(left: 84, bottom: 34));
      expect(tester.getRect(find.byType(FloraCard).first).left, greaterThanOrEqualTo(84 - 0.5));
    });

    testWidgets('le contenu reste présent et défilable', (tester) async {
      await _pumpPage(tester, const Size(1180, 820));
      // Le groupe de slivers ne doit rien avaler au passage.
      expect(find.text('carte 0'), findsOneWidget);
      expect(find.text('Mes plantes'), findsWidgets);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('carte 7'), findsOneWidget);
    });
  });

  _testsDeLaRecherche();
  _testsDuToast();
  group('les pages secondaires', _testsDesPagesSecondaires);
  group('les feuilles', _testsDesFeuilles);
}

/// Le champ de recherche vit dans la barre, qui garde toute la largeur : il
/// n'est pas couvert par la marge des contenus, et il lui faut la sienne.
Future<void> _pumpAvecRecherche(
  WidgetTester tester,
  Size size,
  EdgeInsets marges, {
  TargetPlatform platform = TargetPlatform.iOS,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      // La barre d'iOS et celle de Material ne posent pas leur `bottom` de la
      // même façon : c'est la première qui laissait passer le champ.
      theme: buildFloraTheme(Brightness.light).copyWith(platform: platform),
      home: MediaQuery(
        data: MediaQueryData(size: size, padding: marges, viewPadding: marges),
        child: LargeTitlePage(
          title: 'Plantes',
          searchField: const TextField(key: Key('recherche')),
          slivers: [
            SliverList.list(children: [for (var i = 0; i < 4; i++) FloraCard(child: Text('carte $i'))]),
          ],
        ),
      ),
    ),
  );
  await tester.pump();
}

void _testsDeLaRecherche() {
  group('le champ de recherche', () {
    testWidgets('s\'arrête avant la bande du système', (tester) async {
      // Un iPhone Duo fermé : la bande de l'heure et de la caméra prend 84
      // points à droite. Le champ passait dessous.
      await _pumpAvecRecherche(tester, const Size(466, 678), const EdgeInsets.only(right: 84));
      expect(tester.takeException(), isNull);
      expect(tester.getRect(find.byKey(const Key('recherche'))).right, lessThanOrEqualTo(466 - 84));
    });

    testWidgets('garde sa marge ordinaire sans bande', (tester) async {
      await _pumpAvecRecherche(tester, const Size(390, 844), EdgeInsets.zero);
      final champ = tester.getRect(find.byKey(const Key('recherche')));
      expect(champ.left, moreOrLessEquals(Space.md, epsilon: 0.5));
      expect(390 - champ.right, moreOrLessEquals(Space.md, epsilon: 0.5));
    });

    testWidgets('et s\'arrête avant la bande sur Material aussi', (tester) async {
      await _pumpAvecRecherche(
        tester,
        const Size(466, 678),
        const EdgeInsets.only(right: 84),
        platform: TargetPlatform.android,
      );
      expect(tester.getRect(find.byKey(const Key('recherche'))).right, lessThanOrEqualTo(466 - 84));
    });
  });
}

/// Le toast évite le menu, où qu'il soit — et il ne doit pas compter le bas
/// de l'écran deux fois là où la barre est dans la marge sûre.
void _testsDuToast() {
  testWidgets('le toast se pose au-dessus de la pilule', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFloraTheme(Brightness.light),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            padding: EdgeInsets.only(bottom: 34),
            viewPadding: EdgeInsets.only(bottom: 34),
          ),
          child: ProviderScope(
            child: ToastHost(child: const SizedBox.expand(key: Key('fond'))),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}

/// La bande du système sur les pages secondaires — celles de `FloraPage`.
///
/// C'est la classe de défaut qui s'est répétée : une page qui pose sa marge à
/// la main oublie ce que le système réserve sur les bords, et son contenu
/// passe sous la bande de la caméra d'un pliable. Trente-six pages en
/// dépendaient.
void _testsDesPagesSecondaires() {
  Future<void> pump(WidgetTester tester, Size size, EdgeInsets marges) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFloraTheme(Brightness.light).copyWith(platform: TargetPlatform.iOS),
        home: MediaQuery(
          data: MediaQueryData(size: size, padding: marges, viewPadding: marges),
          child: FloraPage(
            title: 'Réglages',
            bottom: const SizedBox(key: Key('barre'), height: 60, child: ColoredBox(color: Color(0xFF00FF00))),
            child: Column(children: [for (var i = 0; i < 3; i++) FloraCard(key: ValueKey('c$i'), child: Text('carte $i'))]),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('le contenu s\'arrête avant la bande du système, une fois', (tester) async {
    await pump(tester, const Size(466, 678), const EdgeInsets.only(right: 84));
    expect(tester.takeException(), isNull);
    // « Une fois » n'est pas une coquetterie : le `SafeArea` du corps retire
    // déjà la bande, et la retirer aussi à la main la comptait deux fois —
    // 188 points de marge au lieu de 104, mesuré. Le test fixe donc la cote
    // exacte, pas seulement un maximum.
    expect(
      466 - tester.getRect(find.byKey(const ValueKey('c0'))).right,
      moreOrLessEquals(84 + Space.page, epsilon: 0.5),
    );
  });

  testWidgets('et de la bande passée à gauche, une fois aussi', (tester) async {
    await pump(tester, const Size(678, 466), const EdgeInsets.only(left: 84));
    expect(
      tester.getRect(find.byKey(const ValueKey('c0'))).left,
      moreOrLessEquals(84 + Space.page, epsilon: 0.5),
    );
  });

  testWidgets('sans bande, rien ne change', (tester) async {
    await pump(tester, const Size(390, 844), EdgeInsets.zero);
    final carte = tester.getRect(find.byKey(const ValueKey('c0')));
    expect(carte.left, moreOrLessEquals(Space.page, epsilon: 0.5));
  });
}

/// Les feuilles s'écartent de la bande du système — leur surface, pas
/// seulement leur contenu.
///
/// `CupertinoSheetRoute` remplace la marge de son contenu par celle de sa
/// poignée : tout ce que le système réservait sur les côtés disparaissait, et
/// le fond de la feuille passait sous l'heure. La cote est fixée exactement,
/// pas plafonnée : une marge prise deux fois passerait un plafond sans rien
/// dire.
void _testsDesFeuilles() {
  testWidgets('la surface s\'arrête avant la bande, une fois', (tester) async {
    const size = Size(466, 678);
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.view.devicePixelRatio = 3;
    tester.view.padding = const FakeViewPadding(right: 84 * 3);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildFloraTheme(Brightness.light),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FloraButton(
                label: 'ouvrir',
                onPressed: () => showFloraSheet<void>(
                  context,
                  builder: (_) => const SizedBox(key: Key('dedans'), height: 120, width: double.infinity),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(const Key('dedans'))).right, moreOrLessEquals(466 - 84, epsilon: 0.5));
  });

  // Le contenu s'arrête avant la bande, le fond non : une feuille qui
  // s'arrêtait là laissait voir la page d'en dessous par la bande.
  testWidgets('le fond d\'une feuille iOS passe sous la bande, son contenu non', (tester) async {
    const size = Size(466, 678);
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.view.devicePixelRatio = 3;
    tester.view.padding = const FakeViewPadding(right: 84 * 3);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildFloraTheme(Brightness.light).copyWith(platform: TargetPlatform.iOS),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FloraButton(
                label: 'ouvrir',
                onPressed: () => showFloraFlow<void>(
                  context,
                  builder: (_) => const SizedBox.expand(key: Key('dedans')),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
    final contenu = tester.getRect(find.byKey(const Key('dedans')));
    expect(contenu.right, moreOrLessEquals(466 - 84, epsilon: 0.5));
    final fond = find.ancestor(
      of: find.byKey(const Key('dedans')),
      matching: find.byWidgetPredicate((w) => w is ColoredBox && w.color == FloraColors.light.canvas),
    );
    expect(tester.getRect(fond.first).right, moreOrLessEquals(466, epsilon: 0.5));
  });
}
