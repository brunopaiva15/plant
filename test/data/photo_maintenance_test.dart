import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flora/data/db/database.dart';
import 'package:flora/data/services/photo_maintenance.dart';
import 'package:flora/data/services/photo_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
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
  late Directory photosDir;
  late FloraDatabase db;
  late PhotoMaintenance maintenance;
  final now = DateTime(2026, 6, 1);

  /// Un fichier déjà vieux : le ménage n'épargne que les tout frais.
  Future<File> aged(String name) async {
    final file = File(p.join(photosDir.path, name));
    await file.writeAsString(name);
    await file.setLastModified(DateTime.now().subtract(const Duration(days: 2)));
    return file;
  }

  Future<void> addPhoto(String id, {required String filePath, required String thumbPath, DateTime? deletedAt}) =>
      db.into(db.plantPhotos).insert(PlantPhotosCompanion.insert(
            id: id,
            plantId: 'p1',
            filePath: filePath,
            thumbPath: thumbPath,
            width: 100,
            height: 100,
            takenAt: now,
            createdAt: now,
            deletedAt: Value(deletedAt),
          ));

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    temp = await Directory.systemTemp.createTemp('flora-photos');
    PathProviderPlatform.instance = _FakePaths(temp.path);
    photosDir = await Directory(p.join(temp.path, 'photos')).create(recursive: true);
    db = FloraDatabase(NativeDatabase.memory());
    maintenance = PhotoMaintenance(db, PhotoStorageService());
    await db.into(db.gardens).insert(GardensCompanion.insert(id: 'g1', ownerId: 'u1', name: 'Jardin', createdAt: now, updatedAt: now));
    await db.into(db.plants).insert(PlantsCompanion.insert(id: 'p1', gardenId: 'g1', name: 'Monstera', createdAt: now, updatedAt: now));
  });

  tearDown(() async {
    await db.close();
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  test('les fichiers qu\'aucune ligne ne réclame s\'en vont, les autres restent', () async {
    await addPhoto('ph1', filePath: 'garde.jpg', thumbPath: 'garde_thumb.jpg');
    await db.into(db.locations).insert(LocationsCompanion.insert(
          id: 'l1',
          gardenId: 'g1',
          name: 'Salon',
          icon: '🛋️',
          photoPath: const Value('salon.jpg'),
          thumbPath: const Value('salon_thumb.jpg'),
          createdAt: now,
          updatedAt: now,
        ));
    final garde = await aged('garde.jpg');
    final gardeThumb = await aged('garde_thumb.jpg');
    final salon = await aged('salon.jpg');
    final orphelin = await aged('orphelin.jpg');

    expect(await maintenance.run(), 1);
    expect(garde.existsSync(), isTrue);
    expect(gardeThumb.existsSync(), isTrue);
    expect(salon.existsSync(), isTrue);
    expect(orphelin.existsSync(), isFalse);
  });

  test('une photo supprimée ailleurs laisse partir ses fichiers', () async {
    await addPhoto('ph1', filePath: 'partie.jpg', thumbPath: 'partie_thumb.jpg', deletedAt: now);
    final partie = await aged('partie.jpg');

    expect(await maintenance.run(), 1);
    expect(partie.existsSync(), isFalse);
  });

  test('un import tout frais est épargné : sa ligne n\'existe pas encore', () async {
    final enCours = File(p.join(photosDir.path, 'en-cours.jpg'));
    await enCours.writeAsString('image');

    expect(await maintenance.run(), 0);
    expect(enCours.existsSync(), isTrue);
  });
}
