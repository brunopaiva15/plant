import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flora/app/providers.dart';
import 'package:flora/data/db/mappers.dart';
import 'package:flora/design_system/design_system.dart';
import 'package:flora/domain/models/models.dart';
import 'package:flora/domain/repositories/repositories.dart';
import 'package:flutter_test/flutter_test.dart';

import '../app/app_smoke_test.dart' as harness;

/// Le grand chiffre du matin dit ce qu'il y a à faire, jamais ce qu'on
/// possède. Une première version passait au nombre de plantes une fois la
/// journée faite : « 14 plantes », tous les jours, qui ne disait rien.
void main() {
  Future<HeroNumber> hero(WidgetTester tester, {required int arroseeIlYa}) async {
    final container = await harness.boot(tester, seed: (c) async {
      final db = c.read(databaseProvider);
      final plant = await c.read(plantRepositoryProvider).create(const NewPlant(name: 'Alpha', wateringIntervalDays: 10));
      final watering = (await (db.select(db.careSchedules)
                ..where((s) => s.plantId.equals(plant.id) & s.typeKey.equals(CareKind.watering.key)))
              .getSingle())
          .toDomain();
      await c.read(careRepositoryProvider).upsert(watering.copyWith(intervalDays: 10));
      await c.read(actionRepositoryProvider).log(
            NewAction(plantId: plant.id, typeKey: 'watering', occurredAt: DateTime.now().subtract(Duration(days: arroseeIlYa))),
          );
    });
    await harness.pumpApp(tester, container);
    return tester.widget<HeroNumber>(find.byType(HeroNumber));
  }

  testWidgets('un arrosage dû aujourd\'hui : les soins du jour', (tester) async {
    final h = await hero(tester, arroseeIlYa: 10);
    expect(h.label, contains('aujourd'));
    expect(int.parse(h.value), greaterThan(0));
  });

  testWidgets('la journée faite : les soins de la semaine, pas les plantes', (tester) async {
    // Arrosée il y a sept jours, tous les dix jours : dans trois jours.
    final h = await hero(tester, arroseeIlYa: 7);
    expect(h.label, contains('cette semaine'));
    expect(int.parse(h.value), greaterThanOrEqualTo(1));
    expect(h.label, isNot(contains('plante')));
  });
}
