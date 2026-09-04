import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/models.dart';
import '../../domain/repositories/repositories.dart';
import '../db/database.dart';
import '../db/mappers.dart';

/// Pièces jointes stockées dans `<documents>/attachments`, référencées par un
/// chemin relatif comme les photos.
class DriftAttachmentRepository implements AttachmentRepository {
  DriftAttachmentRepository(this._db, this._gardenId, {String? Function()? currentUserId})
      : _currentUserId = currentUserId ?? (() => null);

  final FloraDatabase _db;
  final String _gardenId;
  final String? Function() _currentUserId;
  static const _uuid = Uuid();
  Directory? _root;

  Future<Directory> _dir() async {
    if (_root != null) return _root!;
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'attachments'));
    if (!dir.existsSync()) await dir.create(recursive: true);
    return _root = dir;
  }

  @override
  Stream<List<PlantAttachment>> watchForPlant(String plantId) => (_db.select(_db.plantAttachments)
        ..where((a) => a.plantId.equals(plantId) & a.deletedAt.isNull())
        ..orderBy([(a) => OrderingTerm.desc(a.createdAt)]))
      .watch()
      .map((rows) => rows.map((r) => r.toDomain()).toList());

  @override
  Future<PlantAttachment> add({required String plantId, required String sourcePath, required String label, String? mimeType}) async {
    final dir = await _dir();
    final id = _uuid.v4();
    // Le nom de fichier est l'identifiant : jamais de collision, jamais de
    // caractère exotique venu du système de fichiers d'origine.
    final ext = p.extension(sourcePath);
    final fileName = '$id$ext';
    final target = File(p.join(dir.path, fileName));
    await File(sourcePath).copy(target.path);
    final size = await target.length();
    final now = DateTime.now();
    final trimmed = label.trim().isEmpty ? p.basename(sourcePath) : label.trim();

    await _db.into(_db.plantAttachments).insert(PlantAttachmentsCompanion.insert(
          id: id,
          gardenId: _gardenId,
          plantId: plantId,
          userId: Value(_currentUserId()),
          label: trimmed,
          filePath: fileName,
          mimeType: Value(mimeType),
          sizeBytes: Value(size),
          createdAt: now,
          updatedAt: now,
        ));
    await _db.enqueueSync('plant_attachments', id, 'upsert', {'label': trimmed});
    return (await (_db.select(_db.plantAttachments)..where((a) => a.id.equals(id))).getSingle()).toDomain();
  }

  @override
  Future<void> rename(String id, String label) async {
    final trimmed = label.trim();
    if (trimmed.isEmpty) return;
    await (_db.update(_db.plantAttachments)..where((a) => a.id.equals(id)))
        .write(PlantAttachmentsCompanion(label: Value(trimmed), updatedAt: Value(DateTime.now())));
    await _db.enqueueSync('plant_attachments', id, 'upsert', {'label': trimmed});
  }

  @override
  Future<void> delete(String id) async {
    final row = await (_db.select(_db.plantAttachments)..where((a) => a.id.equals(id))).getSingleOrNull();
    await (_db.update(_db.plantAttachments)..where((a) => a.id.equals(id)))
        .write(PlantAttachmentsCompanion(deletedAt: Value(DateTime.now()), updatedAt: Value(DateTime.now())));
    await _db.enqueueSync('plant_attachments', id, 'delete', const {});
    if (row != null) {
      final file = File(p.join((await _dir()).path, row.filePath));
      if (file.existsSync()) await file.delete();
    }
  }

  @override
  Future<String> absolutePath(PlantAttachment attachment) async => p.join((await _dir()).path, attachment.filePath);
}
