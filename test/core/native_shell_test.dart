import 'package:flora/core/native_shell.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// L'ordre dans lequel la coquille parle au natif.
///
/// Ce n'est pas de la coquetterie : masquer la barre après que la page
/// ouverte y a posé ses boutons les efface, et la fiche se retrouve nue. Un
/// canal de méthode livre dans l'ordre où on lui confie, encore faut-il ne
/// rien attendre entre deux envois.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const canal = MethodChannel('ch.vergasta.plant/native_shell');
  final appels = <String>[];

  setUp(() {
    appels.clear();
    NativeShell.debugForceSupported = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(canal, (call) async {
      appels.add(call.method);
      return true;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(canal, null);
    NativeShell.debugReset();
  });

  test('une page qui s\'ouvre puis réclame la barre la garde', () async {
    // La coquille se déclare, puis une page se pose dessus, puis elle
    // réclame la barre et publie ses boutons — l'ordre d'un vrai push.
    await NativeShell.publish(tabs: const [NativeTab(title: 'A', symbol: 'sun.max')], selected: 0);
    NativeShell.setOverlay(pages: 1, veils: 0);
    NativeShell.requestBar();
    await NativeShell.publishActions(
      actions: const [NativeAction(id: 'R0', symbol: 'heart', title: 'Favori')],
    );
    await Future<void>.delayed(Duration.zero);

    // Le dernier mot sur la chrome doit être celui qui la rend, pas celui
    // qui l'efface : sinon la fiche se retrouve sans aucun bouton.
    final chromes = [for (final (i, m) in appels.indexed) if (m == 'setChrome') i];
    final dernieresActions = appels.lastIndexOf('setActions');
    expect(chromes.length, greaterThanOrEqualTo(2), reason: 'la barre doit être masquée puis rendue');
    expect(chromes.last, lessThan(dernieresActions), reason: 'le masquage arrive après les boutons');
  });
}
