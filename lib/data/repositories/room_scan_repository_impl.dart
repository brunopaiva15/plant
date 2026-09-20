import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/repositories/repositories.dart';
import '../../domain/room/room_scan.dart';
import '../../domain/room/scanned_room.dart';
import '../db/database.dart';
import '../db/mappers.dart';

/// Les relevés d'un jardin, en base locale. Rien ne part dans l'outbox :
/// un relevé reste sur l'appareil qui l'a fait.
class DriftRoomScanRepository implements RoomScanRepository {
  DriftRoomScanRepository(this._db, this._gardenId);

  final FloraDatabase _db;
  final String _gardenId;
  static const _uuid = Uuid();

  SimpleSelectStatement<$RoomScansTable, RoomScanRow> get _all => _db.select(_db.roomScans)
    ..where((s) => s.gardenId.equals(_gardenId) & s.deletedAt.isNull())
    ..orderBy([(s) => OrderingTerm.desc(s.capturedAt)]);

  @override
  Stream<List<RoomScan>> watchAll() => _all.watch().map((rows) => rows.map((r) => r.toDomain()).toList());

  @override
  Stream<RoomScan?> watch(String id) => (_db.select(_db.roomScans)..where((s) => s.id.equals(id) & s.deletedAt.isNull()))
      .watchSingleOrNull()
      .map((r) => r?.toDomain());

  @override
  Future<RoomScan> create({
    required String name,
    required String filePath,
    required DateTime capturedAt,
    double? northOffsetDeg,
    double floorAreaM2 = 0,
    RoomSectionLabel? section,
    String? locationId,
    String? structureId,
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();
    await _db.into(_db.roomScans).insert(RoomScansCompanion.insert(
          id: id,
          gardenId: _gardenId,
          locationId: Value(locationId),
          name: name.trim(),
          capturedAt: capturedAt,
          northOffsetDeg: Value(northOffsetDeg),
          filePath: filePath,
          floorAreaM2: Value(floorAreaM2),
          sectionLabel: Value(section?.name),
          structureId: Value(structureId),
          createdAt: now,
          updatedAt: now,
        ));
    return (await (_db.select(_db.roomScans)..where((s) => s.id.equals(id))).getSingle()).toDomain();
  }

  @override
  Future<void> update(RoomScan scan) async {
    await (_db.update(_db.roomScans)..where((s) => s.id.equals(scan.id))).write(RoomScansCompanion(
      name: Value(scan.name.trim()),
      locationId: Value(scan.locationId),
      sectionLabel: Value(scan.section?.name),
      updatedAt: Value(DateTime.now()),
    ));
  }

  @override
  Future<void> delete(String id) async {
    await _db.transaction(() async {
      await (_db.delete(_db.roomMarkers)..where((m) => m.scanId.equals(id))).go();
      await (_db.update(_db.roomScans)..where((s) => s.id.equals(id))).write(RoomScansCompanion(deletedAt: Value(DateTime.now())));
    });
  }

  @override
  Stream<List<RoomMarker>> watchMarkers(String scanId) => (_db.select(_db.roomMarkers)
        ..where((m) => m.scanId.equals(scanId))
        ..orderBy([(m) => OrderingTerm.asc(m.createdAt)]))
      .watch()
      .map((rows) => [for (final r in rows) ?r.toDomain()]);

  @override
  Future<void> setWindowOrientation(String scanId, int windowIndex, CardinalDirection? orientation, {required double x, required double z}) async {
    final existing = await (_db.select(_db.roomMarkers)
          ..where((m) => m.scanId.equals(scanId) & m.kind.equals(RoomMarkerKind.windowOrientation.name) & m.windowIndex.equals(windowIndex)))
        .get();
    final now = DateTime.now();
    if (orientation == null) {
      for (final row in existing) {
        await (_db.delete(_db.roomMarkers)..where((m) => m.id.equals(row.id))).go();
      }
      return;
    }
    if (existing.isNotEmpty) {
      await (_db.update(_db.roomMarkers)..where((m) => m.id.equals(existing.first.id)))
          .write(RoomMarkersCompanion(orientation: Value(orientation.name), x: Value(x), z: Value(z), updatedAt: Value(now)));
      return;
    }
    await _db.into(_db.roomMarkers).insert(RoomMarkersCompanion.insert(
          id: _uuid.v4(),
          scanId: scanId,
          kind: RoomMarkerKind.windowOrientation.name,
          x: x,
          z: z,
          windowIndex: Value(windowIndex),
          orientation: Value(orientation.name),
          createdAt: now,
          updatedAt: now,
        ));
  }

  @override
  Future<RoomMarker> addMarker(String scanId, RoomMarkerKind kind, {required double x, required double z, String? plantId}) async {
    final now = DateTime.now();
    final id = _uuid.v4();
    await _db.into(_db.roomMarkers).insert(RoomMarkersCompanion.insert(
          id: id,
          scanId: scanId,
          kind: kind.name,
          x: x,
          z: z,
          plantId: Value(plantId),
          createdAt: now,
          updatedAt: now,
        ));
    return (await (_db.select(_db.roomMarkers)..where((m) => m.id.equals(id))).getSingle()).toDomain()!;
  }

  @override
  Future<void> removeMarker(String id) => (_db.delete(_db.roomMarkers)..where((m) => m.id.equals(id))).go();
}
