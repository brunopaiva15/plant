import 'package:drift/drift.dart';

import '../../domain/models/models.dart';
import '../../domain/repositories/repositories.dart';
import '../db/database.dart';
import '../db/mappers.dart';

class DriftMeasurementRepository implements MeasurementRepository {
  DriftMeasurementRepository(this._db);

  final FloraDatabase _db;

  @override
  Stream<List<MeasurementSeries>> watchSeries(String plantId) => (_db.select(_db.measurements)
        ..where((m) => m.plantId.equals(plantId))
        ..orderBy([(m) => OrderingTerm.asc(m.measuredAt)]))
      .watch()
      .map((rows) {
        final byKind = <MeasurementKind, List<Measurement>>{};
        for (final r in rows) {
          final m = r.toDomain();
          byKind.putIfAbsent(m.kind, () => []).add(m);
        }
        return [
          for (final kind in MeasurementKind.values)
            if (byKind[kind] case final points?) MeasurementSeries(kind: kind, points: points),
        ];
      });
}
