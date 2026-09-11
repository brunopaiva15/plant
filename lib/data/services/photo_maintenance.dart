import '../db/database.dart';
import 'photo_storage_service.dart';

/// Ménage du dossier des photos.
///
/// Un fichier survit à sa ligne plus souvent qu'on ne croit : suppression
/// définitive d'une plante (les lignes partent, les fichiers restaient),
/// photo effacée depuis un autre appareil et arrivée par la synchronisation,
/// import abandonné en cours de création. Rien ne les relisait jamais, et
/// l'espace occupé ne faisait que monter.
class PhotoMaintenance {
  PhotoMaintenance(this._db, this._photos);

  final FloraDatabase _db;
  final PhotoStorageService _photos;

  /// Efface les fichiers que plus aucune ligne ne réclame ; retourne leur nombre.
  Future<int> run() async {
    final keep = <String>{};
    for (final photo in await (_db.select(_db.plantPhotos)..where((p) => p.deletedAt.isNull())).get()) {
      keep
        ..add(photo.filePath)
        ..add(photo.thumbPath);
    }
    // Les emplacements rangent leur photo d'illustration au même endroit.
    for (final location in await (_db.select(_db.locations)..where((l) => l.deletedAt.isNull())).get()) {
      final photoPath = location.photoPath;
      final thumbPath = location.thumbPath;
      if (photoPath != null) keep.add(photoPath);
      if (thumbPath != null) keep.add(thumbPath);
    }
    keep.remove('');
    return _photos.sweepOrphans(keep);
  }
}
