import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../../core/config/app_config.dart';
import '../../data/db/database.dart';
import '../../data/db/row_defaults.dart';
import '../../data/services/photo_storage_service.dart';
import 'backup_sections.dart';

/// Ce qu'une sauvegarde contient, lu avant de décider quoi importer.
class BackupManifest {
  const BackupManifest({required this.app, required this.schemaVersion, required this.exportedAt, required this.counts});

  final String app;
  final int schemaVersion;
  final DateTime? exportedAt;

  /// Nombre de lignes par table présentes dans le fichier.
  final Map<String, int> counts;

  /// Sections réellement peuplées : celles dont au moins une table a des lignes.
  Set<BackupSection> get sections => {
        for (final s in BackupSection.values)
          if (s.tables.any((t) => (counts[t] ?? 0) > 0)) s,
      };

  int get totalRows => counts.values.fold(0, (a, b) => a + b);
}

/// Résultat d'un import, affiché tel quel à l'utilisateur.
class ImportReport {
  const ImportReport({required this.imported, required this.skipped, required this.photos});

  /// Lignes écrites, par table.
  final Map<String, int> imported;

  /// Lignes refusées (référence manquante, ligne illisible), par table.
  final Map<String, int> skipped;
  final int photos;

  int get totalImported => imported.values.fold(0, (a, b) => a + b);
  int get totalSkipped => skipped.values.fold(0, (a, b) => a + b);
}

/// Erreur volontairement lisible : c'est elle qu'on montre à l'utilisateur.
class ImportException implements Exception {
  const ImportException(this.reason);

  final ImportFailure reason;
}

enum ImportFailure { notAZip, noData, wrongApp, tooRecent }

/// Restauration d'une sauvegarde produite par [ExportService].
class ImportService {
  ImportService(this._db, this._photos);

  final FloraDatabase _db;
  final PhotoStorageService _photos;

  /// Lit l'entête sans rien écrire : de quoi montrer un aperçu avant import.
  Future<BackupManifest> inspect(File zip) async {
    final data = await _readData(zip);
    return _manifest(data);
  }

  BackupManifest _manifest(Map<String, Object?> data) {
    final counts = <String, int>{};
    for (final table in backupTableOrder) {
      final rows = data[table];
      if (rows is List && rows.isNotEmpty) counts[table] = rows.length;
    }
    return BackupManifest(
      app: data['app'] as String? ?? '',
      schemaVersion: (data['schema_version'] as num?)?.toInt() ?? 0,
      exportedAt: DateTime.tryParse(data['exported_at'] as String? ?? ''),
      counts: counts,
    );
  }

  /// Importe les sections demandées (toutes par défaut).
  ///
  /// Les lignes existantes de même identifiant sont remplacées ; celles qui
  /// n'existent que localement sont conservées. Une ligne dont la référence
  /// manque (photo sans sa plante) est comptée comme sautée, jamais fatale.
  Future<ImportReport> import(File zip, {Set<BackupSection>? sections}) async {
    final archive = await _openArchive(zip);
    final data = await _readData(zip, archive: archive);
    final manifest = _manifest(data);
    if (manifest.app.isNotEmpty && manifest.app != AppConfig.appName) {
      throw const ImportException(ImportFailure.wrongApp);
    }
    if (manifest.schemaVersion > _db.schemaVersion) {
      // Une sauvegarde plus récente peut contenir des colonnes inconnues :
      // mieux vaut refuser que d'en perdre la moitié en silence.
      throw const ImportException(ImportFailure.tooRecent);
    }

    final tables = sections == null ? backupTableOrder : tablesFor(sections);
    final imported = <String, int>{};
    final skipped = <String, int>{};

    for (final table in tables) {
      final rows = data[table];
      if (rows is! List) continue;
      for (final raw in rows) {
        if (raw is! Map) {
          skipped.update(table, (n) => n + 1, ifAbsent: () => 1);
          continue;
        }
        final json = Map<String, Object?>.from(raw);
        RowDefaults.fill(table, json);
        try {
          await _insert(table, json);
          imported.update(table, (n) => n + 1, ifAbsent: () => 1);
        } catch (_) {
          skipped.update(table, (n) => n + 1, ifAbsent: () => 1);
        }
      }
    }

    final photos = tables.contains('plant_photos') ? await _restorePhotos(archive) : 0;
    return ImportReport(imported: imported, skipped: skipped, photos: photos);
  }

