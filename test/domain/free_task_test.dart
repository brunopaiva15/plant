import 'package:flora/domain/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  FreeTask task({DateTime? dueAt, bool allDay = true, bool done = false}) => FreeTask(
        id: 't',
        gardenId: 'g',
        title: 'Nettoyer la serre',
        allDay: allDay,
        done: done,
        dueAt: dueAt,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

  group('TaskRecurrence.next', () {
    test('heures, jours et semaines avancent d\'une durée fixe', () {
      final from = DateTime(2026, 3, 10, 9);
      expect(const TaskRecurrence(value: 6, unit: RecurrenceUnit.hours).next(from), DateTime(2026, 3, 10, 15));
      expect(const TaskRecurrence(value: 3, unit: RecurrenceUnit.days).next(from), DateTime(2026, 3, 13, 9));
      expect(const TaskRecurrence(value: 2, unit: RecurrenceUnit.weeks).next(from), DateTime(2026, 3, 24, 9));
    });

    test('les mois gardent le jour du mois', () {
      expect(const TaskRecurrence(value: 1, unit: RecurrenceUnit.months).next(DateTime(2026, 1, 15)), DateTime(2026, 2, 15));
      expect(const TaskRecurrence(value: 3, unit: RecurrenceUnit.months).next(DateTime(2026, 11, 5)), DateTime(2027, 2, 5));
    });

    test('un jour absent du mois cible est ramené au dernier jour', () {
      expect(const TaskRecurrence(value: 1, unit: RecurrenceUnit.months).next(DateTime(2026, 1, 31)), DateTime(2026, 2, 28));
      expect(const TaskRecurrence(value: 1, unit: RecurrenceUnit.years).next(DateTime(2028, 2, 29)), DateTime(2029, 2, 28));
    });

    test('nextAfter rattrape les occurrences manquées', () {
      // Échéance du 1er mars, hebdomadaire, on complète le 20 mars.
      final next = const TaskRecurrence(value: 1, unit: RecurrenceUnit.weeks).nextAfter(DateTime(2026, 3, 1), DateTime(2026, 3, 20));
      expect(next, DateTime(2026, 3, 22));
    });
  });

  group('FreeTask.status', () {
    final now = DateTime(2026, 3, 10, 14);

    test('sans date', () => expect(task().status(now), FreeTaskStatus.noDate));
    test('terminée', () => expect(task(dueAt: DateTime(2026, 1, 1), done: true).status(now), FreeTaskStatus.done));
    test('journée entière : le jour même est « aujourd\'hui »', () {
      expect(task(dueAt: DateTime(2026, 3, 10)).status(now), FreeTaskStatus.today);
    });
    test('journée entière : la veille est en retard', () {
      expect(task(dueAt: DateTime(2026, 3, 9)).status(now), FreeTaskStatus.overdue);
    });
    test('avec heure : dépassée dans la journée = en retard', () {
      expect(task(dueAt: DateTime(2026, 3, 10, 9), allDay: false).status(now), FreeTaskStatus.overdue);
    });
    test('avec heure : plus tard dans la journée = aujourd\'hui', () {
      expect(task(dueAt: DateTime(2026, 3, 10, 18), allDay: false).status(now), FreeTaskStatus.today);
    });
    test('à venir', () => expect(task(dueAt: DateTime(2026, 3, 12)).status(now), FreeTaskStatus.upcoming));
  });
}
