import 'package:flora/domain/care/care_engine.dart';
import 'package:flora/domain/care/season.dart';
import 'package:flora/domain/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

CareSchedule schedule({CareStrategy strategy = CareStrategy.fixed, int interval = 7, bool enabled = true, Map<String, double>? rules}) {
  final now = DateTime(2026, 9, 4, 10);
  return CareSchedule(
    id: 's1',
    plantId: 'p1',
    typeKey: CareKind.watering.key,
    strategy: strategy,
    intervalDays: interval,
    enabled: enabled,
    seasonalRules: rules,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('CareEngine.nextDueAfter', () {
    test('fixed interval adds the interval from midnight of completion day', () {
      final next = CareEngine.nextDueAfter(schedule(), DateTime(2026, 9, 4, 18, 30));
      expect(next, DateTime(2026, 9, 11));
    });

    test('manual strategy never produces a due date', () {
      expect(CareEngine.nextDueAfter(schedule(strategy: CareStrategy.manual), DateTime(2026, 9, 4)), isNull);
    });

    test('disabled schedule never produces a due date', () {
      expect(CareEngine.nextDueAfter(schedule(enabled: false), DateTime(2026, 9, 4)), isNull);
    });

    test('seasonal strategy stretches the interval in winter and shortens it in summer', () {
      final s = schedule(strategy: CareStrategy.seasonal, interval: 10);
      expect(CareEngine.nextDueAfter(s, DateTime(2026, 1, 10)), DateTime(2026, 1, 25)); // ×1.5
      expect(CareEngine.nextDueAfter(s, DateTime(2026, 7, 10)), DateTime(2026, 7, 18)); // ×0.8
      expect(CareEngine.nextDueAfter(s, DateTime(2026, 4, 10)), DateTime(2026, 4, 20)); // ×1.0
    });

    test('custom seasonal rules are honoured and clamped to at least one day', () {
      final s = schedule(strategy: CareStrategy.seasonal, interval: 2, rules: {'summer': 0.1});
      expect(CareEngine.nextDueAfter(s, DateTime(2026, 7, 1)), DateTime(2026, 7, 2));
    });
  });

  group('CareEngine.status', () {
    final now = DateTime(2026, 9, 4, 15);
    test('classifies overdue, today, upcoming and none', () {
      expect(CareEngine.status(DateTime(2026, 9, 2), now), DueStatus.overdue);
      expect(CareEngine.status(DateTime(2026, 9, 4, 23), now), DueStatus.today);
      expect(CareEngine.status(DateTime(2026, 9, 5, 0, 1), now), DueStatus.upcoming);
      expect(CareEngine.status(null, now), DueStatus.none);
    });

    test('daysUntil counts civil days, not 24h periods', () {
      expect(CareEngine.daysUntil(DateTime(2026, 9, 5, 1), DateTime(2026, 9, 4, 23, 59)), 1);
      expect(CareEngine.daysUntil(DateTime(2026, 9, 1), now), -3);
    });
  });

  test('complete records completion and moves next due', () {
    final done = CareEngine.complete(schedule(), DateTime(2026, 9, 4, 9, 42));
    expect(done.lastCompletedAt, DateTime(2026, 9, 4, 9, 42));
    expect(done.nextDueAt, DateTime(2026, 9, 11));
  });

  test('snooze pushes the due date to tomorrow', () {
    final s = CareEngine.snooze(schedule(), DateTime(2026, 9, 4, 20));
    expect(s.nextDueAt, DateTime(2026, 9, 5));
  });

  test('Season.of respects hemisphere', () {
    expect(Season.of(DateTime(2026, 1, 15)), Season.winter);
    expect(Season.of(DateTime(2026, 1, 15), southernHemisphere: true), Season.summer);
    expect(Season.of(DateTime(2026, 10, 1)), Season.autumn);
  });
}
