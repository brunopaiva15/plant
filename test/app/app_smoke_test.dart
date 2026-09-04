import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flora/app/app.dart';
import 'package:flora/app/providers.dart';
import 'package:flora/data/auth/local_auth_repository.dart';
import 'package:flora/data/db/database.dart';
import 'package:flora/data/db/mappers.dart';
import 'package:flora/data/services/notification_service.dart';
import 'package:flora/data/services/preferences_service.dart';
import 'package:flora/domain/models/models.dart';
import 'package:flora/design_system/design_system.dart';
import 'package:flora/domain/repositories/repositories.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeNotifications extends NotificationService {
  int scheduled = 0;
  @override
  Future<void> init() async {}
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<void> scheduleDaily({required DateTime at, required String title, required String body, required String channelName, String? payload}) async {
    scheduled++;
  }

  @override
  Future<void> cancelAll() async {}
}

/// Démarre l'app avec une base en mémoire.
///
/// Sous FakeAsync, les requêtes drift (insert / select) se résolvent, mais les
/// flux (`watch`) attendent un timer : le seed n'utilise donc que des requêtes.
Future<ProviderContainer> boot(WidgetTester tester, {bool onboardingDone = true, Future<void> Function(ProviderContainer c)? seed}) async {
  SharedPreferences.setMockInitialValues({'onboarding_done': onboardingDone, 'locale': 'fr'});
  final prefs = await PreferencesService.load();
  final db = FloraDatabase(NativeDatabase.memory());
  final auth = LocalAuthRepository(db, prefs);
  await auth.ensureLocalUser();
  final container = ProviderContainer(overrides: [
    databaseProvider.overrideWithValue(db),
    preferencesServiceProvider.overrideWithValue(prefs),
    notificationServiceProvider.overrideWithValue(FakeNotifications()),
    authRepositoryProvider.overrideWithValue(auth),
    gardenIdProvider.overrideWithValue(auth.gardenId),
  ]);
  if (seed != null) await seed(container);
  addTearDown(container.dispose);
  return container;
}

Future<List<PlantActionRow>> actionsOf(ProviderContainer c, String plantId) {
  final db = c.read(databaseProvider);
  return (db.select(db.plantActions)..where((a) => a.plantId.equals(plantId))).get();
}

Future<void> pumpApp(WidgetTester tester, ProviderContainer container) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const FloraApp()));
  await settle(tester);
}

Future<void> settle(WidgetTester tester) => tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5));

