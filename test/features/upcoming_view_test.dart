import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flora/app/providers.dart';
import 'package:flora/data/db/mappers.dart';
import 'package:flora/design_system/design_system.dart';
import 'package:flora/domain/models/models.dart';
import 'package:flora/domain/repositories/repositories.dart';
import 'package:flora/features/today/presentation/care_task_card.dart';
import 'package:flora/features/today/presentation/upcoming_section.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../app/app_smoke_test.dart' as harness;

/// « À venir » : la grille, la liste, et le bouton qui passe de l'une à l'autre.
///
/// C'est la seule section de l'écran du matin qui se lit en grille — des
/// photos plutôt qu'une colonne de cartes — et le choix se garde d'une
/// session à l'autre.

/// Une plante dont le prochain arrosage tombe dans [inDays] jours.
Future<void> seedUpcoming(ProviderContainer c, String name, int inDays) async {
  final plant = await c.read(plantRepositoryProvider).create(NewPlant(name: name));
  final db = c.read(databaseProvider);
  final watering = (await (db.select(db.careSchedules)
            ..where((s) => s.plantId.equals(plant.id) & s.typeKey.equals(CareKind.watering.key)))
          .getSingle())
      .toDomain();
  await c.read(careRepositoryProvider).upsert(watering.copyWith(intervalDays: inDays));
  // Un soin enregistré aujourd'hui repousse l'échéance d'un intervalle.
  await c.read(actionRepositoryProvider).log(NewAction(plantId: plant.id, typeKey: CareKind.watering.key, occurredAt: DateTime.now()));
}

/// Amène la section sous les yeux : posée plus bas que la carte du jour, ses
/// [tiles] tuiles ne sont pas construites tant qu'elles n'approchent pas de
/// l'écran.
Future<void> revealUpcoming(WidgetTester tester, {int tiles = 1}) async {
  for (var i = 0; i < 12 && find.byType(UpcomingTile).evaluate().length < tiles; i++) {
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -280));
    await tester.pump();
  }
  await harness.settle(tester);
}

void main() {
  testWidgets('la section s\'ouvre en grille, et un seul tap la passe en liste', (tester) async {
    final container = await harness.boot(tester, seed: (c) => seedUpcoming(c, 'Monstera', 3));
    await harness.pumpApp(tester, container);
    await revealUpcoming(tester);

    expect(find.text('À venir'), findsOneWidget);
    // La grille est la vue d'accueil de la section.
    expect(find.byType(UpcomingTile), findsOneWidget);
    expect(find.byType(CareTaskCard), findsNothing);

    await tester.tap(find.bySemanticsLabel('Afficher en liste'));
    await harness.settle(tester);

    expect(find.byType(CareTaskCard), findsOneWidget);
    expect(find.byType(UpcomingTile), findsNothing);
    // Le choix est mémorisé : on le retrouvera au lancement suivant.
    expect(container.read(preferencesServiceProvider).upcomingGridView, isFalse);

    await tester.tap(find.bySemanticsLabel('Afficher en grille'));
    await harness.settle(tester);

    expect(find.byType(UpcomingTile), findsOneWidget);
    expect(container.read(preferencesServiceProvider).upcomingGridView, isTrue);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('le bouton se tient au bout de la ligne du titre, sans libellé', (tester) async {
    final container = await harness.boot(tester, seed: (c) => seedUpcoming(c, 'Monstera', 3));
    await harness.pumpApp(tester, container);
    await revealUpcoming(tester);

    final button = find.bySemanticsLabel('Afficher en liste');
    // Même ligne que « À venir »…
    expect(tester.getCenter(button).dy, closeTo(tester.getCenter(find.text('À venir')).dy, 1));
    // … et le glyphe de 20 points, centré là, s'arrête pile sur la marge de
    // page : la boîte tactile de 44 points déborde, le dessin non.
    expect(tester.getCenter(button).dx + 10, closeTo(390 - Space.page, 1));
    expect(tester.getSize(button), const Size(kMinTapTarget, kMinTapTarget));
    // Aucun mot ne double l'icône.
    expect(find.text('Liste'), findsNothing);
    expect(find.text('Grille'), findsNothing);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('la grille range les tuiles sur deux colonnes', (tester) async {
    final container = await harness.boot(tester, seed: (c) async {
      await seedUpcoming(c, 'Monstera', 3);
      await seedUpcoming(c, 'Pilea', 4);
      await seedUpcoming(c, 'Ficus', 5);
    });
    await harness.pumpApp(tester, container);
    await revealUpcoming(tester, tiles: 3);

    final tiles = find.byType(UpcomingTile);
    expect(tiles, findsNWidgets(3));
    final first = tester.getRect(tiles.at(0));
    final second = tester.getRect(tiles.at(1));
    final third = tester.getRect(tiles.at(2));
    // Deux voisines sur la même ligne, la troisième en dessous.
    expect(second.top, closeTo(first.top, 1));
    expect(second.left, greaterThan(first.right));
    expect(third.top, greaterThan(first.bottom));
    // La photo tient le haut de la tuile : plus haute que large.
    expect(first.height, greaterThan(first.width));
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('à 200 % de Dynamic Type, la tuile s\'allonge au lieu de rogner', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final container = await harness.boot(tester, seed: (c) => seedUpcoming(c, 'Monstera', 3));
    await harness.pumpApp(tester, container);
    await revealUpcoming(tester);

    expect(find.byType(UpcomingTile), findsOneWidget);
    // Un débordement se signalerait par une exception : il n'y en a pas.
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 6));
  });
}
