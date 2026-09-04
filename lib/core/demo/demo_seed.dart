import 'package:flutter/foundation.dart';

import '../../data/db/database.dart';
import '../../data/repositories/action_repository_impl.dart';
import '../../data/repositories/care_repository_impl.dart';
import '../../data/repositories/inventory_repository_impl.dart';
import '../../data/repositories/location_repository_impl.dart';
import '../../data/repositories/plant_repository_impl.dart';
import '../../data/repositories/tag_repository_impl.dart';
import '../../domain/models/models.dart';
import '../../domain/repositories/repositories.dart';

/// Jeu de données de démonstration pour la revue visuelle sur le web
/// (`?demo`), jamais en release. Aucune photo : les vignettes restent des
/// placeholders.
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

    // Une routine saisonnière pour la variété.
    final hoyaSchedules = await care.watchByPlant(hoya.id).first;
    await care.upsert(hoyaSchedules.first.copyWith(strategy: CareStrategy.seasonal));
  }
}
