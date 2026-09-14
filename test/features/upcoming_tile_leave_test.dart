import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flora/app/providers.dart';
import 'package:flora/data/db/mappers.dart';
import 'package:flora/domain/models/models.dart';
import 'package:flora/domain/repositories/repositories.dart';
import 'package:flora/features/today/presentation/upcoming_section.dart';
import 'package:flutter_test/flutter_test.dart';

import '../app/app_smoke_test.dart' as harness;

/// Un soin enregistré depuis la grille « À venir » repousse l'échéance, donc
/// le rang : la tuile filait en fin de grille, une autre prenait sa case, et
/// de l'écran cela ressemblait à une disparition instantanée.
///
/// Elle garde maintenant sa case le temps de dire « Arrosée », puis s'efface.
void main() {
  testWidgets('la tuile arrosée garde sa case avant de s\'effacer', (tester) async {
    final container = await harness.boot(tester, seed: (c) async {
      final plants = c.read(plantRepositoryProvider);
      final db = c.read(databaseProvider);
      // Trois plantes au même intervalle, arrosées à des dates différentes :
      // elles tombent dans deux, quatre et six jours, et la grille les range
      // ainsi. Arroser la deuxième repousse son échéance de dix jours — c'est
      // ce saut de rang qui la faisait disparaître de l'écran.
      const intervalle = 10;
      for (final (name, dans) in [('Alpha', 2), ('Beta', 4), ('Gamma', 6)]) {
        final plant = await plants.create(NewPlant(name: name, wateringIntervalDays: intervalle));
        final watering = (await (db.select(db.careSchedules)
                  ..where((s) => s.plantId.equals(plant.id) & s.typeKey.equals(CareKind.watering.key)))
                .getSingle())
            .toDomain();
        await c.read(careRepositoryProvider).upsert(watering.copyWith(intervalDays: intervalle));
        await c.read(actionRepositoryProvider).log(
              NewAction(
                plantId: plant.id,
                typeKey: 'watering',
                occurredAt: DateTime.now().subtract(Duration(days: intervalle - dans)),
              ),
            );
      }
    });
    await harness.pumpApp(tester, container);

    // La grille est paresseuse : seules les tuiles à l'écran sont construites.
    // C'est justement ce qui rendait le saut visible — la troisième prenait la
    // case de la deuxième.
    List<String> ordre() => tester
        .widgetList<UpcomingTile>(find.byType(UpcomingTile))
        .map((t) => t.task.summary.plant.name)
        .toList();

    expect(ordre(), ['Alpha', 'Beta']);

    // Le rond de validation de la tuile du milieu.
    await tester.tap(find.descendant(
      of: find.ancestor(of: find.text('Beta'), matching: find.byType(UpcomingTile)),
      matching: find.bySemanticsLabel('Arroser'),
    ));
    await tester.pump(const Duration(milliseconds: 400));

    expect(ordre(), ['Alpha', 'Beta'], reason: 'elle garde sa case pendant qu\'elle confirme');
    expect(find.text('Arrosée'), findsOneWidget, reason: 'et elle le dit');

    // Puis elle s'en va, et la grille se referme sur les deux autres. Le
    // séjour tient sur des minuteurs qui ne demandent pas d'image : on avance
    // le temps à la main plutôt que d'attendre un repos qui vient trop tôt.
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump(const Duration(milliseconds: 600));
    await harness.settle(tester);
    expect(ordre(), ['Alpha', 'Gamma']);
    await tester.pump(const Duration(seconds: 6));
  });
}
