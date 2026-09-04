import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flora/core/utils/file_kinds.dart';
import 'package:flora/data/db/database.dart';
import 'package:flora/data/repositories/photo_repository_impl.dart';
import 'package:flora/data/repositories/plant_repository_impl.dart';
import 'package:flora/domain/repositories/repositories.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FileKinds', () {
    test('reconnaît les familles par extension', () {
      expect(FileKinds.of('facture.pdf'), FileKind.pdf);
      expect(FileKinds.of('photo.HEIC'), FileKind.image);
      expect(FileKinds.of('notes.docx'), FileKind.document);
      expect(FileKinds.of('analyse.csv'), FileKind.spreadsheet);
      expect(FileKinds.of('sauvegarde.zip'), FileKind.archive);
      expect(FileKinds.of('sansextension'), FileKind.other);
    });

    test('le type MIME complète l\'extension', () {
      expect(FileKinds.of('fichier', 'application/pdf'), FileKind.pdf);
      expect(FileKinds.of('fichier', 'image/png'), FileKind.image);
    });

    test('taille lisible', () {
      expect(FileKinds.size(null), '');
      expect(FileKinds.size(0), '');
      expect(FileKinds.size(512), '512 o');
      expect(FileKinds.size(2048), '2 Ko');
      expect(FileKinds.size(1572864), '1,5 Mo');
    });
  });

  group('photos', () {
    late FloraDatabase db;
    late PhotoRepository photos;
    late PlantRepository plants;

    setUp(() async {
      db = FloraDatabase(NativeDatabase.memory());
      await db.into(db.gardens).insert(GardensCompanion.insert(id: 'g1', ownerId: 'u1', name: 'Jardin', createdAt: DateTime.now(), updatedAt: DateTime.now()));
      photos = DriftPhotoRepository(db);
      plants = DriftPlantRepository(db, 'g1');
    });

    tearDown(() => db.close());

    test('une photo distante n\'a pas de fichier local et devient principale', () async {
      final plant = await plants.create(const NewPlant(name: 'Monstera'));
      final photo = await photos.addFromUrl(plantId: plant.id, url: ' https://exemple.test/feuille.jpg ', label: ' Feuille ');

      expect(photo.isRemote, isTrue);
      expect(photo.remoteUrl, 'https://exemple.test/feuille.jpg');
      expect(photo.filePath, isEmpty);
      expect(photo.label, 'Feuille');
      expect((await plants.getPlant(plant.id))!.primaryPhotoId, photo.id, reason: 'la première photo devient la principale');
    });

    test('le titre d\'une photo se modifie et s\'efface', () async {
      final plant = await plants.create(const NewPlant(name: 'Pilea'));
      final photo = await photos.addFromUrl(plantId: plant.id, url: 'https://exemple.test/a.jpg');
      expect(photo.label, isNull);

      await photos.setLabel(photo.id, '  Avant rempotage  ');
      var stored = (await photos.watchByPlant(plant.id).first).single;
      expect(stored.label, 'Avant rempotage');

      await photos.setLabel(photo.id, '   ');
      stored = (await photos.watchByPlant(plant.id).first).single;
      expect(stored.label, isNull, reason: 'un titre vide efface le titre');
    });

    test('la photo principale se change', () async {
      final plant = await plants.create(const NewPlant(name: 'Hoya'));
      final first = await photos.addFromUrl(plantId: plant.id, url: 'https://exemple.test/1.jpg');
      final second = await photos.addFromUrl(plantId: plant.id, url: 'https://exemple.test/2.jpg');
      expect((await plants.getPlant(plant.id))!.primaryPhotoId, first.id);

      await photos.setPrimary(plant.id, second.id);
      expect((await plants.getPlant(plant.id))!.primaryPhotoId, second.id);
    });

    test('chaque ajout est mis en file de synchronisation', () async {
      final plant = await plants.create(const NewPlant(name: 'Calathea'));
      final photo = await photos.addFromUrl(plantId: plant.id, url: 'https://exemple.test/a.jpg');
      final pending = await (db.select(db.syncOutbox)..where((o) => o.entity.equals('plant_photos') & o.entityId.equals(photo.id))).get();
      expect(pending, isNotEmpty);
    });
  });
}
