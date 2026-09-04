import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/models.dart';
import '../../domain/repositories/repositories.dart';
import '../db/database.dart';
import '../db/mappers.dart';
import 'plant_repository_impl.dart';

class DriftTagRepository implements TagRepository {
  DriftTagRepository(this._db, this._gardenId);

  final FloraDatabase _db;
  final String _gardenId;

  @override
  Stream<List<Tag>> watchAll() => (_db.select(_db.tags)
        ..where((t) => t.gardenId.equals(_gardenId))
        ..orderBy([(t) => OrderingTerm.asc(t.name)]))
      .watch()
      .map((rows) => rows.map((r) => r.toDomain()).toList());

  @override
  Stream<List<Tag>> watchForPlant(String plantId) {
    final q = _db.select(_db.tags).join([innerJoin(_db.plantTags, _db.plantTags.tagId.equalsExp(_db.tags.id))])
      ..where(_db.plantTags.plantId.equals(plantId))
      ..orderBy([OrderingTerm.asc(_db.tags.name)]);
    return q.watch().map((rows) => rows.map((r) => r.readTable(_db.tags).toDomain()).toList());
  }

  @override
  Future<Tag> create(String name) async {
    final trimmed = name.replaceAll(DriftPlantRepository.tagSeparator, ' ').trim();
    final existing = await (_db.select(_db.tags)
          ..where((t) => t.gardenId.equals(_gardenId) & t.name.lower().equals(trimmed.toLowerCase())))
        .getSingleOrNull();
    if (existing != null) return existing.toDomain();
    final id = const Uuid().v4();
    await _db.into(_db.tags).insert(TagsCompanion.insert(id: id, gardenId: _gardenId, name: trimmed, createdAt: DateTime.now()));
    return (await (_db.select(_db.tags)..where((t) => t.id.equals(id))).getSingle()).toDomain();
  }

  @override
  Future<void> setPlantTags(String plantId, List<String> tagIds) => _db.transaction(() async {
        await (_db.delete(_db.plantTags)..where((p) => p.plantId.equals(plantId))).go();
        for (final tagId in tagIds) {
          await _db.into(_db.plantTags).insert(PlantTagsCompanion.insert(plantId: plantId, tagId: tagId), mode: InsertMode.insertOrIgnore);
        }
      });

  @override
  Future<void> addTagToPlants(List<String> plantIds, String tagId) => _db.batch((b) {
        for (final id in plantIds) {
          b.insert(_db.plantTags, PlantTagsCompanion.insert(plantId: id, tagId: tagId), mode: InsertMode.insertOrIgnore);
        }
      });

  @override
  Future<void> delete(String tagId) => _db.transaction(() async {
        await (_db.delete(_db.plantTags)..where((p) => p.tagId.equals(tagId))).go();
        await (_db.delete(_db.tags)..where((t) => t.id.equals(tagId))).go();
      });
}
