import 'package:flora/app/providers.dart';
import 'package:flora/app/router.dart';
import 'package:flora/core/native_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_smoke_test.dart';

/// Ce que le natif reçoit vraiment, routeur réel à l'appui.
///
/// L'observateur des routes a été mis en défaut deux fois de suite, et jamais
/// par la mécanique qu'on lui prêtait. Les tests à la main ne l'avaient pas
/// vu : go_router renvoie aux observateurs de la racine ce qui se passe dans
/// les navigateurs de branche, et chaque page d'onglet y arrive avec
/// `previousRoute` à `null` — comptée comme une page posée sur la coquille,
/// elle effaçait les deux barres dès le premier écran. Ces cas-ci montent
/// l'application entière et lisent ce qui part sur le canal.
void main() {
  const canal = MethodChannel('ch.vergasta.plant/native_shell');
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

  testWidgets('la coquille ouverte au lancement a ses deux barres', (tester) async {
    final container = await boot(tester);
    await pumpApp(tester, container);

    expect(NativeShell.overlayDepth, 0, reason: 'une page d’onglet n’est pas posée sur la coquille');
    expect(chromes.last['tabs'], isTrue, reason: 'la barre d’onglets manque au lancement');
    expect(chromes.last['bar'], isTrue, reason: 'la barre du haut manque au lancement');
  });

  testWidgets('au sortir de l’introduction, la coquille les a aussi', (tester) async {
    final container = await boot(tester, onboardingDone: false);
    await pumpApp(tester, container, settleAfter: false);
    await step(tester);
    await tester.tap(find.text('Passer'));
    await step(tester);
    await skipLater(tester);
    await skipLater(tester);
    await tester.enterText(find.byType(EditableText), 'Bruno');
    await skipLater(tester);
    await tester.tap(find.text('Non merci'));
    await settle(tester);

    expect(container.read(preferencesProvider).onboardingDone, isTrue);
    expect(NativeShell.overlayDepth, 0, reason: 'l’introduction est partie, elle ne couvre plus rien');
    expect(chromes.last['tabs'], isTrue, reason: 'la barre d’onglets ne revient pas après l’introduction');
    expect(chromes.last['bar'], isTrue);
  });

  testWidgets('une page posée sur la coquille lui prend la barre d’onglets', (tester) async {
    final container = await boot(tester);
    await pumpApp(tester, container);

    container.read(routerProvider).push(Routes.about);
    await settle(tester);
    expect(NativeShell.overlayDepth, 1);
    expect(chromes.last['tabs'], isFalse, reason: 'la barre d’onglets reste sous la page ouverte');

    container.read(routerProvider).pop();
    await settle(tester);
    expect(NativeShell.overlayDepth, 0);
    expect(chromes.last['tabs'], isTrue, reason: 'la barre d’onglets ne revient pas au retour');
  });
}