void main() {
  testWidgets('empty garden shows the first-plant call to action', (tester) async {
    final container = await boot(tester);
    await pumpApp(tester, container);
    expect(find.text('Votre jardin commence ici.'), findsOneWidget);
    expect(find.text('Ajouter ma première plante'), findsOneWidget);
  });

  testWidgets('a due plant appears on Today and can be watered in one tap with undo', (tester) async {
    late String plantId;
    final container = await boot(tester, seed: (c) async {
      final plants = c.read(plantRepositoryProvider);
      final care = c.read(careRepositoryProvider);
      final salon = await c.read(locationRepositoryProvider).create(name: 'Salon', icon: '🛋️');
      final plant = await plants.create(NewPlant(name: 'Monstera', locationId: salon.id));
      plantId = plant.id;
      final db = c.read(databaseProvider);
      final watering = (await (db.select(db.careSchedules)..where((s) => s.plantId.equals(plant.id) & s.typeKey.equals(CareKind.watering.key))).getSingle()).toDomain();
      await care.upsert(watering.copyWith(intervalDays: 1));
      await c.read(actionRepositoryProvider).log(NewAction(plantId: plant.id, typeKey: 'watering', occurredAt: DateTime.now().subtract(const Duration(days: 2))));
    });

    await pumpApp(tester, container);
    expect(find.text('Monstera'), findsWidgets);
    expect(find.text('Arroser'), findsOneWidget);

    await tester.tap(find.text('Arroser'));
    await tester.pump(const Duration(milliseconds: 300));
    // La carte reste visible en état « Arrosée » le temps de l'animation.
    expect(find.text('Arrosée'), findsOneWidget);
    expect(find.text('Annuler'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await settle(tester);
    // Puis elle quitte la section « En retard » et passe en « À venir ».
    expect(find.text('Arrosée'), findsNothing);
    expect(find.text('À venir'), findsOneWidget);

    final logged = await actionsOf(container, plantId);
    expect(logged, hasLength(2));
    expect(logged.map((a) => a.typeKey), everyElement('watering'));
    expect(logged.any((a) => DateTime.now().difference(a.occurredAt).inMinutes < 1), isTrue);

    await tester.tap(find.text('Annuler'));
    await tester.pump(const Duration(milliseconds: 300));
    await settle(tester);
    final afterUndo = await actionsOf(container, plantId);
    expect(afterUndo, hasLength(1));
    expect(find.text('En retard'), findsOneWidget);
    expect(find.text('Arroser'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('tabs render the collection, the garden and the profile', (tester) async {
    final container = await boot(tester, seed: (c) => c.read(plantRepositoryProvider).create(const NewPlant(name: 'Pilea')));
    await pumpApp(tester, container);

    await tester.tap(find.text('Plantes'));
    await settle(tester);
    expect(find.text('Pilea'), findsOneWidget);

    await tester.tap(find.text('Pilea'));
    await settle(tester);
    expect(find.text('Prochains soins'), findsOneWidget);
    expect(find.text('Ajouter une action'), findsOneWidget);

    await tester.ensureVisible(find.text('Ajouter une action'));
    await settle(tester);
    await tester.tap(find.text('Ajouter une action'));
    await settle(tester);
    expect(find.text("Qu'avez-vous fait ?"), findsOneWidget);
    await tester.tap(find.text('Enregistrer'));
    await settle(tester);
    expect(find.textContaining('Arrosée'), findsWidgets);
    await tester.pump(const Duration(seconds: 6));

    await tester.tap(find.bySemanticsLabel('Retour'));
    await settle(tester);
    await tester.tap(find.text('Jardin'));
    await settle(tester);
    expect(find.text('Jardin'), findsWidgets);

    await tester.tap(find.text('Profil'));
    await settle(tester);
    expect(find.text('Apparence'), findsOneWidget);
  });

  testWidgets('garden tab shows inventory and calendar without layout errors', (tester) async {
    final container = await boot(tester, seed: (c) async {
      await c.read(plantRepositoryProvider).create(const NewPlant(name: 'Hoya'));
      await c.read(inventoryRepositoryProvider).create(category: InventoryCategory.fertilizer, name: 'Engrais', quantity: 120, unit: 'ml', lowThreshold: 200);
    });
    await pumpApp(tester, container);
    await tester.tap(find.text('Jardin'));
    await settle(tester);
    expect(find.text('Aucun emplacement'), findsOneWidget);

    await tester.tap(find.text('Inventaire'));
    await settle(tester);
    expect(find.text('Engrais'), findsWidgets);
    expect(find.text('1 article en stock bas'), findsOneWidget);
    await tester.tap(find.byIcon(CupertinoIcons.plus).last);
    await settle(tester);
    expect(find.textContaining('170 ml'), findsOneWidget);

    await tester.tap(find.text('Calendrier'));
    await settle(tester);
    expect(find.text('Hoya'), findsWidgets);
    await tester.tap(find.text('Mois'));
    await settle(tester);
    expect(find.text('Agenda'), findsOneWidget);
  });

  testWidgets('a due task shows on Today and on the Garden tasks tab, and can be ticked off', (tester) async {
    late String plantId;
    final container = await boot(tester, seed: (c) async {
      final plant = await c.read(plantRepositoryProvider).create(const NewPlant(name: 'Monstera'));
      plantId = plant.id;
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      await c.read(taskRepositoryProvider).create(NewTask(title: 'Nettoyer la serre', dueAt: yesterday));
      await c.read(taskRepositoryProvider).create(NewTask(title: 'Bouturer', plantId: plantId, dueAt: yesterday));
    });
    await pumpApp(tester, container);

    // Aujourd'hui : les deux tâches échues sont listées.
    expect(find.text('Nettoyer la serre'), findsOneWidget);
    expect(find.text('Bouturer'), findsOneWidget);

    // Onglet Jardin > Tâches.
    await tester.tap(find.text('Jardin'));
    await settle(tester);
    await tester.tap(find.text('Tâches').first);
    await settle(tester);
    expect(find.text('Nettoyer la serre'), findsOneWidget);

    // Cocher la tâche : la ligne passe en terminée (requête directe : sous
    // FakeAsync, `stream.first` n'émet jamais).
    await tester.tap(find.descendant(of: find.widgetWithText(FloraListRow, 'Nettoyer la serre'), matching: find.byType(Pressable)).last);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(seconds: 2));
    await settle(tester);
    final db = container.read(databaseProvider);
    final rows = await (db.select(db.tasks)..where((t) => t.title.equals('Nettoyer la serre'))).get();
    expect(rows.single.done, isTrue);
    // Laisse expirer la fenêtre d'annulation du toast (5 s) : sinon un timer
    // reste en attente à la fin du test.
    await tester.pump(const Duration(seconds: 6));
    await settle(tester);
  });

  testWidgets('onboarding leads to Today after entering a name', (tester) async {
    final container = await boot(tester, onboardingDone: false);
    await pumpApp(tester, container);
    expect(find.text('Votre jardin, simplement.'), findsOneWidget);
    // « Passer » saute les diapositives et mène droit à la saisie du prénom.
    await tester.tap(find.text('Passer'));
    await settle(tester);
    expect(find.text('Comment vous appelez-vous\u00a0?'), findsOneWidget);
    await tester.enterText(find.byType(EditableText), 'Bruno');
    await tester.tap(find.text('Plus tard'));
    await settle(tester);
    expect(find.text('Bonjour Bruno'), findsWidgets);
    expect(container.read(preferencesProvider).onboardingDone, isTrue);
  });
}
