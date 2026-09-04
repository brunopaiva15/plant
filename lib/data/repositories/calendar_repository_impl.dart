import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/dates.dart';
import '../../domain/models/models.dart';
import '../../domain/repositories/repositories.dart';
import '../db/database.dart';
import '../db/mappers.dart';

class DriftCalendarRepository implements CalendarRepository {
  DriftCalendarRepository(this._db, this._gardenId);

  final FloraDatabase _db;
  final String _gardenId;

  @override
  Stream<List<CalendarEntry>> watchBetween(DateTime from, DateTime to) {
    // Un événement de plusieurs jours doit remonter dès qu'il chevauche la
    // plage : on compare sa fin (ou son début s'il n'en a pas) au début de
    // la plage, et son début à la fin de la plage.
    final start = from.dateOnly;
    final end = to.dateOnly.addDays(1);
    return (_db.select(_db.calendarEntries)
          ..where((e) =>
              e.gardenId.equals(_gardenId) &
              e.deletedAt.isNull() &
              e.startAt.isSmallerThanValue(end) &
              (e.endAt.isNull() & e.startAt.isBiggerOrEqualValue(start) | e.endAt.isBiggerOrEqualValue(start)))
          ..orderBy([(e) => OrderingTerm.asc(e.startAt)]))
        .watch()
        .map((rows) => rows.map((r) => r.toDomain()).toList());
  }

  @override
  Stream<List<CalendarEntry>> watchForPlant(String plantId) => (_db.select(_db.calendarEntries)
        ..where((e) => e.plantId.equals(plantId) & e.deletedAt.isNull())
        ..orderBy([(e) => OrderingTerm.desc(e.startAt)]))
      .watch()
      .map((rows) => rows.map((r) => r.toDomain()).toList());

  @override
  Future<CalendarEntry?> get(String id) async =>
      (await (_db.select(_db.calendarEntries)..where((e) => e.id.equals(id) & e.deletedAt.isNull())).getSingleOrNull())?.toDomain();

  @override
  Future<CalendarEntry> create(NewCalendarEntry entry) async {
    final now = DateTime.now();
    final id = const Uuid().v4();
    await _db.into(_db.calendarEntries).insert(CalendarEntriesCompanion.insert(
          id: id,
          gardenId: _gardenId,
          plantId: Value(entry.plantId),
          categoryId: Value(entry.categoryId),
          title: entry.title.trim(),
          notes: Value(_clean(entry.notes)),
          startAt: entry.startAt,
          endAt: Value(_normalizeEnd(entry.startAt, entry.endAt)),
          allDay: Value(entry.allDay),
          reminderMinutes: Value(entry.reminderMinutes),
          createdAt: now,
          updatedAt: now,
        ));
    await _db.enqueueSync('calendar_entries', id, 'upsert', {'title': entry.title});
    return (await (_db.select(_db.calendarEntries)..where((e) => e.id.equals(id))).getSingle()).toDomain();
  }

  @override
  Future<void> update(CalendarEntry entry) async {
    await (_db.update(_db.calendarEntries)..where((e) => e.id.equals(entry.id))).write(CalendarEntriesCompanion(
      plantId: Value(entry.plantId),
      categoryId: Value(entry.categoryId),
      title: Value(entry.title.trim()),
      notes: Value(_clean(entry.notes)),
      startAt: Value(entry.startAt),
      endAt: Value(_normalizeEnd(entry.startAt, entry.endAt)),
      allDay: Value(entry.allDay),
      reminderMinutes: Value(entry.reminderMinutes),
      updatedAt: Value(DateTime.now()),
    ));
    await _db.enqueueSync('calendar_entries', entry.id, 'upsert', {'title': entry.title});
  }

  @override
  Future<void> delete(String id) async {
    await (_db.update(_db.calendarEntries)..where((e) => e.id.equals(id)))
        .write(CalendarEntriesCompanion(deletedAt: Value(DateTime.now()), updatedAt: Value(DateTime.now())));
    await _db.enqueueSync('calendar_entries', id, 'delete', const {});
  }

