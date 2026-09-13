import 'package:flora/app/quick_actions.dart';
import 'package:flora/app/router.dart';
import 'package:flora/data/services/quick_actions_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_smoke_test.dart' as harness;

/// Les raccourcis de l'icône : posés dans la langue de l'interface dès que
/// la coquille est là, et exécutés qu'ils aient lancé l'application ou
/// qu'ils arrivent pendant qu'elle tourne.
void main() {
  const channel = MethodChannel(QuickActionsService.channelName);
  final calls = <MethodCall>[];
  String? launch;

  setUp(() {
    calls.clear();
    launch = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return call.method == 'launchAction' ? launch : null;
    });
  });
  tearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));

  testWidgets('la coquille pose trois raccourcis, dans la langue de l\'interface', (tester) async {
    final container = await harness.boot(tester);
    await harness.pumpApp(tester, container);

    final set = calls.where((c) => c.method == 'setItems').map((c) => c.arguments as List).toList();
    expect(set, hasLength(1), reason: 'une seule fois tant que la langue ne change pas');
    expect(set.single.map((i) => i['title']), ['Ajouter une plante', 'Scanner une étiquette', 'Trouver une plante']);
    expect(set.single.map((i) => i['type']), [QuickActions.add, QuickActions.scan, QuickActions.finder]);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('le raccourci qui a lancé l\'application s\'ouvre sur l\'accueil', (tester) async {
    launch = QuickActions.finder;
    final container = await harness.boot(tester);
    await harness.pumpApp(tester, container);

    expect(container.read(routerProvider).state.uri.path, Routes.finder);
    expect(container.read(pendingQuickActionProvider), isNull, reason: 'consommé, il ne se rejoue pas');
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('un raccourci choisi en route s\'exécute aussitôt', (tester) async {
    final container = await harness.boot(tester);
    await harness.pumpApp(tester, container);
    expect(container.read(routerProvider).state.uri.path, Routes.today);

    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
      QuickActionsService.channelName,
      const StandardMethodCodec().encodeMethodCall(const MethodCall('perform', QuickActions.finder)),
      (_) {},
    );
    await harness.settle(tester);
    expect(container.read(routerProvider).state.uri.path, Routes.finder);
    await tester.pump(const Duration(seconds: 6));
  });
}
