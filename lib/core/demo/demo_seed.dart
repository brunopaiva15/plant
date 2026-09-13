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
import '../../domain/diagnosis/diagnosis_record.dart';
import '../../domain/diagnosis/plant_diagnoser.dart';
import '../../domain/models/models.dart';
import '../../domain/repositories/repositories.dart';

/// Jeu de données de démonstration pour la revue visuelle sur le web
/// (`?demo`) et les captures du magasin sur le simulateur
/// (`--dart-define=DEMO=true`), jamais en release. Les photos sont des liens
/// vers des fichiers CC0 (store/demo-photos), servis à côté du build web ou
/// par `store/serve.py` sur la machine (`--dart-define=DEMO_PHOTOS=…`).
abstract final class DemoSeed {
  static bool get requested =>
      !kReleaseMode && (kIsWeb ? Uri.base.queryParameters.containsKey('demo') : const bool.fromEnvironment('DEMO'));

  /// D'où viennent les photos de démo, sans barre oblique finale.
  static String get photoBase {
    const defined = String.fromEnvironment('DEMO_PHOTOS');
    if (defined.isNotEmpty) return defined;
    return kIsWeb ? '${Uri.base.origin}/demo-photos' : 'http://localhost:8081/demo-photos';
  }

  /// [language] est celle de l'app quand elle est réglée ; sinon celle de
  /// l'appareil.
  static Future<void> apply(FloraDatabase db, String gardenId, {String? language}) async {
    final plants = DriftPlantRepository(db, gardenId);
    if ((await plants.watchSummaries(const PlantFilter()).first).isNotEmpty) return;
    final locations = DriftLocationRepository(db, gardenId);
    final actions = DriftActionRepository(db);
    final care = DriftCareRepository(db, plants);
    final tags = DriftTagRepository(db, gardenId);
    final inventory = DriftInventoryRepository(db, gardenId);
    final calendar = DriftCalendarRepository(db, gardenId);
    final tasks = DriftTaskRepository(db, gardenId);

    // Les textes libres suivent la langue du navigateur : la démo sert aussi
    // aux visuels du magasin, en français et en anglais.
    final en = (language ?? PlatformDispatcher.instance.locale.languageCode) == 'en';
    final all = await locations.watchAll().first;
    String? loc(String name) => all.where((l) => l.name.toLowerCase().startsWith(name)).firstOrNull?.id;
    final salon = loc('salon') ?? loc('living') ?? (await locations.create(name: en ? 'Living room' : 'Salon', icon: '🛋️')).id;
    final cuisine = loc('cuisine') ?? loc('kitchen');
    final balcon = loc('balcon') ?? loc('balcony');
    final bureau = (await locations.create(name: en ? 'Office' : 'Bureau', icon: '🖥️')).id;

    final now = DateTime.now();
    Future<Plant> mk(String name, String? species, String? location, {int water = 7, int fert = 30, DateTime? acquired}) =>
        plants.create(NewPlant(name: name, speciesName: species, locationId: location, wateringIntervalDays: water, fertilizingIntervalDays: fert, acquiredAt: acquired));

    final monstera = await mk('Monstera', 'Monstera deliciosa', salon, acquired: DateTime(now.year - 1, 3, 12));
    final pilea = await mk('Pilea', 'Pilea peperomioides', salon, water: 5);
    final ficus = await mk('Ficus lyrata', 'Ficus lyrata', bureau, water: 8);
    final calathea = await mk('Calathea', 'Goeppertia orbifolia', cuisine, water: 4, fert: 21);
    final olivier = await mk(en ? 'Olive tree' : 'Olivier', 'Olea europaea', balcon, water: 6, fert: 45);
    final basilic = await mk(en ? 'Basil' : 'Basilic', 'Ocimum basilicum', balcon, water: 2, fert: 14);
    final pothos = await mk('Pothos', 'Epipremnum aureum', bureau, water: 9);
    final hoya = await mk('Hoya', 'Hoya carnosa', salon, water: 12, fert: 60);

    // Des photos, pour que la démo ressemble à une vraie collection : des
    // observations iNaturalist en CC0 (store/demo-photos, avec leurs
    // sources), servies à côté du build. Distantes, donc jamais copiées.
    final photos = DriftPhotoRepository(db);
    for (final (plant, slug) in [(monstera, 'monstera'), (pilea, 'pilea'), (ficus, 'ficus'), (calathea, 'calathea'), (olivier, 'olivier'), (basilic, 'basilic'), (pothos, 'pothos'), (hoya, 'hoya')]) {
      final photo = await photos.addFromUrl(plantId: plant.id, url: '$photoBase/$slug.jpg');
      await photos.setPrimary(plant.id, photo.id);
    }

    // Historique : des arrosages récents, pour que rien ne soit dû
    // aujourd'hui et que l'écran du matin dise « Tout est en ordre » puis
    // montre « À venir » en grille, à des échéances variées.
    await actions.log(NewAction(plantId: monstera.id, typeKey: 'watering', occurredAt: now.subtract(const Duration(days: 4))));
    await actions.log(NewAction(plantId: pilea.id, typeKey: 'watering', occurredAt: now.subtract(const Duration(days: 4))));
    await actions.log(NewAction(plantId: calathea.id, typeKey: 'watering', occurredAt: now.subtract(const Duration(days: 2))));
    await actions.log(NewAction(plantId: ficus.id, typeKey: 'watering', occurredAt: now.subtract(const Duration(days: 5))));
    await actions.log(NewAction(plantId: ficus.id, typeKey: 'fertilizing', occurredAt: now.subtract(const Duration(days: 27))));
    await actions.log(NewAction(plantId: basilic.id, typeKey: 'watering', occurredAt: now.subtract(const Duration(days: 1))));
    await actions.log(NewAction(plantId: olivier.id, typeKey: 'watering', occurredAt: now.subtract(const Duration(days: 2))));
    await actions.log(NewAction(plantId: hoya.id, typeKey: 'watering', occurredAt: now.subtract(const Duration(days: 7))));
    await actions.log(NewAction(plantId: pothos.id, typeKey: 'watering', occurredAt: now.subtract(const Duration(days: 3))));
    await actions.log(NewAction(plantId: monstera.id, typeKey: 'note', occurredAt: now.subtract(const Duration(days: 12)), notes: en ? 'New leaf on its way.' : 'Nouvelle feuille en train de sortir.'));
    await actions.log(NewAction(plantId: monstera.id, typeKey: 'repotting', occurredAt: now.subtract(const Duration(days: 40))));
    await actions.log(NewAction(plantId: monstera.id, typeKey: 'measurement', occurredAt: now.subtract(const Duration(days: 90)), metadata: {'kind': 'height', 'value': 34, 'unit': 'cm'}));
    await actions.log(NewAction(plantId: monstera.id, typeKey: 'measurement', occurredAt: now.subtract(const Duration(days: 30)), metadata: {'kind': 'height', 'value': 42, 'unit': 'cm'}));
    await actions.log(NewAction(plantId: monstera.id, typeKey: 'measurement', occurredAt: now.subtract(const Duration(days: 30)), metadata: {'kind': 'leaves', 'value': 9, 'unit': ''}));

    // Un diagnostic gardé au journal de la Calathea : le compte rendu entier,
    // rouvrable depuis la fiche, tel que l'analyse l'aurait rendu. Les pistes
    // portent les numéros de la base des problèmes (assets/problems/catalog.txt).
    await actions.log(NewAction(
      plantId: calathea.id,
      typeKey: 'note',
      occurredAt: now.subtract(const Duration(days: 3)),
      notes: en ? 'Brown, dry leaf edges on several leaves.' : 'Bords bruns et secs sur plusieurs feuilles.',
      metadata: {DiagnosisRecord.metadataKey: _demoDiagnosis(en).toJson()},
    ));

    final tropical = await tags.create(en ? 'Tropical' : 'Tropicale');
    final rare = await tags.create(en ? 'Rare' : 'Rare');
    await tags.setPlantTags(monstera.id, [tropical.id]);
    await tags.setPlantTags(calathea.id, [tropical.id, rare.id]);
    await plants.setFavorite(monstera.id, true);

    await inventory.create(category: InventoryCategory.fertilizer, name: en ? 'Green plant fertiliser' : 'Engrais plantes vertes', quantity: 420, unit: 'ml', lowThreshold: 100);
    await inventory.create(category: InventoryCategory.soil, name: en ? 'Tropical potting mix' : 'Terreau tropical', quantity: 7, unit: 'L', lowThreshold: 5);
    await inventory.create(category: InventoryCategory.substrate, name: 'Perlite', quantity: 2, unit: 'L', lowThreshold: 3);
    await inventory.create(category: InventoryCategory.pot, name: en ? 'Ø15 cm pots' : 'Pots Ø15 cm', quantity: 4, unit: '');

    // Un groupe d'inventaire, avec un article étiqueté.
    final etagere = await inventory.createGroup(label: en ? 'Balcony shelf' : 'Étagère du balcon', emoji: '🪟');
    final graines = await inventory.create(category: InventoryCategory.seed, name: en ? 'Basil seeds' : 'Graines de basilic', quantity: 3, unit: '', groupId: etagere.id);
    await inventory.setItemTags(graines.id, [rare.id]);

    // Deux événements de calendrier et leur catégorie.
    final sorties = await calendar.createCategory(label: en ? 'Outings' : 'Sorties', emoji: '🛒');
    await calendar.create(NewCalendarEntry(title: en ? 'Plant market' : 'Marché aux plantes', startAt: now.add(const Duration(days: 3)), categoryId: sorties.id, reminderMinutes: 60));
    await calendar.create(NewCalendarEntry(
      title: en ? 'Spring repotting' : 'Rempotage de printemps',
      startAt: now.add(const Duration(days: 9)),
      endAt: now.add(const Duration(days: 10)),
      plantId: ficus.id,
      notes: en ? 'Get potting mix and a wider pot.' : 'Prévoir du terreau et un pot plus large.',
    ));

    // Une tâche libre ouverte, et une plante archivée pour les archives.
    await tasks.create(NewTask(title: en ? 'Order potting mix' : 'Commander du terreau', dueAt: now.add(const Duration(days: 1))));
    final disparue = await mk(en ? 'Fern' : 'Fougère', 'Nephrolepis exaltata', cuisine, acquired: DateTime(now.year - 2, 5, 4));
    await plants.archive([disparue.id], reason: 'died');

    // Une routine saisonnière pour la variété.
    final hoyaSchedules = await care.watchByPlant(hoya.id).first;
    await care.upsert(hoyaSchedules.first.copyWith(strategy: CareStrategy.seasonal));
  }

