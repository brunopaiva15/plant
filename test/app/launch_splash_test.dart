import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flora/app/launch_splash.dart';
import 'package:flora/core/native_shell.dart';
import 'package:flora/design_system/design_system.dart';

/// L'animation d'ouverture se retire d'elle-même, rend la main au premier
/// cadre, et respecte « réduire les animations ».
void main() {
  Future<void> pumpSplash(WidgetTester tester, {bool reduceMotion = false}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFloraTheme(Brightness.light),
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduceMotion),
          child: const LaunchSplash(child: _Compteur()),
        ),
      ),
    );
    // Les images se décodent pour de vrai : il faut laisser le temps courir.
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump();
  }

  Finder logo() => find.byWidgetPredicate((w) => w is Image && w.image == const AssetImage('assets/splash/logo.webp'));

  testWidgets('le logo couvre l’application puis se retire', (tester) async {
    await pumpSplash(tester);
    expect(logo(), findsOneWidget);
    expect(find.text('app'), findsOneWidget);
    expect(tester.binding.sendFramesToEngine, isTrue);

    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pump();
    expect(logo(), findsNothing);
    expect(find.text('app'), findsOneWidget);
  });

  testWidgets('l’œil se ferme pendant le clin d’œil', (tester) async {
    await pumpSplash(tester);
    // 400 ms : l'œil est fermé en arc.
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.byWidgetPredicate((w) => w is Image && w.image == const AssetImage('assets/splash/clin_100.webp')),
      findsOneWidget,
    );
  });

  testWidgets('un toucher saute le clin d’œil', (tester) async {
    await pumpSplash(tester);
    await tester.tap(logo(), warnIfMissed: false);
    // Le contrôleur repart de l'ouverture : son horloge démarre au cadre
    // suivant.
    await tester.pump();
    // L'ouverture seule dure une seconde : sans le toucher, on serait encore
    // au clin d'œil, et loin de la fin.
    await tester.pump(const Duration(milliseconds: 1020));
    await tester.pump();
    expect(find.byType(CustomPaint).evaluate().where((e) => e.widget is CustomPaint && (e.widget as CustomPaint).painter != null), isEmpty);
    expect(logo(), findsNothing);
  });

  testWidgets('les barres natives reviennent en fondu avec l’application', (tester) async {
    const canal = MethodChannel('ch.vergasta.plant/native_shell');
    final chromes = <Map<Object?, Object?>>[];
    NativeShell.debugForceSupported = true;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(canal, (call) async {
      if (call.method == 'setChrome') chromes.add(call.arguments as Map<Object?, Object?>);
      return true;
    });
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(canal, null);
      NativeShell.debugReset();
    });

    await pumpSplash(tester);
    expect(chromes.last['veil'], isTrue, reason: 'la barre d’onglets paraîtrait sur l’écran de lancement');
    // 950 ms : la fenêtre s'ouvre, l'application n'y a pas fini de paraître.
    await tester.pump(const Duration(milliseconds: 950));
    expect(chromes.last['veil'], isTrue, reason: 'encore voilées pendant que la fenêtre s’ouvre');
    // 1100 ms : l'application a paru, l'ouverture n'est pas finie.
    await tester.pump(const Duration(milliseconds: 150));
    expect(logo(), findsNothing);
    expect(chromes.last['veil'], isFalse, reason: 'rendues avec l’application, pas 600 ms après');
    expect(chromes.last['fade'], 250, reason: 'en fondu, comme l’application');
    final rendues = chromes.length;
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    expect(chromes.length, rendues, reason: 'la fin de l’ouverture ne redit rien');
  });

  testWidgets('réduire les animations : les barres reviennent avec le fondu', (tester) async {
    const canal = MethodChannel('ch.vergasta.plant/native_shell');
    final chromes = <Map<Object?, Object?>>[];
    NativeShell.debugForceSupported = true;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(canal, (call) async {
      if (call.method == 'setChrome') chromes.add(call.arguments as Map<Object?, Object?>);
      return true;
    });
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(canal, null);
      NativeShell.debugReset();
    });

    await pumpSplash(tester, reduceMotion: true);
    await tester.pump(const Duration(milliseconds: 250));
    expect(chromes.last['veil'], isTrue);
    await tester.pump(const Duration(milliseconds: 100));
    expect(chromes.last['veil'], isFalse, reason: 'le fondu du pot a commencé');
    expect(chromes.last['fade'], 250);
  });

  testWidgets('l’application reste la même du premier au dernier cadre', (tester) async {
    await pumpSplash(tester);
    final avant = tester.state(find.byType(_Compteur));
    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pump();
    expect(logo(), findsNothing);
    expect(identical(tester.state(find.byType(_Compteur)), avant), isTrue,
        reason: 'la fin de l’ouverture ne doit pas reconstruire l’application');
  });

  testWidgets('réduire les animations : ni clin d’œil ni zoom, un fondu', (tester) async {
    await pumpSplash(tester, reduceMotion: true);
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.getRect(logo()).size, const Size.square(LaunchSplash.logoSize));
    expect(
      find.byWidgetPredicate((w) => w is Image && (w.image as AssetImage).assetName.contains('clin_')),
      findsNothing,
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(logo(), findsNothing);
  });
}

/// Une application qui garde un état : si l'ouverture la reconstruisait, son
/// état changerait d'identité.
class _Compteur extends StatefulWidget {
  const _Compteur();

  @override
  State<_Compteur> createState() => _CompteurState();
}

class _CompteurState extends State<_Compteur> {
  @override
  Widget build(BuildContext context) => const Text('app');
}
