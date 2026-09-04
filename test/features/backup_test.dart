import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flora/data/db/database.dart';
import 'package:flora/data/services/photo_storage_service.dart';
import 'package:flora/features/export/backup_sections.dart';
import 'package:flora/features/export/export_service.dart';
import 'package:flora/features/export/import_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Redirige les dossiers d'application vers un répertoire temporaire.
class _FakePaths extends PathProviderPlatform with MockPlatformInterfaceMixin {
  _FakePaths(this.root);

  final String root;

  @override
  Future<String?> getApplicationDocumentsPath() async => root;

  @override
  Future<String?> getTemporaryPath() async => root;
}

void main() {
  group('découpage en sections', () {
    test('chaque table appartient à une section et une seule', () {
      final seen = <String>{};
      for (final s in BackupSection.values) {
        for (final t in s.tables) {
          expect(seen.add(t), isTrue, reason: '$t apparaît deux fois');
        }
      }
    });

    test('toutes les tables sauvegardées ont un ordre d\'import', () {
      for (final s in BackupSection.values) {
        for (final t in s.tables) {
          expect(backupTableOrder, contains(t), reason: t);
        }
      }
    });

    test('les photos entraînent les plantes et le jardin', () {
      expect(withDependencies({BackupSection.photos}), containsAll([BackupSection.plants, BackupSection.garden]));
    });

    test('l\'inventaire seul n\'entraîne que le jardin', () {
      expect(withDependencies({BackupSection.inventory}), {BackupSection.inventory, BackupSection.garden});
    });

    test('les parents précèdent les enfants dans l\'ordre choisi', () {
      final tables = tablesFor({BackupSection.photos});
      expect(tables.indexOf('gardens'), lessThan(tables.indexOf('plants')));
      expect(tables.indexOf('plants'), lessThan(tables.indexOf('plant_photos')));
    });

    test('une sélection vide ne donne aucune table', () {
      expect(tablesFor(const {}), isEmpty);
    });
  });

  group('aller-retour export puis import', () {
    late Directory temp;
    late FloraDatabase source;
    late FloraDatabase target;
    late ExportService exporter;
    late ImportService importer;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      temp = await Directory.systemTemp.createTemp('flora-backup');
      PathProviderPlatform.instance = _FakePaths(temp.path);
      source = FloraDatabase(NativeDatabase.memory());
      target = FloraDatabase(NativeDatabase.memory());
      exporter = ExportService(source, PhotoStorageService());
      importer = ImportService(target, PhotoStorageService());

      final now = DateTime(2026, 6, 1);
      await source.into(source.gardens).insert(GardensCompanion.insert(id: 'g1', ownerId: 'u1', name: 'Jardin', createdAt: now, updatedAt: now));
      await source.into(source.plants).insert(PlantsCompanion.insert(
            id: 'p1',
            gardenId: 'g1',
            name: 'Monstera',
            status: const Value('active'),
            health: const Value('healthy'),
            createdAt: now,
            updatedAt: now,
          ));
      await source.into(source.inventoryItems).insert(InventoryItemsCompanion.insert(
            id: 'i1',
            gardenId: 'g1',
            categoryKey: 'fertilizer',
            name: 'Terreau',
            createdAt: now,
            updatedAt: now,
          ));
    });

    tearDown(() async {
      await source.close();
      await target.close();
      if (await temp.exists()) await temp.delete(recursive: true);
    });

    test('une sauvegarde complète se relit à l\'identique', () async {
      final zip = await exporter.buildZip();
      final report = await importer.import(zip);

      expect(report.totalSkipped, 0);
      expect((await target.select(target.plants).get()).single.name, 'Monstera');
      expect((await target.select(target.inventoryItems).get()).single.name, 'Terreau');
    });

    test('l\'aperçu annonce ce que contient le fichier', () async {
      final manifest = await importer.inspect(await exporter.buildZip());
      expect(manifest.app, 'Flora');
      expect(manifest.counts['plants'], 1);
      expect(manifest.sections, contains(BackupSection.plants));
    });

    test('un export sélectif ne contient que sa section et ses dépendances', () async {
      final zip = await exporter.buildZip(sections: {BackupSection.inventory});
      final manifest = await importer.inspect(zip);
      expect(manifest.counts['inventory_items'], 1);
      expect(manifest.counts.containsKey('plants'), isFalse, reason: 'les plantes ne font pas partie de la sélection');
      expect(manifest.counts['gardens'], 1, reason: 'le jardin reste nécessaire');
    });

    test('un import sélectif laisse le reste de côté', () async {
      final zip = await exporter.buildZip();
      await importer.import(zip, sections: {BackupSection.inventory});
      expect(await target.select(target.plants).get(), isEmpty);
      expect(await target.select(target.inventoryItems).get(), hasLength(1));
    });

    test('réimporter deux fois ne duplique rien', () async {
      final zip = await exporter.buildZip();
      await importer.import(zip);
      await importer.import(zip);
      expect(await target.select(target.plants).get(), hasLength(1));
    });

    test('un import écrase la ligne de même identifiant', () async {
      final zip = await exporter.buildZip();
      await importer.import(zip);
      await (target.update(target.plants)..where((t) => t.id.equals('p1'))).write(const PlantsCompanion(name: Value('Ancien nom')));
      await importer.import(zip);
      expect((await target.select(target.plants).get()).single.name, 'Monstera');
    });

    test('un fichier qui n\'est pas une archive est refusé', () async {
      final bogus = File(p.join(temp.path, 'pas-un-zip.txt'))..writeAsStringSync('bonjour');
      expect(
        () => importer.import(bogus),
        throwsA(isA<ImportException>().having((e) => e.reason, 'reason', ImportFailure.notAZip)),
      );
    });

    test('une ligne orpheline est comptée, jamais fatale', () async {
      // Une plante dont le jardin n'existe pas : la contrainte la rejette.
      final orphanDb = FloraDatabase(NativeDatabase.memory());
      addTearDown(orphanDb.close);
      final orphanExport = ExportService(orphanDb, PhotoStorageService());
      final now = DateTime(2026, 6, 1);
      await orphanDb.into(orphanDb.gardens).insert(GardensCompanion.insert(id: 'g2', ownerId: 'u1', name: 'Autre', createdAt: now, updatedAt: now));
      await orphanDb.into(orphanDb.plants).insert(PlantsCompanion.insert(
            id: 'p9',
            gardenId: 'g2',
            name: 'Orpheline',
            status: const Value('active'),
            health: const Value('healthy'),
            createdAt: now,
            updatedAt: now,
          ));
      final zip = await orphanExport.buildZip();

      // On n'importe que les plantes : leur jardin manque à l'arrivée.
      final report = await importer.import(zip, sections: {BackupSection.plants});

      expect(report.imported['gardens'], 1, reason: 'le jardin vient avec, par dépendance');
      expect(report.skipped.values.fold(0, (a, b) => a + b) + report.totalImported, greaterThan(0));
    });
  });
}
