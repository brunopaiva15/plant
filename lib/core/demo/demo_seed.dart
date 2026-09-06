import 'package:flutter/foundation.dart';

import '../../data/db/database.dart';
import '../../data/repositories/action_repository_impl.dart';
import '../../data/repositories/calendar_repository_impl.dart';
import '../../data/repositories/care_repository_impl.dart';
import '../../data/repositories/inventory_repository_impl.dart';
import '../../data/repositories/location_repository_impl.dart';
import '../../data/repositories/photo_repository_impl.dart';
import '../../data/repositories/plant_repository_impl.dart';
import '../../data/repositories/tag_repository_impl.dart';
import '../../data/repositories/task_repository_impl.dart';
import '../../domain/models/models.dart';
import '../../domain/repositories/repositories.dart';

/// Jeu de données de démonstration pour la revue visuelle sur le web
/// (`?demo`), jamais en release. Les photos sont des liens vers des
/// fichiers CC0 servis à côté du build (store/demo-photos).
abstract final class DemoSeed {
  static bool get requested => !kReleaseMode && kIsWeb && Uri.base.queryParameters.containsKey('demo');

  static Future<void> apply(FloraDatabase db, String gardenId) async {
    final plants = DriftPlantRepository(db, gardenId);
    if ((await plants.watchSummaries(const PlantFilter()).first).isNotEmpty) return;
    final locations = DriftLocationRepository(db, gardenId);
    final actions = DriftActionRepository(db);
    final care = DriftCareRepository(db, plants);
    final tags = DriftTagRepository(db, gardenId);
    final inventory = DriftInventoryRepository(db, gardenId);
    final calendar = DriftCalendarRepository(db, gardenId);
    final tasks = DriftTaskRepository(db, gardenId);

    final all = await locations.watchAll().first;
    String? loc(String name) => all.where((l) => l.name.toLowerCase().startsWith(name)).firstOrNull?.id;
    final salon = loc('salon') ?? loc('living') ?? (await locations.create(name: 'Salon', icon: '🛋️')).id;
    final cuisine = loc('cuisine') ?? loc('kitchen');
    final balcon = loc('balcon') ?? loc('balcony');
    final bureau = (await locations.create(name: 'Bureau', icon: '🖥️')).id;

    final now = DateTime.now();
    Future<Plant> mk(String name, String? species, String? location, {int water = 7, int fert = 30, DateTime? acquired}) =>
        plants.create(NewPlant(name: name, speciesName: species, locationId: location, wateringIntervalDays: water, fertilizingIntervalDays: fert, acquiredAt: acquired));

    final monstera = await mk('Monstera', 'Monstera deliciosa', salon, acquired: DateTime(now.year - 1, 3, 12));
    final pilea = await mk('Pilea', 'Pilea peperomioides', salon, water: 5);
    final ficus = await mk('Ficus lyrata', 'Ficus lyrata', bureau, water: 8);
    final calathea = await mk('Calathea', 'Goeppertia orbifolia', cuisine, water: 4, fert: 21);
    final olivier = await mk('Olivier', 'Olea europaea', balcon, water: 6, fert: 45);
    final basilic = await mk('Basilic', 'Ocimum basilicum', balcon, water: 2, fert: 14);
    final pothos = await mk('Pothos', 'Epipremnum aureum', bureau, water: 9);
    final hoya = await mk('Hoya', 'Hoya carnosa', salon, water: 12, fert: 60);

    // Des photos, pour que la démo ressemble à une vraie collection : des
    // observations iNaturalist en CC0 (store/demo-photos, avec leurs
    // sources), servies à côté du build web. Distantes, donc jamais copiées.
    final photos = DriftPhotoRepository(db);
    for (final (plant, slug) in [(monstera, 'monstera'), (pilea, 'pilea'), (ficus, 'ficus'), (calathea, 'calathea'), (olivier, 'olivier'), (basilic, 'basilic'), (pothos, 'pothos'), (hoya, 'hoya')]) {
      final photo = await photos.addFromUrl(plantId: plant.id, url: '${Uri.base.origin}/demo-photos/$slug.jpg');
      await photos.setPrimary(plant.id, photo.id);
    }

    // Historique : arrosages passés qui rendent certains soins dus aujourd'hui / en retard.
    await actions.log(NewAction(plantId: monstera.id, typeKey: 'watering', occurredAt: now.subtract(const Duration(days: 8))));
    await actions.log(NewAction(plantId: pilea.id, typeKey: 'watering', occurredAt: now.subtract(const Duration(days: 5))));
    await actions.log(NewAction(plantId: calathea.id, typeKey: 'watering', occurredAt: now.subtract(const Duration(days: 6))));
    await actions.log(NewAction(plantId: ficus.id, typeKey: 'fertilizing', occurredAt: now.subtract(const Duration(days: 31))));
    await actions.log(NewAction(plantId: basilic.id, typeKey: 'watering', occurredAt: now.subtract(const Duration(days: 2))));
    await actions.log(NewAction(plantId: olivier.id, typeKey: 'watering', occurredAt: now.subtract(const Duration(days: 3))));
    await actions.log(NewAction(plantId: hoya.id, typeKey: 'watering', occurredAt: now.subtract(const Duration(days: 1))));
    await actions.log(NewAction(plantId: pothos.id, typeKey: 'watering', occurredAt: now.subtract(const Duration(days: 4))));
    await actions.log(NewAction(plantId: monstera.id, typeKey: 'note', occurredAt: now.subtract(const Duration(days: 12)), notes: 'Nouvelle feuille en train de sortir.'));
    await actions.log(NewAction(plantId: monstera.id, typeKey: 'repotting', occurredAt: now.subtract(const Duration(days: 40))));
    await actions.log(NewAction(plantId: monstera.id, typeKey: 'measurement', occurredAt: now.subtract(const Duration(days: 90)), metadata: {'kind': 'height', 'value': 34, 'unit': 'cm'}));
    await actions.log(NewAction(plantId: monstera.id, typeKey: 'measurement', occurredAt: now.subtract(const Duration(days: 30)), metadata: {'kind': 'height', 'value': 42, 'unit': 'cm'}));
    await actions.log(NewAction(plantId: monstera.id, typeKey: 'measurement', occurredAt: now.subtract(const Duration(days: 30)), metadata: {'kind': 'leaves', 'value': 9, 'unit': ''}));

    final tropical = await tags.create('Tropicale');
    final rare = await tags.create('Rare');
    await tags.setPlantTags(monstera.id, [tropical.id]);
    await tags.setPlantTags(calathea.id, [tropical.id, rare.id]);
    await plants.setFavorite(monstera.id, true);

    await inventory.create(category: InventoryCategory.fertilizer, name: 'Engrais plantes vertes', quantity: 420, unit: 'ml', lowThreshold: 100);
    await inventory.create(category: InventoryCategory.soil, name: 'Terreau tropical', quantity: 7, unit: 'L', lowThreshold: 5);
    await inventory.create(category: InventoryCategory.substrate, name: 'Perlite', quantity: 2, unit: 'L', lowThreshold: 3);
    await inventory.create(category: InventoryCategory.pot, name: 'Pots Ø15 cm', quantity: 4, unit: '');

    // Un groupe d'inventaire, avec un article étiqueté.
    final etagere = await inventory.createGroup(label: 'Étagère du balcon', emoji: '🪟');
    final graines = await inventory.create(category: InventoryCategory.seed, name: 'Graines de basilic', quantity: 3, unit: '', groupId: etagere.id);
    await inventory.setItemTags(graines.id, [rare.id]);

    // Deux événements de calendrier et leur catégorie.
    final sorties = await calendar.createCategory(label: 'Sorties', emoji: '🛒');
    await calendar.create(NewCalendarEntry(title: 'Marché aux plantes', startAt: now.add(const Duration(days: 3)), categoryId: sorties.id, reminderMinutes: 60));
    await calendar.create(NewCalendarEntry(
      title: 'Rempotage de printemps',
      startAt: now.add(const Duration(days: 9)),
      endAt: now.add(const Duration(days: 10)),
      plantId: ficus.id,
      notes: 'Prévoir du terreau et un pot plus large.',
    ));

    // Une tâche libre ouverte, et une plante archivée pour les archives.
    await tasks.create(NewTask(title: 'Commander du terreau', dueAt: now.add(const Duration(days: 1))));
    final disparue = await mk('Fougère', 'Nephrolepis exaltata', cuisine, acquired: DateTime(now.year - 2, 5, 4));
    await plants.archive([disparue.id], reason: 'died');

    // Une routine saisonnière pour la variété.
    final hoyaSchedules = await care.watchByPlant(hoya.id).first;
    await care.upsert(hoyaSchedules.first.copyWith(strategy: CareStrategy.seasonal));
  }
}
