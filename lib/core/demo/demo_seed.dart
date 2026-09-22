import 'dart:io';

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
import '../../data/services/photo_storage_service.dart';
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
  /// l'appareil. Avec [storage], les photos sont rangées comme de vraies
  /// photos de plante plutôt que laissées à leur adresse.
  static Future<void> apply(FloraDatabase db, String gardenId, {String? language, PhotoStorageService? storage}) async {
    final plants = DriftPlantRepository(db, gardenId);
    if ((await plants.watchSummaries(const PlantFilter()).first).isNotEmpty) return;
    final locations = DriftLocationRepository(db, gardenId);
    final actions = DriftActionRepository(db);
    final care = DriftCareRepository(db, plants);
    final tags = DriftTagRepository(db, gardenId);
    final inventory = DriftInventoryRepository(db, gardenId);
    final calendar = DriftCalendarRepository(db, gardenId);
    final tasks = DriftTaskRepository(db, gardenId);

    // Les textes libres suivent la langue de l'app : la démo sert aussi aux
    // visuels du magasin, dans les quatre langues.
    final lang = language ?? PlatformDispatcher.instance.locale.languageCode;
    String tr(String fr, String en, String de, String it) => switch (lang) { 'en' => en, 'de' => de, 'it' => it, _ => fr };
    final all = await locations.watchAll().first;
    String? loc(String name) => all.where((l) => l.name.toLowerCase().startsWith(name)).firstOrNull?.id;
    final salon = loc('salon') ?? loc('living') ?? (await locations.create(name: tr('Salon', 'Living room', 'Wohnzimmer', 'Soggiorno'), icon: '🛋️')).id;
    final cuisine = loc('cuisine') ?? loc('kitchen');
    final balcon = loc('balcon') ?? loc('balcony');
    final bureau = (await locations.create(name: tr('Bureau', 'Office', 'Büro', 'Studio'), icon: '🖥️')).id;

    final now = DateTime.now();
    Future<Plant> mk(String name, String? species, String? location, {int water = 7, int fert = 30, DateTime? acquired}) =>
        plants.create(NewPlant(name: name, speciesName: species, locationId: location, wateringIntervalDays: water, fertilizingIntervalDays: fert, acquiredAt: acquired));

    final monstera = await mk('Monstera', 'Monstera deliciosa', salon, acquired: DateTime(now.year - 1, 3, 12));
    final pilea = await mk('Pilea', 'Pilea peperomioides', salon, water: 5);
    final ficus = await mk('Ficus lyrata', 'Ficus lyrata', bureau, water: 8);
    final calathea = await mk('Calathea', 'Goeppertia orbifolia', cuisine, water: 4, fert: 21);
    final olivier = await mk(tr('Olivier', 'Olive tree', 'Olivenbaum', 'Olivo'), 'Olea europaea', balcon, water: 6, fert: 45);
    final basilic = await mk(tr('Basilic', 'Basil', 'Basilikum', 'Basilico'), 'Ocimum basilicum', balcon, water: 2, fert: 14);
    final pothos = await mk('Pothos', 'Epipremnum aureum', bureau, water: 9);
    final hoya = await mk('Hoya', 'Hoya carnosa', salon, water: 12, fert: 60);

    // Des photos, pour que la démo ressemble à une vraie collection : des
    // observations iNaturalist en CC0 (store/demo-photos, avec leurs
    // sources), servies à côté du build.
    final photos = DriftPhotoRepository(db);
    for (final (plant, slug) in [(monstera, 'monstera'), (pilea, 'pilea'), (ficus, 'ficus'), (calathea, 'calathea'), (olivier, 'olivier'), (basilic, 'basilic'), (pothos, 'pothos'), (hoya, 'hoya')]) {
      final url = '$photoBase/$slug.jpg';
      final photo = await _addPhoto(photos, storage, plant.id, url, slug);
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
    await actions.log(NewAction(plantId: monstera.id, typeKey: 'note', occurredAt: now.subtract(const Duration(days: 12)), notes: tr('Nouvelle feuille en train de sortir.', 'New leaf on its way.', 'Neues Blatt im Anmarsch.', 'Sta spuntando una foglia nuova.')));
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
      notes: tr('Bords bruns et secs sur plusieurs feuilles.', 'Brown, dry leaf edges on several leaves.', 'Braune, trockene Blattränder an mehreren Blättern.', 'Bordi bruni e secchi su diverse foglie.'),
      metadata: {DiagnosisRecord.metadataKey: _demoDiagnosis(tr).toJson()},
    ));

    final tropical = await tags.create(tr('Tropicale', 'Tropical', 'Tropisch', 'Tropicale'));
    final rare = await tags.create(tr('Rare', 'Rare', 'Selten', 'Rara'));
    await tags.setPlantTags(monstera.id, [tropical.id]);
    await tags.setPlantTags(calathea.id, [tropical.id, rare.id]);
    await plants.setFavorite(monstera.id, true);

    await inventory.create(
      category: InventoryCategory.fertilizer,
      name: tr('Engrais plantes vertes', 'Green plant fertiliser', 'Grünpflanzendünger', 'Concime per piante verdi'),
      quantity: 420,
      unit: 'ml',
      lowThreshold: 100,
      fertilizerForm: FertilizerForm.liquid,
      fertilizerOrigin: FertilizerOrigin.mineral,
      nitrogen: 7,
      phosphorus: 3,
      potassium: 5,
    );
    await inventory.create(category: InventoryCategory.soil, name: tr('Terreau tropical', 'Tropical potting mix', 'Tropenerde', 'Terriccio tropicale'), quantity: 7, unit: 'L', lowThreshold: 5);
    await inventory.create(category: InventoryCategory.substrate, name: 'Perlite', quantity: 2, unit: 'L', lowThreshold: 3);
    await inventory.create(category: InventoryCategory.pot, name: tr('Pots Ø15 cm', 'Ø15 cm pots', 'Töpfe Ø15 cm', 'Vasi Ø15 cm'), quantity: 4, unit: '');

    // Un groupe d'inventaire, avec un article étiqueté.
    final etagere = await inventory.createGroup(label: tr('Étagère du balcon', 'Balcony shelf', 'Balkonregal', 'Scaffale del balcone'), emoji: '🪟');
    final graines = await inventory.create(category: InventoryCategory.seed, name: tr('Graines de basilic', 'Basil seeds', 'Basilikumsamen', 'Semi di basilico'), quantity: 3, unit: '', groupId: etagere.id);
    await inventory.setItemTags(graines.id, [rare.id]);

    // Deux événements de calendrier et leur catégorie.
    final sorties = await calendar.createCategory(label: tr('Sorties', 'Outings', 'Ausflüge', 'Uscite'), emoji: '🛒');
    await calendar.create(NewCalendarEntry(title: tr('Marché aux plantes', 'Plant market', 'Pflanzenmarkt', 'Mercato delle piante'), startAt: now.add(const Duration(days: 3)), categoryId: sorties.id, reminderMinutes: 60));
    await calendar.create(NewCalendarEntry(
      title: tr('Rempotage de printemps', 'Spring repotting', 'Umtopfen im Frühjahr', 'Rinvaso di primavera'),
      startAt: now.add(const Duration(days: 9)),
      endAt: now.add(const Duration(days: 10)),
      plantId: ficus.id,
      notes: tr('Prévoir du terreau et un pot plus large.', 'Get potting mix and a wider pot.', 'Erde und einen breiteren Topf besorgen.', 'Procurare terriccio e un vaso più largo.'),
    ));

    // Une tâche libre ouverte, et une plante archivée pour les archives.
    await tasks.create(NewTask(title: tr('Commander du terreau', 'Order potting mix', 'Blumenerde bestellen', 'Ordinare del terriccio'), dueAt: now.add(const Duration(days: 1))));
    final disparue = await mk(tr('Fougère', 'Fern', 'Farn', 'Felce'), 'Nephrolepis exaltata', cuisine, acquired: DateTime(now.year - 2, 5, 4));
    await plants.archive([disparue.id], reason: 'died');

    // Une routine saisonnière pour la variété.
    final hoyaSchedules = await care.watchByPlant(hoya.id).first;
    await care.upsert(hoyaSchedules.first.copyWith(strategy: CareStrategy.seasonal));
  }

  /// La photo d'une plante de démo, rangée comme l'app range les siennes
  /// quand elle le peut.
  ///
  /// Une photo laissée à son adresse s'affiche, mais n'a pas de fichier :
  /// Iris n'a alors rien à lire et la feuille « Espèce » répond « Aucune
  /// correspondance fiable ». Sur le web, où rien ne s'écrit sur disque,
  /// c'est le seul chemin ; ailleurs on la télécharge et on l'importe.
  static Future<PlantPhoto> _addPhoto(PhotoRepository photos, PhotoStorageService? storage, String plantId, String url, String slug) async {
    if (storage == null || kIsWeb) return photos.addFromUrl(plantId: plantId, url: url);

    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
      final File temp;
      try {
        // Un délai, sans quoi un serveur absent ou muet fige le premier
        // lancement : le jeu de démo se charge avant que l'application ne
        // s'ouvre, et la capture attendrait sans fin. Passé ce délai, la
        // photo reste distante, comme sur le web.
        temp = await _fetch(client, url, slug).timeout(const Duration(seconds: 30));
      } finally {
        client.close(force: true);
      }
      final stored = await storage.importFile(temp);
      if (temp.existsSync()) temp.deleteSync();
      return await photos.add(plantId: plantId, filePath: stored.filePath, thumbPath: stored.thumbPath, width: stored.width, height: stored.height);
    } catch (e) {
      // Pas de serveur en face : la photo reste distante, la collection
      // garde son allure, et seule l'identification n'aura rien à lire.
      debugPrint('photo de démo « $slug » non téléchargée ($e) : elle reste distante');
      return await photos.addFromUrl(plantId: plantId, url: url);
    }
  }

  /// Une photo du jeu de démo dans un fichier temporaire, ou `null` quand le
  /// serveur qui les sert n'est pas là.
  ///
  /// [DemoPhotoStorage] s'en sert pour tenir lieu de photothèque : un
  /// simulateur n'a pas de caméra et sa photothèque ne montre que les images
  /// d'Apple, si bien que l'étape photo de la création n'aurait jamais de
  /// plante à lire.
  ///
  /// [base] n'est là que pour les tests, qui servent les photos depuis un
  /// port libre plutôt que depuis celui de `store/serve.py`.
  static Future<File?> photoFile(String slug, {String? base}) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    try {
      return await _fetch(client, '${base ?? photoBase}/$slug.jpg', slug).timeout(const Duration(seconds: 30));
    } catch (e) {
      debugPrint('photo de démo « $slug » non téléchargée ($e) : le picker ne rend rien');
      return null;
    } finally {
      client.close(force: true);
    }
  }

  /// La photo, dans un fichier temporaire.
  static Future<File> _fetch(HttpClient client, String url, String slug) async {
    final response = await (await client.getUrl(Uri.parse(url))).close();
    if (response.statusCode != 200) throw HttpException('${response.statusCode}', uri: Uri.parse(url));
    return File('${Directory.systemTemp.path}/flora-demo-$slug.jpg')..writeAsBytesSync(await consolidateHttpClientResponseBytes(response));
  }

  /// Ce qu'une analyse dit d'une Calathea aux bords bruns : l'air sec en
  /// tête, les tétranyques en doute, l'excès d'eau écarté.
  static DiagnosisRecord _demoDiagnosis(String Function(String, String, String, String) tr) => DiagnosisRecord(
        symptoms: tr(
          'Les bords des feuilles brunissent depuis deux semaines.',
          'Leaf edges have been browning for two weeks.',
          'Die Blattränder werden seit zwei Wochen braun.',
          'I bordi delle foglie imbruniscono da due settimane.',
        ),
        diagnosis: Diagnosis(
          summary: tr(
            "Pointes et bords bruns et secs sur plusieurs feuilles, limbe qui s'enroule légèrement. Aucune trace visible de parasites.",
            'Brown, dry tips and edges on several leaves, blades curling slightly. No visible sign of pests.',
            'Braune, trockene Spitzen und Ränder an mehreren Blättern, Blattspreiten leicht eingerollt. Keine sichtbaren Schädlinge.',
            'Punte e bordi bruni e secchi su diverse foglie, lamina leggermente arrotolata. Nessuna traccia visibile di parassiti.',
          ),
          causes: [
            DiagnosisCause(
              title: tr('Air trop sec', 'Low air humidity', 'Zu trockene Luft', "Aria troppo secca"),
              problemId: '013',
              likelihood: Likelihood.likely,
              explanation: tr(
                "Des bords bruns et secs, sur les feuilles anciennes comme sur les jeunes, sont la marque d'un air trop sec pour une Marantacée, surtout près d'un radiateur.",
                'Dry brown edges on old and young leaves alike are the mark of air too dry for a prayer plant, especially near a heater.',
                'Trockene braune Ränder an alten wie an jungen Blättern sprechen für zu trockene Luft, besonders in der Nähe einer Heizung.',
                "Bordi bruni e secchi, sulle foglie vecchie come su quelle giovani, indicano un'aria troppo secca, soprattutto vicino a un radiatore.",
              ),
              actions: [
                tr("Regrouper la plante avec d'autres, ou poser le pot sur un lit de billes d'argile humides",
                   'Group the plant with others, or stand the pot on a tray of damp clay pebbles',
                   'Die Pflanze zu anderen stellen oder den Topf auf feuchte Blähtonkugeln setzen',
                   "Raggruppare la pianta con altre, o posare il vaso su argilla espansa umida"),
                tr("L'éloigner des radiateurs et des courants d'air",
                   'Move it away from radiators and draughts',
                   'Von Heizkörpern und Zugluft wegstellen',
                   'Allontanarla dai radiatori e dalle correnti'),
                tr('Couper les parties sèches au ras du tissu sain',
                   'Trim the dry parts back to healthy tissue',
                   'Die trockenen Stellen bis zum gesunden Gewebe zurückschneiden',
                   'Tagliare le parti secche a filo del tessuto sano'),
              ],
            ),
            DiagnosisCause(
              title: tr('Tétranyques', 'Spider mites', 'Spinnmilben', 'Acari tetranichidi'),
              problemId: '060',
              likelihood: Likelihood.possible,
              explanation: tr(
                "Un limbe qui s'enroule et de fines mouchetures peuvent annoncer des tétranyques, qui prospèrent dans l'air sec. Aucune toile visible sur la photo.",
                'Curling blades and fine speckling can announce spider mites, which thrive in dry air. No webbing visible in the photo.',
                'Eingerollte Blätter und feine Sprenkel können auf Spinnmilben deuten, die trockene Luft lieben. Auf dem Foto sind keine Gespinste zu sehen.',
                "Una lamina arrotolata e fini punteggiature possono annunciare acari tetranichidi, che prosperano nell'aria secca. Nessuna ragnatela visibile nella foto.",
              ),
              actions: [
                tr('Examiner le revers des feuilles à la loupe',
                   'Check the undersides of the leaves with a magnifier',
                   'Die Blattunterseiten mit der Lupe prüfen',
                   'Esaminare il rovescio delle foglie con la lente'),
                tr("Doucher le feuillage à l'eau tiède",
                   'Shower the foliage with lukewarm water',
                   'Das Laub mit lauwarmem Wasser abbrausen',
                   'Docciare il fogliame con acqua tiepida'),
              ],
            ),
            DiagnosisCause(
              title: tr("Excès d'eau", 'Waterlogging', 'Staunässe', "Eccesso d'acqua"),
              problemId: '002',
              likelihood: Likelihood.unlikely,
              explanation: tr(
                "Le terreau n'a pas l'air détrempé et les feuilles restent fermes.",
                'The potting mix does not look soaked and the leaves stay firm.',
                'Die Erde wirkt nicht durchnässt und die Blätter bleiben fest.',
                'Il terriccio non sembra inzuppato e le foglie restano sode.',
              ),
              actions: [
                tr('Laisser sécher les deux premiers centimètres entre deux arrosages',
                   'Let the top two centimetres dry out between waterings',
                   'Die obersten zwei Zentimeter zwischen zwei Wassergaben abtrocknen lassen',
                   'Lasciare asciugare i primi due centimetri tra due annaffiature'),
              ],
            ),
          ],
        ),
      );
}
