import 'package:flora/app/native_chrome_observer.dart';
import 'package:flora/core/native_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ce que l'observateur des routes dit de la chrome native.
///
/// Le cas qui a coûté cher : au premier lancement, l'introduction est la page
/// du bas, et `context.go` pose la coquille **par-dessus** avant de retirer
/// l'introduction d'en dessous. Une profondeur comptée à l'aveugle restait
/// alors à 1 pour toujours, et l'application n'avait plus ni barre d'onglets
/// ni barre du haut jusqu'au lancement suivant.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const canal = MethodChannel('ch.vergasta.plant/native_shell');
  final chromes = <Map<Object?, Object?>>[];

  MaterialPageRoute<void> page() => MaterialPageRoute<void>(builder: (_) => const SizedBox());

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

  const onglets = [NativeTab(title: 'Aujourd’hui', symbol: 'sun.max')];

  test("l'introduction n'a ni barre d'onglets ni barre du haut", () async {
    final observateur = NativeChromeObserver();
    observateur.didPush(page(), null);
    await Future<void>.delayed(Duration.zero);

    expect(chromes.last['bar'], isFalse);
    expect(chromes.last['tabs'], isFalse);
  });

  test('la coquille qui remplace l’introduction retrouve ses barres', () async {
    final observateur = NativeChromeObserver();
    final introduction = page();
    observateur.didPush(introduction, null);

    // Ce que fait `context.go(Routes.today)` : la coquille se pose sur
    // l'introduction, puis l'introduction s'en va — et elle n'a rien en
    // dessous, ce qui est précisément le cas qu'on rate à compter naïvement.
    final coquille = page();
    observateur.didPush(coquille, introduction);
    observateur.didRemove(introduction, null);
    expect(NativeShell.overlayDepth, 0);

    await NativeShell.publish(tabs: onglets, selected: 0);
    await Future<void>.delayed(Duration.zero);

    expect(chromes.last['bar'], isTrue, reason: 'la barre du haut revient');
    expect(chromes.last['tabs'], isTrue, reason: 'la barre d’onglets revient');
  });

  test('une page posée sur la coquille efface la barre d’onglets', () async {
    final observateur = NativeChromeObserver();
    final coquille = page();
    observateur.didPush(coquille, null);
    await NativeShell.publish(tabs: onglets, selected: 0);

    final fiche = page();
    observateur.didPush(fiche, coquille);
    await Future<void>.delayed(Duration.zero);
    expect(NativeShell.overlayDepth, 1);
    expect(chromes.last['tabs'], isFalse);

    observateur.didPop(fiche, coquille);
    await Future<void>.delayed(Duration.zero);
    expect(NativeShell.overlayDepth, 0);
    expect(chromes.last['tabs'], isTrue);
  });

  test('une surcouche voile la chrome sans compter pour une page', () async {
    final observateur = NativeChromeObserver();
    final coquille = page();
    observateur.didPush(coquille, null);
    await NativeShell.publish(tabs: onglets, selected: 0);

    final menu = RawDialogRoute<void>(pageBuilder: (_, _, _) => const SizedBox());
    observateur.didPush(menu, coquille);
    await Future<void>.delayed(Duration.zero);
    expect(NativeShell.overlayDepth, 0, reason: 'un menu ne couvre pas la coquille');
    expect(chromes.last['veil'], isTrue);

    observateur.didRemove(menu, coquille);
    await Future<void>.delayed(Duration.zero);
    expect(chromes.last['veil'], isFalse);
  });
}
