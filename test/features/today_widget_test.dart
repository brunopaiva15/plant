import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;

import 'package:flora/app/providers.dart';
import 'package:flora/data/db/mappers.dart';
import 'package:flora/domain/models/models.dart';
import 'package:flora/domain/repositories/repositories.dart';
import 'package:flora/features/today/application/today_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../app/app_smoke_test.dart' as harness;

/// Le widget montre ce que l'application lui écrit : le chiffre du jour, les
/// premières lignes dans l'ordre de l'écran Aujourd'hui, et les mots des
/// états sans ligne — tout déjà traduit, pluriels compris.
/// Comme `main.dart` : on écoute l'instantané, ce qui garde les soins en
/// vie, et on attend qu'ils soient chargés.
Future<TodayWidgetSnapshot> load(WidgetTester tester, ProviderContainer container) async {
  final sub = container.listen(todayWidgetSnapshotProvider, (_, _) {});
  addTearDown(sub.close);
  // Les flux de la base livrent sur un timer : on avance le temps jusqu'à ce
  // que l'instantané existe.
  for (var i = 0; i < 50 && sub.read() == null; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  return sub.read()!;
}

void main() {
  testWidgets('l\'instantané dit le chiffre du jour et les plantes qui attendent', (tester) async {
    final container = await harness.boot(tester, seed: (c) async {
      final plants = c.read(plantRepositoryProvider);
      final care = c.read(careRepositoryProvider);
      final db = c.read(databaseProvider);
      Future<void> due(String name, int daysAgo) async {
        final plant = await plants.create(NewPlant(name: name));
        final watering = (await (db.select(db.careSchedules)..where((s) => s.plantId.equals(plant.id) & s.typeKey.equals(CareKind.watering.key))).getSingle()).toDomain();
        await care.upsert(watering.copyWith(intervalDays: 1));
        await c.read(actionRepositoryProvider).log(NewAction(plantId: plant.id, typeKey: 'watering', occurredAt: DateTime.now().subtract(Duration(days: daysAgo))));
      }

      await due('Pilea', 2);
      await due('Monstera', 5);
      await plants.create(const NewPlant(name: 'Cactus'));
    });

    final snapshot = await load(tester, container);
    expect(snapshot.dueCount, 2);
    expect(snapshot.plantCount, 3);
    expect(snapshot.tasks.map((t) => t.name), ['Monstera', 'Pilea'], reason: 'la plus en retard d\'abord');
    expect(snapshot.tasks.first.label, 'Arroser');
    expect(snapshot.tasks.first.emoji, '💧');
    expect(snapshot.tasks.first.overdue, isTrue);
    expect(snapshot.tasks.first.due, 'En retard de 4 jours');
    expect(snapshot.labels['count'], 'soins');
    expect(snapshot.labels['allDone'], 'Tout est en ordre');

    final json = jsonDecode(snapshot.encode()) as Map<String, Object?>;
    expect(json['version'], 1);
    expect((json['tasks'] as List).first, containsPair('plantId', isNotNull));
  });

  testWidgets('sans plante, le chiffre est zéro et le mot est « Aucune plante »', (tester) async {
    final container = await harness.boot(tester);
    final snapshot = await load(tester, container);
    expect(snapshot.dueCount, 0);
    expect(snapshot.plantCount, 0);
    expect(snapshot.tasks, isEmpty);
    expect(snapshot.labels['empty'], 'Aucune plante');
  });
}
