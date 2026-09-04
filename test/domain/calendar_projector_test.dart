import 'package:flora/domain/care/calendar_projector.dart';
import 'package:flora/domain/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 9, 4);
  PlantSummary plant(String id) => PlantSummary(
        plant: Plant(id: id, gardenId: 'g', name: id, status: PlantStatus.active, health: PlantHealth.healthy, isFavorite: false, createdAt: now, updatedAt: now),
      );
  CareSchedule schedule(String plantId, {CareStrategy strategy = CareStrategy.fixed, int interval = 7, DateTime? next, bool enabled = true}) => CareSchedule(
        id: '$plantId-w',
        plantId: plantId,
        typeKey: 'watering',
        strategy: strategy,
        intervalDays: interval,
        enabled: enabled,
        nextDueAt: next ?? DateTime(2026, 9, 6),
        createdAt: now,
        updatedAt: now,
      );

  test('projects the next due date then repeats the interval until the end of the range', () {
    final events = CalendarProjector.project(
      schedules: [schedule('Monstera')],
      actions: const [],
      plants: {'Monstera': plant('Monstera')},
      from: DateTime(2026, 9, 1),
      to: DateTime(2026, 9, 30),
    );
    expect(events.map((e) => e.date), [DateTime(2026, 9, 6), DateTime(2026, 9, 13), DateTime(2026, 9, 20), DateTime(2026, 9, 27)]);
    expect(events.first.kind, CalendarEventKind.due);
    expect(events.skip(1).every((e) => e.kind == CalendarEventKind.projected), isTrue);
  });

  test('ignores manual and disabled routines, and plants outside the map', () {
    final events = CalendarProjector.project(
      schedules: [schedule('A', strategy: CareStrategy.manual), schedule('B', enabled: false), schedule('C')],
      actions: const [],
      plants: {'A': plant('A'), 'B': plant('B')},
      from: DateTime(2026, 9, 1),
      to: DateTime(2026, 9, 30),
    );
    expect(events, isEmpty);
  });

  test('includes past actions within the range and sorts everything chronologically', () {
    final events = CalendarProjector.project(
      schedules: [schedule('Pilea', next: DateTime(2026, 9, 10))],
      actions: [
        PlantAction(id: 'a1', plantId: 'Pilea', typeKey: 'fertilizing', occurredAt: DateTime(2026, 9, 2, 9), createdAt: now),
        PlantAction(id: 'a2', plantId: 'Pilea', typeKey: 'watering', occurredAt: DateTime(2026, 8, 20), createdAt: now),
      ],
      plants: {'Pilea': plant('Pilea')},
      from: DateTime(2026, 9, 1),
      to: DateTime(2026, 9, 12),
    );
    expect(events.map((e) => e.kind), [CalendarEventKind.past, CalendarEventKind.due]);
    final days = CalendarProjector.byDay(events);
    expect(days.keys, [DateTime(2026, 9, 2), DateTime(2026, 9, 10)]);
  });

  test('seasonal routines stretch projected intervals in winter', () {
    final events = CalendarProjector.project(
      schedules: [schedule('Ficus', strategy: CareStrategy.seasonal, interval: 10, next: DateTime(2026, 1, 5))],
      actions: const [],
      plants: {'Ficus': plant('Ficus')},
      from: DateTime(2026, 1, 1),
      to: DateTime(2026, 1, 31),
    );
    expect(events.map((e) => e.date), [DateTime(2026, 1, 5), DateTime(2026, 1, 20)]);
  });
}
