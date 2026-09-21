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

  setUp(() {
    NativeShell.debugForceSupported = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(canal, (call) async => true);
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
