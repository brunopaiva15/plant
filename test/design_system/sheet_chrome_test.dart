import 'package:flora/app/native_chrome_observer.dart';
import 'package:flora/core/native_shell.dart';
import 'package:flora/design_system/design_system.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// La chrome d'une feuille plein écran.
///
/// Une page posée dans une feuille cédait ses boutons à UIKit comme les
/// autres — mais la barre d'UIKit est celle de la coquille, et la feuille
/// passe par-dessus : l'observateur l'a effacée, et la page ne peut pas la
/// reprendre depuis le navigateur de la feuille. « Où la poser » s'ouvrait
/// donc sur son contenu nu : ni titre, ni retour, ni croix, ni poignée.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const canal = MethodChannel('ch.vergasta.plant/native_shell');

  /// Ce que la coquille a demandé au natif pour ses barres, dans l'ordre.
  final chromes = <Map<Object?, Object?>>[];

  setUp(() {
    chromes.clear();
    NativeShell.debugForceSupported = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(canal, (call) async {
      if (call.method == 'setChrome') chromes.add(call.arguments as Map<Object?, Object?>);
      return true;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(canal, null);
    NativeShell.debugReset();
  });

  /// La plateforme se pose dans le corps du test : la reposer ailleurs fait
  /// échouer la vérification d'invariants de `flutter_test`.
  Future<void> surIOS(Future<void> Function() corps) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await corps();
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  }

  /// Une page ordinaire, et de quoi ouvrir une feuille dessus.
  Future<void> poser(WidgetTester tester, {required VoidCallback Function(BuildContext) ouvrir}) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildFloraTheme(Brightness.light),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(child: FloraButton(label: 'Ouvrir', onPressed: ouvrir(context))),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('une page de feuille garde sa barre, que le natif ne peut pas lui rendre', (tester) => surIOS(() async {
        await poser(tester, ouvrir: (context) => () => showFloraScrollableFlow<void>(
              context,
              builder: (ctx, controller) => const FloraPage(title: 'Où la poser', child: Text('les places')),
            ));

        expect(find.text('les places'), findsOneWidget);
        expect(find.text('Où la poser'), findsOneWidget, reason: 'le titre, que la barre du système ne porterait pas');
        expect(find.byType(CupertinoNavigationBar), findsOneWidget);
      }));

  testWidgets('elle porte la croix qui referme la feuille', (tester) => surIOS(() async {
        await poser(tester, ouvrir: (context) => () => showFloraScrollableFlow<void>(
              context,
              builder: (ctx, controller) => const FloraPage(title: 'Où la poser', child: Text('les places')),
            ));

        // Rien à dépiler dans la feuille : sans cette croix, elle ne se
        // refermait qu'au glissement.
        final croix = find.byIcon(CupertinoIcons.xmark);
        expect(croix, findsOneWidget);
        await tester.tap(croix);
        await tester.pumpAndSettle();
        expect(find.text('les places'), findsNothing);
        expect(find.text('Ouvrir'), findsOneWidget);
      }));

  testWidgets('la feuille porte sa poignée, et lui fait sa place', (tester) => surIOS(() async {
        await poser(tester, ouvrir: (context) => () => showFloraScrollableFlow<void>(
              context,
              builder: (ctx, controller) => const Scaffold(body: SafeArea(child: Text('le contenu'))),
            ));

        expect(find.byType(SheetHandle), findsOneWidget);
        // Le contenu s'écarte de la poignée par la marge sûre, sans rien
        // savoir d'elle : il commence là où elle finit, pas dessous.
        final poignee = tester.getRect(find.byType(SheetHandle));
        expect(tester.getTopLeft(find.text('le contenu')).dy, greaterThanOrEqualTo(poignee.bottom));
      }));

  /// Ouvrir une pièce du relevé : une feuille de Flutter, posée sur une page
  /// dont la barre est celle d'UIKit.
  ///
  /// La barre du système passe **par-dessus** tout ce que Flutter dessine :
  /// la feuille s'ouvrait coiffée du titre et du retour de la page d'en
  /// dessous, sa poignée cachée et son propre titre lu au travers. Une
  /// surcouche doit donc voiler la chrome — sans l'effacer, puisque la place
  /// qu'elle occupe ne doit pas bouger.
  testWidgets('une feuille ouverte sur une page voile la barre du système', (tester) => surIOS(() async {
        await NativeShell.publish(tabs: const [NativeTab(title: 'Profil', symbol: 'person')], selected: 0);
        await tester.pumpWidget(MaterialApp(
          theme: buildFloraTheme(Brightness.light),
          navigatorObservers: [NativeChromeObserver()],
          home: Builder(
            builder: (accueil) => Scaffold(
              body: Center(
                child: FloraButton(
                  label: 'Ouvrir la page',
                  onPressed: () => Navigator.of(accueil).push(MaterialPageRoute<void>(
                    builder: (_) => Builder(
                      builder: (page) => FloraPage(
                        title: 'Relevé de la maison',
                        child: FloraButton(
                          label: 'Ouvrir la pièce',
                          onPressed: () => showFloraSheet<void>(page, builder: (_) => const Text('Salle Gaming')),
                        ),
                      ),
                    ),
                  )),
                ),
              ),
            ),
          ),
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Ouvrir la page'));
        await tester.pumpAndSettle();
        expect(chromes.last['bar'], isTrue, reason: 'la page poussée a repris la barre du système');

        await tester.tap(find.text('Ouvrir la pièce'));
        await tester.pumpAndSettle();
        expect(find.text('Salle Gaming'), findsOneWidget);
        expect(chromes.last['veil'], isTrue, reason: 'sans voile, la barre du système reste posée sur la feuille');
        expect(chromes.last['bar'], isTrue, reason: 'voiler n\'est pas effacer : la place de la barre ne bouge pas');

        Navigator.of(tester.element(find.text('Salle Gaming'))).pop();
        await tester.pumpAndSettle();
        expect(chromes.last['veil'], isFalse, reason: 'la feuille refermée rend la barre');
      }));

  testWidgets('hors d\'une feuille, la page cède toujours sa barre au système', (tester) => surIOS(() async {
        await tester.pumpWidget(MaterialApp(
          theme: buildFloraTheme(Brightness.light),
          home: const FloraPage(title: 'Relevé de la maison', child: Text('les pièces')),
        ));
        await tester.pumpAndSettle();

        expect(find.text('les pièces'), findsOneWidget);
        expect(find.byType(CupertinoNavigationBar), findsNothing, reason: 'UIKit la dessine, et deux barres seraient une faute');
        expect(find.byType(NativeActions), findsOneWidget);
      }));
}
