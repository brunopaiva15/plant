import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flora/app/providers.dart';
import 'package:flora/data/db/mappers.dart';
import 'package:flora/domain/models/models.dart';
import 'package:flora/domain/repositories/repositories.dart';
import 'package:flora/features/today/presentation/care_task_card.dart';
import 'package:flutter_test/flutter_test.dart';

import '../app/app_smoke_test.dart' as harness;

/// Une carte dont le soin vient d'être enregistré ne disparaît pas d'un coup :
/// elle tient un instant en « Arrosée », puis s'en va vers la droite en
/// s'effaçant, et la place qu'elle occupait se referme derrière elle.
void main() {
  testWidgets('la carte s\'en va en refermant sa place', (tester) async {
    final container = await harness.boot(tester, seed: (c) async {
      final plants = c.read(plantRepositoryProvider);
      final plant = await plants.create(const NewPlant(name: 'Monstera'));
      final db = c.read(databaseProvider);
      final watering = (await (db.select(db.careSchedules)
                ..where((s) => s.plantId.equals(plant.id) & s.typeKey.equals(CareKind.watering.key)))
              .getSingle())
          .toDomain();
      await c.read(careRepositoryProvider).upsert(watering.copyWith(intervalDays: 1));
      await c.read(actionRepositoryProvider).log(
            NewAction(plantId: plant.id, typeKey: 'watering', occurredAt: DateTime.now().subtract(const Duration(days: 2))),
          );
    });
    await harness.pumpApp(tester, container);

    final card = find.byType(CareTaskCard);
    expect(card, findsOneWidget);
    final pleine = tester.getSize(card).height;
    expect(pleine, greaterThan(40));

    await tester.tap(find.text('Arroser'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Arrosée'), findsOneWidget);
    expect(tester.getSize(card).height, pleine, reason: 'elle tient sa place le temps qu\'on puisse annuler');

    // La sortie commence après le temps de lecture.
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump(const Duration(milliseconds: 200));
    final enPartant = tester.getSize(card).height;
    expect(enPartant, lessThan(pleine), reason: 'la place se referme pendant qu\'elle s\'en va');
    expect(enPartant, greaterThan(0), reason: 'et elle ne se referme pas d\'un coup');

    await harness.settle(tester);
    expect(find.byType(CareTaskCard), findsNothing);
    await tester.pump(const Duration(seconds: 6));
  });
}
