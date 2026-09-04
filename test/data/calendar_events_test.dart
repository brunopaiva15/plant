import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flora/core/utils/dates.dart';
import 'package:flora/data/db/database.dart';
import 'package:flora/data/repositories/calendar_repository_impl.dart';
import 'package:flora/domain/care/calendar_projector.dart';
import 'package:flora/domain/models/models.dart';
import 'package:flora/domain/repositories/repositories.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FloraDatabase db;
  late CalendarRepository calendar;
  const gardenId = 'g1';
  final day = DateTime(2026, 6, 15);

  setUp(() async {
    db = FloraDatabase(NativeDatabase.memory());
    await db.into(db.gardens).insert(GardensCompanion.insert(id: gardenId, ownerId: 'u1', name: 'Jardin', createdAt: DateTime.now(), updatedAt: DateTime.now()));
    calendar = DriftCalendarRepository(db, gardenId);
  });

  tearDown(() => db.close());

  Future<CalendarEntry> event(String title, {DateTime? start, DateTime? end, bool allDay = true, int? reminder, String? categoryId}) =>
      calendar.create(NewCalendarEntry(title: title, startAt: start ?? day, endAt: end, allDay: allDay, reminderMinutes: reminder, categoryId: categoryId));

  group('événements', () {
    test('création, modification et suppression', () async {
      final created = await event('  Marché aux plantes  ');
      expect(created.title, 'Marché aux plantes');

      await calendar.update(created.copyWith(title: 'Bourse aux plantes'));
      expect((await calendar.get(created.id))!.title, 'Bourse aux plantes');

      await calendar.delete(created.id);
      expect(await calendar.get(created.id), isNull);
    });

    test('un événement supprimé disparaît de la plage', () async {
      final created = await event('Taille');
      await calendar.delete(created.id);
      expect(await calendar.watchBetween(day, day).first, isEmpty);
    });

    test('une fin antérieure au début est ignorée', () async {
      final created = await event('Bouture', start: day, end: day.addDays(-3));
      expect(created.endAt, isNull, reason: 'un événement ne peut pas finir avant de commencer');
    });

    test('des notes vides ne sont pas stockées', () async {
      final created = await calendar.create(NewCalendarEntry(title: 'Taille', startAt: day, notes: '   '));
      expect(created.notes, isNull);
    });
  });

  group('plage de dates', () {
    test('un événement du jour remonte', () async {
      await event('Taille');
      expect(await calendar.watchBetween(day, day).first, hasLength(1));
    });

    test('un événement hors plage ne remonte pas', () async {
      await event('Taille', start: day.addDays(10));
      expect(await calendar.watchBetween(day, day.addDays(5)).first, isEmpty);
    });

    test('un événement de plusieurs jours remonte s\'il chevauche la plage', () async {
      await event('Vacances', start: day, end: day.addDays(20));
      final found = await calendar.watchBetween(day.addDays(10), day.addDays(12)).first;
      expect(found, hasLength(1), reason: 'la plage tombe au milieu de l\'événement');
    });

    test('les bornes de la plage sont incluses', () async {
      await event('Début', start: day);
      await event('Fin', start: day.addDays(5));
      expect(await calendar.watchBetween(day, day.addDays(5)).first, hasLength(2));
    });

    test('un événement à une heure tardive reste dans son jour', () async {
      await event('Soirée', start: DateTime(2026, 6, 15, 23, 30), allDay: false);
      expect(await calendar.watchBetween(day, day).first, hasLength(1));
    });
  });

  group('rappels', () {
    test('l\'instant du rappel précède le début', () async {
      final created = await event('Marché', start: DateTime(2026, 6, 15, 14), allDay: false, reminder: 60);
      expect(created.remindAt, DateTime(2026, 6, 15, 13));
    });

    test('sans rappel, pas d\'instant', () async {
      expect((await event('Marché')).remindAt, isNull);
    });
  });

  group('catégories', () {
    test('création et ordre', () async {
      final a = await calendar.createCategory(label: 'Taille', emoji: '✂️');
      final b = await calendar.createCategory(label: 'Sorties');
      expect(a.position, 0);
      expect(b.position, 1);
      expect(a.emoji, '✂️');
    });

    test('supprimer une catégorie ne supprime pas ses événements', () async {
      final cat = await calendar.createCategory(label: 'Taille');
      final created = await event('Tailler le figuier', categoryId: cat.id);

      await calendar.deleteCategory(cat.id);

      expect(await calendar.watchCategories().first, isEmpty);
      final kept = await calendar.get(created.id);
      expect(kept, isNotNull);
      expect(kept!.categoryId, isNull);
    });

    test('réordonner change les positions', () async {
      final a = await calendar.createCategory(label: 'A');
      final b = await calendar.createCategory(label: 'B');
      await calendar.reorderCategories([b.id, a.id]);
      expect((await calendar.watchCategories().first).map((c) => c.label), ['B', 'A']);
    });

    test('chaque écriture est mise en file de synchronisation', () async {
      final created = await event('Taille');
      final pending = await (db.select(db.syncOutbox)..where((o) => o.entity.equals('calendar_entries') & o.entityId.equals(created.id))).get();
      expect(pending, isNotEmpty);
    });
  });

  group('projection dans le calendrier', () {
    CalendarEntry entry({required DateTime start, DateTime? end, bool allDay = true, String? plantId}) => CalendarEntry(
          id: 'e1',
          gardenId: gardenId,
          title: 'Marché',
          startAt: start,
          endAt: end,
          allDay: allDay,
          plantId: plantId,
          createdAt: day,
          updatedAt: day,
        );

    List<CalendarEvent> project(List<CalendarEntry> entries, {DateTime? from, DateTime? to}) => CalendarProjector.project(
          schedules: const [],
          actions: const [],
          plants: const {},
          entries: entries,
          from: from ?? day,
          to: to ?? day.addDays(30),
        );

    test('un événement d\'un jour donne un seul point', () {
      final events = project([entry(start: day)]);
      expect(events, hasLength(1));
      expect(events.single.kind, CalendarEventKind.custom);
      expect(events.single.title, 'Marché');
    });

    test('un événement de plusieurs jours apparaît chaque jour', () {
      final events = project([entry(start: day, end: day.addDays(2))]);
      expect(events.map((e) => e.date), [day, day.addDays(1), day.addDays(2)]);
    });

    test('seuls les jours dans la plage sont retenus', () {
      final events = project([entry(start: day.addDays(-2), end: day.addDays(1))], from: day, to: day.addDays(5));
      expect(events.map((e) => e.date), [day, day.addDays(1)]);
    });

    test('un événement à l\'heure garde son heure le premier jour', () {
      final start = DateTime(2026, 6, 15, 14, 30);
      final events = project([entry(start: start, end: day.addDays(1), allDay: false)]);
      expect(events.first.date, start);
      expect(events.last.date, day.addDays(1), reason: 'les jours suivants commencent au matin');
    });

    test('les événements se mêlent aux soins dans l\'ordre chronologique', () {
      final events = project([entry(start: day.addDays(3)), entry(start: day.addDays(1))]);
      expect(events.map((e) => e.date), [day.addDays(1), day.addDays(3)]);
    });

    test('une plante inconnue ne fait pas disparaître l\'événement', () {
      final events = project([entry(start: day, plantId: 'fantôme')]);
      expect(events, hasLength(1));
      expect(events.single.plantId, isNull, reason: 'l\'événement reste, sans plante');
    });
  });
}
