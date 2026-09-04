import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flora/data/db/database.dart';
import 'package:flora/data/repositories/inventory_repository_impl.dart';
import 'package:flora/data/repositories/tag_repository_impl.dart';
import 'package:flora/domain/models/models.dart';
import 'package:flora/domain/repositories/repositories.dart';
import 'package:flora/features/inventory/application/inventory_export.dart';
import 'package:flora/features/qr/application/plant_links.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FloraDatabase db;
  late InventoryRepository inventory;
  late TagRepository tags;
  const gardenId = 'g1';

  setUp(() async {
    db = FloraDatabase(NativeDatabase.memory());
    await db.into(db.gardens).insert(GardensCompanion.insert(id: gardenId, ownerId: 'u1', name: 'Jardin', createdAt: DateTime.now(), updatedAt: DateTime.now()));
    inventory = DriftInventoryRepository(db, gardenId);
    tags = DriftTagRepository(db, gardenId);
  });

  tearDown(() => db.close());

  Future<InventoryItem> item(String name, {String? groupId, double quantity = 2}) => inventory.create(
        category: InventoryCategory.fertilizer,
        name: name,
        quantity: quantity,
        unit: 'ml',
        groupId: groupId,
      );

  group('groupes personnalisés', () {
    test('les groupes se suivent dans leur ordre de création', () async {
      final a = await inventory.createGroup(label: '  Engrais  ');
      final b = await inventory.createGroup(label: 'Outils', emoji: '🧰');
      expect(a.label, 'Engrais', reason: 'les espaces sont rognées');
      expect(a.position, 0);
      expect(b.position, 1);
      expect(b.emoji, '🧰');
    });

    test('un article rejoint un groupe et le quitte', () async {
      final g = await inventory.createGroup(label: 'Étagère');
      final created = await item('Terreau', groupId: g.id);
      expect(created.groupId, g.id);

      await inventory.update(created.copyWith(groupId: () => null));
      expect((await inventory.get(created.id))!.groupId, isNull);
    });

    test('supprimer un groupe ne supprime pas ses articles', () async {
      final g = await inventory.createGroup(label: 'Étagère');
      final created = await item('Terreau', groupId: g.id);

      await inventory.deleteGroup(g.id);

      expect(await inventory.watchGroups().first, isEmpty);
      final kept = await inventory.get(created.id);
      expect(kept, isNotNull, reason: 'un article ne disparaît jamais avec son groupe');
      expect(kept!.groupId, isNull);
    });

    test('les articles peuvent être déplacés vers un autre groupe', () async {
      final a = await inventory.createGroup(label: 'A');
      final b = await inventory.createGroup(label: 'B');
      final created = await item('Terreau', groupId: a.id);

      await inventory.deleteGroup(a.id, moveTo: b.id);

      expect((await inventory.get(created.id))!.groupId, b.id);
    });

    test('réordonner change les positions', () async {
      final a = await inventory.createGroup(label: 'A');
      final b = await inventory.createGroup(label: 'B');
      final c = await inventory.createGroup(label: 'C');

      await inventory.reorderGroups([c.id, a.id, b.id]);

      final ordered = await inventory.watchGroups().first;
      expect(ordered.map((g) => g.label), ['C', 'A', 'B']);
    });

    test('chaque écriture est mise en file de synchronisation', () async {
      final g = await inventory.createGroup(label: 'A');
      final pending = await (db.select(db.syncOutbox)..where((o) => o.entity.equals('inventory_groups') & o.entityId.equals(g.id))).get();
      expect(pending, isNotEmpty);
    });
  });

  group('tags d\'articles', () {
    test('les tags sont enregistrés et relus', () async {
      final created = await item('Terreau');
      final bio = await tags.create('bio');
      final stock = await tags.create('à racheter');

      await inventory.setItemTags(created.id, [bio.id, stock.id]);

      expect((await inventory.watchItemTags(created.id).first).map((t) => t.name), ['bio', 'à racheter']..sort());
      expect((await inventory.get(created.id))!.tags, containsAll(['bio', 'à racheter']));
    });

    test('réenregistrer la liste remplace l\'ancienne', () async {
      final created = await item('Terreau');
      final bio = await tags.create('bio');
      final other = await tags.create('local');
      await inventory.setItemTags(created.id, [bio.id, other.id]);

      await inventory.setItemTags(created.id, [other.id]);

      expect((await inventory.watchItemTags(created.id).first).map((t) => t.name), ['local']);
    });

    test('les tags d\'un article ne débordent pas sur un autre', () async {
      final a = await item('A');
      final b = await item('B');
      final bio = await tags.create('bio');
      await inventory.setItemTags(a.id, [bio.id]);

      expect(await inventory.watchItemTags(b.id).first, isEmpty);
    });
  });

  group('export CSV', () {
    InventoryItem fake({String name = 'Terreau', double quantity = 2, double? threshold, List<String> tags = const [], String? notes}) => InventoryItem(
          id: 'i1',
          gardenId: gardenId,
          category: InventoryCategory.fertilizer,
          name: name,
          quantity: quantity,
          unit: 'ml',
          lowThreshold: threshold,
          tags: tags,
          notes: notes,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        );

    test('une ligne d\'en-tête puis une ligne par article', () {
      final csv = buildInventoryCsv([fake(), fake(name: 'Perlite')]);
      final lines = csv.split('\r\n');
      expect(lines, hasLength(3));
      expect(lines.first, startsWith('"nom";"categorie"'));
      expect(lines[2], contains('"Perlite"'));
    });

    test('les décimales sont écrites à la française', () {
      expect(buildInventoryCsv([fake(quantity: 1.5)]), contains('"1,5"'));
      expect(buildInventoryCsv([fake(quantity: 2)]), contains('"2"'), reason: 'pas de « 2.0 »');
    });

    test('un guillemet dans un nom est échappé, pas cassé', () {
      final csv = buildInventoryCsv([fake(name: 'Engrais "bio"')]);
      expect(csv, contains('"Engrais ""bio"""'));
      expect(csv.split('\r\n'), hasLength(2));
    });

    test('un point-virgule dans les notes ne crée pas de colonne', () {
      final csv = buildInventoryCsv([fake(notes: 'à diluer ; puis arroser')]);
      expect(csv.split('\r\n')[1].split('";"'), hasLength(7));
    });

    test('les tags sont regroupés dans une seule colonne', () {
      expect(buildInventoryCsv([fake(tags: ['bio', 'local'])]), contains('"bio, local"'));
    });

    test('un seuil absent laisse la cellule vide', () {
      expect(buildInventoryCsv([fake()]), contains('"ml";"";'));
    });
  });

  group('liens QR', () {
    test('un article s\'encode et se décode', () {
      final link = PlantLinks.decodeLink(PlantLinks.encodeItem('abc'));
      expect(link, const FloraLink(FloraLinkKind.item, 'abc'));
    });

    test('un lien d\'article n\'est pas pris pour une plante', () {
      expect(PlantLinks.decode(PlantLinks.encodeItem('abc')), isNull);
    });

    test('une plante reste décodée comme avant', () {
      expect(PlantLinks.decode(PlantLinks.encode('p1')), 'p1');
      expect(PlantLinks.decodeLink(PlantLinks.encode('p1')), const FloraLink(FloraLinkKind.plant, 'p1'));
    });

    test('un lien inconnu est rejeté', () {
      for (final raw in ['https://example.test/p1', 'flora://other/p1', 'flora://item/', 'flora://item/a/b', 'nimportequoi']) {
        expect(PlantLinks.decodeLink(raw), isNull, reason: raw);
      }
    });
  });
}
