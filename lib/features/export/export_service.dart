import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/config/app_config.dart';
import '../../data/db/database.dart';
import '../../data/services/photo_storage_service.dart';
import 'backup_sections.dart';

/// Export complet : `data.json` (toutes les tables) + dossier `photos/`.
/// Format ouvert et documenté : l'utilisateur n'est jamais prisonnier.
class ExportService {
  ExportService(this._db, this._photos);

  final FloraDatabase _db;
  final PhotoStorageService _photos;

  /// Sauvegarde complète, ou seulement les sections demandées.
  Future<File> buildZip({Set<BackupSection>? sections}) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'exports'));
    if (!await dir.exists()) await dir.create(recursive: true);
    final stamp = DateTime.now().toIso8601String().replaceAll(RegExp('[:.]'), '-').substring(0, 19);
    final zipPath = p.join(dir.path, '${AppConfig.appName.toLowerCase()}-export-$stamp.zip');

    final chosen = sections == null ? null : withDependencies(sections);
    final data = await _collect(chosen);
    final encoder = ZipFileEncoder()..create(zipPath);
    encoder.addArchiveFile(ArchiveFile.string('data.json', const JsonEncoder.withIndent('  ').convert(data)));
    // Les fichiers ne partent qu'avec la section Photos : sans elle, le zip
    // pèserait le même poids pour rien.
    if (chosen == null || chosen.contains(BackupSection.photos)) {
      for (final photo in await _db.select(_db.plantPhotos).get()) {
        for (final rel in [photo.filePath, photo.thumbPath]) {
          final f = File(await _photos.absolutePath(rel));
          if (await f.exists()) await encoder.addFile(f, 'photos/$rel');
        }
      }
    }
    await encoder.close();
    return File(zipPath);
  }

  Future<Map<String, Object?>> _collect(Set<BackupSection>? sections) async {
    final wanted = sections == null ? null : tablesFor(sections).toSet();
    Future<List<Map<String, Object?>>> rows(String table, Future<List<dynamic>> Function() load) async {
      if (wanted != null && !wanted.contains(table)) return const [];
      return (await load()).map((r) => (r as dynamic).toJson() as Map<String, Object?>).toList();
    }

    return {
      'app': AppConfig.appName,
      'schema_version': _db.schemaVersion,
      'exported_at': DateTime.now().toIso8601String(),
      if (sections != null) 'sections': withDependencies(sections).map((s) => s.name).toList(),
      'gardens': await rows('gardens', () => _db.select(_db.gardens).get()),
      'locations': await rows('locations', () => _db.select(_db.locations).get()),
      'plants': await rows('plants', () => _db.select(_db.plants).get()),
      'plant_photos': await rows('plant_photos', () => _db.select(_db.plantPhotos).get()),
      'action_types': await rows('action_types', () => _db.select(_db.actionTypes).get()),
      'plant_actions': await rows('plant_actions', () => _db.select(_db.plantActions).get()),
      'care_schedules': await rows('care_schedules', () => _db.select(_db.careSchedules).get()),
      'tags': await rows('tags', () => _db.select(_db.tags).get()),
      'plant_tags': await rows('plant_tags', () => _db.select(_db.plantTags).get()),
      'measurements': await rows('measurements', () => _db.select(_db.measurements).get()),
      'inventory_items': await rows('inventory_items', () => _db.select(_db.inventoryItems).get()),
      'tasks': await rows('tasks', () => _db.select(_db.tasks).get()),
      'plant_attributes': await rows('plant_attributes', () => _db.select(_db.plantAttributes).get()),
      'attribute_schemas': await rows('attribute_schemas', () => _db.select(_db.attributeSchemas).get()),
      'plant_attachments': await rows('plant_attachments', () => _db.select(_db.plantAttachments).get()),
      'location_logs': await rows('location_logs', () => _db.select(_db.locationLogs).get()),
      'inventory_groups': await rows('inventory_groups', () => _db.select(_db.inventoryGroups).get()),
      'inventory_tags': await rows('inventory_tags', () => _db.select(_db.inventoryTags).get()),
      'event_categories': await rows('event_categories', () => _db.select(_db.eventCategories).get()),
      'calendar_entries': await rows('calendar_entries', () => _db.select(_db.calendarEntries).get()),
    };
  }
}
