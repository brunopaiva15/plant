// Le côté machine des captures du magasin : reçoit chaque capture prise par
// integration_test/store_screenshots_test.dart et l'écrit dans le dossier
// donné par STORE_SHOTS (store/shots-fr par défaut). Lancé par
// store/capture_ios.sh.
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final dir = Directory(Platform.environment['STORE_SHOTS'] ?? 'store/shots-fr')..createSync(recursive: true);
  await integrationDriver(
    onScreenshot: (String name, List<int> bytes, [Map<String, Object?>? args]) async {
      File('${dir.path}/$name.png').writeAsBytesSync(bytes);
      stdout.writeln('capture : ${dir.path}/$name.png');
      return true;
    },
  );
}
