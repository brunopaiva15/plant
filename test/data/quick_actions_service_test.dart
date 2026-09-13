import 'package:flora/data/services/quick_actions_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Le service Dart n'est qu'un traducteur : il pose les raccourcis, rend
/// celui qui a lancé l'application, et relaie celui qui arrive en route.
/// Sans natif, rien ne casse.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(QuickActionsService.channelName);
  final calls = <MethodCall>[];

  void native(Object? Function(MethodCall call)? handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      handler == null
          ? null
          : (call) async {
              calls.add(call);
              return handler(call);
            },
    );
  }

  setUp(calls.clear);
  tearDown(() => native(null));

  test('pose les raccourcis avec leur type, leur libellé et leur symbole', () async {
    native((_) => null);
    await QuickActionsService().setItems(const [QuickAction(type: 'add', title: 'Ajouter une plante', icon: 'plus')]);
    expect(calls.single.method, 'setItems');
    expect(calls.single.arguments, [
      {'type': 'add', 'title': 'Ajouter une plante', 'icon': 'plus'},
    ]);
  });

  test('rend le raccourci qui a lancé l\'application, et rien quand il n\'y en a pas', () async {
    native((call) => 'scan');
    expect(await QuickActionsService().launchAction(), 'scan');
    native((call) => null);
    expect(await QuickActionsService().launchAction(), isNull);
    native((call) => '');
    expect(await QuickActionsService().launchAction(), isNull);
  });

  test('relaie le raccourci choisi pendant que l\'application tourne', () async {
    final received = <String>[];
    QuickActionsService().onAction = received.add;
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
      QuickActionsService.channelName,
      const StandardMethodCodec().encodeMethodCall(const MethodCall('perform', 'finder')),
      (_) {},
    );
    expect(received, ['finder']);
  });

  test('sans natif, chaque appel se résout sans rien faire', () async {
    final service = QuickActionsService();
    await service.setItems(const []);
    expect(await service.launchAction(), isNull);
  });
}