  /// Une fin antérieure au début n'a pas de sens : on la laisse tomber
  /// plutôt que d'enregistrer un événement qui finit avant de commencer.
  static DateTime? _normalizeEnd(DateTime start, DateTime? end) => end == null || end.isBefore(start) ? null : end;

  static String? _clean(String? v) => v == null || v.trim().isEmpty ? null : v.trim();

  // ------------------------------------------------------------ catégories

  @override
  Stream<List<EventCategory>> watchCategories() => (_db.select(_db.eventCategories)
        ..where((c) => c.gardenId.equals(_gardenId) & c.deletedAt.isNull())
        ..orderBy([(c) => OrderingTerm.asc(c.position), (c) => OrderingTerm.asc(c.label)]))
      .watch()
      .map((rows) => rows.map((r) => r.toDomain()).toList());

  @override
  Future<EventCategory> createCategory({required String label, String emoji = '📅', String? colorKey}) async {
    final now = DateTime.now();
    final id = const Uuid().v4();
    final existing = await (_db.select(_db.eventCategories)..where((c) => c.gardenId.equals(_gardenId) & c.deletedAt.isNull())).get();
    final position = existing.fold<int>(-1, (m, r) => r.position > m ? r.position : m) + 1;
    await _db.into(_db.eventCategories).insert(EventCategoriesCompanion.insert(
          id: id,
          gardenId: _gardenId,
          label: label.trim(),
          emoji: Value(emoji),
          colorKey: Value(colorKey),
          position: Value(position),
          createdAt: now,
          updatedAt: now,
        ));
    await _db.enqueueSync('event_categories', id, 'upsert', {'label': label});
    return (await (_db.select(_db.eventCategories)..where((c) => c.id.equals(id))).getSingle()).toDomain();
  }

  @override
  Future<void> updateCategory(EventCategory category) async {
    await (_db.update(_db.eventCategories)..where((c) => c.id.equals(category.id))).write(EventCategoriesCompanion(
      label: Value(category.label.trim()),
      emoji: Value(category.emoji),
      colorKey: Value(category.colorKey),
      position: Value(category.position),
      updatedAt: Value(DateTime.now()),
    ));
    await _db.enqueueSync('event_categories', category.id, 'upsert', {'label': category.label});
  }

  @override
  Future<void> deleteCategory(String id) async {
    final now = DateTime.now();
    await _db.transaction(() async {
      // Les événements survivent à leur catégorie : ils la perdent, c'est tout.
      final orphans = await (_db.select(_db.calendarEntries)..where((e) => e.categoryId.equals(id) & e.deletedAt.isNull())).get();
      await (_db.update(_db.calendarEntries)..where((e) => e.categoryId.equals(id)))
          .write(CalendarEntriesCompanion(categoryId: const Value(null), updatedAt: Value(now)));
      await (_db.update(_db.eventCategories)..where((c) => c.id.equals(id)))
          .write(EventCategoriesCompanion(deletedAt: Value(now), updatedAt: Value(now)));
      for (final e in orphans) {
        await _db.enqueueSync('calendar_entries', e.id, 'upsert', const {});
      }
    });
    await _db.enqueueSync('event_categories', id, 'delete', const {});
  }

  @override
  Future<void> reorderCategories(List<String> orderedIds) async {
    final now = DateTime.now();
    await _db.transaction(() async {
      for (final (i, id) in orderedIds.indexed) {
        await (_db.update(_db.eventCategories)..where((c) => c.id.equals(id)))
            .write(EventCategoriesCompanion(position: Value(i), updatedAt: Value(now)));
      }
    });
    for (final id in orderedIds) {
      await _db.enqueueSync('event_categories', id, 'upsert', const {});
    }
  }
}
