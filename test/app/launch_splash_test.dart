import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flora/app/launch_splash.dart';
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
          child: const LaunchSplash(child: Text('app')),
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

    await tester.pump(const Duration(milliseconds: 1500));
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

  testWidgets('un toucher passe directement au zoom', (tester) async {
    await pumpSplash(tester);
    await tester.tap(logo(), warnIfMissed: false);
    // Le contrôleur repart du zoom : son horloge démarre au cadre suivant.
    await tester.pump();
    // Le zoom seul dure 500 ms : sans le toucher, le logo serait encore là.
    await tester.pump(const Duration(milliseconds: 520));
    await tester.pump();
    expect(logo(), findsNothing);
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