  /// Ce qu'une analyse dit d'une Calathea aux bords bruns : l'air sec en
  /// tête, les tétranyques en doute, l'excès d'eau écarté.
  static DiagnosisRecord _demoDiagnosis(bool en) => DiagnosisRecord(
        symptoms: en ? 'Leaf edges have been browning for two weeks.' : 'Les bords des feuilles brunissent depuis deux semaines.',
        diagnosis: Diagnosis(
          summary: en
              ? 'Brown, dry tips and edges on several leaves, blades curling slightly. No visible sign of pests.'
              : "Pointes et bords bruns et secs sur plusieurs feuilles, limbe qui s'enroule légèrement. Aucune trace visible de parasites.",
          causes: [
            DiagnosisCause(
              title: en ? 'Low air humidity' : 'Air trop sec',
              problemId: '013',
              likelihood: Likelihood.likely,
              explanation: en
                  ? 'Dry brown edges on old and young leaves alike are the mark of air too dry for a prayer plant, especially near a heater.'
                  : "Des bords bruns et secs, sur les feuilles anciennes comme sur les jeunes, sont la marque d'un air trop sec pour une Marantacée, surtout près d'un radiateur.",
              actions: en
                  ? ['Group the plant with others, or stand the pot on a tray of damp clay pebbles', 'Move it away from radiators and draughts', 'Trim the dry parts back to healthy tissue']
                  : ["Regrouper la plante avec d'autres, ou poser le pot sur un lit de billes d'argile humides", "L'éloigner des radiateurs et des courants d'air", 'Couper les parties sèches au ras du tissu sain'],
            ),
            DiagnosisCause(
              title: en ? 'Spider mites' : 'Tétranyques',
              problemId: '060',
              likelihood: Likelihood.possible,
              explanation: en
                  ? 'Curling blades and fine speckling can announce spider mites, which thrive in dry air. No webbing visible in the photo.'
                  : "Un limbe qui s'enroule et de fines mouchetures peuvent annoncer des tétranyques, qui prospèrent dans l'air sec. Aucune toile visible sur la photo.",
              actions: en ? ['Check the undersides of the leaves with a magnifier', 'Shower the foliage with lukewarm water'] : ['Examiner le revers des feuilles à la loupe', "Doucher le feuillage à l'eau tiède"],
            ),
            DiagnosisCause(
              title: en ? 'Waterlogging' : "Excès d'eau",
              problemId: '002',
              likelihood: Likelihood.unlikely,
              explanation: en ? 'The potting mix does not look soaked and the leaves stay firm.' : "Le terreau n'a pas l'air détrempé et les feuilles restent fermes.",
              actions: en ? ['Let the top two centimetres dry out between waterings'] : ['Laisser sécher les deux premiers centimètres entre deux arrosages'],
            ),
          ],
        ),
      );
}
