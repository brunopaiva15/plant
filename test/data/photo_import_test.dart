import 'dart:io';

import 'package:flora/data/services/photo_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Redirige les dossiers d'application vers un répertoire temporaire.
class _FakePaths extends PathProviderPlatform with MockPlatformInterfaceMixin {
  _FakePaths(this.root);

  final String root;

  @override
  Future<String?> getApplicationDocumentsPath() async => root;

  @override
  Future<String?> getTemporaryPath() async => root;
}

void main() {
  late Directory temp;
  late PhotoStorageService photos;

  /// Une image comme en sort d'un appareil : datée, géolocalisée, trop grande.
  Future<File> source({String? takenAt, bool gps = true}) async {
    final image = img.Image(width: 3000, height: 2000);
    img.fill(image, color: img.ColorRgb8(60, 120, 60));
    if (takenAt != null) image.exif.exifIfd['DateTimeOriginal'] = takenAt;
    if (gps) image.exif.gpsIfd.gpsLatitudeRef = 'N';
    final file = File(p.join(temp.path, 'source.jpg'));
    await file.writeAsBytes(img.encodeJpg(image));
    return file;
  }

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    temp = await Directory.systemTemp.createTemp('flora-import');
    PathProviderPlatform.instance = _FakePaths(temp.path);
    photos = PhotoStorageService();
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  test('la date de prise de vue vient de l\'EXIF', () async {
    final stored = await photos.importFile(await source(takenAt: '2024:05:12 09:31:22'));
    expect(stored.takenAt, DateTime(2024, 5, 12, 9, 31, 22));
  });

  test('sans EXIF, pas de date : l\'appelant prendra l\'heure courante', () async {
    expect((await photos.importFile(await source())).takenAt, isNull);
  });

  test('une date absurde est écartée plutôt que crue', () async {
    expect((await photos.importFile(await source(takenAt: '1970:01:01 00:00:00'))).takenAt, isNull);
    expect((await photos.importFile(await source(takenAt: 'pas une date du tout'))).takenAt, isNull);
  });

  test('les coordonnées GPS ne suivent pas la photo, la date si', () async {
    final stored = await photos.importFile(await source(takenAt: '2024:05:12 09:31:22'));
    final kept = img.decodeImage(await File(await photos.absolutePath(stored.filePath)).readAsBytes())!;
    expect(kept.exif.gpsIfd.isEmpty, isTrue, reason: 'le jardin de quelqu\'un n\'a pas à dire où il habite');
    expect(kept.exif.exifIfd['DateTimeOriginal']?.toString(), '2024:05:12 09:31:22');
    // Redimensionnée au passage, avec sa miniature.
    expect(stored.width, 2048);
    expect(kept.width, 2048);
    expect(File(await photos.absolutePath(stored.thumbPath)).existsSync(), isTrue);
  });
}