  Future<Archive> _openArchive(File zip) async {
    Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(await zip.readAsBytes());
    } catch (_) {
      throw const ImportException(ImportFailure.notAZip);
    }
    // Un fichier quelconque se décode parfois en archive vide : ce n'en est
    // pas une pour autant.
    if (archive.files.isEmpty) throw const ImportException(ImportFailure.notAZip);
    return archive;
  }

  Future<Map<String, Object?>> _readData(File zip, {Archive? archive}) async {
    final files = archive ?? await _openArchive(zip);
    final entry = files.files.where((f) => f.isFile && p.basename(f.name) == 'data.json').firstOrNull;
    if (entry == null) throw const ImportException(ImportFailure.noData);
    try {
      return jsonDecode(utf8.decode(entry.content as List<int>)) as Map<String, Object?>;
    } catch (_) {
      throw const ImportException(ImportFailure.noData);
    }
  }

  /// Réécrit les fichiers photo à leur place, sans écraser ceux qui existent.
  Future<int> _restorePhotos(Archive archive) async {
    var written = 0;
    for (final entry in archive.files) {
      if (!entry.isFile || !entry.name.startsWith('photos/')) continue;
      final relative = entry.name.substring('photos/'.length);
      if (relative.isEmpty || relative.contains('..')) continue;
      final target = File(await _photos.absolutePath(relative));
      if (await target.exists()) continue;
      await target.parent.create(recursive: true);
      await target.writeAsBytes(entry.content as List<int>);
      written++;
    }
    return written;
  }

  Future<void> _insert(String table, Map<String, Object?> json) async {
    const s = ValueSerializer.defaults();
    switch (table) {
      case 'gardens':
        await _db.into(_db.gardens).insertOnConflictUpdate(GardenRow.fromJson(json, serializer: s));
      case 'locations':
        await _db.into(_db.locations).insertOnConflictUpdate(LocationRow.fromJson(json, serializer: s));
      case 'plants':
        await _db.into(_db.plants).insertOnConflictUpdate(PlantRow.fromJson(json, serializer: s));
      case 'plant_photos':
        await _db.into(_db.plantPhotos).insertOnConflictUpdate(PlantPhotoRow.fromJson(json, serializer: s));
      case 'action_types':
        await _db.into(_db.actionTypes).insertOnConflictUpdate(ActionTypeRow.fromJson(json, serializer: s));
      case 'plant_actions':
        await _db.into(_db.plantActions).insertOnConflictUpdate(PlantActionRow.fromJson(json, serializer: s));
      case 'care_schedules':
        await _db.into(_db.careSchedules).insertOnConflictUpdate(CareScheduleRow.fromJson(json, serializer: s));
      case 'tags':
        await _db.into(_db.tags).insertOnConflictUpdate(TagRow.fromJson(json, serializer: s));
      case 'plant_tags':
        await _db.into(_db.plantTags).insertOnConflictUpdate(PlantTagRow.fromJson(json, serializer: s));
      case 'measurements':
        await _db.into(_db.measurements).insertOnConflictUpdate(MeasurementRow.fromJson(json, serializer: s));
      case 'inventory_items':
        await _db.into(_db.inventoryItems).insertOnConflictUpdate(InventoryItemRow.fromJson(json, serializer: s));
      case 'tasks':
        await _db.into(_db.tasks).insertOnConflictUpdate(TaskRow.fromJson(json, serializer: s));
      case 'plant_attributes':
        await _db.into(_db.plantAttributes).insertOnConflictUpdate(PlantAttributeRow.fromJson(json, serializer: s));
      case 'attribute_schemas':
        await _db.into(_db.attributeSchemas).insertOnConflictUpdate(AttributeSchemaRow.fromJson(json, serializer: s));
      case 'plant_attachments':
        await _db.into(_db.plantAttachments).insertOnConflictUpdate(PlantAttachmentRow.fromJson(json, serializer: s));
      case 'location_logs':
        await _db.into(_db.locationLogs).insertOnConflictUpdate(LocationLogRow.fromJson(json, serializer: s));
      case 'inventory_groups':
        await _db.into(_db.inventoryGroups).insertOnConflictUpdate(InventoryGroupRow.fromJson(json, serializer: s));
      case 'inventory_tags':
        await _db.into(_db.inventoryTags).insertOnConflictUpdate(InventoryTagRow.fromJson(json, serializer: s));
      case 'event_categories':
        await _db.into(_db.eventCategories).insertOnConflictUpdate(EventCategoryRow.fromJson(json, serializer: s));
      case 'calendar_entries':
        await _db.into(_db.calendarEntries).insertOnConflictUpdate(CalendarEntryRow.fromJson(json, serializer: s));
    }
  }
}
