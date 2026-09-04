import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/models.dart';
import '../../domain/repositories/repositories.dart';
import '../db/database.dart';
import '../db/mappers.dart';

class DriftPhotoRepository implements PhotoRepository {
  DriftPhotoRepository(this._db, {String? Function()? currentUserId}) : _currentUserId = currentUserId ?? (() => null);

  final FloraDatabase _db;
  final String? Function() _currentUserId;
  static const _uuid = Uuid();

  @override
  Stream<List<PlantPhoto>> watchByPlant(String plantId) => (_db.select(_db.plantPhotos)
        ..where((p) => p.plantId.equals(plantId) & p.deletedAt.isNull())
        ..orderBy([(p) => OrderingTerm.desc(p.takenAt)]))
      .watch()
      .map((rows) => rows.map((r) => r.toDomain()).toList());

  @override
  Stream<List<PlantPhoto>> watchRecent({int limit = 12}) => (_db.select(_db.plantPhotos)
        ..where((p) => p.deletedAt.isNull())
        ..orderBy([(p) => OrderingTerm.desc(p.takenAt)])
        ..limit(limit))
      .watch()
      .map((rows) => rows.map((r) => r.toDomain()).toList());

  @override
  Future<PlantPhoto> add({
    required String plantId,
    required String filePath,
    required String thumbPath,
    required int width,
    required int height,
    DateTime? takenAt,
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();
    await _db.transaction(() async {
      await _db.into(_db.plantPhotos).insert(PlantPhotosCompanion.insert(
            id: id,
            plantId: plantId,
            userId: Value(_currentUserId()),
            filePath: filePath,
            thumbPath: thumbPath,
            width: width,
            height: height,
            takenAt: takenAt ?? now,
            createdAt: now,
          ));
      // La première photo devient automatiquement la photo principale.
      await (_db.update(_db.plants)..where((p) => p.id.equals(plantId) & p.primaryPhotoId.isNull()))
          .write(PlantsCompanion(primaryPhotoId: Value(id), updatedAt: Value(now)));
      await _db.enqueueSync('plant_photos', id, 'upsert', {});
      await _db.enqueueSync('plants', plantId, 'upsert', {});
    });
    return (await (_db.select(_db.plantPhotos)..where((p) => p.id.equals(id))).getSingle()).toDomain();
  }

  @override
  Future<PlantPhoto> addFromUrl({required String plantId, required String url, String? label}) async {
    final now = DateTime.now();
    final id = _uuid.v4();
    await _db.transaction(() async {
      await _db.into(_db.plantPhotos).insert(PlantPhotosCompanion.insert(
            id: id,
            plantId: plantId,
            userId: Value(_currentUserId()),
            label: Value(_clean(label)),
            remoteUrl: Value(url.trim()),
            // Une photo distante n'a pas de fichier local ni de dimensions connues.
            filePath: '',
            thumbPath: '',
            width: 0,
            height: 0,
            takenAt: now,
            createdAt: now,
          ));
      await (_db.update(_db.plants)..where((p) => p.id.equals(plantId) & p.primaryPhotoId.isNull()))
          .write(PlantsCompanion(primaryPhotoId: Value(id), updatedAt: Value(now)));
      await _db.enqueueSync('plant_photos', id, 'upsert', {});
      await _db.enqueueSync('plants', plantId, 'upsert', {});
    });
    return (await (_db.select(_db.plantPhotos)..where((p) => p.id.equals(id))).getSingle()).toDomain();
  }

  @override
  Future<void> setLabel(String photoId, String? label) async {
    await (_db.update(_db.plantPhotos)..where((p) => p.id.equals(photoId))).write(PlantPhotosCompanion(label: Value(_clean(label))));
    await _db.enqueueSync('plant_photos', photoId, 'upsert', {});
  }

  static String? _clean(String? s) {
    final t = s?.trim();
    return t == null || t.isEmpty ? null : t;
  }

  @override
  Future<void> setPrimary(String plantId, String photoId) async {
    await (_db.update(_db.plants)..where((p) => p.id.equals(plantId))).write(PlantsCompanion(primaryPhotoId: Value(photoId), updatedAt: Value(DateTime.now())));
    await _db.enqueueSync('plants', plantId, 'upsert', {});
  }

  @override
  Future<void> delete(String photoId) async {
    final now = DateTime.now();
    await _db.transaction(() async {
      final photo = await (_db.select(_db.plantPhotos)..where((p) => p.id.equals(photoId))).getSingleOrNull();
      if (photo == null) return;
      await (_db.update(_db.plantPhotos)..where((p) => p.id.equals(photoId)))
          .write(PlantPhotosCompanion(deletedAt: Value(now)));
      // Si c'était la principale, on bascule sur la plus récente restante.
      final plant = await (_db.select(_db.plants)..where((p) => p.id.equals(photo.plantId))).getSingleOrNull();
      if (plant?.primaryPhotoId == photoId) {
        final next = await (_db.select(_db.plantPhotos)
              ..where((p) => p.plantId.equals(photo.plantId) & p.deletedAt.isNull())
              ..orderBy([(p) => OrderingTerm.desc(p.takenAt)])
              ..limit(1))
            .getSingleOrNull();
        await (_db.update(_db.plants)..where((p) => p.id.equals(photo.plantId)))
            .write(PlantsCompanion(primaryPhotoId: Value(next?.id), updatedAt: Value(now)));
        await _db.enqueueSync('plants', photo.plantId, 'upsert', {});
      }
      await (_db.update(_db.plantActions)..where((a) => a.photoId.equals(photoId)))
          .write(PlantActionsCompanion(deletedAt: Value(now)));
      // Suppression logique : la ligne reste, avec deleted_at, pour les autres appareils.
      await _db.enqueueSync('plant_photos', photoId, 'upsert', {});
    });
  }
}
