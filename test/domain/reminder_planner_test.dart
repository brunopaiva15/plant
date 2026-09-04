import 'package:flora/domain/care/reminder_planner.dart';
import 'package:flora/domain/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

CareTask task(String name, String type, DateTime due) {
  final now = DateTime(2026, 9, 4);
  return CareTask(
    summary: PlantSummary(
      plant: Plant(
        id: name,
        gardenId: 'g',
        name: name,
        status: PlantStatus.active,
        health: PlantHealth.healthy,
        isFavorite: false,
        createdAt: now,
        updatedAt: now,
      ),
    ),
    schedule: CareSchedule(
      id: '$name-$type',
      plantId: name,
      typeKey: type,
      strategy: CareStrategy.fixed,
      intervalDays: 7,
      enabled: true,
      nextDueAt: due,
      createdAt: now,
      updatedAt: now,
    ),
  );
}

void main() {
  final now = DateTime(2026, 9, 4, 9);

  test('digest groups due plants by type, ordered by due date, ignoring upcoming ones', () {
    final digest = ReminderPlanner.digest([
      task('Pilea', 'watering', DateTime(2026, 9, 4)),
      task('Monstera', 'watering', DateTime(2026, 9, 2)),
      task('Ficus', 'fertilizing', DateTime(2026, 9, 4)),
      task('Calathea', 'watering', DateTime(2026, 9, 8)),
    ], now);
    expect(digest.byType['watering'], ['Monstera', 'Pilea']);
    expect(digest.byType['fertilizing'], ['Ficus']);
    expect(digest.totalPlants, 3);
  });

  test('digest is empty when nothing is due', () {
    expect(ReminderPlanner.digest([task('Pilea', 'watering', DateTime(2026, 9, 6))], now).isEmpty, isTrue);
  });

  test('nextFireTime picks today if the hour is still ahead, tomorrow otherwise', () {
    expect(ReminderPlanner.nextFireTime(now, hour: 10, minute: 0), DateTime(2026, 9, 4, 10));
    expect(ReminderPlanner.nextFireTime(now, hour: 8, minute: 0), DateTime(2026, 9, 5, 8));
  });

  test('nextFireTime skips quiet weekdays', () {
    // 2026-09-05 is a Saturday (6), 09-06 a Sunday (7).
    final t = ReminderPlanner.nextFireTime(now, hour: 8, minute: 0, quietWeekdays: {6, 7});
    expect(t, DateTime(2026, 9, 7, 8));
  });
}
