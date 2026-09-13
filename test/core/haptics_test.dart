import 'package:flora/core/haptics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sur iPhone, les retours qui racontent quelque chose passent par Core
/// Haptics ; partout ailleurs, et dès que le natif ne répond pas, c'est le
/// retour du système d'avant. Le test vérifie l'aiguillage, pas la sensation.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(Haptics.channelName);
  final patterns = <String>[];
  final system = <String>[];

  void native(Object? Function(MethodCall call)? handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      handler == null
          ? null
          : (call) async {
              patterns.add(call.arguments as String);
              return handler(call);
            },
    );
  }

  setUp(() {
    patterns.clear();
    system.clear();
    Haptics.debugUseChannel(null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') system.add(call.arguments as String);
      return null;
    });
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    native(null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null);
  });

  test('sur iPhone, la goutte, le roulement et le coup sourd sont des motifs natifs', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    native((_) => true);
    await Haptics.drop();
    await Haptics.success();
    await Haptics.warning();
    expect(patterns, ['drop', 'success', 'warning']);
    expect(system, isEmpty);
  });

  test('la sélection et le tap restent ceux du système', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    native((_) => true);
    await Haptics.selection();
    await Haptics.light();
    expect(patterns, isEmpty);
    expect(system, ['HapticFeedbackType.selectionClick', 'HapticFeedbackType.lightImpact']);
  });

  test('sans moteur, le repli du système joue, et on ne redemande plus', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    native((_) => false);
    await Haptics.drop();
    await Haptics.warning();
    expect(patterns, ['drop'], reason: 'le natif a dit non une fois, cela suffit');
    expect(system, ['HapticFeedbackType.mediumImpact', 'HapticFeedbackType.heavyImpact']);
  });

  test('sans canal natif du tout, le repli du système joue', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await Haptics.success();
    expect(system, ['HapticFeedbackType.mediumImpact']);
  });

  test('sur Android, le natif n\'est même pas sollicité', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    native((_) => true);
    await Haptics.drop();
    expect(patterns, isEmpty);
    expect(system, ['HapticFeedbackType.mediumImpact']);
  });
}
