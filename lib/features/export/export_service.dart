import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/config/app_config.dart';
import '../../data/db/database.dart';
import '../../data/services/photo_storage_service.dart';

/// Export complet : `data.json` (toutes les tables) + dossier `photos/`.
/// Format ouvert et documenté : l'utilisateur n'est jamais prisonnier.
class ExportService {
  ExportService(this._db, this._photos);

  final FloraDatabase _db;
  final PhotoStorageService _photos;

  Future<File> buildZip() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'exports'));
    if (!await dir.exists()) await dir.create(recursive: true);
    final stamp = DateTime.now().toIso8601String().replaceAll(RegExp('[:.]'), '-').substring(0, 19);
    final zipPath = p.join(dir.path, '${AppConfig.appName.toLowerCase()}-export-$stamp.zip');

    final data = await _collect();
    final encoder = ZipFileEncoder()..create(zipPath);
    encoder.addArchiveFile(ArchiveFile.string('data.json', const JsonEncoder.withIndent('  ').convert(data)));
    for (final photo in await _db.select(_db.plantPhotos).get()) {
      for (final rel in [photo.filePath, photo.thumbPath]) {
        final f = File(await _photos.absolutePath(rel));
        if (await f.exists()) await encoder.addFile(f, 'photos/$rel');
      }
    }
    await encoder.close();
    return File(zipPath);
  }

  Future<Map<String, Object?>> _collect() async => {
        'app': AppConfig.appName,
        'schema_version': _db.schemaVersion,
        'exported_at': DateTime.now().toIso8601String(),
        'gardens': (await _db.select(_db.gardens).get()).map((r) => r.toJson()).toList(),
        'locations': (await _db.select(_db.locations).get()).map((r) => r.toJson()).toList(),
        'plants': (await _db.select(_db.plants).get()).map((r) => r.toJson()).toList(),
        'plant_photos': (await _db.select(_db.plantPhotos).get()).map((r) => r.toJson()).toList(),
        'action_types': (await _db.select(_db.actionTypes).get()).map((r) => r.toJson()).toList(),
        'plant_actions': (await _db.select(_db.plantActions).get()).map((r) => r.toJson()).toList(),
        'care_schedules': (await _db.select(_db.careSchedules).get()).map((r) => r.toJson()).toList(),
        'tags': (await _db.select(_db.tags).get()).map((r) => r.toJson()).toList(),
        'plant_tags': (await _db.select(_db.plantTags).get()).map((r) => r.toJson()).toList(),
        'measurements': (await _db.select(_db.measurements).get()).map((r) => r.toJson()).toList(),
        'inventory_items': (await _db.select(_db.inventoryItems).get()).map((r) => r.toJson()).toList(),
        'tasks': (await _db.select(_db.tasks).get()).map((r) => r.toJson()).toList(),
        'plant_attributes': (await _db.select(_db.plantAttributes).get()).map((r) => r.toJson()).toList(),
        'attribute_schemas': (await _db.select(_db.attributeSchemas).get()).map((r) => r.toJson()).toList(),
        'plant_attachments': (await _db.select(_db.plantAttachments).get()).map((r) => r.toJson()).toList(),
        'location_logs': (await _db.select(_db.locationLogs).get()).map((r) => r.toJson()).toList(),
        'inventory_groups': (await _db.select(_db.inventoryGroups).get()).map((r) => r.toJson()).toList(),
        'inventory_tags': (await _db.select(_db.inventoryTags).get()).map((r) => r.toJson()).toList(),
      };
}
